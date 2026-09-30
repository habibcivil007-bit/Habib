using System;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Boq;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Etabs;
using RooMNRooF.Core.Export;
using RooMNRooF.Core.Models;
using RooMNRooF.Core.Units;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;

[assembly: CommandClass(typeof(RooMNRooF.Plugin.Commands.DataCommands))]

namespace RooMNRooF.Plugin.Commands
{
    /// <summary>BOQ, ETABS-ready exchange, project configuration, DWG/DXF utilities, UI.</summary>
    public class DataCommands
    {
        [CommandMethod("RNR", "RNRBOQ", CommandFlags.Modal)]
        public void Boq() => Rnr.Run("RNRBOQ", (doc, tr) =>
        {
            var ed = doc.Editor;
            ed.WriteMessage("\n" + BoqCalculator.Disclaimer);
            double wh = Prompts.Double(ed, "Wall height for wall area (mm)", 3000);
            double wt = Prompts.Double(ed, "Wall thickness for A-WALL lines (mm)", 250);
            var inp = ExtractionService.BoqInput(doc.Database, tr, wh, wt);
            var skipped = new System.Collections.Generic.List<string>();
            inp.Bars.AddRange(ExtractionService.Bbs(inp.Members, ExtractionService.ProjectBbsParameters(), skipped));
            var lines = BoqCalculator.Compute(inp);
            foreach (var l in lines) ed.WriteMessage($"\n  {l.Item,-16} {l.Description,-50} {l.Quantity,12:0.###} {l.Unit,-4} {(l.AltUnit.Length > 0 ? $"({l.AltQuantity:0.##} {l.AltUnit})" : "")}");
            var fmt = Prompts.Keyword(ed, "Export [CSV/XLSX/JSON/All/None]", "All", "CSV", "XLSX", "JSON", "All", "None");
            if (fmt == "None") return;
            var b = RebarCommands.ExportBase(doc, "BOQ");
            var sheet = ExtractionService.BoqSheet(lines);
            if (fmt is "CSV" or "All") CsvExporter.Write(b + ".csv", sheet);
            if (fmt is "XLSX" or "All") XlsxExporter.Write(b + ".xlsx", sheet, ExtractionService.BbsSheet(inp.Bars));
            if (fmt is "JSON" or "All") JsonExporter.Write(b + ".json", new { disclaimer = BoqCalculator.Disclaimer, lines });
            Rnr.Msg($"BOQ exported: {b}.*");
        }, modifiesDb: false);

        /// <summary>Exports grids/members to the neutral RooMNRooF exchange JSON (future ETABS link). No ETABS API is used.</summary>
        [CommandMethod("RNR", "RNRETABS", CommandFlags.Modal)]
        public void Etabs() => Rnr.Run("RNRETABS", (doc, tr) =>
        {
            var ed = doc.Editor;
            var model = new ExchangeModel();
            double story = Prompts.Double(ed, "Typical storey height (mm)", 3000);
            var ms = (BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(doc.Database), OpenMode.ForRead);
            foreach (ObjectId id in ms)
            {
                var o = tr.GetObject(id, OpenMode.ForRead);
                if (o is Line ln && ln.Layer == "S-GRID")
                {
                    bool vertical = Math.Abs(ln.StartPoint.X - ln.EndPoint.X) < 1e-3;
                    model.Grids.Add(new ExGrid { Axis = vertical ? "X" : "Y", Ordinate = vertical ? ln.StartPoint.X : ln.StartPoint.Y });
                    continue;
                }
                var m = DrawService.ReadMember(o);
                if (m == null || o is not Entity e) continue;
                var ext = e.Bounds;
                if (ext == null) continue;
                var mn = ext.Value.MinPoint; var mx = ext.Value.MaxPoint;
                if (!model.Stories.Any(s => s.Name == m.Level)) model.Stories.Add(new ExStory { Name = m.Level, Height = story, Elevation = model.Stories.Count * story });
                switch (m.Schedule)
                {
                    case "COLUMN":
                        var c = new[] { (mn.X + mx.X) / 2, (mn.Y + mx.Y) / 2 };
                        model.Columns.Add(new ExFrame { Mark = m.Mark, Section = JsonStructuralExchange.SectionName(m), Material = m.ConcreteGrade, Start = c, End = c, Story = m.Level });
                        break;
                    case "BEAM":
                        if (o is Polyline bp && bp.NumberOfVertices >= 2)
                        {
                            var s0 = bp.GetPoint2dAt(0); var s1 = bp.GetPoint2dAt(1);
                            model.Beams.Add(new ExFrame { Mark = m.Mark, Section = JsonStructuralExchange.SectionName(m), Material = m.ConcreteGrade, Start = new[] { s0.X, s0.Y }, End = new[] { s1.X, s1.Y }, Story = m.Level });
                        }
                        break;
                    case "SLAB":
                    case "WALL":
                    case "FOOTING":
                        var area = new ExArea { Mark = m.Mark, Thickness = m.Dim("Thickness"), Material = m.ConcreteGrade, Story = m.Level };
                        if (o is Polyline ap) for (int i = 0; i < ap.NumberOfVertices; i++) { var v = ap.GetPoint2dAt(i); area.Boundary.Add(new[] { v.X, v.Y }); }
                        (m.Schedule == "SLAB" ? model.Slabs : m.Schedule == "WALL" ? model.Walls : model.Foundations).Add(area);
                        break;
                }
            }
            // label grids in drawing order
            int xi = 0, yi = 0;
            foreach (var g in model.Grids.OrderBy(g => g.Axis).ThenBy(g => g.Ordinate))
                g.Label = g.Axis == "X" ? (++xi).ToString() : RooMNRooF.Core.Geometry.GridGeometry.LetterLabel(yi++);
            var path = RebarCommands.ExportBase(doc, "EXCHANGE") + ".json";
            new JsonStructuralExchange().Export(model, path);
            Rnr.Msg($"Exchange model: {model.Grids.Count} grids, {model.Columns.Count} columns, {model.Beams.Count} beams, {model.Slabs.Count} slabs, {model.Walls.Count} walls, {model.Foundations.Count} foundations -> {path}");
            Rnr.Msg("This is a neutral data file for a future analysis link. It is NOT an ETABS model.");
        }, modifiesDb: false);

        [CommandMethod("RNR", "RNRPROJECT", CommandFlags.Modal)]
        public void Project() => Rnr.RunNoTx("RNRPROJECT", doc =>
        {
            var ed = doc.Editor;
            var local = Rnr.ProjectFileForActiveDrawing();
            var cfg = Rnr.Project;
            var op = Prompts.Keyword(ed, "Project config [Show/Edit/SaveToProjectFolder/Engineering]", "Show", "Show", "Edit", "SaveToProjectFolder", "Engineering");
            if (op == "Show")
            {
                ed.WriteMessage("\n" + System.Text.Json.JsonSerializer.Serialize(cfg, StandardsRepository.Json));
                ed.WriteMessage($"\nProject file for this drawing: {local ?? "(save the drawing first)"} {(local != null && File.Exists(local) ? "[in use]" : "[not present - defaults in use]")}");
                return;
            }
            if (op == "Edit")
            {
                cfg.ProjectName = Prompts.Text(ed, "Project name", cfg.ProjectName);
                cfg.Client = Prompts.Text(ed, "Client", cfg.Client);
                cfg.Consultant = Prompts.Text(ed, "Consultant", cfg.Consultant);
                cfg.Location = Prompts.Text(ed, "Location", cfg.Location);
                cfg.DrawingScale = Prompts.Keyword(ed, "Drawing scale [1:20/1:25/1:50/1:75/1:100/1:150/1:200/1:500]", cfg.DrawingScale, "1:20", "1:25", "1:50", "1:75", "1:100", "1:150", "1:200", "1:500");
                cfg.SheetSize = Prompts.Keyword(ed, "Sheet [A0/A1/A2/A3/A4]", cfg.SheetSize, "A0", "A1", "A2", "A3", "A4");
                cfg.TitleBlock = Prompts.Keyword(ed, "Title block [ARCHITECTURAL/STRUCTURAL/RCC/CIVIL]", cfg.TitleBlock, "ARCHITECTURAL", "STRUCTURAL", "RCC", "CIVIL");
            }
            if (op == "Engineering")
            {
                ed.WriteMessage("\nEngineering values are PROJECT INPUTS (0 = leave unset). They are used only for drafting/BBS arithmetic.");
                var e = cfg.Engineering;
                double? N(string m, double? v) { var x = Prompts.Double(ed, m, v ?? 0, allowZero: true); return x <= 0 ? null : x; }
                e.ConcreteGrade = Prompts.Text(ed, "Concrete grade", e.ConcreteGrade, false);
                e.FckMPa = N("f'c (MPa)", e.FckMPa); e.FyMPa = N("fy (MPa)", e.FyMPa);
                e.ClearCoverSlabMm = N("Clear cover slab (mm)", e.ClearCoverSlabMm); e.ClearCoverBeamMm = N("Clear cover beam (mm)", e.ClearCoverBeamMm);
                e.ClearCoverColumnMm = N("Clear cover column (mm)", e.ClearCoverColumnMm); e.ClearCoverFootingMm = N("Clear cover footing (mm)", e.ClearCoverFootingMm);
                e.LapFactorD = N("Lap length factor (x d)", e.LapFactorD); e.AnchorageFactorD = N("Anchorage factor (x d)", e.AnchorageFactorD);
            }
            string target = op == "SaveToProjectFolder" || (local != null && File.Exists(local))
                ? local ?? throw new RnrInputException("Save the drawing first so the project folder is known.")
                : Path.Combine(Rnr.UserDir, "RooMNRooF_Project.json");
            StandardsRepository.SaveFile(target, cfg);
            Rnr.ResetProjectCache();
            Rnr.Msg($"Project configuration saved: {target} (previous version kept as .bak)");
        });

        [CommandMethod("RNR", "RNRDXFOUT", CommandFlags.Modal)]
        public void DxfOut() => Rnr.RunNoTx("RNRDXFOUT", doc =>
        {
            var ed = doc.Editor;
            var baseName = RebarCommands.ExportBase(doc, "EXPORT");
            var fmt = Prompts.Keyword(ed, "Export copy as [DXF/DWG]", "DXF", "DXF", "DWG");
            var path = baseName + (fmt == "DXF" ? ".dxf" : ".dwg");
            using (doc.LockDocument())
            using (var copy = doc.Database.Wblock())
            {
                if (fmt == "DXF") copy.DxfOut(path, 16, DwgVersion.Current);
                else copy.SaveAs(path, DwgVersion.Current);
            }
            Rnr.Msg($"Copy written (current drawing untouched): {path}");
        });

        /// <summary>Imports a DWG/DXF as a block/xref-free copy into model space, mapping layers onto the standard where names match.</summary>
        [CommandMethod("RNR", "RNRIMPORT", CommandFlags.Modal)]
        public void Import() => Rnr.Run("RNRIMPORT", (doc, tr) =>
        {
            var ed = doc.Editor;
            var file = Prompts.Text(ed, "DWG/DXF file to import", "");
            if (!File.Exists(file)) throw new RnrInputException("File not found.");
            using var src = new Database(false, true);
            if (file.EndsWith(".dxf", StringComparison.OrdinalIgnoreCase)) src.DxfIn(file, null);
            else src.ReadDwgFile(file, FileShare.Read, true, "");
            var srcUnits = UnitConverter.FromInsUnits((int)src.Insunits);
            var dstUnits = UnitConverter.FromInsUnits((int)doc.Database.Insunits);
            ed.WriteMessage($"\nSource units: {src.Insunits}; current drawing: {doc.Database.Insunits}.");
            double scale = 1;
            if (srcUnits != null && dstUnits != null && srcUnits != dstUnits &&
                Prompts.YesNo(ed, $"Scale geometry from {srcUnits} to {dstUnits}?", true))
                scale = (double)UnitConverter.Convert(1m, srcUnits.Value, dstUnits.Value);
            var name = "IMP_" + Path.GetFileNameWithoutExtension(file).Replace(" ", "_");
            var blockId = doc.Database.Insert(name, src, true);
            var at = Prompts.Point(ed, "Insertion point:");
            var d = new DrawService(doc.Database, tr);
            var br = new BlockReference(at, blockId) { ScaleFactors = new Autodesk.AutoCAD.Geometry.Scale3d(scale) };
            d.Add(br, "XREF");
            Rnr.Msg($"Imported as block {name} (scale {scale}). EXPLODE it to integrate; run RNRLA to audit layers.");
        });

        [CommandMethod("RNR", "RNRPANEL", CommandFlags.Modal)]
        public void Panel() => Rnr.RunNoTx("RNRPANEL", doc => UI.PanelHost.ShowPalette());
    }
}
