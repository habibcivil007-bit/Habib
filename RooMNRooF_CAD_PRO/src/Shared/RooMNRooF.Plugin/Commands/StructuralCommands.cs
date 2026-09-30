using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Geometry;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;

[assembly: CommandClass(typeof(RooMNRooF.Plugin.Commands.StructuralCommands))]

namespace RooMNRooF.Plugin.Commands
{
    /// <summary>RCC structural drafting commands (grid + 55 member definitions).</summary>
    public class StructuralCommands
    {
        // ------------------------------------------------------------------ grid
        [CommandMethod("RNR", "RNRGRID", CommandFlags.Modal)]
        public void Grid() => Rnr.Run("RNRGRID", (doc, tr) =>
        {
            var ed = doc.Editor;
            var xs = GridGeometry.ParseSpacings(Prompts.Text(ed, "X-direction spacings (e.g. 3*5000 or 4500,5000,4500)", "3*5000"));
            var ys = GridGeometry.ParseSpacings(Prompts.Text(ed, "Y-direction spacings", "2*4500"));
            var naming = Prompts.Keyword(ed, "Naming [NumbersOnX/LettersOnX]", "NumbersOnX", "NumbersOnX", "LettersOnX");
            var bubbles = Prompts.Keyword(ed, "Bubbles [Both/Start/End]", "Both", "Both", "Start", "End");
            double ext = Prompts.Double(ed, "Grid extension beyond last line (mm)", 1500);
            double bubblePaper = Prompts.Double(ed, "Bubble diameter on paper (mm)", 10);
            var origin = Prompts.Point(ed, "Grid origin (intersection 1/A):");
            var lines = GridGeometry.Build(xs, ys, ext, naming == "LettersOnX");

            var d = new DrawService(doc.Database, tr);
            double scale = bubblePaper / 10.0 * d.TextScale;   // RNR_GRIDBUBBLE is 10 mm diameter in paper units
            double r = 5 * scale;
            var o = new Vector3d(origin.X, origin.Y, 0);
            foreach (var g in lines)
            {
                var a = DrawService.P3(g.Start) + o; var b = DrawService.P3(g.End) + o;
                d.Line(a, b, "S-GRID");
                var dir = (b - a).GetNormal();
                if (bubbles is "Both" or "Start") BlockFactory.Insert(d, "RNR_GRIDBUBBLE", a - dir * r, scale, 0, "ANNO-GRID", new Dictionary<string, string> { ["GRID"] = g.Label });
                if (bubbles is "Both" or "End") BlockFactory.Insert(d, "RNR_GRIDBUBBLE", b + dir * r, scale, 0, "ANNO-GRID", new Dictionary<string, string> { ["GRID"] = g.Label });
            }
            // overall + intermediate grid dimensions
            var vert = lines.Where(l => l.Vertical).ToList(); var hor = lines.Where(l => !l.Vertical).ToList();
            double dimY = origin.Y - ext - 3 * r; double dimX = origin.X - ext - 3 * r;
            for (int i = 0; i + 1 < vert.Count; i++)
                d.DimRotated(new Point3d(origin.X + vert[i].Ordinate, origin.Y, 0), new Point3d(origin.X + vert[i + 1].Ordinate, origin.Y, 0), new Point3d(origin.X, dimY, 0), 0, "S-DIMS");
            d.DimRotated(new Point3d(origin.X, origin.Y, 0), new Point3d(origin.X + vert[^1].Ordinate, origin.Y, 0), new Point3d(origin.X, dimY - 8 * d.TextScale, 0), 0, "S-DIMS");
            for (int i = 0; i + 1 < hor.Count; i++)
                d.DimRotated(new Point3d(origin.X, origin.Y + hor[i].Ordinate, 0), new Point3d(origin.X, origin.Y + hor[i + 1].Ordinate, 0), new Point3d(dimX, origin.Y, 0), Math.PI / 2, "S-DIMS");
            d.DimRotated(new Point3d(origin.X, origin.Y, 0), new Point3d(origin.X, origin.Y + hor[^1].Ordinate, 0), new Point3d(dimX - 8 * d.TextScale, origin.Y, 0), Math.PI / 2, "S-DIMS");
            Rnr.Msg($"Grid created: {vert.Count} x {hor.Count} lines.");
            Rnr.Done();
        });

        // ------------------------------------------------------------------ columns
        [CommandMethod("RNR", "RNRCOLUMN", CommandFlags.Modal)]
        public void Column() => Rnr.Run("RNRCOLUMN", (doc, tr) =>
        {
            var ed = doc.Editor;
            var t = Prompts.Keyword(ed, "Column type [Rectangular/Square/Circular/L/T/Cross/Custom/Pedestal/Starter]", "Rectangular",
                "Rectangular", "Square", "Circular", "L", "T", "Cross", "Custom", "Pedestal", "Starter");
            string code = t switch
            {
                "Rectangular" => "COL-RECT", "Square" => "COL-SQ", "Circular" => "COL-CIRC", "L" => "COL-L", "T" => "COL-T",
                "Cross" => "COL-X", "Pedestal" => "PED", "Starter" => "STARTER", _ => "COL",
            };
            var def = MemberService.Def(code);
            Dictionary<string, double>? fixedDims = null;
            if (t == "Square")
            {
                double s = Prompts.Double(ed, "Side (mm)", def.Param("Width"));
                fixedDims = new() { ["Width"] = s, ["Depth"] = s };
            }
            if (t == "Custom")
            {
                Rnr.Msg("Custom column: enter any rectangular size; for other shapes use RNRMEMBER.");
            }
            int n = MemberService.PlaceRepeated(doc, tr, def, fixedDims);
            Rnr.Msg($"{n} column(s) placed on {def.Layer}.");
        });

        // ------------------------------------------------------------------ beams (pick start/end)
        [CommandMethod("RNR", "RNRBEAM", CommandFlags.Modal)]
        public void Beam() => Rnr.Run("RNRBEAM", (doc, tr) =>
        {
            var ed = doc.Editor;
            var t = Prompts.Keyword(ed, "Beam type [Beam/Primary/Secondary/Edge/Hidden/Tie/Plinth/Roof/Ground/Grade/FoundationTie/Corbel]", "Beam",
                "Beam", "Primary", "Secondary", "Edge", "Hidden", "Tie", "Plinth", "Roof", "Ground", "Grade", "FoundationTie", "Corbel");
            string code = t switch
            {
                "Primary" => "BM-PRI", "Secondary" => "BM-SEC", "Edge" => "BM-EDGE", "Hidden" => "BM-HID", "Tie" => "BM-TIE",
                "Plinth" => "BM-PLINTH", "Roof" => "BM-ROOF", "Ground" => "GB", "Grade" => "GRB", "FoundationTie" => "FTIE", "Corbel" => "CORBEL", _ => "BM",
            };
            var def = MemberService.Def(code);
            if (code == "CORBEL") { int c = MemberService.PlaceRepeated(doc, tr, def); Rnr.Msg($"{c} corbel(s) placed."); return; }
            var m = MemberService.Ask(ed, def, new Dictionary<string, double> { ["Length"] = 1 });
            var d = new DrawService(doc.Database, tr);
            int n = 0;
            while (true)
            {
                var a = Prompts.PointOrNone(ed, $"Beam {m.Mark} start point <done>:");
                if (a == null) break;
                var b = Prompts.Point(ed, "End point:", a.Value);
                var len = a.Value.DistanceTo(b);
                if (len < 1) throw new RnrInputException("Beam length must be > 1 mm.");
                m.Dims["Length"] = Math.Round(len, 1);
                var rot = Math.Atan2(b.Y - a.Value.Y, b.X - a.Value.X);
                MemberService.Draw(d, def, m, a.Value, rot);
                n++;
                doc.TransactionManager.QueueForGraphicsFlush(); doc.TransactionManager.FlushGraphics();
            }
            Rnr.Msg($"{n} beam(s) placed on {def.Layer}.");
        });

        // ------------------------------------------------------------------ slabs (pick corners)
        [CommandMethod("RNR", "RNRSLAB", CommandFlags.Modal)]
        public void Slab() => Rnr.Run("RNRSLAB", (doc, tr) =>
        {
            var ed = doc.Editor;
            var t = Prompts.Keyword(ed, "Slab type [Slab/Flat/Ribbed/DropPanel/Cantilever/Roof/Canopy/Landing/Waist/Plinth/Opening]", "Slab",
                "Slab", "Flat", "Ribbed", "DropPanel", "Cantilever", "Roof", "Canopy", "Landing", "Waist", "Plinth", "Opening");
            string code = t switch
            {
                "Flat" => "SLB-FLAT", "Ribbed" => "SLB-RIB", "DropPanel" => "DROP", "Cantilever" => "SLB-CANT", "Roof" => "SLB-ROOF",
                "Canopy" => "CANOPY", "Landing" => "LAND", "Waist" => "WAIST", "Plinth" => "PLINTH", "Opening" => "OPEN", _ => "SLB",
            };
            PlaceByCorners(doc, tr, MemberService.Def(code));
        });

        static void PlaceByCorners(Autodesk.AutoCAD.ApplicationServices.Document doc, Transaction tr, RooMNRooF.Core.Models.MemberDef def)
        {
            var ed = doc.Editor;
            var m = MemberService.Ask(ed, def, new Dictionary<string, double> { ["Length"] = 1, ["Width"] = 1 });
            var d = new DrawService(doc.Database, tr);
            int n = 0;
            while (true)
            {
                var a = Prompts.PointOrNone(ed, $"{def.Name} {m.Mark} first corner <done>:");
                if (a == null) break;
                var b = Prompts.Corner(ed, "Opposite corner:", a.Value);
                double l = Math.Abs(b.X - a.Value.X), w = Math.Abs(b.Y - a.Value.Y);
                if (l < 1 || w < 1) throw new RnrInputException("Corners must define a non-zero rectangle.");
                m.Dims["Length"] = Math.Round(l, 1); m.Dims["Width"] = Math.Round(w, 1);
                var c = new Point3d((a.Value.X + b.X) / 2, (a.Value.Y + b.Y) / 2, 0);
                MemberService.Draw(d, def, m, c, 0, dims: true, hatch: def.Schedule != "SLAB");
                n++;
                doc.TransactionManager.QueueForGraphicsFlush(); doc.TransactionManager.FlushGraphics();
            }
            Rnr.Msg($"{n} {def.Name.ToLowerInvariant()}(s) placed on {def.Layer}.");
        }

        // ------------------------------------------------------------------ foundations
        [CommandMethod("RNR", "RNRFOOTING", CommandFlags.Modal)]
        public void Footing() => Rnr.Run("RNRFOOTING", (doc, tr) =>
        {
            var t = Prompts.Keyword(doc.Editor, "Footing type [Isolated/Combined/Strap/Strip/Wall]", "Isolated", "Isolated", "Combined", "Strap", "Strip", "Wall");
            string code = t switch { "Combined" => "FTG-COMB", "Strap" => "FTG-STRAP", "Strip" => "FTG-STRIP", "Wall" => "FTG-WALL", _ => "FTG-ISO" };
            int n = MemberService.PlaceRepeated(doc, tr, MemberService.Def(code));
            Rnr.Msg($"{n} footing(s) placed.");
        });

        [CommandMethod("RNR", "RNRRAFT", CommandFlags.Modal)]
        public void Raft() => Rnr.Run("RNRRAFT", (doc, tr) => PlaceByCorners(doc, tr, MemberService.Def("RAFT")));

        [CommandMethod("RNR", "RNRPILE", CommandFlags.Modal)]
        public void Pile() => Rnr.Run("RNRPILE", (doc, tr) => Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, MemberService.Def("PILE"))} pile(s) placed."));

        [CommandMethod("RNR", "RNRPILECAP", CommandFlags.Modal)]
        public void PileCap() => Rnr.Run("RNRPILECAP", (doc, tr) => Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, MemberService.Def("PCAP"))} pile cap(s) placed."));

        // ------------------------------------------------------------------ walls (structural) - pick start/end
        [CommandMethod("RNR", "RNRSWALL", CommandFlags.Modal)]
        public void StructuralWall() => Rnr.Run("RNRSWALL", (doc, tr) =>
        {
            var ed = doc.Editor;
            var t = Prompts.Keyword(ed, "Wall type [Shear/Retaining/Boundary/Parapet/LiftCore/ExpansionJoint/ConstructionJoint]", "Shear",
                "Shear", "Retaining", "Boundary", "Parapet", "LiftCore", "ExpansionJoint", "ConstructionJoint");
            string code = t switch { "Retaining" => "RW", "Boundary" => "BWALL", "Parapet" => "PARAPET", "LiftCore" => "CORE", "ExpansionJoint" => "EJ", "ConstructionJoint" => "CJ", _ => "SW" };
            var def = MemberService.Def(code);
            if (code == "CORE") { Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, def)} core(s) placed."); return; }
            var m = MemberService.Ask(ed, def, new Dictionary<string, double> { ["Length"] = 1 });
            var d = new DrawService(doc.Database, tr);
            int n = 0;
            while (true)
            {
                var a = Prompts.PointOrNone(ed, $"{def.Name} start point <done>:");
                if (a == null) break;
                var b = Prompts.Point(ed, "End point:", a.Value);
                var len = a.Value.DistanceTo(b);
                if (len < 1) throw new RnrInputException("Length must be > 1 mm.");
                m.Dims["Length"] = Math.Round(len, 1);
                MemberService.Draw(d, def, m, a.Value, Math.Atan2(b.Y - a.Value.Y, b.X - a.Value.X));
                n++;
            }
            Rnr.Msg($"{n} {def.Name.ToLowerInvariant()}(s) placed.");
        });

        // ------------------------------------------------------------------ stairs / ramps / roof / tanks
        [CommandMethod("RNR", "RNRSTAIR", CommandFlags.Modal)]
        public void Stair() => Rnr.Run("RNRSTAIR", (doc, tr) =>
        {
            var ed = doc.Editor;
            var disc = Prompts.Keyword(ed, "Stair [Structural/Architectural]", "Structural", "Structural", "Architectural");
            var t = Prompts.Keyword(ed, "Type [DogLeg/Straight]", "DogLeg", "DogLeg", "Straight");
            var def = MemberService.Def(t == "DogLeg" ? "STR-DOG" : "STR-STRT");
            if (disc == "Architectural")
            {
                // architectural stair: same geometry on A-STAIR without RCC metadata/hatch
                var m = MemberService.Ask(ed, def, askRebar: false);
                var p = Prompts.Point(ed, "Stair start corner:");
                var d = new DrawService(doc.Database, tr);
                var s = MemberGeometry.Build(def, m.Dims).Transform(new Pt(p.X, p.Y), Prompts.Angle(ed, "Rotation <0>:", p, 0));
                d.Shape(s, "A-STAIR", "A-STAIR", out _);
                d.Text(DrawService.P3(s.TagPoint), $"STAIR  {m.Dim("Steps"):0} R @ {m.Dim("Riser"):0} / T {m.Dim("Going"):0}", 2.5, "A-TEXT");
                Rnr.Done();
                return;
            }
            Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, def)} stair(s) placed.");
        });

        [CommandMethod("RNR", "RNRRAMP", CommandFlags.Modal)]
        public void Ramp() => Rnr.Run("RNRRAMP", (doc, tr) =>
        {
            var m = MemberService.Def("RMP");
            int n = MemberService.PlaceRepeated(doc, tr, m);
            Rnr.Msg($"{n} ramp(s) placed. Slope is shown in the member data (RiseTotal/Length).");
        });

        [CommandMethod("RNR", "RNRROOF", CommandFlags.Modal)]
        public void Roof() => Rnr.Run("RNRROOF", (doc, tr) =>
        {
            var t = Prompts.Keyword(doc.Editor, "Roof element [RoofSlab/RoofBeam/Parapet/RoofTank/Outline]", "RoofSlab", "RoofSlab", "RoofBeam", "Parapet", "RoofTank", "Outline");
            switch (t)
            {
                case "RoofSlab": PlaceByCorners(doc, tr, MemberService.Def("SLB-ROOF")); break;
                case "RoofTank": Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, MemberService.Def("TANK-ROOF"))} tank(s) placed."); break;
                case "Outline": ArchitectureCommands.RoofOutline(doc, tr); break;
                default: Rnr.Msg($"Use {(t == "RoofBeam" ? "RNRBEAM > Roof" : "RNRSWALL > Parapet")} for this element."); break;
            }
        });

        [CommandMethod("RNR", "RNRTANK", CommandFlags.Modal)]
        public void Tank() => Rnr.Run("RNRTANK", (doc, tr) =>
        {
            var t = Prompts.Keyword(doc.Editor, "Tank [Water/Underground/Roof]", "Water", "Water", "Underground", "Roof");
            Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, MemberService.Def(t switch { "Underground" => "TANK-UG", "Roof" => "TANK-ROOF", _ => "TANK" }))} tank(s) placed.");
        });

        /// <summary>Any of the 55 definitions by number or code.</summary>
        [CommandMethod("RNR", "RNRMEMBER", CommandFlags.Modal)]
        public void Member() => Rnr.Run("RNRMEMBER", (doc, tr) =>
        {
            var ed = doc.Editor;
            foreach (var m in Rnr.Repo.Members.Members) ed.WriteMessage($"\n  {m.No:00} {m.Code,-10} {m.Name,-22} [{m.Shape}] -> {m.Layer}");
            var key = Prompts.Text(ed, "Member number or code", "1", false);
            var def = MemberService.Def(key);
            Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, def)} {def.Name}(s) placed.");
        });

        [CommandMethod("RNR", "RNRJOINT", CommandFlags.Modal)]
        public void BeamColumnJoint() => Rnr.Run("RNRJOINT", (doc, tr) =>
            Rnr.Msg($"{MemberService.PlaceRepeated(doc, tr, MemberService.Def("BCJ"))} joint marker(s) placed."));
    }
}
