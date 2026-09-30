using System;
using System.Collections.Generic;
using System.Linq;
using RooMNRooF.Core.Models;

namespace RooMNRooF.Core.Geometry
{
    public readonly record struct Pt(double X, double Y)
    {
        public Pt Rotate(double ang) => new(X * Math.Cos(ang) - Y * Math.Sin(ang), X * Math.Sin(ang) + Y * Math.Cos(ang));
        public static Pt operator +(Pt a, Pt b) => new(a.X + b.X, a.Y + b.Y);
    }

    /// <summary>Role decides the target layer inside the plugin: Outline -> member layer, Hidden -> hidden linetype, Detail -> S-DETAIL/rebar.</summary>
    public enum PathRole { Outline, Hidden, Detail, Center }

    public sealed class Path2D
    {
        public List<Pt> Points { get; } = new();
        public bool Closed { get; set; }
        public PathRole Role { get; set; } = PathRole.Outline;
        public Path2D(bool closed, PathRole role, params Pt[] pts) { Closed = closed; Role = role; Points.AddRange(pts); }
    }

    public sealed class Circle2D { public Pt Center; public double Radius; public PathRole Role = PathRole.Outline; }

    public sealed class Shape2D
    {
        public List<Path2D> Paths { get; } = new();
        public List<Circle2D> Circles { get; } = new();
        /// <summary>Closed path index to hatch (or -1). For circles use HatchCircle.</summary>
        public int HatchPath { get; set; } = -1;
        public bool HatchCircle { get; set; }
        public Pt TagPoint { get; set; }
        public double Area { get; set; }

        public Shape2D Transform(Pt origin, double rotation)
        {
            var s = new Shape2D { HatchPath = HatchPath, HatchCircle = HatchCircle, Area = Area, TagPoint = TagPoint.Rotate(rotation) + origin };
            foreach (var p in Paths) s.Paths.Add(new Path2D(p.Closed, p.Role, p.Points.Select(q => q.Rotate(rotation) + origin).ToArray()));
            foreach (var c in Circles) s.Circles.Add(new Circle2D { Center = c.Center.Rotate(rotation) + origin, Radius = c.Radius, Role = c.Role });
            return s;
        }
    }

    /// <summary>
    /// Pure 2D plan geometry for every member shape family. All coordinates in mm, local origin =
    /// member centre (columns/footings) or start point (beams/walls/joints). The AutoCAD layer converts
    /// these to Polyline/Circle/Hatch entities.
    /// </summary>
    public static class MemberGeometry
    {
        public static Shape2D Build(MemberDef def, IReadOnlyDictionary<string, double> p)
        {
            double G(string k) => p.TryGetValue(k, out var v) ? v : def.Param(k);
            switch (def.Shape)
            {
                case "RECT": return Rect(G("Width"), def.Parameters.Any(x => x.Name == "Projection") ? G("Projection") : G("Depth"), true);
                case "CIRCLE": { var r = G("Diameter") / 2; Pos(r, "Diameter"); return new Shape2D { Circles = { new Circle2D { Radius = r } }, HatchCircle = true, Area = Math.PI * r * r }; }
                case "PILE": { var r = G("Diameter") / 2; Pos(r, "Diameter"); var s = new Shape2D { Circles = { new Circle2D { Radius = r } }, HatchCircle = false, Area = Math.PI * r * r }; s.Paths.Add(Cross(r * 1.3)); s.Paths.Add(Cross2(r * 1.3)); return s; }
                case "LSHAPE": return Poly(LPoints(G("Width"), G("Depth"), G("Thickness")));
                case "TSHAPE": return Poly(TPoints(G("Width"), G("Depth"), G("Thickness")));
                case "CROSS": return Poly(XPoints(G("Width"), G("Depth"), G("Thickness")));
                case "BEAM": return Beam(G("Length"), G("Width"), def.Layer.EndsWith("HIDDEN", StringComparison.OrdinalIgnoreCase));
                case "WALL": return Band(G("Length"), G("Thickness"), true);
                case "SLAB":
                case "LANDING":
                    { var s = Rect(G("Length"), G("Width"), false); AddSlabSpanMark(s, G("Length"), G("Width")); if (def.Code == "SLB-RIB") AddRibs(s, G("Length"), G("Width"), G("RibSpacing"), G("RibWidth")); return s; }
                case "RAMP": { var s = Rect(G("Length"), G("Width"), false); s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(-G("Length") / 2 + 200, 0), new Pt(G("Length") / 2 - 200, 0), new Pt(G("Length") / 2 - 500, 150), new Pt(G("Length") / 2 - 200, 0), new Pt(G("Length") / 2 - 500, -150))); return s; }
                case "FOOTING": return Footing(G("Length"), G("Width"));
                case "PILECAP": return PileCap(G("Length"), G("Width"), (int)Math.Round(G("Piles")));
                case "STAIR": return Stair(G("Width"), G("Going"), (int)Math.Round(G("Steps")), def.Code == "STR-DOG" || def.Code == "STR");
                case "TANK": return Tank(G("Length"), G("Width"), G("WallThickness"));
                case "CORE": return Core(G("Length"), G("Width"), G("Thickness"), G("DoorWidth"));
                case "OPENING": { var s = Rect(G("Length"), G("Width"), false); var l = G("Length") / 2; var w = G("Width") / 2; s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(-l, -w), new Pt(l, w))); s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(-l, w), new Pt(l, -w))); s.HatchPath = -1; return s; }
                case "JOINT": return Joint(G("Length"), G("Gap"));
                case "STARTER": { var s = Rect(G("Width"), G("Depth"), false); s.Paths[0].Role = PathRole.Hidden; return s; }
                case "JOINTBC": { var s = Rect(G("Width"), G("Depth"), true); s.Paths.Add(Cross(Math.Min(G("Width"), G("Depth")) / 2)); s.Paths.Add(Cross2(Math.Min(G("Width"), G("Depth")) / 2)); return s; }
                default: throw new NotSupportedException($"Shape {def.Shape} not supported");
            }
        }

        static void Pos(double v, string name) { if (!(v > 0)) throw new ArgumentException($"{name} must be > 0"); }

        public static Shape2D Rect(double w, double d, bool hatch)
        {
            Pos(w, "Width"); Pos(d, "Depth");
            var s = new Shape2D { Area = w * d };
            s.Paths.Add(new Path2D(true, PathRole.Outline, new Pt(-w / 2, -d / 2), new Pt(w / 2, -d / 2), new Pt(w / 2, d / 2), new Pt(-w / 2, d / 2)));
            s.HatchPath = hatch ? 0 : -1;
            return s;
        }

        static Shape2D Poly(Pt[] pts)
        {
            var s = new Shape2D { Area = Math.Abs(ShoelaceArea(pts)) };
            s.Paths.Add(new Path2D(true, PathRole.Outline, pts));
            s.HatchPath = 0;
            return s;
        }

        public static double ShoelaceArea(IReadOnlyList<Pt> pts)
        {
            double a = 0;
            for (int i = 0; i < pts.Count; i++) { var p = pts[i]; var q = pts[(i + 1) % pts.Count]; a += p.X * q.Y - q.X * p.Y; }
            return a / 2;
        }

        static void Leg(double w, double d, double t) { Pos(w, "Width"); Pos(d, "Depth"); Pos(t, "Thickness"); if (t >= w || t >= d) throw new ArgumentException("Thickness must be less than width and depth"); }

        public static Pt[] LPoints(double w, double d, double t)
        {
            Leg(w, d, t);
            // corner at origin-centred bounding box
            double x0 = -w / 2, y0 = -d / 2;
            return new[] { new Pt(x0, y0), new Pt(x0 + w, y0), new Pt(x0 + w, y0 + t), new Pt(x0 + t, y0 + t), new Pt(x0 + t, y0 + d), new Pt(x0, y0 + d) };
        }

        public static Pt[] TPoints(double w, double d, double t)
        {
            Leg(w, d, t);
            double hw = w / 2, top = d / 2, bot = -d / 2, ht = t / 2;
            return new[] { new Pt(-hw, top), new Pt(-hw, top - t), new Pt(-ht, top - t), new Pt(-ht, bot), new Pt(ht, bot), new Pt(ht, top - t), new Pt(hw, top - t), new Pt(hw, top) };
        }

        public static Pt[] XPoints(double w, double d, double t)
        {
            Leg(w, d, t);
            double hw = w / 2, hd = d / 2, ht = t / 2;
            return new[] { new Pt(-ht, hd), new Pt(ht, hd), new Pt(ht, ht), new Pt(hw, ht), new Pt(hw, -ht), new Pt(ht, -ht), new Pt(ht, -hd), new Pt(-ht, -hd), new Pt(-ht, -ht), new Pt(-hw, -ht), new Pt(-hw, ht), new Pt(-ht, ht) };
        }

        static Shape2D Beam(double len, double w, bool hidden)
        {
            Pos(len, "Length"); Pos(w, "Width");
            var s = new Shape2D { Area = len * w, TagPoint = new Pt(len / 2, w / 2 + 150) };
            var role = hidden ? PathRole.Hidden : PathRole.Outline;
            s.Paths.Add(new Path2D(false, role, new Pt(0, w / 2), new Pt(len, w / 2)));
            s.Paths.Add(new Path2D(false, role, new Pt(0, -w / 2), new Pt(len, -w / 2)));
            s.Paths.Add(new Path2D(false, PathRole.Center, new Pt(0, 0), new Pt(len, 0)));
            return s;
        }

        static Shape2D Band(double len, double t, bool hatch)
        {
            Pos(len, "Length"); Pos(t, "Thickness");
            var s = new Shape2D { Area = len * t, TagPoint = new Pt(len / 2, t / 2 + 150) };
            s.Paths.Add(new Path2D(true, PathRole.Outline, new Pt(0, -t / 2), new Pt(len, -t / 2), new Pt(len, t / 2), new Pt(0, t / 2)));
            s.HatchPath = hatch ? 0 : -1;
            return s;
        }

        static void AddSlabSpanMark(Shape2D s, double l, double w)
        {
            // Two-way span arrows (standard slab symbol) as detail lines
            double a = Math.Min(l, w) * 0.25;
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(-a, 0), new Pt(a, 0)));
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(0, -a), new Pt(0, a)));
            s.TagPoint = new Pt(a * 0.15, a * 0.15);
        }

        static void AddRibs(Shape2D s, double l, double w, double spacing, double ribW)
        {
            if (spacing <= 0 || ribW <= 0) return;
            for (double x = -l / 2 + spacing; x < l / 2 - 1; x += spacing)
            {
                s.Paths.Add(new Path2D(false, PathRole.Hidden, new Pt(x - ribW / 2, -w / 2), new Pt(x - ribW / 2, w / 2)));
                s.Paths.Add(new Path2D(false, PathRole.Hidden, new Pt(x + ribW / 2, -w / 2), new Pt(x + ribW / 2, w / 2)));
            }
        }

        static Shape2D Footing(double l, double w)
        {
            var s = Rect(l, w, false);
            // pedestal/column outline hint at centre (hidden) + diagonal slope lines (sloped footing convention)
            double c = Math.Min(l, w) * 0.2;
            s.Paths.Add(new Path2D(true, PathRole.Hidden, new Pt(-c, -c), new Pt(c, -c), new Pt(c, c), new Pt(-c, c)));
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(-l / 2, -w / 2), new Pt(-c, -c)));
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(l / 2, -w / 2), new Pt(c, -c)));
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(l / 2, w / 2), new Pt(c, c)));
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(-l / 2, w / 2), new Pt(-c, c)));
            s.TagPoint = new Pt(0, -w / 2 - 250);
            return s;
        }

        public static IReadOnlyList<Pt> PileLayout(double l, double w, int n)
        {
            if (n < 1) throw new ArgumentException("Piles must be >= 1");
            double ex = l * 0.3, ey = w * 0.3;
            return n switch
            {
                1 => new[] { new Pt(0, 0) },
                2 => new[] { new Pt(-ex, 0), new Pt(ex, 0) },
                3 => new[] { new Pt(-ex, -ey), new Pt(ex, -ey), new Pt(0, ey) },
                4 => new[] { new Pt(-ex, -ey), new Pt(ex, -ey), new Pt(ex, ey), new Pt(-ex, ey) },
                5 => new[] { new Pt(-ex, -ey), new Pt(ex, -ey), new Pt(ex, ey), new Pt(-ex, ey), new Pt(0, 0) },
                _ => Enumerable.Range(0, n).Select(i => { double a = 2 * Math.PI * i / n; return new Pt(ex * Math.Cos(a), ey * Math.Sin(a)); }).ToArray(),
            };
        }

        static Shape2D PileCap(double l, double w, int n)
        {
            var s = Rect(l, w, false);
            double r = Math.Min(l, w) * 0.12;
            foreach (var p in PileLayout(l, w, n)) s.Circles.Add(new Circle2D { Center = p, Radius = r, Role = PathRole.Hidden });
            s.TagPoint = new Pt(0, -w / 2 - 250);
            return s;
        }

        static Shape2D Stair(double width, double going, int steps, bool dogLeg)
        {
            Pos(width, "Width"); Pos(going, "Going"); if (steps < 2) throw new ArgumentException("Steps must be >= 2");
            var s = new Shape2D();
            if (!dogLeg)
            {
                double len = going * steps;
                s.Paths.Add(new Path2D(true, PathRole.Outline, new Pt(0, 0), new Pt(len, 0), new Pt(len, width), new Pt(0, width)));
                for (int i = 1; i < steps; i++) s.Paths.Add(new Path2D(false, PathRole.Outline, new Pt(i * going, 0), new Pt(i * going, width)));
                s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(going / 2, width / 2), new Pt(len - going, width / 2), new Pt(len - going * 1.5, width / 2 + 120), new Pt(len - going, width / 2), new Pt(len - going * 1.5, width / 2 - 120)));
                s.Area = len * width; s.TagPoint = new Pt(len / 2, -300);
                return s;
            }
            int f1 = (steps + 1) / 2, f2 = steps - f1;
            double gap = 100, flight = going * (f1 - 1), totalW = 2 * width + gap, landing = width;
            s.Paths.Add(new Path2D(true, PathRole.Outline, new Pt(0, 0), new Pt(flight + landing, 0), new Pt(flight + landing, totalW), new Pt(0, totalW)));
            for (int i = 1; i < f1; i++) s.Paths.Add(new Path2D(false, PathRole.Outline, new Pt(i * going, 0), new Pt(i * going, width)));
            double f2len = going * (Math.Max(f2, 1) - 1);
            for (int i = 1; i < f2; i++) s.Paths.Add(new Path2D(false, PathRole.Outline, new Pt(flight - i * going + going, width + gap), new Pt(flight - i * going + going, totalW)));
            s.Paths.Add(new Path2D(true, PathRole.Outline, new Pt(0, width), new Pt(flight, width), new Pt(flight, width + gap), new Pt(0, width + gap)));
            s.Paths.Add(new Path2D(false, PathRole.Outline, new Pt(flight, 0), new Pt(flight, totalW)));
            s.Paths.Add(new Path2D(false, PathRole.Detail, new Pt(going / 2, width / 2), new Pt(flight + landing / 2, width / 2), new Pt(flight + landing / 2, width + gap + width / 2), new Pt(Math.Max(going, flight - f2len), width + gap + width / 2)));
            s.Area = (flight + landing) * totalW; s.TagPoint = new Pt((flight + landing) / 2, -300);
            return s;
        }

        static Shape2D Tank(double l, double w, double t)
        {
            Pos(l, "Length"); Pos(w, "Width"); Pos(t, "WallThickness");
            if (2 * t >= Math.Min(l, w)) throw new ArgumentException("Wall thickness too large for tank size");
            var s = Rect(l, w, false);
            s.Paths.Add(new Path2D(true, PathRole.Outline, new Pt(-l / 2 + t, -w / 2 + t), new Pt(l / 2 - t, -w / 2 + t), new Pt(l / 2 - t, w / 2 - t), new Pt(-l / 2 + t, w / 2 - t)));
            s.Area = l * w - (l - 2 * t) * (w - 2 * t);
            s.TagPoint = new Pt(0, 0);
            return s;
        }

        static Shape2D Core(double l, double w, double t, double door)
        {
            Pos(l, "Length"); Pos(w, "Width"); Pos(t, "Thickness");
            if (door >= l - 2 * t) throw new ArgumentException("Door width too large for core");
            double x0 = -l / 2, y0 = -w / 2, dl = -door / 2, dr = door / 2;
            var outer = new[] { new Pt(dr, y0), new Pt(-x0, y0), new Pt(-x0, -y0), new Pt(x0, -y0), new Pt(x0, y0), new Pt(dl, y0), new Pt(dl, y0 + t), new Pt(x0 + t, y0 + t), new Pt(x0 + t, -y0 - t), new Pt(-x0 - t, -y0 - t), new Pt(-x0 - t, y0 + t), new Pt(dr, y0 + t) };
            var s = Poly(outer);
            s.Paths.Add(Cross(Math.Min(l, w) / 2 - t));
            s.Paths.Add(Cross2(Math.Min(l, w) / 2 - t));
            s.TagPoint = new Pt(0, -w / 2 - 250);
            return s;
        }

        static Shape2D Joint(double len, double gap)
        {
            Pos(len, "Length");
            var s = new Shape2D { TagPoint = new Pt(len / 2, 200) };
            if (gap > 0)
            {
                s.Paths.Add(new Path2D(false, PathRole.Outline, new Pt(0, gap / 2), new Pt(len, gap / 2)));
                s.Paths.Add(new Path2D(false, PathRole.Outline, new Pt(0, -gap / 2), new Pt(len, -gap / 2)));
            }
            s.Paths.Add(new Path2D(false, PathRole.Center, new Pt(0, 0), new Pt(len, 0)));
            return s;
        }

        static Path2D Cross(double r) => new(false, PathRole.Detail, new Pt(-r, -r), new Pt(r, r));
        static Path2D Cross2(double r) => new(false, PathRole.Detail, new Pt(-r, r), new Pt(r, -r));
    }

    /// <summary>Structural grid generator (pure). Labels: letters skip I and O (common drafting practice).</summary>
    public static class GridGeometry
    {
        public sealed class GridLine { public string Label = ""; public Pt Start; public Pt End; public bool Vertical; public double Ordinate; }

        public static string LetterLabel(int index)
        {
            const string letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"; // no I, O
            var s = "";
            index++;
            while (index > 0) { int m = (index - 1) % letters.Length; s = letters[m] + s; index = (index - 1) / letters.Length; }
            return s;
        }

        public static List<GridLine> Build(IReadOnlyList<double> xSpacings, IReadOnlyList<double> ySpacings, double extension, bool lettersOnX = false)
        {
            if (xSpacings.Any(v => v <= 0) || ySpacings.Any(v => v <= 0)) throw new ArgumentException("Grid spacings must be > 0");
            var xs = new List<double> { 0 }; foreach (var d in xSpacings) xs.Add(xs[^1] + d);
            var ys = new List<double> { 0 }; foreach (var d in ySpacings) ys.Add(ys[^1] + d);
            double xmax = xs[^1], ymax = ys[^1];
            var list = new List<GridLine>();
            for (int i = 0; i < xs.Count; i++)
                list.Add(new GridLine { Label = lettersOnX ? LetterLabel(i) : (i + 1).ToString(), Vertical = true, Ordinate = xs[i], Start = new Pt(xs[i], -extension), End = new Pt(xs[i], ymax + extension) });
            for (int j = 0; j < ys.Count; j++)
                list.Add(new GridLine { Label = lettersOnX ? (j + 1).ToString() : LetterLabel(j), Vertical = false, Ordinate = ys[j], Start = new Pt(-extension, ys[j]), End = new Pt(xmax + extension, ys[j]) });
            return list;
        }

        /// <summary>Parses "4*5000" or "5000,4500,5000" into spacings.</summary>
        public static List<double> ParseSpacings(string text)
        {
            var result = new List<double>();
            foreach (var raw in text.Split(new[] { ',', ' ' }, StringSplitOptions.RemoveEmptyEntries))
            {
                var parts = raw.Split('*');
                if (parts.Length == 2)
                {
                    int n = int.Parse(parts[0], System.Globalization.CultureInfo.InvariantCulture);
                    double v = double.Parse(parts[1], System.Globalization.CultureInfo.InvariantCulture);
                    if (n <= 0 || n > 200) throw new FormatException("Repeat count out of range");
                    for (int i = 0; i < n; i++) result.Add(v);
                }
                else result.Add(double.Parse(raw, System.Globalization.CultureInfo.InvariantCulture));
            }
            if (result.Count == 0 || result.Any(v => v <= 0)) throw new FormatException("Spacings must be positive numbers");
            return result;
        }
    }
}
