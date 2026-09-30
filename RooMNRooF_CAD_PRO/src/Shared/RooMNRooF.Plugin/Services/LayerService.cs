using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.LayerManager;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Logging;
using RooMNRooF.Core.Models;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    public static class LayerService
    {
        public static LineWeight ToLineWeight(double mm)
        {
            int v = (int)Math.Round(mm * 100);
            return Enum.IsDefined(typeof(LineWeight), v) ? (LineWeight)v : LineWeight.ByLineWeightDefault;
        }

        /// <summary>Transparency percent (0..90) -> AutoCAD alpha.</summary>
        public static Transparency ToTransparency(int percent)
        {
            percent = Math.Max(0, Math.Min(90, percent));
            return new Transparency((byte)Math.Round(255 * (100 - percent) / 100.0));
        }

        public static int FromTransparency(Transparency t) =>
            t.IsByAlpha ? (int)Math.Round(100 - t.Alpha * 100.0 / 255) : 0;

        /// <summary>Returns the layer id, creating it from the standard (or a neutral default) when missing.</summary>
        public static ObjectId Ensure(Database db, Transaction tr, string name, bool reportCreation = true)
        {
            var lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
            if (lt.Has(name)) return lt[name];
            var def = Rnr.Repo.Layer(name);
            lt.UpgradeOpen();
            var rec = new LayerTableRecord { Name = name };
            var id = lt.Add(rec);
            tr.AddNewlyCreatedDBObject(rec, true);
            if (def != null) Apply(db, tr, rec, def);
            if (reportCreation) Rnr.Msg($"Required layer {name} was created automatically.");
            RnrLog.Info($"Layer created: {name}");
            return id;
        }

        public static void Apply(Database db, Transaction tr, LayerTableRecord rec, LayerDef def)
        {
            if (!rec.IsWriteEnabled) rec.UpgradeOpen();
            rec.Color = Color.FromRgb((byte)def.Rgb[0], (byte)def.Rgb[1], (byte)def.Rgb[2]);
            rec.LinetypeObjectId = StyleService.EnsureLinetype(db, tr, def.Linetype);
            rec.LineWeight = ToLineWeight(def.Lineweight);
            rec.Transparency = ToTransparency(def.Transparency);
            rec.IsPlottable = def.Plot;
            rec.Description = def.Description;
        }

        /// <summary>Creates/updates all standard layers matching a filter (default ALL). Returns (created, updated).</summary>
        public static (int created, int updated) ApplyStandard(Database db, Transaction tr, string filter = "ALL", bool updateExisting = true)
        {
            var lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForWrite);
            int c = 0, u = 0;
            foreach (var def in Rnr.Repo.LayersInFilter(filter))
            {
                if (lt.Has(def.Name))
                {
                    if (!updateExisting) continue;
                    var rec = (LayerTableRecord)tr.GetObject(lt[def.Name], OpenMode.ForWrite);
                    Apply(db, tr, rec, def); u++;
                }
                else
                {
                    var rec = new LayerTableRecord { Name = def.Name };
                    lt.Add(rec);
                    tr.AddNewlyCreatedDBObject(rec, true);
                    Apply(db, tr, rec, def); c++;
                }
            }
            RnrLog.Info($"ApplyStandard({filter}) created={c} updated={u}");
            return (c, u);
        }

        /// <summary>Compares drawing layers against the standard. Returns human-readable deviations.</summary>
        public static List<(string layer, string issue, bool isError)> Audit(Database db, Transaction tr)
        {
            var issues = new List<(string, string, bool)>();
            var lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
            foreach (ObjectId id in lt)
            {
                var rec = (LayerTableRecord)tr.GetObject(id, OpenMode.ForRead);
                if (rec.Name == "0" || rec.Name.Equals("Defpoints", StringComparison.OrdinalIgnoreCase) || rec.IsDependent) continue;
                var def = Rnr.Repo.Layer(rec.Name);
                if (def == null) { issues.Add((rec.Name, "not in RooMNRooF layer standard", false)); continue; }
                var c = rec.Color;
                if (!(c.ColorMethod == ColorMethod.ByColor && c.Red == def.Rgb[0] && c.Green == def.Rgb[1] && c.Blue == def.Rgb[2]))
                    issues.Add((rec.Name, $"color {c} != RGB {string.Join(",", def.Rgb)}", false));
                var ltr = (LinetypeTableRecord)tr.GetObject(rec.LinetypeObjectId, OpenMode.ForRead);
                if (!ltr.Name.Equals(def.Linetype, StringComparison.OrdinalIgnoreCase))
                    issues.Add((rec.Name, $"linetype {ltr.Name} != {def.Linetype}", false));
                if (rec.LineWeight != ToLineWeight(def.Lineweight))
                    issues.Add((rec.Name, $"lineweight {rec.LineWeight} != {def.Lineweight:0.00} mm", false));
                if (rec.IsPlottable != def.Plot)
                    issues.Add((rec.Name, $"plot flag {rec.IsPlottable} != {def.Plot}", true));
            }
            return issues;
        }

        /// <summary>Freeze (or thaw) every drawing layer inside/outside a standard filter. Current layer is never frozen.</summary>
        public static int SetFrozenByFilter(Database db, Transaction tr, string filterName, bool isolate)
        {
            var flt = Rnr.Repo.Filters.Filters.FirstOrDefault(f => f.Name.Equals(filterName, StringComparison.OrdinalIgnoreCase))
                      ?? throw new RnrInputException($"Unknown filter {filterName}");
            var lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
            int n = 0;
            foreach (ObjectId id in lt)
            {
                var rec = (LayerTableRecord)tr.GetObject(id, OpenMode.ForRead);
                bool inFilter = WildcardMatcher.MatchesList(rec.Name, flt.Expr);
                bool freeze = isolate && !inFilter && id != db.Clayer;
                if (rec.IsFrozen != freeze) { rec.UpgradeOpen(); rec.IsFrozen = freeze; n++; }
            }
            return n;
        }

        /// <summary>Creates the named layer filters in the Layer Properties Manager filter tree.</summary>
        public static int CreateLayerFilters(Database db)
        {
            LayerFilterTree tree = db.LayerFilters;
            LayerFilterCollection col = tree.Root.NestedFilters;
            int n = 0;
            foreach (var f in Rnr.Repo.Filters.Filters.Where(f => f.Name != "ALL"))
            {
                var name = "RNR " + f.Name;
                bool exists = false;
                foreach (LayerFilter existing in col) if (existing.Name == name) { exists = true; break; }
                if (exists) continue;
                var parts = f.Expr.Split(',').Select(p => p.Trim()).ToList();
                var inc = parts.Where(p => !p.StartsWith("~")).Select(p => $"NAME==\"{p}\"");
                var exc = parts.Where(p => p.StartsWith("~")).Select(p => $"NAME!=\"{p.Substring(1)}\"");
                string expr = string.Join(" OR ", inc);
                if (exc.Any()) expr = (expr.Length > 0 ? $"({expr}) AND " : "") + string.Join(" AND ", exc);
                var lf = new LayerFilter { Name = name, FilterExpression = expr };
                col.Add(lf);
                n++;
            }
            db.LayerFilters = tree; // must be re-assigned for the change to persist
            return n;
        }

        // ------------------------- palette (RNRCOLOR) -------------------------
        public static void ExportPalette(string path) => StandardsRepository.SaveFile(path, Rnr.Repo.Colors);

        /// <summary>Imports a palette JSON into the USER standards folder (never overwrites the installed defaults).</summary>
        public static int ImportPalette(string path)
        {
            var incoming = StandardsRepository.LoadFile<ColorFile>(path);
            if (incoming.Colors.Count == 0) throw new RnrInputException("Palette contains no colors.");
            foreach (var c in incoming.Colors)
                if (c.Rgb.Length != 3 || c.Rgb.Any(v => v < 0 || v > 255)) throw new RnrInputException($"Color {c.Id} has invalid RGB.");
            var userDir = Path.Combine(Rnr.UserDir, "Standards");
            StandardsRepository.SaveFile(Path.Combine(userDir, "RNR_Colors.json"), incoming);
            // regenerate user layer file so every layer references the new RGB for its colorId
            var layers = Rnr.Repo.Layers;
            foreach (var l in layers.Layers)
            {
                var c = incoming.Colors.FirstOrDefault(x => x.Id == l.ColorId);
                if (c != null) l.Rgb = c.Rgb;
            }
            StandardsRepository.SaveFile(Path.Combine(userDir, "RNR_Layers.json"), layers);
            Rnr.ReloadStandards();
            return incoming.Colors.Count;
        }

        public static void RestoreDefaults()
        {
            var userDir = Path.Combine(Rnr.UserDir, "Standards");
            foreach (var f in new[] { "RNR_Colors.json", "RNR_Layers.json" })
            {
                var p = Path.Combine(userDir, f);
                if (File.Exists(p)) File.Move(p, p + $".{DateTime.Now:yyyyMMddHHmmss}.bak");
            }
            Rnr.ReloadStandards();
        }
    }
}
