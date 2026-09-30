using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Geometry;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;

[assembly: CommandClass(typeof(RooMNRooF.Plugin.Commands.ArchitectureCommands))]

namespace RooMNRooF.Plugin.Commands
{
    /// <summary>2D architectural drafting: walls, doors, windows, rooms, furniture, ceiling, floor, roof outline.</summary>
    public class ArchitectureCommands
    {
        static double _wallThk = 250;

        [CommandMethod("RNR", "RNRWALL", CommandFlags.Modal)]
        public void Wall() => Rnr.Run("RNRWALL", (doc, tr) =>
        {
            var ed = doc.Editor;
            var status = Prompts.Keyword(ed, "Wall status [New/Existing/Demolish]", "New", "New", "Existing", "Demolish");
            string layer = status switch { "Existing" => "A-WALL-EXST", "Demolish" => "A-WALL-DEMO", _ => "A-WALL" };
            _wallThk = Prompts.Double(ed, "Wall thickness (mm) [125/250/...]", _wallThk);
            var just = Prompts.Keyword(ed, "Justification [Center/Left/Right]", "Center", "Center", "Left", "Right");
            bool hatch = status == "New" && Prompts.YesNo(ed, "Hatch walls (brick)?", true);
            var d = new DrawService(doc.Database, tr);
            var a = Prompts.Point(ed, "Wall start point:");
            int n = 0;
            while (true)
            {
                var b = Prompts.PointOrNone(ed, "Next point <done>:", a);
                if (b == null) break;
                DrawWallSegment(d, a, b.Value, _wallThk, just, layer, hatch);
                a = b.Value; n++;
                doc.TransactionManager.QueueForGraphicsFlush(); doc.TransactionManager.FlushGraphics();
            }
            Rnr.Msg($"{n} wall segment(s) drawn on {layer}.");
        });

        internal static ObjectId DrawWallSegment(DrawService d, Point3d a, Point3d b, double t, string just, string layer, bool hatch)
        {
            var dir = b - a;
            if (dir.Length < 1) throw new RnrInputException("Wall segment too short.");
            var n = dir.GetNormal().RotateBy(Math.PI / 2, Vector3d.ZAxis);
            double left = just switch { "Left" => t, "Right" => 0, _ => t / 2 };
            double right = t - left;
            var p1 = a + n * left; var p2 = b + n * left; var p3 = b - n * right; var p4 = a - n * right;
            var pl = d.Poly(new[] { new Pt(p1.X, p1.Y), new Pt(p2.X, p2.Y), new Pt(p3.X, p3.Y), new Pt(p4.X, p4.Y) }, true, layer);
            if (hatch)
            {
                var h = Rnr.Repo.Hatch("Brick");
                if (h != null) HatchService.Apply(d, pl.ObjectId, h, "A-HATCH");
            }
            return pl.ObjectId;
        }

        [CommandMethod("RNR", "RNRDOOR", CommandFlags.Modal)]
        public void Door() => Rnr.Run("RNRDOOR", (doc, tr) =>
        {
            var ed = doc.Editor;
            double w = Prompts.Double(ed, "Door width (mm) [750/900/1000/1200]", 900);
            var p = Prompts.Point(ed, "Hinge point (on wall face/centre-line):");
            double ang = Prompts.Angle(ed, "Wall direction (angle along the opening):", p, 0);
            var swing = Prompts.Keyword(ed, "Swing side [Left/Right]", "Left", "Left", "Right");
            var mark = Prompts.Text(ed, "Door mark", "D1", false);
            var d = new DrawService(doc.Database, tr);
            var br = BlockFactory.Insert(d, $"RNR_DOOR_{w:0}", p, 1, ang, "A-DOOR");
            if (swing == "Right") br.ScaleFactors = new Scale3d(1, -1, 1);   // mirror swing
            d.Text(p + new Vector3d(Math.Cos(ang), Math.Sin(ang), 0) * (w / 2) + new Vector3d(-Math.Sin(ang), Math.Cos(ang), 0) * (-4 * d.TextScale), mark, 2.0, "A-TEXT");
            Rnr.Done();
        });

        [CommandMethod("RNR", "RNRWINDOW", CommandFlags.Modal)]
        public void Window() => Rnr.Run("RNRWINDOW", (doc, tr) =>
        {
            var ed = doc.Editor;
            double w = Prompts.Double(ed, "Window width (mm)", 1200);
            double t = Prompts.Double(ed, "Wall thickness (mm)", _wallThk);
            var p = Prompts.Point(ed, "Window start point (wall centre-line):");
            double ang = Prompts.Angle(ed, "Wall direction:", p, 0);
            var mark = Prompts.Text(ed, "Window mark", "W1", false);
            var d = new DrawService(doc.Database, tr);
            BlockFactory.Insert(d, $"RNR_WINDOW_{w:0}x{t:0}", p, 1, ang, "A-WINDOW");
            d.Text(p + new Vector3d(Math.Cos(ang), Math.Sin(ang), 0) * (w / 2) + new Vector3d(-Math.Sin(ang), Math.Cos(ang), 0) * (t / 2 + 4 * d.TextScale), mark, 2.0, "A-TEXT");
            Rnr.Done();
        });

        /// <summary>Room generator: walls, door, window, room boundary, tag with area, dimensions, optional floor finish.</summary>
        [CommandMethod("RNR", "RNRROOM", CommandFlags.Modal)]
        public void Room() => Rnr.Run("RNRROOM", (doc, tr) =>
        {
            var ed = doc.Editor;
            double L = Prompts.Double(ed, "Room internal length (mm)", 4000), W = Prompts.Double(ed, "Room internal width (mm)", 3500);
            double t = Prompts.Double(ed, "Wall thickness (mm)", _wallThk);
            var name = Prompts.Text(ed, "Room name", "BED ROOM");
            bool door = Prompts.YesNo(ed, "Add door (bottom wall)?", true);
            double dw = door ? Prompts.Double(ed, "Door width (mm)", 900) : 0;
            bool win = Prompts.YesNo(ed, "Add window (top wall)?", true);
            double ww = win ? Prompts.Double(ed, "Window width (mm)", 1500) : 0;
            var finish = Prompts.Keyword(ed, "Floor finish [None/Tile/Marble/Wood/Granite]", "Tile", "None", "Tile", "Marble", "Wood", "Granite");
            if (door && dw > L - 200) throw new RnrInputException("Door wider than wall.");
            if (win && ww > L - 200) throw new RnrInputException("Window wider than wall.");
            var o = Prompts.Point(ed, "Internal lower-left corner:");
            var d = new DrawService(doc.Database, tr);

            var inner = new[] { new Pt(o.X, o.Y), new Pt(o.X + L, o.Y), new Pt(o.X + L, o.Y + W), new Pt(o.X, o.Y + W) };
            var outer = new[] { new Pt(o.X - t, o.Y - t), new Pt(o.X + L + t, o.Y - t), new Pt(o.X + L + t, o.Y + W + t), new Pt(o.X - t, o.Y + W + t) };
            var inPl = d.Poly(inner, true, "A-WALL");
            var outPl = d.Poly(outer, true, "A-WALL");
            var brick = Rnr.Repo.Hatch("Brick");
            if (brick != null)
            {
                var h = new Hatch();
                d.Add(h, "A-HATCH");
                h.PatternScale = brick.Scale;
                try { h.SetHatchPattern(brick.Custom ? HatchPatternType.CustomDefined : HatchPatternType.PreDefined, brick.Pattern); }
                catch (Autodesk.AutoCAD.Runtime.Exception) { h.SetHatchPattern(HatchPatternType.PreDefined, "ANSI31"); }
                h.AppendLoop(HatchLoopTypes.Outermost, new ObjectIdCollection { outPl.ObjectId });
                h.AppendLoop(HatchLoopTypes.Default, new ObjectIdCollection { inPl.ObjectId });
                h.Color = DrawService.Rgb(brick.Rgb);
                h.EvaluateHatch(true);
            }
            // room boundary (for area / BOQ) on A-ROOM
            var room = d.Poly(inner, true, "A-ROOM");
            if (finish != "None")
            {
                var f = Rnr.Repo.Hatch(finish);
                if (f != null) HatchService.Apply(d, room.ObjectId, f, "A-FLOR");
            }
            double cx = o.X + L / 2;
            if (door) BlockFactory.Insert(d, $"RNR_DOOR_{dw:0}", new Point3d(cx - dw / 2, o.Y - t / 2, 0), 1, 0, "A-DOOR");
            if (win) BlockFactory.Insert(d, $"RNR_WINDOW_{ww:0}x{t:0}", new Point3d(cx - ww / 2, o.Y + W + t / 2, 0), 1, 0, "A-WINDOW");
            double areaM2 = L * W / 1e6;
            BlockFactory.Insert(d, "RNR_ROOMTAG", new Point3d(cx, o.Y + W / 2, 0), d.TextScale, 0, "A-ROOM",
                new Dictionary<string, string> { ["NAME"] = name.ToUpperInvariant(), ["AREA"] = $"{areaM2:0.00} m² ({areaM2 * 10.7639:0} sft)" });
            d.DimRotated(new Point3d(o.X, o.Y + W, 0), new Point3d(o.X + L, o.Y + W, 0), new Point3d(o.X, o.Y + W + t + 8 * d.TextScale, 0), 0, "A-DIMS", "RNR_ARCH");
            d.DimRotated(new Point3d(o.X + L, o.Y, 0), new Point3d(o.X + L, o.Y + W, 0), new Point3d(o.X + L + t + 8 * d.TextScale, o.Y, 0), Math.PI / 2, "A-DIMS", "RNR_ARCH");
            Rnr.Msg($"Room '{name}' {L:0} x {W:0} mm = {areaM2:0.00} m² created.");
        });

        [CommandMethod("RNR", "RNRFURN", CommandFlags.Modal)]
        public void Furniture() => Rnr.Run("RNRFURN", (doc, tr) =>
        {
            var ed = doc.Editor;
            var blocks = Rnr.Repo.Blocks.Blocks.Where(b => b.Category is "Furniture" or "Kitchen" or "Bathroom" or "Site" or "Landscape" or "Electrical" or "HVAC" or "Vertical transport").ToList();
            for (int i = 0; i < blocks.Count; i++) ed.WriteMessage($"\n  {i + 1,2}. {blocks[i].Name,-22} ({blocks[i].Category})");
            int sel = Prompts.Int(ed, "Block number", 1, 1, blocks.Count);
            var def = blocks[sel - 1];
            var d = new DrawService(doc.Database, tr);
            int n = 0;
            while (true)
            {
                var p = Prompts.PointOrNone(ed, $"Insertion point for {def.Name} <done>:");
                if (p == null) break;
                var rot = Prompts.Angle(ed, "Rotation <0>:", p.Value, 0);
                BlockFactory.Insert(d, def.Name, p.Value, 1, rot, def.Layer);
                n++;
            }
            Rnr.Msg($"{n} x {def.Name} inserted on {def.Layer}.");
        });

        [CommandMethod("RNR", "RNRBLOCKS", CommandFlags.Modal)]
        public void Blocks() => Rnr.Run("RNRBLOCKS", (doc, tr) =>
        {
            BlockFactory.EnsureAll(doc.Database, tr);
            Rnr.Msg($"{BlockFactory.Names.Count()} RooMNRooF block definitions available in this drawing (INSERT or RNRFURN).");
        });

        static ObjectId PickInsideBoundary(Document doc, Transaction tr, string layer)
        {
            var ed = doc.Editor;
            var p = Prompts.Point(ed, "Pick a point inside the closed area:");
            var col = ed.TraceBoundary(p, true);
            if (col == null || col.Count == 0) throw new RnrInputException("No closed boundary found around that point.");
            var d = new DrawService(doc.Database, tr);
            Entity outer = (Entity)col[0];
            foreach (DBObject o in col) if (o is Curve c && c.Area > ((Curve)outer).Area) outer = (Entity)o;
            d.Add(outer, layer);
            foreach (DBObject o in col) if (!ReferenceEquals(o, outer)) o.Dispose();
            return outer.ObjectId;
        }

        [CommandMethod("RNR", "RNRFLOOR", CommandFlags.Modal)]
        public void Floor() => Rnr.Run("RNRFLOOR", (doc, tr) =>
        {
            var mat = Prompts.Keyword(doc.Editor, "Floor finish [Tile/Marble/Granite/Wood/Concrete]", "Tile", "Tile", "Marble", "Granite", "Wood", "Concrete");
            var id = PickInsideBoundary(doc, tr, "A-FLOR");
            var d = new DrawService(doc.Database, tr);
            HatchService.Apply(d, id, HatchService.Resolve(mat), "A-FLOR");
            var c = (Curve)tr.GetObject(id, OpenMode.ForRead);
            Rnr.Msg($"Floor finish {mat} applied, area {c.Area / 1e6:0.00} m².");
        });

        [CommandMethod("RNR", "RNRCEILING", CommandFlags.Modal)]
        public void Ceiling() => Rnr.Run("RNRCEILING", (doc, tr) =>
        {
            var ed = doc.Editor;
            double grid = Prompts.Double(ed, "Ceiling grid size (mm) [600/1200]", 600);
            var id = PickInsideBoundary(doc, tr, "A-CEIL");
            var d = new DrawService(doc.Database, tr);
            var h = new Hatch();
            d.Add(h, "A-CEIL");
            h.PatternSpace = grid;
            h.PatternDouble = true;
            h.SetHatchPattern(HatchPatternType.UserDefined, "_USER");
            h.AppendLoop(HatchLoopTypes.Outermost, new ObjectIdCollection { id });
            h.EvaluateHatch(true);
            Rnr.Msg($"Reflected ceiling grid {grid:0} x {grid:0} mm applied.");
        });

        internal static void RoofOutline(Document doc, Transaction tr)
        {
            var ed = doc.Editor;
            var id = Prompts.Entity(ed, "Select closed building outline polyline:", typeof(Polyline));
            double overhang = Prompts.Double(ed, "Roof overhang (mm)", 600);
            var pl = (Polyline)tr.GetObject(id, OpenMode.ForRead);
            if (!pl.Closed) throw new RnrInputException("Outline must be a closed polyline.");
            var d = new DrawService(doc.Database, tr);
            var offs = pl.GetOffsetCurves(overhang);
            Curve? best = null;
            foreach (DBObject o in offs) { if (o is Curve c && (best == null || c.Area > best.Area)) best = c; }
            // choose the offset side that is OUTSIDE (larger area); if it's smaller, try negative
            if (best == null || best.Area < pl.Area)
            {
                foreach (DBObject o in offs) o.Dispose();
                offs = pl.GetOffsetCurves(-overhang);
                best = null;
                foreach (DBObject o in offs) { if (o is Curve c && (best == null || c.Area > best.Area)) best = c; }
            }
            if (best == null) throw new RnrInputException("Offset failed for this outline.");
            d.Add((Entity)best, "A-ROOF");
            foreach (DBObject o in offs) if (!ReferenceEquals(o, best)) o.Dispose();
            d.Text(pl.GeometricExtents.MinPoint + (pl.GeometricExtents.MaxPoint - pl.GeometricExtents.MinPoint) / 2, "ROOF (OVERHANG " + overhang.ToString("0") + ")", 2.5, "A-TEXT");
            Rnr.Done();
        }
    }
}
