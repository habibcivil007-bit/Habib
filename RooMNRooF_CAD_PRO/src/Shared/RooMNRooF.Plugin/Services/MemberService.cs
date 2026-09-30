using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using RooMNRooF.Core.Geometry;
using RooMNRooF.Core.Models;
using RooMNRooF.Core.Schedules;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>
    /// Generic parametric placement for all 55 member definitions. Collects parameters, mark,
    /// concrete grade and reinforcement fields; draws geometry, hatch, tag and dimensions; attaches
    /// metadata (XData) used by schedules / BBS / BOQ; groups the parts.
    /// </summary>
    public static class MemberService
    {
        static readonly HashSet<string> DiaFields = new(StringComparer.OrdinalIgnoreCase) { "TieDia", "StirrupDia" };
        static readonly HashSet<string> SpacingFields = new(StringComparer.OrdinalIgnoreCase) { "TieSpacing", "StirrupSpacing" };

        /// <summary>Last-used values per member code (session memory) so repeated placement is fast.</summary>
        static readonly Dictionary<string, DraftedMember> Last = new(StringComparer.OrdinalIgnoreCase);

        public static DraftedMember Ask(Editor ed, MemberDef def, IDictionary<string, double>? fixedDims = null, bool askRebar = true)
        {
            Last.TryGetValue(def.Code, out var prev);
            var m = new DraftedMember { Code = def.Code, Schedule = def.Schedule };
            ed.WriteMessage($"\n--- {def.No:00} {def.Name} (layer {def.Layer}) ---");
            foreach (var p in def.Parameters)
            {
                if (fixedDims != null && fixedDims.TryGetValue(p.Name, out var fixedV)) { m.Dims[p.Name] = fixedV; continue; }
                double d = prev?.Dim(p.Name, p.Default) ?? p.Default;
                m.Dims[p.Name] = p.Unit == "nos"
                    ? Prompts.Int(ed, $"{p.Name} (nos)", (int)Math.Round(d), 1, 500)
                    : Prompts.Double(ed, $"{p.Name} ({p.Unit})", d, allowZero: p.Name == "Gap");
            }
            m.Mark = Prompts.Text(ed, "Member ID / mark", prev?.Mark ?? def.MarkPrefix + "1", false);
            m.ConcreteGrade = Prompts.Text(ed, "Concrete grade", prev?.ConcreteGrade ?? Rnr.Project.Engineering.ConcreteGrade, false);
            m.Level = Prompts.Text(ed, "Level / storey", prev?.Level ?? "GF", false);
            if (askRebar && def.RebarFields.Count > 0 && Prompts.YesNo(ed, "Enter reinforcement data?", true))
            {
                foreach (var f in def.RebarFields)
                {
                    var pv = prev != null && prev.Rebar.TryGetValue(f, out var x) ? x : DefaultRebar(f);
                    if (DiaFields.Contains(f))
                    {
                        var dia = Prompts.Int(ed, $"{f} (mm: 8,10,12,16,20,25,32)", int.TryParse(pv, out var di) ? di : 8, 8, 32);
                        if (Array.IndexOf(RooMNRooF.Core.Rebar.RebarNotation.StandardDiameters, dia) < 0) throw new RnrInputException($"T{dia} is not a supported diameter.");
                        m.Rebar[f] = dia.ToString(CultureInfo.InvariantCulture);
                    }
                    else if (SpacingFields.Contains(f))
                        m.Rebar[f] = Prompts.Double(ed, $"{f} (mm c/c)", double.TryParse(pv, NumberStyles.Float, CultureInfo.InvariantCulture, out var sp) ? sp : 150).ToString("0.#", CultureInfo.InvariantCulture);
                    else
                    {
                        var v = Prompts.Rebar(ed, $"{f} (e.g. 4T16 or T10 @ 150, '-' = none)", pv);
                        if (v != "-") m.Rebar[f] = v;
                    }
                }
            }
            Last[def.Code] = m;
            return m;
        }

        static string DefaultRebar(string field) => field switch
        {
            "MainBars" => "4T16", "TopBars" => "2T16", "BottomBars" => "3T16", "ExtraBars" => "-",
            "MainBarsX" or "MainBarsY" or "BottomX" or "BottomY" => "T10 @ 150", "TopExtra" or "TopX" or "TopY" => "-",
            "Distribution" => "T10 @ 200", "VerticalBars" or "WallVertical" => "T12 @ 200", "HorizontalBars" or "WallHorizontal" => "T10 @ 200",
            "Links" => "-", "BaseBars" or "CoverBars" => "T10 @ 150", _ => "-",
        };

        /// <summary>Draws a member at <paramref name="origin"/> with <paramref name="rotation"/> (radians).</summary>
        public static ObjectId Draw(DrawService d, MemberDef def, DraftedMember m, Point3d origin, double rotation, bool dims = true, bool hatch = true)
        {
            var local = MemberGeometry.Build(def, new Dictionary<string, double>(m.Dims));
            var s = local.Transform(new Pt(origin.X, origin.Y), rotation);
            string detail = def.Layer.StartsWith("S-") ? "S-DETAIL" : def.Layer;
            var ids = d.Shape(s, def.Layer, detail, out var boundary);
            if (ids.Count == 0) throw new InvalidOperationException("No geometry generated.");

            if (hatch && def.Hatch != null && !boundary.IsNull)
            {
                var h = Rnr.Repo.Hatch(def.Hatch);
                if (h != null) ids.Add(HatchService.Apply(d, boundary, h, "S-HATCH").ObjectId);
            }

            // tag
            var tagPt = DrawService.P3(s.TagPoint);
            var tagText = def.Schedule is "BEAM" or "WALL" ? $"{m.Mark} ({m.SizeText()})" : m.Mark;
            if (def.Shape is "RECT" or "CIRCLE" or "LSHAPE" or "TSHAPE" or "CROSS" or "STARTER")
            {
                double r = BoundingRadius(s);
                tagPt = new Point3d(origin.X + r + 150, origin.Y + r + 150, 0);
            }
            var tagRot = def.Schedule is "BEAM" or "WALL" ? rotation : 0;
            ids.Add(d.Text(tagPt, tagText, 2.5, def.TextLayer, TextHorizontalMode.TextCenter, TextVerticalMode.TextVerticalMid, tagRot).ObjectId);

            if (dims) ids.AddRange(Dimension(d, def, m, s, origin, rotation));

            // metadata on the primary entity
            var primary = (Entity)d.Tr.GetObject(ids[0], OpenMode.ForWrite);
            d.AttachMember(primary, m);
            d.Group($"{def.Name} {m.Mark}", ids);
            return ids[0];
        }

        static double BoundingRadius(Shape2D s)
        {
            double r = 0;
            var pts = s.Paths.SelectMany(p => p.Points).ToList();
            if (pts.Count > 0) r = Math.Max(pts.Max(p => p.X) - pts.Min(p => p.X), pts.Max(p => p.Y) - pts.Min(p => p.Y)) / 2;
            foreach (var c in s.Circles) r = Math.Max(r, c.Radius);
            return r;
        }

        static IEnumerable<ObjectId> Dimension(DrawService d, MemberDef def, DraftedMember m, Shape2D s, Point3d origin, double rot)
        {
            var list = new List<ObjectId>();
            double off = 8 * d.TextScale; // 8 mm paper offset
            Vector3d ux = new Vector3d(Math.Cos(rot), Math.Sin(rot), 0), uy = ux.RotateBy(Math.PI / 2, Vector3d.ZAxis);
            switch (def.DimensionBehavior)
            {
                case "ALIGNED_OVERALL":
                    {
                        var pts = s.Paths[0].Points;
                        var loc = pts.Select(p => new Point3d(p.X, p.Y, 0) - origin).ToList();
                        double minX = loc.Min(v => v.DotProduct(ux)), maxX = loc.Max(v => v.DotProduct(ux));
                        double minY = loc.Min(v => v.DotProduct(uy)), maxY = loc.Max(v => v.DotProduct(uy));
                        var a = origin + ux * minX + uy * minY; var b = origin + ux * maxX + uy * minY; var c = origin + ux * maxX + uy * maxY;
                        list.Add(d.Dim(b, a, off, def.DimLayer).ObjectId);   // below
                        list.Add(d.Dim(b, c, off, def.DimLayer).ObjectId);   // right
                        break;
                    }
                case "LENGTH_ONLY":
                    {
                        double len = m.Dim("Length");
                        double half = Math.Max(m.Dim("Width"), m.Dim("Thickness")) / 2;
                        var a = origin - uy * half; var b = origin + ux * len - uy * half;
                        list.Add(d.Dim(b, a, off, def.DimLayer).ObjectId);
                        break;
                    }
                case "DIAMETER":
                    {
                        if (s.Circles.Count == 0) break;
                        var c = s.Circles[0];
                        var cp = DrawService.P3(c.Center);
                        var dd = new DiametricDimension(cp + ux * c.Radius, cp - ux * c.Radius, c.Radius * 0.6, "", StyleService.DimStyleId(d.Db, d.Tr, "RNR_STRUCT"));
                        d.Add(dd, def.DimLayer); dd.Dimscale = d.TextScale;
                        list.Add(dd.ObjectId);
                        break;
                    }
            }
            return list;
        }

        public static MemberDef Def(string code) => Rnr.Repo.Member(code) ?? throw new RnrInputException($"Member definition {code} not found in RNR_Members.json.");

        /// <summary>Interactive: ask once, then place repeatedly at picked points (ENTER to finish).</summary>
        public static int PlaceRepeated(Document doc, Transaction tr, MemberDef def, IDictionary<string, double>? fixedDims = null)
        {
            var ed = doc.Editor;
            var m = Ask(ed, def, fixedDims);
            var d = new DrawService(doc.Database, tr);
            int n = 0;
            while (true)
            {
                var p = Prompts.PointOrNone(ed, n == 0 ? $"Insertion point for {m.Mark}:" : $"Next {m.Mark} insertion point <done>:");
                if (p == null) break;
                double rot = Prompts.Angle(ed, "Rotation <0>:", p.Value, 0);
                Draw(d, def, m, p.Value, rot);
                n++;
                // flush graphics so the user sees each placement
                doc.TransactionManager.QueueForGraphicsFlush();
                doc.TransactionManager.FlushGraphics();
            }
            return n;
        }
    }
}
