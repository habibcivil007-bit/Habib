using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using RooMNRooF.Core.Models;

namespace RooMNRooF.Core.Configuration
{
    /// <summary>
    /// Loads and validates the RooMNRooF standards JSON set.
    /// Search order for every file: user override (%APPDATA%\RooMNRooF\Standards) then install folder.
    /// </summary>
    public sealed class StandardsRepository
    {
        public static readonly JsonSerializerOptions Json = new()
        {
            PropertyNameCaseInsensitive = true,
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            ReadCommentHandling = JsonCommentHandling.Skip,
            AllowTrailingCommas = true,
        };

        public string InstallStandardsDir { get; }
        public string UserStandardsDir { get; }

        public ColorFile Colors { get; private set; } = new();
        public LayerFile Layers { get; private set; } = new();
        public LayerFilterFile Filters { get; private set; } = new();
        public MemberFile Members { get; private set; } = new();
        public HatchFile Hatches { get; private set; } = new();
        public BlockFile Blocks { get; private set; } = new();
        public StylesFile Styles { get; private set; } = new();
        public RebarFile Rebar { get; private set; } = new();

        public StandardsRepository(string installStandardsDir, string? userStandardsDir = null)
        {
            InstallStandardsDir = installStandardsDir;
            UserStandardsDir = userStandardsDir ?? Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "RooMNRooF", "Standards");
        }

        public string Resolve(string fileName)
        {
            var user = Path.Combine(UserStandardsDir, fileName);
            if (File.Exists(user)) return user;
            return Path.Combine(InstallStandardsDir, fileName);
        }

        public static T LoadFile<T>(string path) where T : new()
        {
            if (!File.Exists(path)) throw new FileNotFoundException($"RooMNRooF standard file not found: {path}", path);
            var text = File.ReadAllText(path);
            return JsonSerializer.Deserialize<T>(text, Json) ?? new T();
        }

        public static void SaveFile<T>(string path, T data)
        {
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
            // write to temp then replace: never leaves a half-written standards file
            var tmp = path + ".tmp";
            File.WriteAllText(tmp, JsonSerializer.Serialize(data, Json));
            if (File.Exists(path)) File.Replace(tmp, path, path + ".bak");
            else File.Move(tmp, path);
        }

        public StandardsRepository Load()
        {
            Colors = LoadFile<ColorFile>(Resolve("RNR_Colors.json"));
            Layers = LoadFile<LayerFile>(Resolve("RNR_Layers.json"));
            Filters = LoadFile<LayerFilterFile>(Resolve("RNR_LayerFilters.json"));
            Members = LoadFile<MemberFile>(Resolve("RNR_Members.json"));
            Hatches = LoadFile<HatchFile>(Resolve("RNR_Hatches.json"));
            Blocks = LoadFile<BlockFile>(Resolve("RNR_Blocks.json"));
            Styles = LoadFile<StylesFile>(Resolve("RNR_Styles.json"));
            Rebar = LoadFile<RebarFile>(Resolve("RNR_Rebar.json"));
            return this;
        }

        public LayerDef? Layer(string name) =>
            Layers.Layers.FirstOrDefault(l => string.Equals(l.Name, name, StringComparison.OrdinalIgnoreCase));

        public MemberDef? Member(string code) =>
            Members.Members.FirstOrDefault(m => string.Equals(m.Code, code, StringComparison.OrdinalIgnoreCase)
                                             || m.No.ToString() == code);

        public HatchDef? Hatch(string name) =>
            Hatches.Hatches.FirstOrDefault(h => string.Equals(h.Name, name, StringComparison.OrdinalIgnoreCase));

        public ColorDef? Color(string id) =>
            Colors.Colors.FirstOrDefault(c => string.Equals(c.Id, id, StringComparison.OrdinalIgnoreCase));

        /// <summary>Layers matching a filter expression (AutoCAD-style wildcards, "~" excludes).</summary>
        public IEnumerable<LayerDef> LayersInFilter(string filterName)
        {
            var f = Filters.Filters.FirstOrDefault(x => string.Equals(x.Name, filterName, StringComparison.OrdinalIgnoreCase));
            if (f == null) return Enumerable.Empty<LayerDef>();
            return Layers.Layers.Where(l => WildcardMatcher.MatchesList(l.Name, f.Expr));
        }

        /// <summary>Structural validation of the whole set. Returns empty list if OK.</summary>
        public List<string> Validate()
        {
            var errors = new List<string>();
            var validLw = new HashSet<double> { 0, 0.05, 0.09, 0.13, 0.15, 0.18, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, 0.53, 0.60, 0.70, 0.80, 0.90, 1.00, 1.06, 1.20, 1.40, 1.58, 2.00, 2.11 };
            var hex = new Regex("^#[0-9A-F]{6}$");
            var colorIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var c in Colors.Colors)
            {
                if (!colorIds.Add(c.Id)) errors.Add($"Duplicate color id {c.Id}");
                if (c.Rgb.Length != 3 || c.Rgb.Any(v => v < 0 || v > 255)) errors.Add($"Color {c.Id}: RGB out of range");
                if (!hex.IsMatch(c.Hex)) errors.Add($"Color {c.Id}: bad hex {c.Hex}");
                if (c.Aci < 1 || c.Aci > 255) errors.Add($"Color {c.Id}: ACI {c.Aci} out of range");
                if (!validLw.Contains(Math.Round(c.Lineweight, 2))) errors.Add($"Color {c.Id}: non-standard lineweight {c.Lineweight}");
                if (c.Transparency < 0 || c.Transparency > 90) errors.Add($"Color {c.Id}: transparency {c.Transparency} out of range");
            }

            var layerNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var l in Layers.Layers)
            {
                if (!layerNames.Add(l.Name)) errors.Add($"Duplicate layer {l.Name}");
                if (!colorIds.Contains(l.ColorId)) errors.Add($"Layer {l.Name}: unknown color {l.ColorId}");
                if (!validLw.Contains(Math.Round(l.Lineweight, 2))) errors.Add($"Layer {l.Name}: non-standard lineweight {l.Lineweight}");
                if (string.IsNullOrWhiteSpace(l.Description)) errors.Add($"Layer {l.Name}: missing description");
                if (l.Name.IndexOfAny(new[] { '<', '>', '/', '\\', '"', ':', ';', '?', '*', '|', ',', '=', '`' }) >= 0)
                    errors.Add($"Layer {l.Name}: illegal characters");
            }

            var codes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var m in Members.Members)
            {
                if (!codes.Add(m.Code)) errors.Add($"Duplicate member code {m.Code}");
                if (!layerNames.Contains(m.Layer)) errors.Add($"Member {m.Code}: unknown layer {m.Layer}");
                if (!layerNames.Contains(m.TextLayer)) errors.Add($"Member {m.Code}: unknown text layer {m.TextLayer}");
                if (m.Parameters.Count == 0) errors.Add($"Member {m.Code}: no parameters");
                if (m.Parameters.Any(p => p.Default < 0)) errors.Add($"Member {m.Code}: negative default");
            }
            if (Members.Members.Count < 50) errors.Add($"Only {Members.Members.Count} members defined (need >= 50)");

            foreach (var h in Hatches.Hatches)
            {
                if (!colorIds.Contains(h.ColorId)) errors.Add($"Hatch {h.Name}: unknown color {h.ColorId}");
                if (h.Scale <= 0) errors.Add($"Hatch {h.Name}: scale must be > 0");
                if (h.Custom && string.IsNullOrEmpty(h.PatFile)) errors.Add($"Hatch {h.Name}: custom without PAT file");
            }
            foreach (var b in Blocks.Blocks)
                if (!layerNames.Contains(b.Layer)) errors.Add($"Block {b.Name}: unknown layer {b.Layer}");
            foreach (var bar in Rebar.Bars)
            {
                var expected = Math.Round(bar.Diameter * bar.Diameter / 162.2, 3);
                if (Math.Abs(expected - bar.UnitWeight) > 0.001) errors.Add($"Bar {bar.Mark}: unit weight {bar.UnitWeight} != {expected}");
            }
            return errors;
        }
    }

    /// <summary>AutoCAD-compatible wildcard matching (subset: * ? # @ ~ and comma lists).</summary>
    public static class WildcardMatcher
    {
        public static bool Matches(string name, string pattern)
        {
            var rx = "^" + Regex.Escape(pattern).Replace("\\*", ".*").Replace("\\?", ".")
                .Replace("\\#", "[0-9]").Replace("@", "[A-Za-z]") + "$";
            return Regex.IsMatch(name, rx, RegexOptions.IgnoreCase);
        }

        public static bool MatchesList(string name, string expr)
        {
            var parts = expr.Split(',').Select(p => p.Trim()).Where(p => p.Length > 0).ToList();
            var includes = parts.Where(p => !p.StartsWith("~")).ToList();
            var excludes = parts.Where(p => p.StartsWith("~")).Select(p => p.Substring(1)).ToList();
            bool inc = includes.Count == 0 || includes.Any(p => Matches(name, p));
            bool exc = excludes.Any(p => Matches(name, p));
            return inc && !exc;
        }
    }
}
