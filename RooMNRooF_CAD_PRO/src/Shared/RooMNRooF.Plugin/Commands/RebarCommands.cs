using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Export;
using RooMNRooF.Core.Geometry;
using RooMNRooF.Core.Rebar;
using RooMNRooF.Core.Schedules;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;

[assembly: CommandClass(typeof(RooMNRooF.Plugin.Commands.RebarCommands))]

namespace RooMNRooF.Plugin.Commands
{
    /// <summary>Reinforcement drafting, section details, schedules and BBS data.</summary>
    public class RebarCommands
    {
        [CommandMethod("RNR", "RNRREBAR", CommandFlags.Modal)]
        public void Rebar() => Rnr.Run("RNRREBAR", (doc, tr) =>
        {
            var ed = doc.Editor;
            var role = Prompts.Keyword(ed, "Bar role [Main/Distribution/Top/Bottom/Extra/Anchorage/Lap]", "Main", "Main", "Distribution", "Top", "Bottom", "Extra", "Anchorage", "Lap");
            var callout = Prompts.Rebar(ed, "Bar call-out", role == "Distribution" ? "T10 @ 200" : "2T16");
            var c = RebarNotation.Parse(callout);
            var a = Prompts.Point(ed, "Bar start point:");
            var pts = new List<Pt> { new(a.X, a.Y) };
            var last = a;
            while (true)
            {
                var p = Prompts.PointOrNone(ed, "Next point <done>:", last);
                if (p == null) break;
                pts.Add(new Pt(p.Value.X, p.Value.Y)); last = p.Value;
            }
            if (pts.Count < 2) throw new RnrInputException("A bar needs at least two points.");
            var d = new DrawService(doc.Database, tr);
            var layer = role == "Distribution" ? "S-REBAR-DIST" : "S-REBAR";
            var pl = d.Poly(pts, false, layer);
            // polyline global width = bar diameter so thick bars read clearly at detail scales
            pl.ConstantWidth = c.Diameter;
            string suffix = role switch { "Anchorage" => " (ANCHORAGE - Ld per project)", "Lap" => " (LAP - per project)", "Main" or "Distribution" => "", _ => $" {role.ToUpperInvariant()}" };
            var mid = new Point3d((pts[0].X + pts[1].X) / 2, (pts[0].Y + pts[1].Y) / 2, 0);
            var ang = Math.Atan2(pts[1].Y - pts[0].Y, pts[1].X - pts[0].X);
            if (ang > Math.PI / 2 || ang < -Math.PI / 2) ang += Math.PI; // keep text readable
            d.Text(mid + new Vector3d(-Math.Sin(ang), Math.Cos(ang), 0) * (2.5 * d.TextScale), c + suffix, 2.5, "S-REBAR-TEXT", TextHorizontalMode.TextCenter, TextVerticalMode.TextBottom, ang);
            Rnr.Done();
        });

        [CommandMethod("RNR", "RNRSTIRRUP", CommandFlags.Modal)]
        public void Stirrup() => Rnr.Run("RNRSTIRRUP", (doc, tr) =>
        {
            var ed = doc.Editor;
            double b = Prompts.Double(ed, "Section width b (mm)", 250), h = Prompts.Double(ed, "Section depth h (mm)", 450);
            double cover = Prompts.Double(ed, "Clear cover to stirrup (mm) - project input", Rnr.Project.Engineering.ClearCoverBeamMm ?? 25);
            var call = RebarNotation.Parse(Prompts.Rebar(ed, "Stirrup call-out", "2L-T8 @ 150"));
            if (!call.IsSpacingForm) throw new RnrInputException("Stirrup call-out must use spacing form, e.g. T8 @ 150.");
            var p = Prompts.Point(ed, "Section centre:");
            var d = new DrawService(doc.Database, tr);
            DrawSection(d, p, b, h, cover, call.Diameter, Array.Empty<(int n, int dia, bool top)>());
            d.Text(p + new Vector3d(0, -h / 2 - 6 * d.TextScale, 0), $"STIRRUP {call}", 2.5, "S-REBAR-TEXT");
            Rnr.Done();
        });

        /// <summary>Rectangular column/beam cross-section with stirrup (135° hooks) and bars as filled circles.</summary>
        [CommandMethod("RNR", "RNRSECTIONDETAIL", CommandFlags.Modal)]
        public void SectionDetail() => Rnr.Run("RNRSECTIONDETAIL", (doc, tr) =>
        {
            var ed = doc.Editor;
            var kind = Prompts.Keyword(ed, "Detail [Column/Beam]", "Column", "Column", "Beam");
            double b = Prompts.Double(ed, "Width b (mm)", kind == "Column" ? 300 : 250), h = Prompts.Double(ed, "Depth h (mm)", kind == "Column" ? 300 : 450);
            double cover = Prompts.Double(ed, "Clear cover (mm) - project input", (kind == "Column" ? Rnr.Project.Engineering.ClearCoverColumnMm : Rnr.Project.Engineering.ClearCoverBeamMm) ?? 40);
            var bars = new List<(int n, int dia, bool top)>();
            string label;
            if (kind == "Column")
            {
                var mb = RebarNotation.Parse(Prompts.Rebar(ed, "Main bars", "4T16"));
                if (!mb.Count.HasValue || mb.Count < 4 || mb.Count % 2 != 0) throw new RnrInputException("Column main bars must be an even count >= 4 (e.g. 4T16, 8T16).");
                bars.Add((mb.Count.Value, mb.Diameter, false));
                label = mb.ToString();
            }
            else
            {
                var top = RebarNotation.Parse(Prompts.Rebar(ed, "Top bars", "2T16"));
                var bot = RebarNotation.Parse(Prompts.Rebar(ed, "Bottom bars", "3T16"));
                if (!top.Count.HasValue || !bot.Count.HasValue || top.Count < 2 || bot.Count < 2) throw new RnrInputException("Top/bottom need count form with >= 2 bars.");
                bars.Add((top.Count.Value, top.Diameter, true)); bars.Add((bot.Count.Value, bot.Diameter, false));
                label = $"TOP {top} / BOT {bot}";
            }
            var st = RebarNotation.Parse(Prompts.Rebar(ed, kind == "Column" ? "Ties" : "Stirrups", "T8 @ 150"));
            var p = Prompts.Point(ed, "Section centre:");
            var d = new DrawService(doc.Database, tr);
            DrawSection(d, p, b, h, cover, st.Diameter, bars, kind == "Column");
            double y = p.Y - h / 2 - 6 * d.TextScale;
            d.Text(new Point3d(p.X, y, 0), $"{kind.ToUpperInvariant()} SECTION {b:0}x{h:0}", 3.5, "S-TEXT", style: "RNR_HEADING");
            d.Text(new Point3d(p.X, y - 5 * d.TextScale, 0), label, 2.5, "S-REBAR-TEXT");
            d.Text(new Point3d(p.X, y - 9 * d.TextScale, 0), $"{(kind == "Column" ? "TIES" : "STIRRUPS")} {st}", 2.5, "S-REBAR-TEXT");
            d.Dim(p + new Vector3d(-b / 2, -h / 2, 0), p + new Vector3d(b / 2, -h / 2, 0), -4 * d.TextScale, "S-DIMS");
            d.Dim(p + new Vector3d(b / 2, -h / 2, 0), p + new Vector3d(b / 2, h / 2, 0), 4 * d.TextScale, "S-DIMS");
            Rnr.Done();
        });

        static void DrawSection(DrawService d, Point3d c, double b, double h, double cover, int stirDia, IEnumerable<(int n, int dia, bool top)> bars, bool column = false)
        {
            if (b <= 2 * cover + 2 * stirDia || h <= 2 * cover + 2 * stirDia) throw new RnrInputException("Section too small for the cover/stirrup given.");
            var o = new Pt(c.X, c.Y);
            var outline = d.Poly(new[] { new Pt(o.X - b / 2, o.Y - h / 2), new(o.X + b / 2, o.Y - h / 2), new(o.X + b / 2, o.Y + h / 2), new(o.X - b / 2, o.Y + h / 2) }, true, "S-SECTION");
            var rcc = Rnr.Repo.Hatch("Concrete");
            if (rcc != null) HatchService.Apply(d, outline.ObjectId, rcc, "S-HATCH", d.TextScale / 25.0);
            // stirrup centre-line rectangle + 135° hook tails at top-left corner
            double sx = b / 2 - cover - stirDia / 2.0, sy = h / 2 - cover - stirDia / 2.0;
            var st = d.Poly(new[] { new Pt(o.X - sx, o.Y - sy), new(o.X + sx, o.Y - sy), new(o.X + sx, o.Y + sy), new(o.X - sx, o.Y + sy) }, true, "S-STIRRUP");
            st.ConstantWidth = stirDia;
            double hook = Math.Max(10 * stirDia, 75); // drafting representation only; hook length is a project input
            d.Poly(new[] { new Pt(o.X - sx, o.Y + sy), new(o.X - sx + hook * 0.707, o.Y + sy - hook * 0.707) }, false, "S-STIRRUP").ConstantWidth = stirDia;
            d.Poly(new[] { new Pt(o.X - sx, o.Y + sy), new(o.X - sx + hook * 0.707, o.Y + sy - hook * 0.707 + stirDia * 1.5) }, false, "S-STIRRUP").ConstantWidth = stirDia;

            foreach (var (n, dia, top) in bars)
            {
                double inset = cover + stirDia + dia / 2.0;
                double x0 = o.X - b / 2 + inset, x1 = o.X + b / 2 - inset, y0 = o.Y - h / 2 + inset, y1 = o.Y + h / 2 - inset;
                var pts = new List<Pt>();
                if (column)
                {
                    // perimeter distribution: corners + remaining split between long faces
                    pts.AddRange(new[] { new Pt(x0, y0), new Pt(x1, y0), new Pt(x1, y1), new Pt(x0, y1) });
                    int extra = n - 4, perFace = extra / 2;
                    bool alongX = b >= h;
                    for (int i = 1; i <= perFace; i++)
                    {
                        double t = i / (double)(perFace + 1);
                        if (alongX) { pts.Add(new Pt(x0 + (x1 - x0) * t, y0)); pts.Add(new Pt(x0 + (x1 - x0) * t, y1)); }
                        else { pts.Add(new Pt(x0, y0 + (y1 - y0) * t)); pts.Add(new Pt(x1, y0 + (y1 - y0) * t)); }
                    }
                }
                else
                {
                    double y = top ? y1 : y0;
                    for (int i = 0; i < n; i++) pts.Add(new Pt(x0 + (x1 - x0) * i / (n - 1), y));
                }
                foreach (var p in pts)
                {
                    var circle = d.Circle(new Point3d(p.X, p.Y, 0), dia / 2.0, "S-REBAR");
                    var solid = new Hatch();
                    d.Add(solid, "S-REBAR");
                    solid.SetHatchPattern(HatchPatternType.PreDefined, "SOLID");
                    solid.AppendLoop(HatchLoopTypes.Outermost, new ObjectIdCollection { circle.ObjectId });
                    solid.EvaluateHatch(true);
                }
            }
        }

        [CommandMethod("RNR", "RNRREBARNOTE", CommandFlags.Modal)]
        public void RebarNote() => Rnr.Run("RNRREBARNOTE", (doc, tr) =>
        {
            var ed = doc.Editor;
            var kind = Prompts.Keyword(ed, "Note [Beam/Simple]", "Beam", "Beam", "Simple");
            string text;
            if (kind == "Beam")
            {
                var top = Prompts.Rebar(ed, "Top bars", "2T16");
                var bot = Prompts.Rebar(ed, "Bottom bars", "3T16");
                var extra = Prompts.Rebar(ed, "Extra top bars ('-' none)", "-");
                var st = Prompts.Rebar(ed, "Stirrups", "2L-T8 @ 150");
                text = RebarNotation.ComposeBeamNote(top, bot, extra == "-" ? null : extra, st).Replace(" / ", "\\P");
            }
            else text = RebarNotation.Parse(Prompts.Rebar(ed, "Call-out", "T12 @ 200")).ToString();
            var arrow = Prompts.Point(ed, "Leader arrow point:");
            var land = Prompts.Point(ed, "Text location:", arrow);
            var d = new DrawService(doc.Database, tr);
            var ml = new MLeader();
            ml.SetDatabaseDefaults(doc.Database);
            var dict = (DBDictionary)tr.GetObject(doc.Database.MLeaderStyleDictionaryId, OpenMode.ForRead);
            if (dict.Contains("RNR_LEADER")) ml.MLeaderStyle = dict.GetAt("RNR_LEADER");
            ml.ContentType = ContentType.MTextContent;
            var mt = new MText { Contents = text, TextHeight = 2.5 * d.TextScale, TextStyleId = StyleService.TextStyleId(doc.Database, tr, "RNR_TEXT") };
            mt.SetDatabaseDefaults(doc.Database);
            mt.Location = land;
            ml.MText = mt;
            ml.AddLeaderLine(arrow);
            ml.ArrowSize = 2 * d.TextScale;
            ml.LandingGap = 1 * d.TextScale;
            ml.TextLocation = land;
            d.Add(ml, "S-REBAR-TEXT");
            Rnr.Done();
        });

        // ------------------------------------------------------------------ schedules
        [CommandMethod("RNR", "RNRSCHEDULE", CommandFlags.Modal)]
        public void Schedule() => Rnr.Run("RNRSCHEDULE", (doc, tr) =>
        {
            var ed = doc.Editor;
            var kind = Prompts.Keyword(ed, "Schedule [COLUMN/BEAM/SLAB/FOOTING/STAIR/WALL/TANK/REBAR]", "COLUMN", "COLUMN", "BEAM", "SLAB", "FOOTING", "STAIR", "WALL", "TANK", "REBAR");
            var members = ExtractionService.Members(doc.Database, tr);
            ScheduleTable table;
            if (kind == "REBAR")
            {
                var skipped = new List<string>();
                var rows = ExtractionService.Bbs(members, ExtractionService.ProjectBbsParameters(), skipped);
                table = new ScheduleTable { Title = "REBAR SCHEDULE (SUMMARY BY DIAMETER)", Headers = { "DIA", "TOTAL LENGTH (m)", "WEIGHT (kg)" }, Footnote = ScheduleBuilder.Footnote };
                foreach (var s in BbsCalculator.SummaryByDiameter(rows)) table.Rows.Add(new() { $"T{s.Diameter}", s.TotalLengthM.ToString("0.00"), s.WeightKg.ToString("0.00") });
                foreach (var s in skipped) ed.WriteMessage($"\n  skipped: {s}");
            }
            else table = ScheduleBuilder.Build(kind, members);
            if (table.Rows.Count == 0) { Rnr.Msg($"No {kind} members with RooMNRooF data found. Place members with RNR commands first."); return; }
            var p = Prompts.Point(ed, "Table insertion point (top-left):");
            ExtractionService.DrawTable(new DrawService(doc.Database, tr), p, table);
            Rnr.Msg($"{table.Title}: {table.Rows.Count} row(s).");
        });

        [CommandMethod("RNR", "RNRBBS", CommandFlags.Modal)]
        public void Bbs() => Rnr.Run("RNRBBS", (doc, tr) =>
        {
            var ed = doc.Editor;
            ed.WriteMessage("\nBBS cut lengths use ONLY the engineering parameters you enter below (nothing is assumed).");
            var e = Rnr.Project.Engineering;
            var p = new BbsParameters
            {
                ClearCover = NullableDouble(ed, "Clear cover (mm, 0 = not applied)", e.ClearCoverBeamMm),
                BendDeductionPer90D = NullableDouble(ed, "Bend deduction per 90° bend (x d, 0 = not applied)", null),
                StirrupHookAllowanceD = NullableDouble(ed, "Stirrup hook allowance total (x d, 0 = not applied)", null),
                LapLengthD = NullableDouble(ed, "Lap length (x d, 0 = not applied)", e.LapFactorD),
                StockLength = Prompts.Double(ed, "Stock bar length (mm)", 12000),
            };
            var skipped = new List<string>();
            var rows = ExtractionService.Bbs(ExtractionService.Members(doc.Database, tr), p, skipped);
            foreach (var s in skipped) ed.WriteMessage($"\n  skipped: {s}");
            if (rows.Count == 0) { Rnr.Msg("No reinforcement data found on RooMNRooF members."); return; }
            foreach (var s in BbsCalculator.SummaryByDiameter(rows)) ed.WriteMessage($"\n  T{s.Diameter,-3} {s.TotalLengthM,10:0.00} m  {s.WeightKg,10:0.00} kg");
            var fmt = Prompts.Keyword(ed, "Export [CSV/XLSX/JSON/All/Table]", "All", "CSV", "XLSX", "JSON", "All", "Table");
            var baseName = ExportBase(doc, "BBS");
            var sheet = ExtractionService.BbsSheet(rows);
            if (fmt is "CSV" or "All") { CsvExporter.Write(baseName + ".csv", sheet); ed.WriteMessage($"\n  {baseName}.csv"); }
            if (fmt is "XLSX" or "All") { XlsxExporter.Write(baseName + ".xlsx", sheet); ed.WriteMessage($"\n  {baseName}.xlsx"); }
            if (fmt is "JSON" or "All") { JsonExporter.Write(baseName + ".json", new { disclaimer = sheet.Notes[0], parameters = p, rows }); ed.WriteMessage($"\n  {baseName}.json"); }
            if (fmt == "Table")
            {
                var t = new ScheduleTable { Title = "BAR BENDING SCHEDULE", Headers = sheet.Headers.ToList(), Footnote = sheet.Notes[0] };
                foreach (var r in sheet.Rows) t.Rows.Add(r.Select(c => CsvExporter_Cell(c)).ToList());
                ExtractionService.DrawTable(new DrawService(doc.Database, tr), Prompts.Point(ed, "Table insertion point:"), t, 2.0);
            }
            Rnr.Msg($"{rows.Count} BBS row(s) prepared.");
        });

        static string CsvExporter_Cell(object? c) => c switch { null => "", double d => d.ToString("0.###"), _ => c.ToString() ?? "" };

        static double? NullableDouble(Autodesk.AutoCAD.EditorInput.Editor ed, string msg, double? def)
        {
            var v = Prompts.Double(ed, msg, def ?? 0, allowZero: true);
            return v <= 0 ? null : v;
        }

        /// <summary>Export base path next to the drawing (or Documents) with timestamp - never overwrites.</summary>
        public static string ExportBase(Autodesk.AutoCAD.ApplicationServices.Document doc, string kind)
        {
            var f = doc.Database.Filename;
            var dir = !string.IsNullOrEmpty(f) && Path.IsPathRooted(f) && !f.EndsWith(".dwt", StringComparison.OrdinalIgnoreCase) ? Path.GetDirectoryName(f)! : Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            var name = Path.GetFileNameWithoutExtension(string.IsNullOrEmpty(f) ? "Drawing" : f);
            return Path.Combine(dir, $"{name}_{kind}_{DateTime.Now:yyyyMMdd_HHmmss}");
        }
    }
}
