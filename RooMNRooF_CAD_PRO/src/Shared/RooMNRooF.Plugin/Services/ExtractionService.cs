using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using RooMNRooF.Core.Boq;
using RooMNRooF.Core.Export;
using RooMNRooF.Core.Rebar;
using RooMNRooF.Core.Schedules;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>Reads RooMNRooF metadata from the drawing and produces schedules, BBS and BOQ data.</summary>
    public static class ExtractionService
    {
        /// <summary>All drafted members in model space (single pass, XData filtered).</summary>
        public static List<DraftedMember> Members(Database db, Transaction tr)
        {
            var list = new List<DraftedMember>();
            var ms = (BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(db), OpenMode.ForRead);
            foreach (ObjectId id in ms)
            {
                var o = tr.GetObject(id, OpenMode.ForRead);
                var m = DrawService.ReadMember(o);
                if (m != null) list.Add(m);
            }
            return list;
        }

        /// <summary>
        /// Builds BBS rows from member metadata using the PROJECT engineering parameters.
        /// Members lacking required inputs are skipped with a reason (never guessed).
        /// </summary>
        public static List<BbsRow> Bbs(IEnumerable<DraftedMember> members, BbsParameters p, List<string> skipped)
        {
            var rows = new List<BbsRow>();
            int n = 0;
            string Mark() => $"{++n:00}";
            foreach (var m in members)
            {
                try
                {
                    switch (m.Schedule)
                    {
                        case "COLUMN":
                            {
                                double h = m.Dim("Height"), w = m.Dim("Width", m.Dim("Diameter")), d = m.Dim("Depth", m.Dim("Diameter"));
                                if (m.Rebar.TryGetValue("MainBars", out var mb) && RebarNotation.TryParse(mb, out var c, out _) && c!.Count.HasValue && h > 0)
                                    rows.Add(BbsCalculator.Straight(Mark(), m.Mark, c.Diameter, c.Count.Value, h + 2 * (p.ClearCover ?? 0), p));
                                if (TryInt(m, "TieDia", out var td) && TryDbl(m, "TieSpacing", out var ts) && h > 0 && w > 0 && d > 0)
                                    rows.Add(BbsCalculator.Stirrup(Mark(), m.Mark, td, w, d, h, ts, p));
                                break;
                            }
                        case "BEAM":
                            {
                                double l = m.Dim("Length"), w = m.Dim("Width"), d = m.Dim("Depth");
                                foreach (var key in new[] { "TopBars", "BottomBars", "ExtraBars" })
                                    if (m.Rebar.TryGetValue(key, out var s) && RebarNotation.TryParse(s, out var c, out _) && c!.Count.HasValue && l > 0)
                                    {
                                        var r = BbsCalculator.Straight(Mark(), m.Mark, c.Diameter, c.Count.Value, key == "ExtraBars" ? l / 3 : l, p);
                                        r.Remarks = (key + (key == "ExtraBars" ? " (L/3 each end assumed - edit)" : "") + (r.Remarks.Length > 0 ? "; " + r.Remarks : ""));
                                        rows.Add(r);
                                    }
                                if (TryInt(m, "StirrupDia", out var sd) && TryDbl(m, "StirrupSpacing", out var ss) && l > 0 && w > 0 && d > 0)
                                    rows.Add(BbsCalculator.Stirrup(Mark(), m.Mark, sd, w, d, l, ss, p));
                                break;
                            }
                        case "SLAB":
                        case "FOOTING":
                            {
                                double l = m.Dim("Length"), w = m.Dim("Width");
                                if (l <= 0 || w <= 0) { skipped.Add($"{m.Mark}: no plan size"); break; }
                                foreach (var (key, alongX) in new[] { ("MainBarsX", true), ("MainBarsY", false), ("BottomX", true), ("BottomY", false), ("TopX", true), ("TopY", false) })
                                    if (m.Rebar.TryGetValue(key, out var s) && RebarNotation.TryParse(s, out var c, out _) && c!.IsSpacingForm)
                                    {
                                        var r = alongX ? BbsCalculator.Mesh(Mark(), m.Mark, c.Diameter, l, w, c.Spacing!.Value, p)
                                                       : BbsCalculator.Mesh(Mark(), m.Mark, c.Diameter, w, l, c.Spacing!.Value, p);
                                        r.Remarks = key + (r.Remarks.Length > 0 ? "; " + r.Remarks : "");
                                        rows.Add(r);
                                    }
                                break;
                            }
                    }
                }
                catch (Exception ex) { skipped.Add($"{m.Mark}: {ex.Message}"); }
            }
            return rows;
        }

        static bool TryInt(DraftedMember m, string k, out int v)
        {
            v = 0;
            return m.Rebar.TryGetValue(k, out var s) && int.TryParse(s.TrimStart('T', 't'), NumberStyles.Integer, CultureInfo.InvariantCulture, out v);
        }
        static bool TryDbl(DraftedMember m, string k, out double v)
        {
            v = 0;
            return m.Rebar.TryGetValue(k, out var s) && double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out v) && v > 0;
        }

        public static BbsParameters ProjectBbsParameters()
        {
            var e = Rnr.Project.Engineering;
            return new BbsParameters
            {
                ClearCover = e.ClearCoverBeamMm, LapLengthD = e.LapFactorD,
                BendDeductionPer90D = null, StirrupHookAllowanceD = null,
            };
        }

        public static DataSheet BbsSheet(IEnumerable<BbsRow> rows)
        {
            var s = new DataSheet
            {
                Name = "BBS",
                Headers = { "Bar Mark", "Member", "Bar Dia (mm)", "Shape Code", "Quantity", "Length (mm)", "Spacing (mm)", "Total Length (m)", "Unit Weight (kg/m)", "Total Weight (kg)", "Remarks" },
                Notes = { "RooMNRooF BBS DATA - CAD-derived, prepared from drafted metadata. Verify cover, laps, anchorage and bends per BNBC 2020 / ACI 318-19 before fabrication." },
            };
            foreach (var r in rows)
                s.Rows.Add(new object?[] { r.BarMark, r.Member, r.BarDiameter, r.ShapeCode, r.Quantity, r.Length, r.Spacing, Math.Round(r.TotalLength / 1000, 3), r.UnitWeight, r.TotalWeight, r.Remarks });
            return s;
        }

        /// <summary>Collects BOQ measurements: members, walls (A-WALL polylines/lines), rooms (A-ROOM closed polylines), doors/windows.</summary>
        public static BoqInput BoqInput(Database db, Transaction tr, double wallHeight, double wallThickness)
        {
            var inp = new BoqInput();
            var ms = (BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(db), OpenMode.ForRead);
            foreach (ObjectId id in ms)
            {
                var o = tr.GetObject(id, OpenMode.ForRead);
                var mem = DrawService.ReadMember(o);
                if (mem != null) { inp.Members.Add(mem); continue; }
                if (o is not Entity e) continue;
                switch (e)
                {
                    case BlockReference br:
                        var name = br.IsDynamicBlock ? ((BlockTableRecord)tr.GetObject(br.DynamicBlockTableRecord, OpenMode.ForRead)).Name : br.Name;
                        if (name.StartsWith("RNR_DOOR", StringComparison.OrdinalIgnoreCase)) inp.DoorCount++;
                        else if (name.StartsWith("RNR_WINDOW", StringComparison.OrdinalIgnoreCase)) inp.WindowCount++;
                        break;
                    case Polyline pl when e.Layer.Equals("A-ROOM", StringComparison.OrdinalIgnoreCase) && pl.Closed:
                        inp.FloorAreasMm2.Add(pl.Area); break;
                    case Polyline pl when e.Layer.Equals("A-WALL", StringComparison.OrdinalIgnoreCase):
                        // RNRWALL draws closed wall bands: centre-line length ≈ perimeter/2 - thickness for a single band
                        if (pl.Closed && pl.NumberOfVertices == 4) inp.Walls.Add((Math.Max(pl.Length / 2 - wallThickness, 0), wallThickness, wallHeight));
                        else if (!pl.Closed) inp.Walls.Add((pl.Length, wallThickness, wallHeight));
                        break;
                    case Line ln when e.Layer.Equals("A-WALL", StringComparison.OrdinalIgnoreCase):
                        inp.Walls.Add((ln.Length / 2, wallThickness, wallHeight)); break; // two faces per wall
                    case Polyline pl when e.Layer.Equals("S-SLAB-OPEN", StringComparison.OrdinalIgnoreCase) && pl.Closed:
                        inp.OpeningAreasMm2.Add(pl.Area); break;
                }
            }
            return inp;
        }

        public static DataSheet BoqSheet(IEnumerable<BoqLine> lines) => new()
        {
            Name = "BOQ",
            Headers = { "Item", "Description", "Quantity", "Unit", "Alt Quantity", "Alt Unit", "Source" },
            Notes = { BoqCalculator.Disclaimer },
            Rows = lines.Select(l => new object?[] { l.Item, l.Description, l.Quantity, l.Unit, l.AltQuantity, l.AltUnit, l.Source }).ToList(),
        };

        /// <summary>Draws a schedule as a native AutoCAD Table on ANNO-SCHEDULE.</summary>
        public static Table DrawTable(DrawService d, Point3d at, ScheduleTable t, double paperTextHeight = 2.5)
        {
            double h = paperTextHeight * d.TextScale;
            var table = new Table { TableStyle = d.Db.Tablestyle, Position = at };
            int rows = t.Rows.Count + 2, cols = Math.Max(1, t.Headers.Count);
            table.SetSize(rows + 1, cols);
            table.SetRowHeight(h * 2.2);
            table.SetColumnWidth(h * 12);
            table.Cells[0, 0].TextString = t.Title;
            table.Cells[0, 0].TextHeight = h * 1.3;
            for (int c = 0; c < cols; c++) { table.Cells[1, c].TextString = t.Headers[c]; table.Cells[1, c].TextHeight = h; }
            for (int r = 0; r < t.Rows.Count; r++)
                for (int c = 0; c < cols && c < t.Rows[r].Count; c++) { table.Cells[r + 2, c].TextString = t.Rows[r][c]; table.Cells[r + 2, c].TextHeight = h; }
            // footnote row, merged
            var last = rows;
            table.MergeCells(CellRange.Create(table, last, 0, last, cols - 1));
            table.Cells[last, 0].TextString = t.Footnote;
            table.Cells[last, 0].TextHeight = h * 0.8;
            d.Add(table, "ANNO-SCHEDULE");
            table.GenerateLayout();
            return table;
        }
    }
}
