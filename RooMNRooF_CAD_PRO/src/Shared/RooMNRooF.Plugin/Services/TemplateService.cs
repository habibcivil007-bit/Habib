using System;
using System.Collections.Generic;
using System.IO;
using Autodesk.AutoCAD.DatabaseServices;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    /// <summary>
    /// Generates the RooMNRooF DWT family from the JSON standards. Templates are produced by AutoCAD
    /// itself (side database -> SaveAs .dwt) so they are always valid for the running AutoCAD version.
    /// </summary>
    public static class TemplateService
    {
        public static readonly Dictionary<string, (string[] filters, string sheet, string tb, string dim, double scale)> Kinds =
            new(StringComparer.OrdinalIgnoreCase)
            {
                ["MASTER"] = (new[] { "ALL" }, "A1", "STRUCTURAL", "RNR_STRUCT", 100),
                ["ARCHITECTURAL"] = (new[] { "ARCHITECTURE", "ANNOTATION", "REFERENCE", "MEP" }, "A1", "ARCHITECTURAL", "RNR_ARCH", 100),
                ["STRUCTURAL"] = (new[] { "STRUCTURE", "ANNOTATION", "REFERENCE" }, "A1", "STRUCTURAL", "RNR_STRUCT", 100),
                ["RCC"] = (new[] { "STRUCTURE", "ANNOTATION", "REFERENCE" }, "A1", "RCC", "RNR_STRUCT", 25),
                ["CIVIL"] = (new[] { "CIVIL", "ANNOTATION", "REFERENCE" }, "A1", "CIVIL", "RNR_CIVIL", 200),
                ["SITE"] = (new[] { "SITE", "ANNOTATION", "REFERENCE", "MEP" }, "A1", "CIVIL", "RNR_CIVIL", 500),
                ["MEP"] = (new[] { "MEP", "ANNOTATION", "REFERENCE" }, "A1", "ARCHITECTURAL", "RNR_ARCH", 100),
            };

        public static string FileName(string kind) => $"RNR_{kind.ToUpperInvariant()}.dwt";

        /// <summary>Applies a template's standards to an existing database inside the given transaction.</summary>
        public static void ApplyStandards(Database db, Transaction tr, string kind)
        {
            if (!Kinds.TryGetValue(kind, out var k)) throw new RnrInputException($"Unknown template kind {kind}");
            StyleService.SetMetricUnits(db);
            StyleService.ApplyAll(db, tr);
            foreach (var f in k.filters) LayerService.ApplyStandard(db, tr, f);
            LayerService.Ensure(db, tr, "Z-VPORT", false);
            LayerService.Ensure(db, tr, "Z-CONST", false);
            BlockFactory.EnsureAll(db, tr);
            foreach (var sheet in new[] { "A0", "A1", "A2", "A3", "A4" }) LayoutService.EnsureTitleBlock(db, tr, sheet, k.tb);
            DrawService.EnsureRegApp(db, tr, RooMNRooF.Core.Schedules.DraftedMember.RegApp);
            db.Dimstyle = StyleService.DimStyleId(db, tr, k.dim);
            db.SetDimstyleData((DimStyleTableRecord)tr.GetObject(db.Dimstyle, OpenMode.ForRead));
            db.Textstyle = StyleService.TextStyleId(db, tr, "RNR_TEXT");
            var ml = (DBDictionary)tr.GetObject(db.MLeaderStyleDictionaryId, OpenMode.ForRead);
            if (ml.Contains("RNR_LEADER")) db.MLeaderstyle = ml.GetAt("RNR_LEADER");
        }

        /// <summary>Creates a template file. Refuses to overwrite unless <paramref name="overwrite"/> (a .bak copy is kept).</summary>
        public static string Create(string kind, string folder, bool overwrite)
        {
            if (!Kinds.TryGetValue(kind, out var k)) throw new RnrInputException($"Unknown template kind {kind}");
            Directory.CreateDirectory(folder);
            var path = Path.Combine(folder, FileName(kind));
            if (File.Exists(path))
            {
                if (!overwrite) throw new RnrInputException($"{path} exists. Choose Overwrite to replace (a backup will be kept).");
                File.Copy(path, path + $".{DateTime.Now:yyyyMMddHHmmss}.bak", true);
            }

            var prevWdb = HostApplicationServices.WorkingDatabase;
            using var db = new Database(true, true);
            try
            {
                HostApplicationServices.WorkingDatabase = db; // LayoutManager works on the working database
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    ApplyStandards(db, tr, kind);
                    tr.Commit();
                }
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    LayoutService.CreateLayout(db, tr, $"{kind.ToUpperInvariant()}-{k.sheet}", k.sheet, k.tb, k.scale, activateViewport: false);
                    // remove default "Layout1"/"Layout2" only if they are empty
                    foreach (var n in new[] { "Layout1", "Layout2" })
                    {
                        var id = LayoutManager.Current.GetLayoutId(n);
                        if (id.IsNull) continue;
                        var lay = (Layout)tr.GetObject(id, OpenMode.ForRead);
                        var btr = (BlockTableRecord)tr.GetObject(lay.BlockTableRecordId, OpenMode.ForRead);
                        int count = 0; foreach (ObjectId _ in btr) count++;
                        if (count <= 1) LayoutManager.Current.DeleteLayout(n);
                    }
                    tr.Commit();
                }
            }
            finally
            {
                HostApplicationServices.WorkingDatabase = prevWdb;
            }
            db.SaveAs(path, DwgVersion.Current);
            RnrLog.Info($"Template created: {path}");
            return path;
        }
    }
}
