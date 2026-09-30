using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using RooMNRooF.Core.Geometry;
using RooMNRooF.Core.Logging;
using RooMNRooF.Core.Schedules;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>Entity creation helpers. All methods require an open transaction and append to the given space.</summary>
    public sealed class DrawService
    {
        readonly Database _db;
        readonly Transaction _tr;
        readonly BlockTableRecord _space;
        public double TextScale { get; }

        public DrawService(Database db, Transaction tr, ObjectId? spaceId = null)
        {
            _db = db; _tr = tr;
            _space = (BlockTableRecord)tr.GetObject(spaceId ?? db.CurrentSpaceId, OpenMode.ForWrite);
            // model-space text height = paper height x drawing scale (non-annotative fallback text)
            TextScale = _space.IsLayout ? 1.0 : Rnr.Project.ScaleFactor;
        }

        public Database Db => _db;
        public Transaction Tr => _tr;

        public T Add<T>(T ent, string layer) where T : Entity
        {
            ent.SetDatabaseDefaults(_db);
            ent.LayerId = LayerService.Ensure(_db, _tr, layer, reportCreation: false);
            _space.AppendEntity(ent);
            _tr.AddNewlyCreatedDBObject(ent, true);
            return ent;
        }

        public static Point2d P2(Pt p) => new Point2d(p.X, p.Y);
        public static Point3d P3(Pt p) => new Point3d(p.X, p.Y, 0);

        public Polyline Poly(IEnumerable<Pt> pts, bool closed, string layer, string? linetype = null)
        {
            var pl = new Polyline();
            int i = 0;
            foreach (var p in pts) pl.AddVertexAt(i++, P2(p), 0, 0, 0);
            pl.Closed = closed;
            Add(pl, layer);
            if (linetype != null) pl.LinetypeId = StyleService.EnsureLinetype(_db, _tr, linetype);
            return pl;
        }

        public Line Line(Point3d a, Point3d b, string layer) => Add(new Line(a, b), layer);
        public Circle Circle(Point3d c, double r, string layer) => Add(new Circle(c, Vector3d.ZAxis, r), layer);

        public DBText Text(Point3d at, string text, double paperHeight, string layer, TextHorizontalMode h = TextHorizontalMode.TextCenter,
                           TextVerticalMode v = TextVerticalMode.TextVerticalMid, double rotation = 0, string style = "RNR_TEXT")
        {
            var t = new DBText
            {
                TextString = text, Height = paperHeight * TextScale, Rotation = rotation,
                TextStyleId = StyleService.TextStyleId(_db, _tr, style), HorizontalMode = h, VerticalMode = v,
            };
            if (h == TextHorizontalMode.TextLeft && v == TextVerticalMode.TextBase) t.Position = at;
            else { t.Position = at; t.AlignmentPoint = at; }
            Add(t, layer);
            t.AdjustAlignment(_db);
            return t;
        }

        public MText MText(Point3d at, string contents, double paperHeight, string layer, double width = 0, string style = "RNR_TEXT")
        {
            var m = new MText
            {
                Location = at, Contents = contents, TextHeight = paperHeight * TextScale, Width = width,
                TextStyleId = StyleService.TextStyleId(_db, _tr, style), Attachment = AttachmentPoint.TopLeft,
            };
            return Add(m, layer);
        }

        public AlignedDimension Dim(Point3d a, Point3d b, double offset, string layer, string style = "RNR_STRUCT")
        {
            var dir = (b - a);
            if (dir.Length < 1e-6) throw new RnrInputException("Zero-length dimension.");
            var n = dir.GetNormal().RotateBy(Math.PI / 2, Vector3d.ZAxis) * offset;
            var d = new AlignedDimension(a, b, a + n + dir / 2, "", StyleService.DimStyleId(_db, _tr, style));
            Add(d, layer);
            d.Dimscale = TextScale; // explicit scale; annotative scale lists can be added by user
            return d;
        }

        public RotatedDimension DimRotated(Point3d a, Point3d b, Point3d dimLine, double rotation, string layer, string style = "RNR_STRUCT")
        {
            var d = new RotatedDimension(rotation, a, b, dimLine, "", StyleService.DimStyleId(_db, _tr, style));
            Add(d, layer);
            d.Dimscale = TextScale;
            return d;
        }

        /// <summary>Draws a pure-geometry Shape2D using member/outline layers. Returns ids of created boundary entities.</summary>
        public List<ObjectId> Shape(Shape2D s, string outlineLayer, string detailLayer, out ObjectId hatchBoundary)
        {
            var ids = new List<ObjectId>();
            hatchBoundary = ObjectId.Null;
            for (int i = 0; i < s.Paths.Count; i++)
            {
                var p = s.Paths[i];
                string layer = p.Role == PathRole.Detail ? detailLayer : outlineLayer;
                string? ltype = p.Role switch { PathRole.Hidden => "RNR_HIDDEN", PathRole.Center => "CENTER", _ => null };
                var pl = Poly(p.Points, p.Closed, layer, ltype);
                ids.Add(pl.ObjectId);
                if (i == s.HatchPath) hatchBoundary = pl.ObjectId;
            }
            foreach (var c in s.Circles)
            {
                var ci = Circle(P3(c.Center), c.Radius, outlineLayer);
                if (c.Role == PathRole.Hidden) ci.LinetypeId = StyleService.EnsureLinetype(_db, _tr, "RNR_HIDDEN");
                ids.Add(ci.ObjectId);
                if (s.HatchCircle && hatchBoundary.IsNull) hatchBoundary = ci.ObjectId;
            }
            return ids;
        }

        // ------------------------------------------------------------ XData metadata
        public static void EnsureRegApp(Database db, Transaction tr, string app)
        {
            var rat = (RegAppTable)tr.GetObject(db.RegAppTableId, OpenMode.ForRead);
            if (rat.Has(app)) return;
            rat.UpgradeOpen();
            var r = new RegAppTableRecord { Name = app };
            rat.Add(r);
            tr.AddNewlyCreatedDBObject(r, true);
        }

        public void AttachMember(Entity ent, DraftedMember m)
        {
            EnsureRegApp(_db, _tr, DraftedMember.RegApp);
            var rb = new ResultBuffer(new TypedValue((int)DxfCode.ExtendedDataRegAppName, DraftedMember.RegApp));
            foreach (var chunk in DraftedMember.Chunk(m.Serialize()))
                rb.Add(new TypedValue((int)DxfCode.ExtendedDataAsciiString, chunk));
            if (!ent.IsWriteEnabled) ent.UpgradeOpen();
            ent.XData = rb;
            rb.Dispose();
        }

        public static DraftedMember? ReadMember(DBObject obj)
        {
            using var rb = obj.GetXDataForApplication(DraftedMember.RegApp);
            if (rb == null) return null;
            var s = string.Concat(rb.AsArray().Where(v => v.TypeCode == (int)DxfCode.ExtendedDataAsciiString).Select(v => (string)v.Value));
            var m = DraftedMember.Deserialize(s);
            m.Handle = obj.Handle.ToString();
            return m;
        }

        // ------------------------------------------------------------ groups (keep a member's parts together)
        public ObjectId Group(string namePrefix, IEnumerable<ObjectId> ids)
        {
            var gd = (DBDictionary)_tr.GetObject(_db.GroupDictionaryId, OpenMode.ForWrite);
            var g = new Group($"{namePrefix} (RooMNRooF)", true);
            string name = "*"; // anonymous group
            var gid = gd.SetAt(name, g);
            _tr.AddNewlyCreatedDBObject(g, true);
            g.Append(new ObjectIdCollection(ids.ToArray()));
            return gid;
        }

        public static Color Rgb(int[] rgb) => Color.FromRgb((byte)rgb[0], (byte)rgb[1], (byte)rgb[2]);
    }
}
