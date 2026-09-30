using System;
using System.Collections.Generic;
using System.Linq;
using RooMNRooF.Core.Rebar;
using RooMNRooF.Core.Schedules;
using RooMNRooF.Core.Units;

namespace RooMNRooF.Core.Boq
{
    public sealed class BoqLine
    {
        public string Item { get; set; } = "";
        public string Description { get; set; } = "";
        public double Quantity { get; set; }
        public string Unit { get; set; } = "";
        public double AltQuantity { get; set; }
        public string AltUnit { get; set; } = "";
        public string Source { get; set; } = "CAD-derived estimate";
    }

    /// <summary>Raw measurements collected from the drawing by the plugin (all mm / mm2).</summary>
    public sealed class BoqInput
    {
        public List<DraftedMember> Members { get; } = new();
        public List<BbsRow> Bars { get; } = new();
        /// <summary>Wall centre-line length (mm) with thickness (mm) and height (mm).</summary>
        public List<(double LengthMm, double ThicknessMm, double HeightMm)> Walls { get; } = new();
        public List<double> FloorAreasMm2 { get; } = new();
        public List<double> OpeningAreasMm2 { get; } = new();
        public int DoorCount { get; set; }
        public int WindowCount { get; set; }
    }

    public static class BoqCalculator
    {
        public const string Disclaimer = "ALL QUANTITIES ARE CAD-DERIVED ESTIMATES FROM DRAFTED GEOMETRY/METADATA. VERIFY BEFORE PROCUREMENT OR BILLING.";

        public static List<BoqLine> Compute(BoqInput input)
        {
            var lines = new List<BoqLine>();

            foreach (var g in input.Members.Where(m => m.ConcreteVolumeM3() != null).GroupBy(m => m.Schedule).OrderBy(g => g.Key))
            {
                var cbm = g.Sum(m => m.ConcreteVolumeM3()!.Value);
                lines.Add(new BoqLine
                {
                    Item = "RCC-" + g.Key, Description = $"RCC concrete in {g.Key.ToLowerInvariant()}s ({g.Count()} nos)",
                    Quantity = Math.Round(cbm, 3), Unit = "CBM",
                    AltQuantity = Math.Round(cbm * (double)UnitConverter.CftPerCbm, 2), AltUnit = "CFT",
                });
            }
            var unmeasured = input.Members.Count(m => m.ConcreteVolumeM3() == null && m.Schedule != "NONE");
            if (unmeasured > 0)
                lines.Add(new BoqLine { Item = "NOTE", Description = $"{unmeasured} member(s) lacked dimensions for volume - excluded", Unit = "-" });

            foreach (var s in BbsCalculator.SummaryByDiameter(input.Bars))
            {
                lines.Add(new BoqLine
                {
                    Item = $"REBAR-T{s.Diameter}", Description = $"Reinforcement T{s.Diameter}",
                    Quantity = s.WeightKg, Unit = "KG", AltQuantity = Math.Round(s.WeightKg / 1000.0, 4), AltUnit = "TON",
                });
                lines.Add(new BoqLine
                {
                    Item = $"REBAR-T{s.Diameter}-L", Description = $"Reinforcement T{s.Diameter} length",
                    Quantity = s.TotalLengthM, Unit = "M", AltQuantity = Math.Round(s.TotalLengthM * (double)UnitConverter.RftPerM, 2), AltUnit = "RFT",
                });
            }

            if (input.Walls.Count > 0)
            {
                double faceArea = input.Walls.Sum(w => w.LengthMm * w.HeightMm) / 1e6;
                double openings = input.OpeningAreasMm2.Sum() / 1e6;
                double net = Math.Max(0, faceArea - openings);
                double vol = input.Walls.Sum(w => w.LengthMm * w.HeightMm * w.ThicknessMm) / 1e9;
                lines.Add(Area("WALL-AREA", "Wall face area (one side, net of openings)", net));
                lines.Add(new BoqLine { Item = "WALL-VOL", Description = "Wall volume (gross)", Quantity = Math.Round(vol, 3), Unit = "CBM",
                    AltQuantity = Math.Round(vol * (double)UnitConverter.CftPerCbm, 2), AltUnit = "CFT" });
            }
            if (input.FloorAreasMm2.Count > 0) lines.Add(Area("FLOOR-AREA", "Floor area (room polylines)", input.FloorAreasMm2.Sum() / 1e6));
            if (input.OpeningAreasMm2.Count > 0) lines.Add(Area("OPENING-AREA", "Opening area", input.OpeningAreasMm2.Sum() / 1e6));
            lines.Add(new BoqLine { Item = "DOOR", Description = "Doors", Quantity = input.DoorCount, Unit = "NOS" });
            lines.Add(new BoqLine { Item = "WINDOW", Description = "Windows", Quantity = input.WindowCount, Unit = "NOS" });
            return lines;
        }

        static BoqLine Area(string item, string desc, double sqm) => new()
        {
            Item = item, Description = desc, Quantity = Math.Round(sqm, 3), Unit = "SQM",
            AltQuantity = Math.Round(sqm * (double)UnitConverter.SftPerSqm, 2), AltUnit = "SFT",
        };
    }
}
