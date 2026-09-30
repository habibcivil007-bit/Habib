using System;
using System.Collections.Generic;
using System.Linq;

namespace RooMNRooF.Core.Rebar
{
    /// <summary>One Bar Bending Schedule row. All lengths in mm, weights in kg.</summary>
    public sealed class BbsRow
    {
        public string BarMark { get; set; } = "";
        public string Member { get; set; } = "";
        public int BarDiameter { get; set; }
        public string ShapeCode { get; set; } = "00";
        public int Quantity { get; set; }
        /// <summary>Cut length of a single bar (mm).</summary>
        public double Length { get; set; }
        public double? Spacing { get; set; }
        public double TotalLength => Quantity * Length;
        public double UnitWeight => RebarNotation.UnitWeight(BarDiameter);
        public double TotalWeight => Math.Round(TotalLength / 1000.0 * UnitWeight, 3);
        public string Remarks { get; set; } = "";
    }

    /// <summary>
    /// Engineering parameters for cut-length calculation. Every value is an explicit input:
    /// no default is claimed to satisfy BNBC 2020 / ACI 318-19. Null => that term is not applied
    /// and a remark is added so the omission is visible in the schedule.
    /// </summary>
    public sealed class BbsParameters
    {
        public double? ClearCover { get; set; }
        /// <summary>Hook / bend allowance per 90° bend as a multiple of d (e.g. project may use 2d deduction).</summary>
        public double? BendDeductionPer90D { get; set; }
        /// <summary>Stirrup hook allowance total, multiple of d (e.g. 20d for two 135° hooks) - project input.</summary>
        public double? StirrupHookAllowanceD { get; set; }
        /// <summary>Lap length as multiple of d for bars longer than the stock length.</summary>
        public double? LapLengthD { get; set; }
        /// <summary>Commercial stock bar length (mm).</summary>
        public double StockLength { get; set; } = 12000;
    }

    public static class BbsCalculator
    {
        /// <summary>Straight bar (shape 00): L = span - 2*cover (+ laps if longer than stock).</summary>
        public static BbsRow Straight(string mark, string member, int dia, int qty, double span, BbsParameters p, double? spacing = null)
        {
            var remarks = new List<string>();
            double len = span;
            if (p.ClearCover is double c) len -= 2 * c; else remarks.Add("cover not deducted");
            len += Laps(len, dia, p, remarks);
            return Row(mark, member, dia, "00", qty, len, spacing, remarks);
        }

        /// <summary>L-bar (shape 11): legs A and B measured outside; minus one bend deduction.</summary>
        public static BbsRow LBar(string mark, string member, int dia, int qty, double a, double b, BbsParameters p)
        {
            var remarks = new List<string>();
            double len = a + b;
            if (p.BendDeductionPer90D is double k) len -= k * dia; else remarks.Add("bend deduction not applied");
            return Row(mark, member, dia, "11", qty, len, null, remarks);
        }

        /// <summary>U-bar (shape 21): A + B + C minus two bend deductions.</summary>
        public static BbsRow UBar(string mark, string member, int dia, int qty, double a, double b, double c, BbsParameters p)
        {
            var remarks = new List<string>();
            double len = a + b + c;
            if (p.BendDeductionPer90D is double k) len -= 2 * k * dia; else remarks.Add("bend deduction not applied");
            return Row(mark, member, dia, "21", qty, len, null, remarks);
        }

        /// <summary>
        /// Closed rectangular stirrup (shape 51) for a section b x h.
        /// Inner dims = b - 2c, h - 2c; L = 2(A+B) + hook allowance - 3 bend deductions (4 corners, one is the hook).
        /// </summary>
        public static BbsRow Stirrup(string mark, string member, int dia, double b, double h, double memberLength, double spacing, BbsParameters p, int legs = 2)
        {
            var remarks = new List<string>();
            double A = b, B = h;
            if (p.ClearCover is double c) { A -= 2 * c; B -= 2 * c; } else remarks.Add("cover not deducted");
            if (A <= 0 || B <= 0) throw new ArgumentException("Stirrup dimensions become non-positive after cover deduction.");
            double len = 2 * (A + B);
            if (p.StirrupHookAllowanceD is double hk) len += hk * dia; else remarks.Add("hook allowance not added");
            if (p.BendDeductionPer90D is double k) len -= 3 * k * dia;
            int qty = RebarNotation.BarsForSpacing(memberLength, spacing);
            if (legs > 2) { qty *= legs / 2; remarks.Add($"{legs}-legged (as {legs / 2} closed links)"); }
            return Row(mark, member, dia, "51", qty, len, spacing, remarks);
        }

        /// <summary>Slab/footing mesh direction: bars at spacing across 'width', each spanning 'length'.</summary>
        public static BbsRow Mesh(string mark, string member, int dia, double length, double width, double spacing, BbsParameters p)
        {
            double dist = width - 2 * (p.ClearCover ?? 0);
            int qty = RebarNotation.BarsForSpacing(dist, spacing);
            return Straight(mark, member, dia, qty, length, p, spacing);
        }

        static double Laps(double len, int dia, BbsParameters p, List<string> remarks)
        {
            if (len <= p.StockLength) return 0;
            int laps = (int)Math.Ceiling(len / p.StockLength) - 1;
            if (p.LapLengthD is double ld) { remarks.Add($"{laps} lap(s) @ {ld}d"); return laps * ld * dia; }
            remarks.Add($"{laps} lap(s) required - lap length NOT added (enter LapLengthD)");
            return 0;
        }

        static BbsRow Row(string mark, string member, int dia, string shape, int qty, double len, double? spacing, List<string> remarks)
        {
            if (Array.IndexOf(RebarNotation.StandardDiameters, dia) < 0) throw new ArgumentException($"Unsupported diameter T{dia}");
            if (qty < 0) throw new ArgumentException("Quantity cannot be negative");
            if (len <= 0) throw new ArgumentException($"Bar {mark}: computed length {len:0} mm is not positive");
            return new BbsRow
            {
                BarMark = mark, Member = member, BarDiameter = dia, ShapeCode = shape, Quantity = qty,
                Length = Math.Round(len, 0), Spacing = spacing, Remarks = string.Join("; ", remarks),
            };
        }

        public static IEnumerable<(int Diameter, double TotalLengthM, double WeightKg)> SummaryByDiameter(IEnumerable<BbsRow> rows) =>
            rows.GroupBy(r => r.BarDiameter).OrderBy(g => g.Key)
                .Select(g => (g.Key, Math.Round(g.Sum(r => r.TotalLength) / 1000.0, 3), Math.Round(g.Sum(r => r.TotalWeight), 3)));
    }
}
