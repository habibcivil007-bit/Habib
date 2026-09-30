using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    public sealed class CleanPreview
    {
        public List<(ObjectId id, string kind, string name)> Purgeable { get; } = new();
        public List<(ObjectId id, string description)> Duplicates { get; } = new();
        public List<(ObjectId id, string description)> ZeroLength { get; } = new();
        public List<string> EmptyText { get; } = new();
        public List<ObjectId> EmptyTextIds { get; } = new();
        public int Total => Purgeable.Count + Duplicates.Count + ZeroLength.Count + EmptyTextIds.Count;
    }

    /// <summary>Safe cleanup: preview first, backup, then delete only confirmed categories.</summary>
    public static class CleanService
    {
        public static CleanPreview Preview(Database db, Transaction tr)
        {
            var p = new CleanPreview();
            void Collect(ObjectId tableId, string kind)
            {
                var ids = new ObjectIdCollection();
                var table = (SymbolTable)tr.GetObject(tableId, OpenMode.ForRead);
                foreach (ObjectId id in table) ids.Add(id);
                db.Purge(ids); // filters the collection down to unreferenced records
                foreach (ObjectId id in ids)
                {
                    var rec = (SymbolTableRecord)tr.GetObject(id, OpenMode.ForRead);
                    if (rec is BlockTableRecord b && (b.IsLayout || b.IsAnonymous || b.IsFromExternalReference)) continue;
                    if (rec is LayerTableRecord && Rnr.Repo.Layer(rec.Name) != null) continue; // keep standard layers
                    if (rec.Name.StartsWith("RNR_", StringComparison.OrdinalIgnoreCase) && !(rec is LayerTableRecord)) continue; // keep RNR styles/blocks
                    p.Purgeable.Add((id, kind, rec.Name));
                }
            }
            Collect(db.LayerTableId, "Layer");
            Collect(db.BlockTableId, "Block");
            Collect(db.LinetypeTableId, "Linetype");
            Collect(db.TextStyleTableId, "Text style");
            Collect(db.DimStyleTableId, "Dim style");
            Collect(db.RegAppTableId, "Regapp");

            // duplicate lines / zero-length curves / empty text in model space (safely detectable cases only)
            var ms = (BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(db), OpenMode.ForRead);
            var seen = new HashSet<string>();
            foreach (ObjectId id in ms)
            {
                var e = tr.GetObject(id, OpenMode.ForRead) as Entity;
                switch (e)
                {
                    case Line l:
                        if (l.Length < 1e-6) { p.ZeroLength.Add((id, $"Zero-length line on {l.Layer}")); break; }
                        var a = l.StartPoint; var b = l.EndPoint;
                        if (Cmp(a, b) > 0) (a, b) = (b, a);
                        var key = $"L|{l.Layer}|{a.X:F4},{a.Y:F4}|{b.X:F4},{b.Y:F4}";
                        if (!seen.Add(key)) p.Duplicates.Add((id, $"Duplicate line on {l.Layer}"));
                        break;
                    case Circle c:
                        var ck = $"C|{c.Layer}|{c.Center.X:F4},{c.Center.Y:F4}|{c.Radius:F4}";
                        if (!seen.Add(ck)) p.Duplicates.Add((id, $"Duplicate circle on {c.Layer}"));
                        break;
                    case DBText t when string.IsNullOrWhiteSpace(t.TextString):
                        p.EmptyTextIds.Add(id); p.EmptyText.Add($"Empty text on {t.Layer}"); break;
                    case MText m when string.IsNullOrWhiteSpace(m.Text):
                        p.EmptyTextIds.Add(id); p.EmptyText.Add($"Empty mtext on {m.Layer}"); break;
                }
            }
            return p;
        }

        static int Cmp(Autodesk.AutoCAD.Geometry.Point3d a, Autodesk.AutoCAD.Geometry.Point3d b) =>
            a.X != b.X ? a.X.CompareTo(b.X) : a.Y != b.Y ? a.Y.CompareTo(b.Y) : a.Z.CompareTo(b.Z);

        /// <summary>Writes a full copy of the current database next to the drawing (or in %APPDATA%\RooMNRooF\Backups).</summary>
        public static string Backup(Database db)
        {
            string dir = !string.IsNullOrEmpty(db.Filename) && Path.IsPathRooted(db.Filename) && File.Exists(db.Filename)
                ? Path.GetDirectoryName(db.Filename)! : Path.Combine(Rnr.UserDir, "Backups");
            Directory.CreateDirectory(dir);
            var name = Path.GetFileNameWithoutExtension(string.IsNullOrEmpty(db.Filename) ? "Drawing" : db.Filename);
            var path = Path.Combine(dir, $"{name}_RNRBACKUP_{DateTime.Now:yyyyMMdd_HHmmss}.dwg");
            using (var copy = db.Wblock()) copy.SaveAs(path, DwgVersion.Current);
            RnrLog.Info($"Backup written: {path}");
            return path;
        }

        public static int Erase(Transaction tr, IEnumerable<ObjectId> ids)
        {
            int n = 0;
            foreach (var id in ids)
            {
                if (id.IsErased || !id.IsValid) continue;
                var o = tr.GetObject(id, OpenMode.ForWrite);
                o.Erase(); n++;
            }
            return n;
        }
    }
}
