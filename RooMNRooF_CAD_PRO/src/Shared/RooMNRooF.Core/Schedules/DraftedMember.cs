using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;

namespace RooMNRooF.Core.Schedules
{
    /// <summary>
    /// Engineering metadata attached to a drafted entity (stored as XData under the
    /// "RNR_MEMBER" application name, serialised with <see cref="Serialize"/>).
    /// Values are exactly what the user typed - nothing is designed or verified.
    /// </summary>
    public sealed class DraftedMember
    {
        public const string RegApp = "RNR_MEMBER";
        public string Code { get; set; } = "";
        public string Mark { get; set; } = "";
        public string Schedule { get; set; } = "NONE";
        public string ConcreteGrade { get; set; } = "";
        public string Level { get; set; } = "";
        public Dictionary<string, double> Dims { get; set; } = new(StringComparer.OrdinalIgnoreCase);
        public Dictionary<string, string> Rebar { get; set; } = new(StringComparer.OrdinalIgnoreCase);
        public string Handle { get; set; } = "";

        public double Dim(string key, double fallback = 0) => Dims.TryGetValue(key, out var v) ? v : fallback;

        /// <summary>Size text for schedules, e.g. "300x450" or "Ø400".</summary>
        public string SizeText()
        {
            if (Dims.ContainsKey("Diameter")) return "Ø" + Fmt(Dim("Diameter"));
            if (Dims.ContainsKey("Width") && Dims.ContainsKey("Depth")) return Fmt(Dim("Width")) + "x" + Fmt(Dim("Depth"));
            if (Dims.ContainsKey("Length") && Dims.ContainsKey("Width")) return Fmt(Dim("Length")) + "x" + Fmt(Dim("Width"));
            if (Dims.ContainsKey("Length") && Dims.ContainsKey("Thickness")) return Fmt(Dim("Length")) + "x" + Fmt(Dim("Thickness"));
            return "";
        }

        /// <summary>Concrete volume (m3) where measurable from parameters, otherwise null.</summary>
        public double? ConcreteVolumeM3()
        {
            double w = Dim("Width"), d = Dim("Depth"), h = Dim("Height"), l = Dim("Length"), t = Dim("Thickness"), dia = Dim("Diameter");
            double mm3;
            switch (Schedule)
            {
                case "COLUMN":
                    if (dia > 0 && h > 0) mm3 = Math.PI * dia * dia / 4 * h;
                    else if (w > 0 && d > 0 && h > 0 && t > 0) mm3 = (w + d - t) * t * h; // L-shape approximation (T/cross use same area formula family)
                    else if (w > 0 && d > 0 && h > 0) mm3 = w * d * h;
                    else return null;
                    break;
                case "BEAM": if (w > 0 && d > 0 && l > 0) mm3 = w * d * l; else return null; break;
                case "SLAB":
                case "FOOTING":
                case "STAIR":
                    if (dia > 0 && l > 0) mm3 = Math.PI * dia * dia / 4 * l;          // pile
                    else if (l > 0 && w > 0 && t > 0) mm3 = l * w * t;
                    else return null;
                    break;
                case "WALL": if (l > 0 && t > 0 && h > 0) mm3 = l * t * h; else return null; break;
                case "TANK":
                    double wt = Dim("WallThickness"), dep = Dim("Depth");
                    if (l > 0 && w > 0 && wt > 0 && dep > 0) mm3 = 2 * (l + w - 2 * wt) * wt * dep + 2 * l * w * wt; // walls + base + cover
                    else return null;
                    break;
                default: return null;
            }
            return Math.Round(mm3 / 1e9, 4);
        }

        static string Fmt(double v) => v.ToString("0.##", CultureInfo.InvariantCulture);

        // ---- compact, XData-friendly serialisation: key=value;key=value (no JSON dependency in XData)
        public string Serialize()
        {
            var sb = new StringBuilder();
            void Add(string k, string v) { if (sb.Length > 0) sb.Append(';'); sb.Append(k).Append('=').Append(Escape(v)); }
            Add("code", Code); Add("mark", Mark); Add("sched", Schedule); Add("grade", ConcreteGrade); Add("level", Level);
            foreach (var kv in Dims) Add("d." + kv.Key, kv.Value.ToString("R", CultureInfo.InvariantCulture));
            foreach (var kv in Rebar) Add("r." + kv.Key, kv.Value);
            return sb.ToString();
        }

        public static DraftedMember Deserialize(string s)
        {
            var m = new DraftedMember();
            foreach (var part in SplitUnescaped(s, ';'))
            {
                int i = part.IndexOf('=');
                if (i <= 0) continue;
                var k = part.Substring(0, i); var v = Unescape(part.Substring(i + 1));
                switch (k)
                {
                    case "code": m.Code = v; break;
                    case "mark": m.Mark = v; break;
                    case "sched": m.Schedule = v; break;
                    case "grade": m.ConcreteGrade = v; break;
                    case "level": m.Level = v; break;
                    default:
                        if (k.StartsWith("d.") && double.TryParse(v, NumberStyles.Float, CultureInfo.InvariantCulture, out var d)) m.Dims[k.Substring(2)] = d;
                        else if (k.StartsWith("r.")) m.Rebar[k.Substring(2)] = v;
                        break;
                }
            }
            return m;
        }

        static string Escape(string v) => v.Replace("\\", "\\\\").Replace(";", "\\;").Replace("=", "\\=");
        static string Unescape(string v)
        {
            var sb = new StringBuilder();
            for (int i = 0; i < v.Length; i++)
            {
                if (v[i] == '\\' && i + 1 < v.Length) { sb.Append(v[++i]); continue; }
                sb.Append(v[i]);
            }
            return sb.ToString();
        }
        static IEnumerable<string> SplitUnescaped(string s, char sep)
        {
            var sb = new StringBuilder();
            for (int i = 0; i < s.Length; i++)
            {
                if (s[i] == '\\' && i + 1 < s.Length) { sb.Append(s[i]).Append(s[++i]); continue; }
                if (s[i] == sep) { yield return sb.ToString(); sb.Clear(); continue; }
                sb.Append(s[i]);
            }
            if (sb.Length > 0) yield return sb.ToString();
        }

        /// <summary>Split a serialized string into XData-safe chunks (&lt;= 250 chars each).</summary>
        public static IEnumerable<string> Chunk(string s, int size = 250)
        {
            for (int i = 0; i < s.Length; i += size) yield return s.Substring(i, Math.Min(size, s.Length - i));
        }
    }

    public sealed class ScheduleTable
    {
        public string Title { get; set; } = "";
        public List<string> Headers { get; set; } = new();
        public List<List<string>> Rows { get; set; } = new();
        public string Footnote { get; set; } = "";
    }

    public static class ScheduleBuilder
    {
        public const string Footnote = "CAD-derived drafting schedule. Values as entered by user; subject to engineering review.";

        public static ScheduleTable Build(string schedule, IEnumerable<DraftedMember> members)
        {
            var list = members.Where(m => string.Equals(m.Schedule, schedule, StringComparison.OrdinalIgnoreCase))
                              .GroupBy(m => m.Mark, StringComparer.OrdinalIgnoreCase)
                              .Select(g => (Mark: g.Key, First: g.First(), Count: g.Count()))
                              .OrderBy(x => x.Mark, NaturalComparer.Instance).ToList();
            var t = new ScheduleTable { Title = schedule.ToUpperInvariant() + " SCHEDULE", Footnote = Footnote };
            switch (schedule.ToUpperInvariant())
            {
                case "COLUMN":
                    t.Headers = new() { "MARK", "SIZE (mm)", "MAIN BARS", "TIES", "GRADE", "NOS" };
                    foreach (var x in list)
                        t.Rows.Add(new() { x.Mark, x.First.SizeText(), R(x.First, "MainBars"), Ties(x.First), x.First.ConcreteGrade, x.Count.ToString() });
                    break;
                case "BEAM":
                    t.Headers = new() { "MARK", "SIZE (mm)", "TOP", "BOTTOM", "EXTRA", "STIRRUPS", "GRADE", "NOS" };
                    foreach (var x in list)
                        t.Rows.Add(new() { x.Mark, x.First.SizeText(), R(x.First, "TopBars"), R(x.First, "BottomBars"), R(x.First, "ExtraBars"),
                            Sp(x.First, "StirrupDia", "StirrupSpacing"), x.First.ConcreteGrade, x.Count.ToString() });
                    break;
                case "SLAB":
                    t.Headers = new() { "MARK", "THK (mm)", "MAIN X", "MAIN Y", "TOP EXTRA", "DISTRIBUTION", "GRADE" };
                    foreach (var x in list)
                        t.Rows.Add(new() { x.Mark, x.First.Dim("Thickness").ToString("0", CultureInfo.InvariantCulture), R(x.First, "MainBarsX"), R(x.First, "MainBarsY"),
                            R(x.First, "TopExtra"), R(x.First, "Distribution"), x.First.ConcreteGrade });
                    break;
                case "FOOTING":
                    t.Headers = new() { "MARK", "SIZE (mm)", "THK (mm)", "BOTTOM X", "BOTTOM Y", "TOP X", "TOP Y", "GRADE", "NOS" };
                    foreach (var x in list)
                        t.Rows.Add(new() { x.Mark, x.First.SizeText(), x.First.Dim("Thickness").ToString("0", CultureInfo.InvariantCulture), R(x.First, "BottomX"), R(x.First, "BottomY"),
                            R(x.First, "TopX"), R(x.First, "TopY"), x.First.ConcreteGrade, x.Count.ToString() });
                    break;
                case "STAIR":
                    t.Headers = new() { "MARK", "WIDTH", "GOING", "RISER", "STEPS", "WAIST/THK", "MAIN", "DIST." };
                    foreach (var x in list)
                        t.Rows.Add(new() { x.Mark, N(x.First, "Width"), N(x.First, "Going"), N(x.First, "Riser"), N(x.First, "Steps"), N(x.First, "Thickness"),
                            R(x.First, "MainBars"), R(x.First, "Distribution") });
                    break;
                default:
                    t.Headers = new() { "MARK", "CODE", "SIZE", "GRADE", "NOS" };
                    foreach (var x in list) t.Rows.Add(new() { x.Mark, x.First.Code, x.First.SizeText(), x.First.ConcreteGrade, x.Count.ToString() });
                    break;
            }
            return t;
        }

        static string R(DraftedMember m, string k) => m.Rebar.TryGetValue(k, out var v) ? v : "-";
        static string N(DraftedMember m, string k) => m.Dims.TryGetValue(k, out var v) ? v.ToString("0.##", CultureInfo.InvariantCulture) : "-";
        static string Ties(DraftedMember m) => Sp(m, "TieDia", "TieSpacing");
        static string Sp(DraftedMember m, string dk, string sk)
        {
            if (!m.Rebar.TryGetValue(dk, out var d) || !m.Rebar.TryGetValue(sk, out var s)) return "-";
            d = d.TrimStart('T', 't');
            return $"T{d} @ {s}";
        }
    }

    /// <summary>C1, C2, C10 ordering (not C1, C10, C2).</summary>
    public sealed class NaturalComparer : IComparer<string>
    {
        public static readonly NaturalComparer Instance = new();
        public int Compare(string? x, string? y)
        {
            x ??= ""; y ??= "";
            int i = 0, j = 0;
            while (i < x.Length && j < y.Length)
            {
                if (char.IsDigit(x[i]) && char.IsDigit(y[j]))
                {
                    int si = i, sj = j;
                    while (i < x.Length && char.IsDigit(x[i])) i++;
                    while (j < y.Length && char.IsDigit(y[j])) j++;
                    var a = long.Parse(x.Substring(si, Math.Min(i - si, 18)), CultureInfo.InvariantCulture);
                    var b = long.Parse(y.Substring(sj, Math.Min(j - sj, 18)), CultureInfo.InvariantCulture);
                    if (a != b) return a.CompareTo(b);
                }
                else
                {
                    int c = char.ToUpperInvariant(x[i]).CompareTo(char.ToUpperInvariant(y[j]));
                    if (c != 0) return c;
                    i++; j++;
                }
            }
            return (x.Length - i).CompareTo(y.Length - j);
        }
    }
}
