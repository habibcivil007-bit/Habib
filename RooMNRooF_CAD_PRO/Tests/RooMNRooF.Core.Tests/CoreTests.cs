using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using RooMNRooF.Core.Boq;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Export;
using RooMNRooF.Core.Geometry;
using RooMNRooF.Core.QA;
using RooMNRooF.Core.Rebar;
using RooMNRooF.Core.Schedules;
using RooMNRooF.Core.Units;
using Xunit;

namespace RooMNRooF.Core.Tests
{
    public class StandardsTests
    {
        static StandardsRepository Repo() =>
            new StandardsRepository(Path.Combine(AppContext.BaseDirectory, "Standards"), Path.Combine(Path.GetTempPath(), "rnr-none")).Load();

        [Fact] public void StandardsValidate() => Assert.Empty(Repo().Validate());
        [Fact] public void HasAtLeast50Members() => Assert.True(Repo().Members.Members.Count >= 50);
        [Fact] public void HasAbout100Colors() => Assert.InRange(Repo().Colors.Colors.Count, 90, 130);
        [Fact] public void RequiredLayersExist()
        {
            var r = Repo();
            foreach (var n in new[] { "A-WALL", "S-GRID", "S-COL", "S-BEAM", "S-REBAR-TEXT", "C-BOUNDARY", "P-WATER", "E-PANEL", "ANNO-TITLE", "XREF-MEP" })
                Assert.NotNull(r.Layer(n));
        }
        [Fact] public void RccFilterContainsColumnsNotWalls()
        {
            var names = Repo().LayersInFilter("RCC").Select(l => l.Name).ToList();
            Assert.Contains("S-COL", names);
            Assert.DoesNotContain("A-WALL", names);
        }
        [Fact] public void ProposedFilterExcludesExisting()
        {
            var names = Repo().LayersInFilter("PROPOSED").Select(l => l.Name).ToList();
            Assert.DoesNotContain("A-WALL-EXST", names);
            Assert.Contains("A-WALL", names);
        }
    }

    public class UnitTests
    {
        [Fact] public void InchIsExact() => Assert.Equal(25.4m, UnitConverter.Convert(1m, LengthUnit.Inch, LengthUnit.Millimeter));
        [Fact] public void FootToMeter() => Assert.Equal(0.3048m, UnitConverter.Convert(1m, LengthUnit.Foot, LengthUnit.Meter));
        [Fact] public void AreaConversion() => Assert.Equal(1_000_000m, UnitConverter.ConvertArea(1m, LengthUnit.Meter, LengthUnit.Millimeter));
        [Theory]
        [InlineData(3048, "10'-0\"")]
        [InlineData(1000, "3'-3 3/8\"")]
        [InlineData(0, "0'-0\"")]
        public void FeetInchesFormat(double mm, string expected) => Assert.Equal(expected, UnitConverter.ToFeetInches((decimal)mm));
        [Fact] public void FeetInchesParse() => Assert.Equal(3200.4m, UnitConverter.ParseFeetInches("10'-6\""));
        [Fact] public void FeetInchesParseFraction() => Assert.Equal(12.7m, UnitConverter.ParseFeetInches("1/2\"".Insert(0, "0 ")));
        [Fact] public void InsUnits() => Assert.Equal(4, UnitConverter.ToInsUnits(LengthUnit.Millimeter));
    }

    public class RebarTests
    {
        [Fact] public void ParseCount() { var c = RebarNotation.Parse("4T16"); Assert.Equal(4, c.Count); Assert.Equal(16, c.Diameter); }
        [Fact] public void ParseSpacing() { var c = RebarNotation.Parse("T10 @ 150 c/c"); Assert.Equal(150, c.Spacing); Assert.Equal("T10 @ 150 c/c", c.ToString()); }
        [Fact] public void ParseLegs() => Assert.Equal(4, RebarNotation.Parse("4L-T8@100").Legs);
        [Fact] public void RejectBadDia() => Assert.False(RebarNotation.TryParse("4T14", out _, out _));
        [Fact] public void BarsForSpacing() => Assert.Equal(11, RebarNotation.BarsForSpacing(1500, 150));
        [Fact] public void UnitWeightT16() => Assert.Equal(1.578, RebarNotation.UnitWeight(16));
        [Fact] public void StraightNoCoverFlagsRemark()
        {
            var r = BbsCalculator.Straight("B1", "B1", 16, 3, 5000, new BbsParameters());
            Assert.Equal(5000, r.Length); Assert.Contains("cover not deducted", r.Remarks);
        }
        [Fact] public void StirrupLength()
        {
            var p = new BbsParameters { ClearCover = 25, StirrupHookAllowanceD = 20, BendDeductionPer90D = 2 };
            var r = BbsCalculator.Stirrup("S1", "B1", 8, 250, 450, 5000, 150, p);
            // inner 200x400 -> 1200 + 160 - 48 = 1312
            Assert.Equal(1312, r.Length); Assert.Equal(34, r.Quantity);
        }
        [Fact] public void LapNotAddedWithoutInput()
        {
            var r = BbsCalculator.Straight("M1", "RAFT", 20, 1, 20000, new BbsParameters { ClearCover = 50 });
            Assert.Contains("NOT added", r.Remarks); Assert.Equal(19900, r.Length);
        }
        [Fact] public void TotalWeight()
        {
            var r = new BbsRow { BarDiameter = 16, Quantity = 10, Length = 1000 };
            Assert.Equal(15.78, r.TotalWeight);
        }
    }

    public class ScheduleTests
    {
        [Fact] public void MemberRoundTrip()
        {
            var m = new DraftedMember { Code = "COL", Mark = "C;1=x", Schedule = "COLUMN", ConcreteGrade = "C25" };
            m.Dims["Width"] = 300; m.Rebar["MainBars"] = "4T16";
            var back = DraftedMember.Deserialize(m.Serialize());
            Assert.Equal("C;1=x", back.Mark); Assert.Equal(300, back.Dim("Width")); Assert.Equal("4T16", back.Rebar["MainBars"]);
        }
        [Fact] public void ColumnScheduleGroupsAndSorts()
        {
            var list = new List<DraftedMember>();
            foreach (var mark in new[] { "C10", "C2", "C1", "C2" })
            {
                var m = new DraftedMember { Mark = mark, Schedule = "COLUMN", ConcreteGrade = "C25" };
                m.Dims["Width"] = 300; m.Dims["Depth"] = 300; m.Rebar["MainBars"] = "4T16"; m.Rebar["TieDia"] = "8"; m.Rebar["TieSpacing"] = "150";
                list.Add(m);
            }
            var t = ScheduleBuilder.Build("COLUMN", list);
            Assert.Equal(new[] { "C1", "C2", "C10" }, t.Rows.Select(r => r[0]));
            Assert.Equal("2", t.Rows[1][5]); Assert.Equal("T8 @ 150", t.Rows[0][3]); Assert.Equal("300x300", t.Rows[0][1]);
        }
        [Fact] public void ColumnVolume()
        {
            var m = new DraftedMember { Schedule = "COLUMN" }; m.Dims["Width"] = 300; m.Dims["Depth"] = 300; m.Dims["Height"] = 3000;
            Assert.Equal(0.27, m.ConcreteVolumeM3());
        }
    }

    public class GeometryTests
    {
        [Fact] public void LShapeArea() => Assert.Equal(600 * 250 + 350 * 250, Math.Abs(MemberGeometry.ShoelaceArea(MemberGeometry.LPoints(600, 600, 250))), 6);
        [Fact] public void CrossArea() => Assert.Equal(750 * 250 * 2 - 250 * 250, Math.Abs(MemberGeometry.ShoelaceArea(MemberGeometry.XPoints(750, 750, 250))), 6);
        [Fact] public void GridLabelsSkipIO() { Assert.Equal("H", GridGeometry.LetterLabel(7)); Assert.Equal("J", GridGeometry.LetterLabel(8)); Assert.Equal("AA", GridGeometry.LetterLabel(24)); }
        [Fact] public void GridBuild()
        {
            var g = GridGeometry.Build(GridGeometry.ParseSpacings("3*5000"), GridGeometry.ParseSpacings("4000,4500"), 1000);
            Assert.Equal(4 + 3, g.Count); Assert.Equal(15000, g.Where(l => l.Vertical).Max(l => l.Ordinate));
        }
        [Fact] public void AllMembersBuild()
        {
            var repo = new StandardsRepository(Path.Combine(AppContext.BaseDirectory, "Standards"), Path.GetTempPath() + "none").Load();
            foreach (var m in repo.Members.Members)
            {
                var s = MemberGeometry.Build(m, new Dictionary<string, double>());
                Assert.True(s.Paths.Count + s.Circles.Count > 0, m.Code);
            }
        }
        [Fact] public void RejectsBadThickness() => Assert.Throws<ArgumentException>(() => MemberGeometry.LPoints(300, 300, 300));
    }

    public class ExportTests
    {
        [Fact] public void CsvEscapes()
        {
            var s = new DataSheet { Headers = { "A", "B" }, Rows = { new object?[] { "x,y", 1.5 } } };
            Assert.Contains("\"x,y\",1.5", CsvExporter.ToCsv(s));
        }
        [Fact] public void XlsxIsValidZip()
        {
            var path = Path.Combine(Path.GetTempPath(), $"rnr_{Guid.NewGuid():N}.xlsx");
            XlsxExporter.Write(path, new DataSheet { Name = "BBS", Headers = { "Mark", "Qty" }, Rows = { new object?[] { "B1", 4 } } });
            using var z = ZipFile.OpenRead(path);
            Assert.NotNull(z.GetEntry("xl/worksheets/sheet1.xml"));
            File.Delete(path);
        }
        [Fact] public void ColName() { Assert.Equal("A", XlsxExporter.ColName(0)); Assert.Equal("AA", XlsxExporter.ColName(26)); }
    }

    public class QaAndBoqTests
    {
        [Fact] public void UncheckedIsNotPass()
        {
            var r = new QaReport();
            Assert.Equal(QaStatus.NOT_CHECKED, r.StatusOf("Layers"));
            r.MarkChecked("Layers");
            Assert.Equal(QaStatus.PASS, r.StatusOf("Layers"));
            r.Add("Layers", QaStatus.WARNING, "x");
            Assert.Equal(QaStatus.WARNING, r.StatusOf("Layers"));
        }
        [Fact] public void BoqConcrete()
        {
            var inp = new BoqInput();
            var m = new DraftedMember { Schedule = "BEAM" }; m.Dims["Width"] = 250; m.Dims["Depth"] = 500; m.Dims["Length"] = 4000;
            inp.Members.Add(m);
            var lines = BoqCalculator.Compute(inp);
            var l = lines.Single(x => x.Item == "RCC-BEAM");
            Assert.Equal(0.5, l.Quantity); Assert.Equal("CBM", l.Unit);
        }
    }
}
