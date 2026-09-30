using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>Sheets, title blocks, layouts, viewports and page setups.</summary>
    public static class LayoutService
    {
        public static readonly Dictionary<string, string> PdfMedia = new(StringComparer.OrdinalIgnoreCase)
        {
            // canonical media names of the "DWG To PDF.pc3" driver
            ["A0"] = "ISO_full_bleed_A0_(841.00_x_1189.00_MM)",
            ["A1"] = "ISO_full_bleed_A1_(841.00_x_594.00_MM)",
            ["A2"] = "ISO_full_bleed_A2_(594.00_x_420.00_MM)",
            ["A3"] = "ISO_full_bleed_A3_(420.00_x_297.00_MM)",
            ["A4"] = "ISO_full_bleed_A4_(297.00_x_210.00_MM)",
        };

        public static (double w, double h) SheetSize(string sheet)
        {
            if (!Rnr.Repo.Styles.Sheets.TryGetValue(sheet.ToUpperInvariant(), out var s)) throw new RnrInputException($"Unknown sheet {sheet}");
            return (s[0], s[1]);
        }

        /// <summary>Title block definition "RNR_TB_{SHEET}_{DISCIPLINE}" in paper units (mm), insertion at sheet lower-left.</summary>
        public static ObjectId EnsureTitleBlock(Database db, Transaction tr, string sheet, string discipline)
        {
            string name = $"RNR_TB_{sheet.ToUpperInvariant()}_{discipline.ToUpperInvariant()}";
            var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            if (bt.Has(name)) return bt[name];
            var (W, H) = SheetSize(sheet);
            double m = sheet.Equals("A4", StringComparison.OrdinalIgnoreCase) ? 10 : 20; // binding margin left
            double o = sheet.Equals("A4", StringComparison.OrdinalIgnoreCase) ? 5 : 10;
            double tbW = Math.Min(180, W - m - o), tbH = 70;
            var btr = new BlockTableRecord { Name = name, Origin = Point3d.Origin, Units = UnitsValue.Millimeters, Comments = "RooMNRooF title block" };
            bt.UpgradeOpen(); var id = bt.Add(btr); tr.AddNewlyCreatedDBObject(btr, true);

            void Add(Entity e) { e.SetDatabaseDefaults(db); e.Layer = "0"; e.ColorIndex = 0; btr.AppendEntity(e); tr.AddNewlyCreatedDBObject(e, true); }
            void Rect(double x, double y, double w, double h, double lw = 0.5)
            {
                var p = new Polyline(); p.AddVertexAt(0, new Point2d(x, y), 0, 0, 0); p.AddVertexAt(1, new Point2d(x + w, y), 0, 0, 0);
                p.AddVertexAt(2, new Point2d(x + w, y + h), 0, 0, 0); p.AddVertexAt(3, new Point2d(x, y + h), 0, 0, 0); p.Closed = true;
                p.LineWeight = LayerService.ToLineWeight(lw); Add(p);
            }
            void Txt(double x, double y, double h, string s) { Add(new DBText { Position = new Point3d(x, y, 0), Height = h, TextString = s }); }
            void Att(string tag, string def, double x, double y, double h) { Add(new AttributeDefinition(new Point3d(x, y, 0), def, tag, tag, ObjectId.Null) { Height = h }); }

            Rect(0, 0, W, H, 0.13);                           // trim line
            Rect(m, o, W - m - o, H - 2 * o, 0.7);             // drawing frame
            double x0 = W - o - tbW, y0 = o;
            Rect(x0, y0, tbW, tbH, 0.5);
            string[] fields = { "PROJECT", "CLIENT", "CONSULTANT", "DWGTITLE", "DWGNO", "REV", "DATE", "SCALE", "DRAWN", "CHECKED", "APPROVED", "SHEET" };
            // rows: 3 wide rows then a 3x3 grid
            double rowH = tbH / 7.0;
            for (int i = 1; i < 7; i++) { var l = new Line(new Point3d(x0, y0 + i * rowH, 0), new Point3d(x0 + tbW, y0 + i * rowH, 0)); Add(l); }
            for (int i = 1; i < 3; i++) { var l = new Line(new Point3d(x0 + i * tbW / 3, y0, 0), new Point3d(x0 + i * tbW / 3, y0 + 3 * rowH, 0)); Add(l); }
            double lab = 1.8, val = 3.0;
            // top wide rows
            string[] wide = { "PROJECT", "CLIENT", "CONSULTANT", "DWGTITLE" };
            for (int i = 0; i < wide.Length; i++)
            {
                double ry = y0 + (6 - i) * rowH;
                Txt(x0 + 2, ry + rowH - lab - 1, lab, wide[i] == "DWGTITLE" ? "DRAWING TITLE" : wide[i]);
                Att(wide[i], wide[i] == "DWGTITLE" ? $"{discipline.ToUpperInvariant()} DRAWING" : "-", x0 + 30, ry + 1.5, val);
            }
            string[] grid = { "DWGNO", "REV", "SHEET", "DATE", "SCALE", "DRAWN", "CHECKED", "APPROVED", "STATUS" };
            for (int i = 0; i < grid.Length; i++)
            {
                int col = i % 3, row = 2 - i / 3;
                double cx = x0 + col * tbW / 3, cy = y0 + row * rowH;
                Txt(cx + 1.5, cy + rowH - lab - 0.8, lab, grid[i]);
                if (grid[i] == "STATUS") Att("STATUS", "PRELIMINARY - NOT FOR CONSTRUCTION", cx + 1.5, cy + 1, 1.8);
                else Att(grid[i], grid[i] == "SCALE" ? Rnr.Project.DrawingScale : "-", cx + 1.5, cy + 1, 2.5);
            }
            Txt(x0 + 2, y0 + tbH + 2, 1.8, "RooMNRooF CAD PRO - CAD drafting output. Engineering content subject to review and approval by the responsible engineer.");
            Txt(m + 3, o + 3, 2.5, $"{discipline.ToUpperInvariant()}  |  {sheet.ToUpperInvariant()}");
            _ = fields;
            RnrLog.Info($"Title block defined: {name}");
            return id;
        }

        /// <summary>
        /// Creates (or reuses) a layout with page setup, title block, and one model-space viewport at the given scale.
        /// Must run in document context (switches current layout to activate the viewport).
        /// </summary>
        public static ObjectId CreateLayout(Database db, Transaction tr, string layoutName, string sheet, string discipline, double scale, bool activateViewport)
        {
            var lm = LayoutManager.Current;
            ObjectId layoutId = lm.GetLayoutId(layoutName);
            if (layoutId.IsNull) layoutId = lm.CreateLayout(layoutName);
            var layout = (Layout)tr.GetObject(layoutId, OpenMode.ForWrite);
            ApplyPageSetup(layout, sheet, Rnr.Project.Plot.ColorCtb);

            var (W, H) = SheetSize(sheet);
            var ps = (BlockTableRecord)tr.GetObject(layout.BlockTableRecordId, OpenMode.ForWrite);
            // remove the default auto-created viewport(s) except the overall paper-space viewport (first)
            var vps = ps.Cast<ObjectId>().Where(id => id.ObjectClass.DxfName == "VIEWPORT").ToList();
            foreach (var v in vps.Skip(1)) ((Entity)tr.GetObject(v, OpenMode.ForWrite)).Erase();

            var tbId = EnsureTitleBlock(db, tr, sheet, discipline);
            var d = new DrawService(db, tr, layout.BlockTableRecordId);
            var tbName = ((BlockTableRecord)tr.GetObject(tbId, OpenMode.ForRead)).Name;
            BlockFactory.Insert(d, tbName, Point3d.Origin, 1, 0, "ANNO-TITLE", new Dictionary<string, string>
            {
                ["PROJECT"] = Rnr.Project.ProjectName, ["CLIENT"] = Rnr.Project.Client, ["CONSULTANT"] = Rnr.Project.Consultant,
                ["DATE"] = DateTime.Now.ToString("dd-MM-yyyy"), ["SCALE"] = $"1:{scale:0}", ["SHEET"] = layoutName,
            });

            double m = sheet.Equals("A4", StringComparison.OrdinalIgnoreCase) ? 10 : 20, o = sheet.Equals("A4", StringComparison.OrdinalIgnoreCase) ? 5 : 10;
            double vw = W - m - o - 200, vh = H - 2 * o - 10;
            if (vw < 50) vw = W - m - o - 10;
            var vp = new Viewport
            {
                CenterPoint = new Point3d(m + vw / 2 + 5, o + vh / 2 + 5, 0), Width = vw, Height = vh,
                CustomScale = 1.0 / scale, ViewCenter = Point2d.Origin,
            };
            d.Add(vp, "Z-VPORT");
            vp.AnnotationScale = FindScale(db, scale) ?? vp.AnnotationScale;
            if (activateViewport)
            {
                try { lm.CurrentLayout = layoutName; vp.On = true; vp.Locked = true; }
                catch (Autodesk.AutoCAD.Runtime.Exception ex) { RnrLog.Warn($"Viewport activation skipped: {ex.ErrorStatus}"); }
            }
            return layoutId;
        }

        static AnnotationScale? FindScale(Database db, double scale)
        {
            var occ = db.ObjectContextManager.GetContextCollection("ACDB_ANNOTATIONSCALES");
            foreach (ObjectContext c in occ)
                if (c is AnnotationScale a && Math.Abs(a.DrawingUnits / a.PaperUnits - scale) < 1e-6) return a;
            return null;
        }

        public static void ApplyPageSetup(Layout layout, string sheet, string ctb)
        {
            var psv = PlotSettingsValidator.Current;
            try
            {
                psv.SetPlotConfigurationName(layout, Rnr.Project.Plot.Device, PdfMedia.TryGetValue(sheet, out var med) ? med : PdfMedia["A1"]);
                psv.SetPlotPaperUnits(layout, PlotPaperUnit.Millimeters);
                psv.SetPlotType(layout, Autodesk.AutoCAD.DatabaseServices.PlotType.Layout);
                psv.SetUseStandardScale(layout, true);
                psv.SetStdScaleType(layout, StdScaleType.StdScale1To1);
                psv.SetPlotRotation(layout, PlotRotation.Degrees000);
                psv.SetCurrentStyleSheet(layout, ctb);
                layout.PlotPlotStyles = true;
                layout.PrintLineweights = true;
            }
            catch (Autodesk.AutoCAD.Runtime.Exception ex)
            {
                RnrLog.Warn($"Page setup for {layout.LayoutName} incomplete: {ex.ErrorStatus}");
                Rnr.Msg($"Page setup could not be fully applied ({ex.ErrorStatus}). Check that '{Rnr.Project.Plot.Device}' and '{ctb}' exist.");
            }
        }
    }
}
