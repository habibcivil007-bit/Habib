using System;
using System.Globalization;
using System.Text.RegularExpressions;

namespace RooMNRooF.Core.Units
{
    public enum LengthUnit { Millimeter, Centimeter, Meter, Inch, Foot }

    /// <summary>
    /// Exact length / area / volume conversions. Inch is defined as exactly 25.4 mm
    /// (international yard and pound agreement), so all factors are exact decimals.
    /// This class never modifies drawing data - it only converts numbers on request.
    /// </summary>
    public static class UnitConverter
    {
        public const decimal MmPerInch = 25.4m;
        public const decimal MmPerFoot = 304.8m;

        public static decimal MmPer(LengthUnit u) => u switch
        {
            LengthUnit.Millimeter => 1m,
            LengthUnit.Centimeter => 10m,
            LengthUnit.Meter => 1000m,
            LengthUnit.Inch => MmPerInch,
            LengthUnit.Foot => MmPerFoot,
            _ => throw new ArgumentOutOfRangeException(nameof(u)),
        };

        public static decimal Convert(decimal value, LengthUnit from, LengthUnit to) => value * MmPer(from) / MmPer(to);
        public static double Convert(double value, LengthUnit from, LengthUnit to) => (double)Convert((decimal)value, from, to);

        public static decimal ConvertArea(decimal value, LengthUnit from, LengthUnit to)
        {
            var f = MmPer(from) / MmPer(to);
            return value * f * f;
        }

        public static decimal ConvertVolume(decimal value, LengthUnit from, LengthUnit to)
        {
            var f = MmPer(from) / MmPer(to);
            return value * f * f * f;
        }

        public static LengthUnit Parse(string s) => s.Trim().ToLowerInvariant() switch
        {
            "mm" or "millimeter" or "millimetre" => LengthUnit.Millimeter,
            "cm" or "centimeter" or "centimetre" => LengthUnit.Centimeter,
            "m" or "meter" or "metre" => LengthUnit.Meter,
            "in" or "inch" or "\"" => LengthUnit.Inch,
            "ft" or "foot" or "feet" or "'" => LengthUnit.Foot,
            _ => throw new FormatException($"Unknown length unit '{s}'"),
        };

        /// <summary>AutoCAD INSUNITS code for a unit (1=in,2=ft,4=mm,5=cm,6=m).</summary>
        public static int ToInsUnits(LengthUnit u) => u switch
        {
            LengthUnit.Inch => 1, LengthUnit.Foot => 2, LengthUnit.Millimeter => 4,
            LengthUnit.Centimeter => 5, LengthUnit.Meter => 6, _ => 0,
        };

        public static LengthUnit? FromInsUnits(int code) => code switch
        {
            1 => LengthUnit.Inch, 2 => LengthUnit.Foot, 4 => LengthUnit.Millimeter,
            5 => LengthUnit.Centimeter, 6 => LengthUnit.Meter, _ => null,
        };

        /// <summary>Formats millimetres as feet-inches, e.g. 3048 -> 10'-0", 1000 -> 3'-3 3/8" (1/denominator rounding).</summary>
        public static string ToFeetInches(decimal mm, int denominator = 8)
        {
            if (denominator <= 0) throw new ArgumentOutOfRangeException(nameof(denominator));
            var sign = mm < 0 ? "-" : "";
            var totalInches = Math.Abs(mm) / MmPerInch;
            var totalUnits = Math.Round(totalInches * denominator, MidpointRounding.AwayFromZero);
            var feet = (long)(totalUnits / (12 * denominator));
            var remUnits = (long)(totalUnits - feet * 12 * denominator);
            var inches = remUnits / denominator;
            var frac = remUnits % denominator;
            string fracStr = "";
            if (frac != 0)
            {
                long g = Gcd(frac, denominator);
                fracStr = $" {frac / g}/{denominator / g}";
            }
            return $"{sign}{feet}'-{inches}{fracStr}\"";
        }

        static readonly Regex FtIn = new(@"^\s*(-)?\s*(?:(\d+(?:\.\d+)?)\s*')?\s*-?\s*(?:(\d+(?:\.\d+)?)(?:\s+(\d+)/(\d+))?\s*"")?\s*$");

        /// <summary>Parses 10'-6", 10', 6", 10'-6 1/2" to millimetres (exact).</summary>
        public static decimal ParseFeetInches(string s)
        {
            var m = FtIn.Match(s);
            if (!m.Success || (!m.Groups[2].Success && !m.Groups[3].Success))
                throw new FormatException($"Not a feet-inch value: '{s}'");
            decimal ft = m.Groups[2].Success ? decimal.Parse(m.Groups[2].Value, CultureInfo.InvariantCulture) : 0;
            decimal inch = m.Groups[3].Success ? decimal.Parse(m.Groups[3].Value, CultureInfo.InvariantCulture) : 0;
            if (m.Groups[4].Success)
            {
                var den = decimal.Parse(m.Groups[5].Value, CultureInfo.InvariantCulture);
                if (den == 0) throw new FormatException("Zero denominator");
                inch += decimal.Parse(m.Groups[4].Value, CultureInfo.InvariantCulture) / den;
            }
            var mm = ft * MmPerFoot + inch * MmPerInch;
            return m.Groups[1].Success ? -mm : mm;
        }

        // BOQ helper units
        public const decimal SftPerSqm = 10.763910416709722m;   // 1 / 0.09290304
        public const decimal CftPerCbm = 35.31466672148859m;    // 1 / 0.028316846592
        public const decimal RftPerM = 3.280839895013123m;      // 1 / 0.3048

        static long Gcd(long a, long b) { while (b != 0) { (a, b) = (b, a % b); } return Math.Abs(a); }
    }
}
