using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>
    /// Builds the RooMNRooF block library directly in the drawing database (real geometry, mm units,
    /// insertion point documented per block). Parametric variants (door/window width etc.) are
    /// generated on demand as named blocks such as RNR_DOOR_900.
    ///
    /// NOTE ON DYNAMIC BLOCKS: the public AutoCAD .NET API can READ and SET dynamic block
    /// properties but cannot AUTHOR dynamic parameters/actions. Dynamic versions are therefore
    /// authored once in the Block Editor following Documentation/09_Dynamic_Block_Manual.md and
    /// saved into Blocks/RNR_DynamicBlocks.dwg; <see cref="InsertFromLibrary"/> imports them when present.
    /// </summary>
    public static class BlockFactory
    {
        sealed class B
        {
            public readonly List<Entity> E = new();
            public B L(double x1, double y1, double x2, double y2) { E.Add(new Line(new Point3d(x1, y1, 0), new Point3d(x2, y2, 0))); return this; }
            public B R(double x, double y, double w, double h, double bulgeRadius = 0)
            {
                var p = new Polyline();
                p.AddVertexAt(0, new Point2d(x, y), 0, 0, 0); p.AddVertexAt(1, new Point2d(x + w, y), 0, 0, 0);
                p.AddVertexAt(2, new Point2d(x + w, y + h), 0, 0, 0); p.AddVertexAt(3, new Point2d(x, y + h), 0, 0, 0);
                p.Closed = true; E.Add(p); return this;
            }
            public B C(double x, double y, double r) { E.Add(new Circle(new Point3d(x, y, 0), Vector3d.ZAxis, r)); return this; }
            public B A(double x, double y, double r, double a0Deg, double a1Deg) { E.Add(new Arc(new Point3d(x, y, 0), r, a0Deg * Math.PI / 180, a1Deg * Math.PI / 180)); return this; }
            public B El(double x, double y, double rx, double ry) { E.Add(new Ellipse(new Point3d(x, y, 0), Vector3d.ZAxis, new Vector3d(rx, 0, 0), ry / rx, 0, 2 * Math.PI)); return this; }
            public B T(double x, double y, double h, string s)
            {
                var t = new DBText { TextString = s, Height = h, HorizontalMode = TextHorizontalMode.TextCenter, VerticalMode = TextVerticalMode.TextVerticalMid };
                t.Position = new Point3d(x, y, 0); t.AlignmentPoint = t.Position; E.Add(t); return this;
            }
            public B Att(string tag, string prompt, string def, double x, double y, double h)
            {
                var a = new AttributeDefinition(new Point3d(x, y, 0), def, tag, prompt, ObjectId.Null)
                { Height = h, HorizontalMode = TextHorizontalMode.TextCenter, VerticalMode = TextVerticalMode.TextVerticalMid };
                a.AlignmentPoint = new Point3d(x, y, 0); E.Add(a); return this;
            }
            public B AttL(string tag, string prompt, string def, double x, double y, double h)
            {
                var a = new AttributeDefinition(new Point3d(x, y, 0), def, tag, prompt, ObjectId.Null) { Height = h };
                E.Add(a); return this;
            }
        }

        static readonly Dictionary<string, Func<B>> Library = new(StringComparer.OrdinalIgnoreCase)
        {
            // Insertion points: doors/windows at opening start on wall centre-line; furniture at lower-left; symbols at centre.
            ["RNR_DOOR"] = () => Door(900),
            ["RNR_WINDOW"] = () => Window(1200, 250),
            ["RNR_BED_DOUBLE"] = () => new B().R(0, 0, 1500, 2000).R(100, 1650, 575, 300).R(825, 1650, 575, 300).L(0, 1550, 1500, 1550).L(0, 600, 1500, 1000),
            ["RNR_SOFA"] = () => new B().R(0, 0, 2100, 900).R(0, 700, 2100, 200).R(0, 0, 200, 700).R(1900, 0, 200, 700).L(767, 0, 767, 700).L(1333, 0, 1333, 700),
            ["RNR_DINING"] = () => { var b = new B().R(0, 0, 1800, 900); foreach (var x in new[] { 300.0, 900, 1500 }) { b.R(x - 225, -500, 450, 420); b.R(x - 225, 980, 450, 420); } return b; },
            ["RNR_CHAIR"] = () => new B().R(0, 0, 450, 450).R(0, 380, 450, 70),
            ["RNR_KITCHEN_COUNTER"] = () => new B().R(0, 0, 2400, 600).C(600, 300, 180).C(600, 300, 60).C(1000, 300, 110).C(1000, 300, 90).R(1500, 80, 800, 440).R(1560, 130, 330, 340).R(1910, 130, 330, 340),
            ["RNR_SINK"] = () => new B().R(0, 0, 800, 500).R(50, 50, 330, 400).R(420, 50, 330, 400).C(400, 470, 20),
            ["RNR_TOILET"] = () => new B().R(0, 0, 500, 200).El(250, 480, 190, 260).El(250, 480, 140, 200),
            ["RNR_BASIN"] = () => new B().R(0, 0, 550, 450).El(275, 200, 210, 150).C(275, 400, 20),
            ["RNR_SHOWER"] = () => new B().R(0, 0, 900, 900).L(0, 0, 900, 900).L(0, 900, 900, 0).C(450, 450, 40),
            ["RNR_BATHTUB"] = () => new B().R(0, 0, 1700, 750).R(60, 60, 1580, 630).C(1500, 375, 30),
            ["RNR_WARDROBE"] = () => new B().R(0, 0, 1800, 600).L(0, 300, 1800, 300).L(900, 0, 900, 600).L(200, 300, 400, 600).L(1100, 300, 1300, 600),
            ["RNR_TV"] = () => new B().R(0, 0, 1800, 450).R(400, 300, 1000, 60),
            ["RNR_DESK"] = () => new B().R(0, 0, 1400, 700).R(475, -350, 450, 450).R(1000, 400, 300, 250),
            ["RNR_CAR"] = () => new B().R(0, 0, 4800, 1900).R(1300, 150, 1900, 1600).L(1300, 150, 1000, 0).L(1300, 1750, 1000, 1900).L(3200, 150, 3500, 0).L(3200, 1750, 3500, 1900),
            ["RNR_TREE"] = () => { var b = new B().C(0, 0, 2000).C(0, 0, 150); for (int i = 0; i < 8; i++) { double a = i * Math.PI / 4; b.L(150 * Math.Cos(a), 150 * Math.Sin(a), 1600 * Math.Cos(a), 1600 * Math.Sin(a)); } return b; },
            ["RNR_PLANT"] = () => new B().C(0, 0, 300).C(0, 0, 200).A(0, 0, 250, 20, 160).A(0, 0, 250, 200, 340),
            ["RNR_LIGHT"] = () => new B().C(0, 0, 150).L(-106, -106, 106, 106).L(-106, 106, 106, -106),
            ["RNR_FAN"] = () => new B().C(0, 0, 100).L(0, 100, 0, 600).L(87, -50, 520, -300).L(-87, -50, -520, -300).C(0, 0, 600),
            ["RNR_AC"] = () => new B().R(0, 0, 900, 250).L(50, 60, 850, 60).L(50, 110, 850, 110).T(450, 180, 60, "AC"),
            ["RNR_LIFT"] = () => new B().R(0, 0, 1800, 1800).R(150, 150, 1500, 1400).L(150, 150, 1650, 1550).L(150, 1550, 1650, 150).R(500, 0, 800, 50),
            ["RNR_STAIR_ARROW"] = () => new B().L(0, 0, 1000, 0).L(1000, 0, 850, 60).L(1000, 0, 850, -60).C(0, 0, 30).T(500, 100, 80, "UP"),
            ["RNR_NORTH"] = () => new B().C(0, 0, 10).L(0, -9, 0, 12).L(0, 12, -4, 0).L(0, 12, 4, 0).L(-4, 0, 4, 0).T(0, 15, 3.5, "N"),
            ["RNR_GRIDBUBBLE"] = () => new B().C(0, 0, 5).Att("GRID", "Grid label", "A", 0, 0, 4),
            ["RNR_LEVEL"] = () => new B().L(-6, 0, 12, 0).L(0, 0, -3, 3).L(0, 0, 3, 3).L(-3, 3, 3, 3).AttL("LEVEL", "Level", "+0.000", 4, 1, 2.5),
            ["RNR_SECTIONMARK"] = () => new B().C(0, 0, 6).L(-6, 0, 6, 0).Att("ID", "Section id", "A", 0, 2.8, 3).Att("SHEET", "Sheet", "S-01", 0, -2.8, 2),
            ["RNR_DETAILMARK"] = () => new B().C(0, 0, 6).L(-6, 0, 6, 0).Att("ID", "Detail no", "1", 0, 2.8, 3).Att("SHEET", "Sheet", "S-01", 0, -2.8, 2),
            ["RNR_ELEVMARK"] = () => new B().C(0, 0, 6).L(-6, 0, 0, 9).L(6, 0, 0, 9).Att("ID", "Elevation", "E1", 0, 0, 3),
            ["RNR_ROOMTAG"] = () => new B().R(-20, -7, 40, 14).Att("NAME", "Room name", "ROOM", 0, 2.5, 3).Att("AREA", "Area", "0.00 m²", 0, -3, 2.2),
            ["RNR_TAG"] = () => new B().R(-8, -4, 16, 8).Att("MARK", "Mark", "C1", 0, 0, 3),
        };

        public static IEnumerable<string> Names => Library.Keys;

        static B Door(double w)
        {
            // leaf + 90° swing arc; insertion at hinge side opening start, wall centre-line
            return new B().L(0, 0, 0, w).A(0, 0, w, 0, 90).L(0, 0, w, 0);
        }

        static B Window(double w, double wall)
        {
            double h = wall / 2;
            return new B().R(0, -h, w, wall).L(0, -25, w, -25).L(0, 25, w, 25);
        }

        /// <summary>Returns block id, defining it if absent. Annotation blocks are defined in paper units.</summary>
        public static ObjectId Ensure(Database db, Transaction tr, string name)
        {
            var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            if (bt.Has(name)) return bt[name];
            B? b = null;
            if (Library.TryGetValue(name, out var f)) b = f();
            else if (name.StartsWith("RNR_DOOR_") && double.TryParse(name.Substring(9), out var dw) && dw > 0) b = Door(dw);
            else if (name.StartsWith("RNR_WINDOW_"))
            {
                var parts = name.Substring(11).Split('x');
                if (parts.Length == 2 && double.TryParse(parts[0], out var ww) && double.TryParse(parts[1], out var wt) && ww > 0 && wt > 0) b = Window(ww, wt);
            }
            if (b == null) throw new RnrInputException($"Unknown block {name}");

            var btr = new BlockTableRecord { Name = name, Origin = Point3d.Origin, Units = UnitsValue.Millimeters };
            bt.UpgradeOpen();
            var id = bt.Add(btr);
            tr.AddNewlyCreatedDBObject(btr, true);
            foreach (var e in b.E)
            {
                e.SetDatabaseDefaults(db);
                e.Layer = "0";            // block content on layer 0 -> inherits insert layer
                e.ColorIndex = 0;         // ByBlock
                btr.AppendEntity(e);
                tr.AddNewlyCreatedDBObject(e, true);
                if (e is DBText t && t.HorizontalMode != TextHorizontalMode.TextLeft) t.AdjustAlignment(db);
            }
            var meta = Rnr.Repo.Blocks.Blocks.FirstOrDefault(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
            btr.Comments = meta != null ? $"RooMNRooF {meta.Category}" : "RooMNRooF block";
            RnrLog.Info($"Block defined: {name}");
            return id;
        }

        public static void EnsureAll(Database db, Transaction tr)
        {
            foreach (var n in Library.Keys) Ensure(db, tr, n);
        }

        /// <summary>Inserts a block reference and fills attributes (values keyed by tag).</summary>
        public static BlockReference Insert(DrawService d, string name, Point3d at, double scale, double rotation, string layer,
                                            IDictionary<string, string>? attrs = null)
        {
            var defId = Ensure(d.Db, d.Tr, name);
            var br = new BlockReference(at, defId) { ScaleFactors = new Scale3d(scale), Rotation = rotation };
            d.Add(br, layer);
            var def = (BlockTableRecord)d.Tr.GetObject(defId, OpenMode.ForRead);
            if (def.HasAttributeDefinitions)
            {
                foreach (ObjectId eid in def)
                {
                    if (d.Tr.GetObject(eid, OpenMode.ForRead) is not AttributeDefinition ad || ad.Constant) continue;
                    var ar = new AttributeReference();
                    ar.SetAttributeFromBlock(ad, br.BlockTransform);
                    if (attrs != null && attrs.TryGetValue(ad.Tag, out var v)) ar.TextString = v;
                    br.AttributeCollection.AppendAttribute(ar);
                    d.Tr.AddNewlyCreatedDBObject(ar, true);
                    if (ar.HorizontalMode != TextHorizontalMode.TextLeft) ar.AdjustAlignment(d.Db);
                }
            }
            return br;
        }

        /// <summary>Imports a (dynamic) block from Blocks/RNR_DynamicBlocks.dwg if the library file exists. Returns false if unavailable.</summary>
        public static bool InsertFromLibrary(Database db, string blockName)
        {
            var lib = System.IO.Path.Combine(Rnr.ResourceRoot, "Blocks", "RNR_DynamicBlocks.dwg");
            if (!System.IO.File.Exists(lib)) return false;
            using var src = new Database(false, true);
            src.ReadDwgFile(lib, System.IO.FileShare.Read, true, "");
            ObjectId srcId;
            using (var tr = src.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)tr.GetObject(src.BlockTableId, OpenMode.ForRead);
                if (!bt.Has(blockName)) return false;
                srcId = bt[blockName];
                tr.Commit();
            }
            var map = new IdMapping();
            src.WblockCloneObjects(new ObjectIdCollection { srcId }, db.BlockTableId, map, DuplicateRecordCloning.Ignore, false);
            return true;
        }

        /// <summary>Sets a dynamic block property by name when the reference is dynamic (e.g. "Width").</summary>
        public static bool SetDynamicProperty(BlockReference br, string prop, object value)
        {
            if (!br.IsDynamicBlock) return false;
            foreach (DynamicBlockReferenceProperty p in br.DynamicBlockReferencePropertyCollection)
            {
                if (!p.PropertyName.Equals(prop, StringComparison.OrdinalIgnoreCase) || p.ReadOnly) continue;
                p.Value = value;
                return true;
            }
            return false;
        }
    }
}
