using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Models;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: CommandClass(typeof(RooMNRooF.Plugin.Commands.AnnotationCommands))]

namespace RooMNRooF.Plugin.Commands
{
    /// <summary>Tags, marks, north arrow, materials/hatch, layouts, title blocks and plotting.</summary>
    public class AnnotationCommands
    {
        static void InsertSymbol(string cmd, string block, string layer, Func<Autodesk.AutoCAD.EditorInput.Editor, Dictionary<string, string>> attrs, bool rotate = false) =>
            Rnr.Run(cmd, (doc, tr) =>
            {
                var ed = doc.Editor;
                var a = attrs(ed);
                var d = new DrawService(doc.Database, tr);
                int n = 0;
                while (true)
                {
                    var p = Prompts.PointOrNone(ed, n == 0 ? "Insertion point:" : "Next insertion point <done>:");
                    if (p == null) break;
                    double rot = rotate ? Prompts.Angle(ed, "Rotation <0>:", p.Value, 0) : 0;
                    BlockFactory.Insert(d, block, p.Value, d.TextScale, rot, layer, a);
                    n++;
                }
                Rnr.Msg($"{n} {block} inserted.");
            });

        [CommandMethod("RNR", "RNRTAG", CommandFlags.Modal)]
        public void Tag() => InsertSymbol("RNRTAG", "RNR_TAG", "ANNO-TAGS", ed => new() { ["MARK"] = Prompts.Text(ed, "Tag text (C1, B1, F1 ...)", "C1", false) });

        [CommandMethod("RNR", "RNRLEVEL", CommandFlags.Modal)]
        public void Level() => InsertSymbol("RNRLEVEL", "RNR_LEVEL", "ANNO-LEVEL", ed => new() { ["LEVEL"] = Prompts.Text(ed, "Level (e.g. +3.050 FFL)", "+0.000 FFL") });

        [CommandMethod("RNR", "RNRSECTIONMARK", CommandFlags.Modal)]
        public void SectionMark() => InsertSymbol("RNRSECTIONMARK", "RNR_SECTIONMARK", "ANNO-SECTION",
            ed => new() { ["ID"] = Prompts.Text(ed, "Section id", "A", false), ["SHEET"] = Prompts.Text(ed, "Sheet ref", "S-05", false) }, rotate: true);

        [CommandMethod("RNR", "RNRDETAILMARK", CommandFlags.Modal)]
        public void DetailMark() => InsertSymbol("RNRDETAILMARK", "RNR_DETAILMARK", "ANNO-DETAIL",
            ed => new() { ["ID"] = Prompts.Text(ed, "Detail number", "1", false), ["SHEET"] = Prompts.Text(ed, "Sheet ref", "S-06", false) });

        [CommandMethod("RNR", "RNRELEVMARK", CommandFlags.Modal)]
        public void ElevationMark() => InsertSymbol("RNRELEVMARK", "RNR_ELEVMARK", "ANNO-SECTION", ed => new() { ["ID"] = Prompts.Text(ed, "Elevation id", "E1", false) }, rotate: true);

        [CommandMethod("RNR", "RNRNORTH", CommandFlags.Modal)]
        public void North() => InsertSymbol("RNRNORTH", "RNR_NORTH", "ANNO-NORTH", ed => new(), rotate: true);

        [CommandMethod("RNR", "RNRLEADER", CommandFlags.Modal)]
        public void Leader() => Rnr.RunNoTx("RNRLEADER", doc =>
        {
            using (doc.LockDocument())
            using (var tr = doc.Database.TransactionManager.StartTransaction())
            {
                var d = new DrawService(doc.Database, tr);
                StyleService.EnsureMLeaderStyle(doc.Database, tr, Rnr.Repo.Styles.MleaderStyles[0]);
                var dict = (DBDictionary)tr.GetObject(doc.Database.MLeaderStyleDictionaryId, OpenMode.ForRead);
                doc.Database.MLeaderstyle = dict.GetAt("RNR_LEADER");
                doc.Database.Clayer = LayerService.Ensure(doc.Database, tr, "ANNO-LEADER", false);
                tr.Commit();
            }
            doc.SendStringToExecute("_.MLEADER ", true, false, true);
        });

        // ------------------------------------------------------------------ materials / hatch
        [CommandMethod("RNR", "RNRHATCH", CommandFlags.Modal)]
        public void HatchCmd() => Rnr.Run("RNRHATCH", (doc, tr) =>
        {
            var ed = doc.Editor;
            var names = Rnr.Repo.Hatches.Hatches.Select(h => h.Name).ToArray();
            for (int i = 0; i < names.Length; i++) ed.WriteMessage($"\n  {i + 1,2}. {names[i]}");
            var def = Rnr.Repo.Hatches.Hatches[Prompts.Int(ed, "Material number", 1, 1, names.Length) - 1];
            var mode = Prompts.Keyword(ed, "Boundary [Select/Pick]", "Pick", "Select", "Pick");
            var d = new DrawService(doc.Database, tr);
            var boundaries = new List<ObjectId>();
            if (mode == "Select")
                boundaries.AddRange(Prompts.Selection(ed, "Select closed boundaries:", new Autodesk.AutoCAD.EditorInput.SelectionFilter(new[] { new TypedValue(0, "LWPOLYLINE,CIRCLE,ELLIPSE,SPLINE") })));
            else
            {
                var p = Prompts.Point(ed, "Pick internal point:");
                var col = ed.TraceBoundary(p, true);
                if (col == null || col.Count == 0) throw new RnrInputException("No boundary found.");
                foreach (DBObject o in col) boundaries.Add(d.Add((Entity)o, "Z-CONST").ObjectId);
            }
            double scale = Prompts.Double(ed, "Scale multiplier", 1.0);
            foreach (var b in boundaries)
            {
                var c = (Entity)tr.GetObject(b, OpenMode.ForRead);
                if (c is Curve cv && !cv.Closed) { ed.WriteMessage("\n  skipped open curve"); continue; }
                HatchService.Apply(d, b, def, def.LayerHint, scale);
            }
            Rnr.Msg($"{def.Name} applied to {boundaries.Count} boundary(ies).");
        });

        /// <summary>Hatch picked areas with a named material (used by the Material Browser "Apply").</summary>
        [CommandMethod("RNR", "RNRHATCHNAME", CommandFlags.Modal)]
        public void HatchByName() => Rnr.Run("RNRHATCHNAME", (doc, tr) =>
        {
            var ed = doc.Editor;
            var def = HatchService.Resolve(Prompts.Text(ed, "Material name", "Concrete"));
            var d = new DrawService(doc.Database, tr);
            int n = 0;
            while (true)
            {
                var p = Prompts.PointOrNone(ed, $"Pick inside area to hatch with {def.Name} <done>:");
                if (p == null) break;
                var col = ed.TraceBoundary(p.Value, true);
                if (col == null || col.Count == 0) { ed.WriteMessage("\n  no closed boundary there"); continue; }
                foreach (DBObject o in col) { var id = d.Add((Entity)o, "Z-CONST").ObjectId; HatchService.Apply(d, id, def, def.LayerHint); n++; }
                doc.TransactionManager.QueueForGraphicsFlush(); doc.TransactionManager.FlushGraphics();
            }
            Rnr.Msg($"{n} area(s) hatched with {def.Name}.");
        });

        [CommandMethod("RNR", "RNRMATAPPLY", CommandFlags.Modal)]
        public void MatApply() => Rnr.Run("RNRMATAPPLY", (doc, tr) =>
        {
            var ed = doc.Editor;
            var name = Prompts.Text(ed, "Material name", "Concrete");
            var def = HatchService.Resolve(name);
            var ids = Prompts.Selection(ed, "Select existing hatches to convert:", new Autodesk.AutoCAD.EditorInput.SelectionFilter(new[] { new TypedValue(0, "HATCH") }));
            foreach (var id in ids)
            {
                var h = (Autodesk.AutoCAD.DatabaseServices.Hatch)tr.GetObject(id, OpenMode.ForWrite);
                h.PatternScale = def.Scale; h.PatternAngle = def.Angle * Math.PI / 180;
                try { h.SetHatchPattern(def.Custom ? HatchPatternType.CustomDefined : HatchPatternType.PreDefined, def.Pattern); }
                catch (Autodesk.AutoCAD.Runtime.Exception) { ed.WriteMessage($"\n  pattern {def.Pattern} not on support path - unchanged"); continue; }
                h.Color = DrawService.Rgb(def.Rgb);
                h.Transparency = LayerService.ToTransparency(def.Transparency);
                h.EvaluateHatch(true);
            }
            Rnr.Msg($"{ids.Length} hatch(es) set to {def.Name}.");
        });

        [CommandMethod("RNR", "RNRMATLIB", CommandFlags.Modal)]
        public void MatLib() => Rnr.RunNoTx("RNRMATLIB", doc => UI.PanelHost.ShowMaterialBrowser());

        [CommandMethod("RNR", "RNRMATPREVIEW", CommandFlags.Modal)]
        public void MatPreview() => Rnr.Run("RNRMATPREVIEW", (doc, tr) =>
        {
            // draws every material as a labelled swatch grid - a real in-drawing preview
            var p = Prompts.Point(doc.Editor, "Preview sheet origin:");
            var d = new DrawService(doc.Database, tr);
            double s = d.TextScale, box = 25 * s, gap = 12 * s;
            int i = 0;
            foreach (var h in Rnr.Repo.Hatches.Hatches)
            {
                int col = i % 5, row = i / 5;
                double x = p.X + col * (box * 1.6 + gap), y = p.Y - row * (box + gap * 1.5);
                var pl = d.Poly(new[] { new RooMNRooF.Core.Geometry.Pt(x, y), new(x + box * 1.6, y), new(x + box * 1.6, y + box), new(x, y + box) }, true, "Z-CONST");
                HatchService.Apply(d, pl.ObjectId, h, "ANNO-TEXT", s / 50.0);
                d.Text(new Point3d(x + box * 0.8, y - 3 * s, 0), h.Name.ToUpperInvariant(), 2.0, "ANNO-TEXT");
                i++;
            }
            Rnr.Msg($"{i} material swatches drawn.");
        });

        [CommandMethod("RNR", "RNRMATLEGEND", CommandFlags.Modal)]
        public void MatLegend() => Rnr.Run("RNRMATLEGEND", (doc, tr) =>
        {
            var ed = doc.Editor;
            // legend of materials actually used in the drawing (by pattern name)
            var used = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var ms = (BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(doc.Database), OpenMode.ForRead);
            foreach (ObjectId id in ms) if (id.ObjectClass.DxfName == "HATCH") used.Add(((Autodesk.AutoCAD.DatabaseServices.Hatch)tr.GetObject(id, OpenMode.ForRead)).PatternName);
            var defs = Rnr.Repo.Hatches.Hatches.Where(h => used.Contains(h.Pattern)).GroupBy(h => h.Pattern).Select(g => g.First()).ToList();
            if (defs.Count == 0) { Rnr.Msg("No RooMNRooF materials found in model space."); return; }
            var p = Prompts.Point(ed, "Legend top-left point:");
            HatchService.Legend(new DrawService(doc.Database, tr), p, defs, new DrawService(doc.Database, tr).TextScale);
            Rnr.Msg($"Legend with {defs.Count} material(s).");
        });

        // ------------------------------------------------------------------ sheets / plotting
        [CommandMethod("RNR", "RNRLAYOUT", CommandFlags.Modal)]
        public void LayoutCmd() => Rnr.Run("RNRLAYOUT", (doc, tr) =>
        {
            var ed = doc.Editor;
            var name = Prompts.Text(ed, "Layout name", "S-01", false);
            var sheet = Prompts.Keyword(ed, "Sheet [A0/A1/A2/A3/A4]", Rnr.Project.SheetSize, "A0", "A1", "A2", "A3", "A4");
            var disc = Prompts.Keyword(ed, "Title block [ARCHITECTURAL/STRUCTURAL/RCC/CIVIL]", Rnr.Project.TitleBlock, "ARCHITECTURAL", "STRUCTURAL", "RCC", "CIVIL");
            var sc = Prompts.Keyword(ed, "Scale [20/25/50/75/100/150/200/500]", "100", "20", "25", "50", "75", "100", "150", "200", "500");
            LayoutService.CreateLayout(doc.Database, tr, name, sheet, disc, double.Parse(sc), activateViewport: true);
            Rnr.Msg($"Layout {name} ({sheet}, 1:{sc}, {disc}) created. Pan the viewport to the drawing area, then lock it.");
        });

        [CommandMethod("RNR", "RNRTITLE", CommandFlags.Modal)]
        public void Title() => Rnr.Run("RNRTITLE", (doc, tr) =>
        {
            var ed = doc.Editor;
            var id = Prompts.Entity(ed, "Select RooMNRooF title block:", typeof(BlockReference));
            var br = (BlockReference)tr.GetObject(id, OpenMode.ForRead);
            if (!br.Name.StartsWith("RNR_TB_")) throw new RnrInputException("Not a RooMNRooF title block.");
            foreach (ObjectId aid in br.AttributeCollection)
            {
                var ar = (AttributeReference)tr.GetObject(aid, OpenMode.ForWrite);
                ar.TextString = Prompts.Text(ed, ar.Tag, ar.TextString);
            }
            Rnr.Done();
        });

        void Plot(string cmd, PlotMode mode) => Rnr.RunNoTx(cmd, doc =>
        {
            var path = PlotService.DefaultPdfPath(doc, mode);
            path = Prompts.Text(doc.Editor, "PDF file", path);
            if (File.Exists(path) && !Prompts.YesNo(doc.Editor, "File exists. Overwrite?", false)) throw new RnrCancelled();
            using (doc.LockDocument()) PlotService.PlotCurrentLayoutToPdf(doc, mode, path);
            Rnr.Msg($"{mode} PDF written ({PlotService.CtbFor(mode)}, lineweights on): {path}");
        });

        [CommandMethod("RNR", "RNRPLOTCOLOR", CommandFlags.Modal)] public void PlotColor() => Plot("RNRPLOTCOLOR", PlotMode.Color);
        [CommandMethod("RNR", "RNRPLOTBW", CommandFlags.Modal)] public void PlotBw() => Plot("RNRPLOTBW", PlotMode.Monochrome);
        [CommandMethod("RNR", "RNRPLOTGRAY", CommandFlags.Modal)] public void PlotGray() => Plot("RNRPLOTGRAY", PlotMode.Grayscale);

        /// <summary>Plot preview in the chosen mode: assigns the CTB to the current layout, then runs AutoCAD PREVIEW.</summary>
        [CommandMethod("RNR", "RNRPREVIEW", CommandFlags.Modal)]
        public void Preview() => Rnr.RunNoTx("RNRPREVIEW", doc =>
        {
            var mode = Prompts.Keyword(doc.Editor, "Preview [Color/Monochrome/Grayscale]", "Monochrome", "Color", "Monochrome", "Grayscale");
            var pm = Enum.Parse<PlotMode>(mode);
            using (doc.LockDocument())
            using (var tr = doc.Database.TransactionManager.StartTransaction())
            {
                var lay = (Layout)tr.GetObject(LayoutManager.Current.GetLayoutId(LayoutManager.Current.CurrentLayout), OpenMode.ForWrite);
                PlotSettingsValidator.Current.SetCurrentStyleSheet(lay, PlotService.CtbFor(pm));
                lay.PrintLineweights = true;
                tr.Commit();
            }
            doc.SendStringToExecute("_.PREVIEW ", true, false, true);
        });
    }
}
