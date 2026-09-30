using System;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Logging;
using RooMNRooF.Core.Models;
using RooMNRooF.Plugin.Core;

namespace RooMNRooF.Plugin.Services
{
    public static class HatchService
    {
        /// <summary>
        /// Hatches a closed boundary with a material definition. Custom RNR_* patterns require the
        /// Hatch folder on the support path (the .bundle / MSI adds it). If a custom pattern cannot be
        /// found, ANSI31 is used and a warning is printed - never a silent substitution.
        /// </summary>
        public static Hatch Apply(DrawService d, ObjectId boundary, HatchDef def, string? layer = null, double drawingScale = 1)
        {
            var h = new Hatch();
            d.Add(h, layer ?? def.LayerHint);
            h.Normal = Vector3d.ZAxis;
            h.Elevation = 0;
            h.PatternScale = def.Scale * drawingScale;
            h.PatternAngle = def.Angle * Math.PI / 180.0;
            try
            {
                h.SetHatchPattern(def.Custom ? HatchPatternType.CustomDefined : HatchPatternType.PreDefined, def.Pattern);
            }
            catch (Autodesk.AutoCAD.Runtime.Exception ex)
            {
                RnrLog.Warn($"Hatch pattern {def.Pattern} unavailable ({ex.ErrorStatus}); ANSI31 used.");
                Rnr.Msg($"Pattern {def.Pattern} not found on support path - ANSI31 used. Add '{Rnr.HatchDir}' to the support path.");
                h.SetHatchPattern(HatchPatternType.PreDefined, "ANSI31");
            }
            h.Associative = true;
            h.AppendLoop(HatchLoopTypes.Outermost, new ObjectIdCollection { boundary });
            h.Color = DrawService.Rgb(def.Rgb);
            h.Transparency = LayerService.ToTransparency(def.Transparency);
            h.EvaluateHatch(true);
            return h;
        }

        public static HatchDef Resolve(string name) =>
            Rnr.Repo.Hatch(name) ?? throw new RnrInputException($"Material '{name}' not in library. Use RNRMATLIB.");

        public static string UserHatchFile => Path.Combine(Rnr.UserDir, "Standards", "RNR_Hatches.json");

        /// <summary>Adds/updates a user-defined material in the user library (installed library untouched).</summary>
        public static void SaveCustom(HatchDef def)
        {
            def.UserDefined = true;
            var lib = Rnr.Repo.Hatches;
            var existing = lib.Hatches.FirstOrDefault(h => h.Name.Equals(def.Name, StringComparison.OrdinalIgnoreCase));
            if (existing != null && !existing.UserDefined) throw new RnrInputException($"'{def.Name}' is a built-in material and cannot be replaced.");
            if (existing != null) lib.Hatches.Remove(existing);
            lib.Hatches.Add(def);
            StandardsRepository.SaveFile(UserHatchFile, lib);
            Rnr.ReloadStandards();
        }

        public static bool DeleteCustom(string name)
        {
            var lib = Rnr.Repo.Hatches;
            var e = lib.Hatches.FirstOrDefault(h => h.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
            if (e == null || !e.UserDefined) return false;
            lib.Hatches.Remove(e);
            StandardsRepository.SaveFile(UserHatchFile, lib);
            Rnr.ReloadStandards();
            return true;
        }

        public static void SetFavorite(string name, bool fav)
        {
            var lib = Rnr.Repo.Hatches;
            var e = lib.Hatches.FirstOrDefault(h => h.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
            if (e == null) return;
            e.Favorite = fav;
            StandardsRepository.SaveFile(UserHatchFile, lib);
        }

        /// <summary>Draws a material legend: swatch box + hatch + label for each selected material.</summary>
        public static void Legend(DrawService d, Point3d origin, System.Collections.Generic.IEnumerable<HatchDef> defs, double scale)
        {
            double box = 15 * scale, gap = 6 * scale, y = origin.Y;
            d.Text(new Point3d(origin.X, y + gap, 0), "MATERIAL LEGEND", 3.5, "ANNO-TEXT", TextHorizontalMode.TextLeft, TextVerticalMode.TextBase, 0, "RNR_HEADING");
            foreach (var h in defs)
            {
                y -= box + gap;
                var pl = d.Poly(new[] { new RooMNRooF.Core.Geometry.Pt(origin.X, y), new(origin.X + box * 2, y), new(origin.X + box * 2, y + box), new(origin.X, y + box) }, true, "ANNO-TEXT");
                Apply(d, pl.ObjectId, h, "ANNO-TEXT", scale / 10.0);
                d.Text(new Point3d(origin.X + box * 2 + gap, y + box / 2, 0), $"{h.Name.ToUpperInvariant()}  ({h.Pattern}, scale {h.Scale:0.##})", 2.5, "ANNO-TEXT", TextHorizontalMode.TextLeft, TextVerticalMode.TextVerticalMid);
            }
        }
    }
}
