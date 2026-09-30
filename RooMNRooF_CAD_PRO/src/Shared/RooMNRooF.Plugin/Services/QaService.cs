using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using RooMNRooF.Core.QA;
using RooMNRooF.Plugin.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>
    /// Drawing QA / CAD standards checker. Each category is only reported PASS after its check
    /// actually executed against the database (see QaReport.MarkChecked).
    /// Single pass over model/paper space entities for performance.
    /// </summary>
    public static class QaService
    {
        public static QaReport Run(Database db, Transaction tr, string drawingName)
        {
            var r = new QaReport
            {
                AutoCadVersion = AcApp.Version.ToString(),
                Drawing = drawingName,
                Template = Convert.ToString(AcApp.GetSystemVariable("DWGNAME")) ?? "",
            };

            // ---------- Layers / Colors / Linetypes / Lineweights (table level)
            var required = new[] { "S-GRID", "S-COL", "S-BEAM", "A-WALL", "ANNO-TEXT", "ANNO-TITLE" };
            var lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
            r.MarkChecked("Layers"); r.MarkChecked("Colors"); r.MarkChecked("Linetypes"); r.MarkChecked("Lineweights");
            int std = 0;
            foreach (var n in required) if (!lt.Has(n)) r.Add("Layers", QaStatus.WARNING, $"Standard layer {n} missing (run RNRLAYERS).");
            foreach (var (layer, issue, isError) in LayerService.Audit(db, tr))
            {
                string cat = issue.StartsWith("color") ? "Colors" : issue.StartsWith("linetype") ? "Linetypes" : issue.StartsWith("lineweight") ? "Lineweights" : "Layers";
                r.Add(cat, isError ? QaStatus.ERROR : QaStatus.WARNING, $"{layer}: {issue}");
            }
            foreach (ObjectId id in lt) if (Rnr.Repo.Layer(((LayerTableRecord)tr.GetObject(id, OpenMode.ForRead)).Name) != null) std++;
            if (std == 0) r.Add("Layers", QaStatus.ERROR, "No RooMNRooF standard layers in drawing.");

            var ltt = (LinetypeTable)tr.GetObject(db.LinetypeTableId, OpenMode.ForRead);
            foreach (var name in Rnr.Repo.Layers.Layers.Select(l => l.Linetype).Distinct())
                if (!ltt.Has(name) && lt.Cast<ObjectId>().Any(id => Rnr.Repo.Layer(((LayerTableRecord)tr.GetObject(id, OpenMode.ForRead)).Name)?.Linetype == name))
                    r.Add("Linetypes", QaStatus.ERROR, $"Linetype {name} not loaded.");

            // ---------- Text styles / Dimension styles
            var tst = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);
            r.MarkChecked("Text Styles");
            foreach (var t in Rnr.Repo.Styles.TextStyles) if (!tst.Has(t.Name)) r.Add("Text Styles", QaStatus.WARNING, $"Text style {t.Name} missing.");
            var dst = (DimStyleTable)tr.GetObject(db.DimStyleTableId, OpenMode.ForRead);
            r.MarkChecked("Dimensions");
            foreach (var d in Rnr.Repo.Styles.DimStyles) if (!dst.Has(d.Name)) r.Add("Dimensions", QaStatus.WARNING, $"Dimension style {d.Name} missing.");

            // ---------- Units
            r.MarkChecked("Units");
            if (db.Insunits != UnitsValue.Millimeters) r.Add("Units", QaStatus.WARNING, $"INSUNITS = {db.Insunits} (RooMNRooF standard: Millimeters). Not changed automatically.");
            if (db.Measurement != MeasurementValue.Metric) r.Add("Units", QaStatus.WARNING, "MEASUREMENT is Imperial.");

            // ---------- Entities (single pass)
            r.MarkChecked("Blocks"); r.MarkChecked("Hatches"); r.MarkChecked("Annotation");
            var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            int onZero = 0, overrides = 0, textOffStd = 0, hatchOffLayer = 0, overriddenDims = 0, titleBlocks = 0;
            foreach (ObjectId btrId in bt)
            {
                var btr = (BlockTableRecord)tr.GetObject(btrId, OpenMode.ForRead);
                if (!btr.IsLayout) continue;
                foreach (ObjectId eid in btr)
                {
                    if (tr.GetObject(eid, OpenMode.ForRead) is not Entity e) continue;
                    if (e is Viewport) continue;
                    if (e.Layer == "0" && !(e is BlockReference)) onZero++;
                    if (e.Color.IsByColor || e.Color.IsByAci) overrides++;
                    switch (e)
                    {
                        case DBText t when t is not AttributeReference && !IsRnrStyle(tr, t.TextStyleId): textOffStd++; break;
                        case MText m when !IsRnrStyle(tr, m.TextStyleId): textOffStd++; break;
                        case Hatch h when !(h.Layer.EndsWith("HATCH") || h.Layer.StartsWith("ANNO") || h.Layer.StartsWith("S-") || h.Layer.StartsWith("A-")): hatchOffLayer++; break;
                        case Dimension d when d.DimensionText.Length > 0 && d.DimensionText != "<>": overriddenDims++; break;
                        case BlockReference br:
                            var name = br.IsDynamicBlock ? ((BlockTableRecord)tr.GetObject(br.DynamicBlockTableRecord, OpenMode.ForRead)).Name : br.Name;
                            if (name.StartsWith("RNR_TB_")) titleBlocks++;
                            if (br.Layer == "0") r.Add("Blocks", QaStatus.WARNING, $"Block {name} inserted on layer 0.", br.Handle.ToString());
                            break;
                    }
                }
            }
            if (onZero > 0) r.Add("Layers", QaStatus.WARNING, $"{onZero} object(s) drawn on layer 0.");
            if (overrides > 0) r.Add("Colors", QaStatus.WARNING, $"{overrides} object(s) with colour override (not ByLayer/ByBlock).");
            if (textOffStd > 0) r.Add("Annotation", QaStatus.WARNING, $"{textOffStd} text object(s) not using an RNR_* text style.");
            if (hatchOffLayer > 0) r.Add("Hatches", QaStatus.WARNING, $"{hatchOffLayer} hatch(es) on non-hatch layers.");
            if (overriddenDims > 0) r.Add("Dimensions", QaStatus.ERROR, $"{overriddenDims} dimension(s) with overridden (typed) text - measured value hidden.");

            // ---------- Layouts / Title block / Plot configuration
            r.MarkChecked("Layouts"); r.MarkChecked("Title Block"); r.MarkChecked("Plot Configuration");
            var layouts = (DBDictionary)tr.GetObject(db.LayoutDictionaryId, OpenMode.ForRead);
            int paperLayouts = 0;
            foreach (DBDictionaryEntry de in layouts)
            {
                var lay = (Layout)tr.GetObject(de.Value, OpenMode.ForRead);
                if (lay.ModelType) continue;
                paperLayouts++;
                if (string.IsNullOrEmpty(lay.PlotConfigurationName) || lay.PlotConfigurationName == "None")
                    r.Add("Plot Configuration", QaStatus.WARNING, $"Layout {lay.LayoutName}: no plotter configured.");
                if (string.IsNullOrEmpty(lay.CurrentStyleSheet))
                    r.Add("Plot Configuration", QaStatus.WARNING, $"Layout {lay.LayoutName}: no plot style table.");
                if (!lay.PrintLineweights && !lay.PlotPlotStyles)
                    r.Add("Plot Configuration", QaStatus.ERROR, $"Layout {lay.LayoutName}: lineweights will not print.");
            }
            if (paperLayouts == 0) r.Add("Layouts", QaStatus.WARNING, "No paper-space layouts.");
            if (titleBlocks == 0) r.Add("Title Block", QaStatus.WARNING, "No RooMNRooF title block (RNR_TB_*) inserted.");

            return r;
        }

        static bool IsRnrStyle(Transaction tr, ObjectId styleId)
        {
            if (styleId.IsNull) return false;
            var s = (TextStyleTableRecord)tr.GetObject(styleId, OpenMode.ForRead);
            return s.Name.StartsWith("RNR_", StringComparison.OrdinalIgnoreCase);
        }
    }
}
