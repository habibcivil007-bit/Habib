using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;

namespace RooMNRooF.Core.Rebar
{
    public enum RebarRole { Main, Distribution, Top, Bottom, Extra, Stirrup, Tie, Link }

    /// <summary>
    /// A parsed reinforcement call-out. Two forms are supported:
    ///   count form   "4T16"            -> Count=4, Dia=16
    ///   spacing form "T10 @ 150 c/c"   -> Dia=10, Spacing=150
    /// Optional "2L-" / "4L-" prefix for number of stirrup legs: "2L-T8@150".
    /// </summary>
    public sealed class RebarCallout
    {
        public int? Count { get; init; }
        public int Diameter { get; init; }
        public double? Spacing { get; init; }
        public int Legs { get; init; } = 1;
        public string Grade { get; init; } = "T";

        public bool IsSpacingForm => Spacing.HasValue;

        public override string ToString()
        {
            var legs = Legs > 1 ? $"{Legs}L-" : "";
            return IsSpacingForm
                ? $"{legs}{Grade}{Diameter} @ {Spacing!.Value.ToString("0.#", CultureInfo.InvariantCulture)} c/c"
                : $"{Count}{Grade}{Diameter}";
        }
    }

    public static class RebarNotation
    {
        public static readonly int[] StandardDiameters = { 8, 10, 12, 16, 20, 25, 32 };

        static readonly Regex CountForm = new(@"^\s*(\d+)\s*([TtYyRr])\s*(\d+)\s*$");
        static readonly Regex SpacingForm = new(@"^\s*(?:(\d+)\s*L\s*-\s*)?([TtYyRr])\s*(\d+)\s*@\s*(\d+(?:\.\d+)?)\s*(?:c/c|mm|c\\c)?\s*$", RegexOptions.IgnoreCase);

        public static bool TryParse(string text, out RebarCallout? callout, out string error)
        {
            callout = null; error = "";
            if (string.IsNullOrWhiteSpace(text)) { error = "Empty reinforcement text."; return false; }
            var m = CountForm.Match(text);
            if (m.Success)
            {
                int n = int.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture);
                int d = int.Parse(m.Groups[3].Value, CultureInfo.InvariantCulture);
                if (n <= 0) { error = "Bar count must be positive."; return false; }
                if (Array.IndexOf(StandardDiameters, d) < 0) { error = $"T{d} is not a supported diameter ({string.Join(",", StandardDiameters)})."; return false; }
                callout = new RebarCallout { Count = n, Diameter = d, Grade = m.Groups[2].Value.ToUpperInvariant() };
                return true;
            }
            m = SpacingForm.Match(text);
            if (m.Success)
            {
                int legs = m.Groups[1].Success ? int.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture) : 1;
                int d = int.Parse(m.Groups[3].Value, CultureInfo.InvariantCulture);
                double s = double.Parse(m.Groups[4].Value, CultureInfo.InvariantCulture);
                if (Array.IndexOf(StandardDiameters, d) < 0) { error = $"T{d} is not a supported diameter."; return false; }
                if (s <= 0) { error = "Spacing must be positive."; return false; }
                if (legs < 1) { error = "Legs must be >= 1."; return false; }
                callout = new RebarCallout { Diameter = d, Spacing = s, Legs = legs, Grade = m.Groups[2].Value.ToUpperInvariant() };
                return true;
            }
            error = $"Unrecognised reinforcement notation '{text}'. Use e.g. 4T16 or T10 @ 150 c/c.";
            return false;
        }

        public static RebarCallout Parse(string text) =>
            TryParse(text, out var c, out var e) ? c! : throw new FormatException(e);

        /// <summary>Number of bars for a spacing call-out across a clear distribution length: floor(L/s)+1.</summary>
        public static int BarsForSpacing(double distributionLength, double spacing)
        {
            if (spacing <= 0) throw new ArgumentOutOfRangeException(nameof(spacing));
            if (distributionLength <= 0) return 0;
            return (int)Math.Floor(distributionLength / spacing + 1e-9) + 1;
        }

        /// <summary>Unit weight kg/m = d^2 / 162.2.</summary>
        public static double UnitWeight(int diameterMm) => Math.Round(diameterMm * diameterMm / 162.2, 3);

        /// <summary>Builds a readable composite note, e.g. "TOP: 2T16 + 1T12 EXTRA / BOT: 3T16 / STIRRUP: 2L-T8 @ 150 c/c".</summary>
        public static string ComposeBeamNote(string top, string bottom, string? extra, string stirrup)
        {
            var parts = new List<string> { $"TOP: {Parse(top)}" };
            if (!string.IsNullOrWhiteSpace(extra)) parts[0] += $" + {Parse(extra!)} EXTRA";
            parts.Add($"BOT: {Parse(bottom)}");
            parts.Add($"STIRRUP: {Parse(stirrup)}");
            return string.Join(" / ", parts);
        }
    }
}
