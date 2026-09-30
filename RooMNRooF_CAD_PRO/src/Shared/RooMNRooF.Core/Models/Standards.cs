using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace RooMNRooF.Core.Models
{
    /// <summary>One controlled TrueColor definition (Standards/RNR_Colors.json).</summary>
    public sealed class ColorDef
    {
        public string Id { get; set; } = "";
        public string Category { get; set; } = "";
        public string Name { get; set; } = "";
        public int[] Rgb { get; set; } = new int[3];
        public string Hex { get; set; } = "";
        public int Aci { get; set; }
        public string Screen { get; set; } = "TrueColor";
        /// <summary>BLACK | GRAY | NOPLOT</summary>
        public string Plot { get; set; } = "BLACK";
        public int Transparency { get; set; }
        public double Lineweight { get; set; }
        public string Discipline { get; set; } = "";
        public string ObjectCategory { get; set; } = "";
    }

    public sealed class ColorFile
    {
        public string Schema { get; set; } = "";
        public string Palette { get; set; } = "";
        public List<ColorDef> Colors { get; set; } = new();
    }

    public sealed class LayerDef
    {
        public string Name { get; set; } = "";
        public string Description { get; set; } = "";
        public string ColorId { get; set; } = "";
        public int[] Rgb { get; set; } = new int[3];
        public int Aci { get; set; }
        public string Linetype { get; set; } = "Continuous";
        /// <summary>Lineweight in millimetres (0.13, 0.18, 0.25, 0.35, 0.50 ...).</summary>
        public double Lineweight { get; set; }
        /// <summary>Transparency percent 0..90.</summary>
        public int Transparency { get; set; }
        public bool Plot { get; set; } = true;
        public string Discipline { get; set; } = "";
        public string ObjectClass { get; set; } = "";
        public string Status { get; set; } = "PROPOSED";
    }

    public sealed class LayerFile
    {
        public string Schema { get; set; } = "";
        public List<LayerDef> Layers { get; set; } = new();
    }

    public sealed class LayerFilterDef
    {
        public string Name { get; set; } = "";
        /// <summary>AutoCAD wildcard list, comma separated, "~" prefix = exclude.</summary>
        public string Expr { get; set; } = "*";
    }

    public sealed class LayerFilterFile
    {
        public string Schema { get; set; } = "";
        public List<LayerFilterDef> Filters { get; set; } = new();
    }

    public sealed class MemberParameter
    {
        public string Name { get; set; } = "";
        public string Unit { get; set; } = "mm";
        public double Default { get; set; }
    }

    /// <summary>Structural drafting member definition. NOT a design object.</summary>
    public sealed class MemberDef
    {
        public int No { get; set; }
        public string Code { get; set; } = "";
        public string Name { get; set; } = "";
        public string Shape { get; set; } = "RECT";
        public string Layer { get; set; } = "";
        public string TextLayer { get; set; } = "";
        public string DimLayer { get; set; } = "S-DIMS";
        public string? Hatch { get; set; }
        public List<MemberParameter> Parameters { get; set; } = new();
        public string Schedule { get; set; } = "NONE";
        public string MarkPrefix { get; set; } = "";
        public string ConcreteGradeDefault { get; set; } = "C25";
        public List<string> RebarFields { get; set; } = new();
        public string DimensionBehavior { get; set; } = "NONE";
        public string Block { get; set; } = "";

        public double Param(string name, double fallback = 0)
        {
            foreach (var p in Parameters)
                if (string.Equals(p.Name, name, System.StringComparison.OrdinalIgnoreCase)) return p.Default;
            return fallback;
        }
    }

    public sealed class MemberFile
    {
        public string Schema { get; set; } = "";
        public string Disclaimer { get; set; } = "";
        public List<MemberDef> Members { get; set; } = new();
    }

    public sealed class HatchDef
    {
        public string Name { get; set; } = "";
        public string Category { get; set; } = "";
        public string Pattern { get; set; } = "";
        public bool Custom { get; set; }
        public double Scale { get; set; } = 1;
        public double Angle { get; set; }
        public string ColorId { get; set; } = "";
        public int[] Rgb { get; set; } = new int[3];
        public int Transparency { get; set; }
        public string LayerHint { get; set; } = "A-HATCH";
        public string? PatFile { get; set; }
        /// <summary>User-created entries are editable/deletable; built-ins are not.</summary>
        public bool UserDefined { get; set; }
        public bool Favorite { get; set; }
    }

    public sealed class HatchFile
    {
        public string Schema { get; set; } = "";
        public List<HatchDef> Hatches { get; set; } = new();
    }

    public sealed class BlockParameter
    {
        public string Name { get; set; } = "";
        public string Action { get; set; } = "";
        public string Values { get; set; } = "";
    }

    public sealed class BlockDef
    {
        public string Name { get; set; } = "";
        public string Category { get; set; } = "";
        public string Layer { get; set; } = "0";
        public bool Dynamic { get; set; }
        public List<BlockParameter> Parameters { get; set; } = new();
        public string Source { get; set; } = "";
    }

    public sealed class BlockFile
    {
        public string Schema { get; set; } = "";
        public List<BlockDef> Blocks { get; set; } = new();
    }

    public sealed class TextStyleDef
    {
        public string Name { get; set; } = "";
        public string Font { get; set; } = "arial.ttf";
        public double Height { get; set; }
        public double WidthFactor { get; set; } = 1;
        public bool Annotative { get; set; } = true;
        public double PaperHeight { get; set; } = 2.5;
    }

    public sealed class DimStyleDef
    {
        public string Name { get; set; } = "";
        public string TextStyle { get; set; } = "RNR_TEXT";
        public double TextHeight { get; set; } = 2.5;
        public string Arrow { get; set; } = "";
        public double ArrowSize { get; set; } = 1.5;
        public double ExtOffset { get; set; } = 1.5;
        public double ExtBeyond { get; set; } = 1.25;
        public int Decimals { get; set; }
        public string Layer { get; set; } = "ANNO-DIMS";
    }

    public sealed class MLeaderStyleDef
    {
        public string Name { get; set; } = "";
        public string TextStyle { get; set; } = "RNR_TEXT";
        public double TextHeight { get; set; } = 2.5;
        public double ArrowSize { get; set; } = 2;
        public double LandingGap { get; set; } = 1;
    }

    public sealed class StylesFile
    {
        public string Schema { get; set; } = "";
        public List<TextStyleDef> TextStyles { get; set; } = new();
        public List<DimStyleDef> DimStyles { get; set; } = new();
        public List<MLeaderStyleDef> MleaderStyles { get; set; } = new();
        public List<string> AnnotationScales { get; set; } = new();
        public Dictionary<string, double[]> Sheets { get; set; } = new();
        public List<string> TitleBlocks { get; set; } = new();
        public List<string> TitleFields { get; set; } = new();
    }

    public sealed class BarDef
    {
        public string Mark { get; set; } = "";
        public int Diameter { get; set; }
        /// <summary>kg per metre.</summary>
        public double UnitWeight { get; set; }
    }

    public sealed class ShapeCodeDef
    {
        public string Code { get; set; } = "";
        public string Description { get; set; } = "";
        public string Formula { get; set; } = "";
    }

    public sealed class RebarFile
    {
        public string Schema { get; set; } = "";
        public string Note { get; set; } = "";
        public List<BarDef> Bars { get; set; } = new();
        public List<ShapeCodeDef> ShapeCodes { get; set; } = new();
    }

    public sealed class ProjectUnits
    {
        public string Length { get; set; } = "mm";
        public string Area { get; set; } = "m2";
        public string Volume { get; set; } = "m3";
        public string Force { get; set; } = "kN";
        public string Stress { get; set; } = "MPa";
        public string Mass { get; set; } = "kg";
    }

    public sealed class ProjectStandards
    {
        public List<string> References { get; set; } = new();
        public string Note { get; set; } = "";
    }

    /// <summary>Engineering inputs. Nullable on purpose: nothing is assumed.</summary>
    public sealed class EngineeringPrefs
    {
        public string ConcreteGrade { get; set; } = "C25";
        public double? FckMPa { get; set; }
        public double? FyMPa { get; set; }
        public double? ClearCoverSlabMm { get; set; }
        public double? ClearCoverBeamMm { get; set; }
        public double? ClearCoverColumnMm { get; set; }
        public double? ClearCoverFootingMm { get; set; }
        public double? LapFactorD { get; set; }
        public double? AnchorageFactorD { get; set; }
        public string Comment { get; set; } = "";
    }

    public sealed class PlotPrefs
    {
        public string ColorCtb { get; set; } = "acad.ctb";
        public string MonoCtb { get; set; } = "monochrome.ctb";
        public string GrayCtb { get; set; } = "grayscale.ctb";
        public string Device { get; set; } = "DWG To PDF.pc3";
    }

    public sealed class BoqPrefs
    {
        public List<string> AreaUnits { get; set; } = new();
        public List<string> VolumeUnits { get; set; } = new();
        public List<string> LengthUnits { get; set; } = new();
        public List<string> MassUnits { get; set; } = new();
    }

    /// <summary>RooMNRooF_Project.json</summary>
    public sealed class ProjectConfig
    {
        public string Schema { get; set; } = "RooMNRooF.Project/1.0";
        public string ProjectName { get; set; } = "New Project";
        public string Client { get; set; } = "";
        public string Consultant { get; set; } = "";
        public string Location { get; set; } = "";
        public ProjectUnits Units { get; set; } = new();
        public ProjectStandards Standards { get; set; } = new();
        public string ColorTheme { get; set; } = "RNR_DEFAULT";
        public string LayerStandard { get; set; } = "RNR_Layers.json";
        public string TextStandard { get; set; } = "RNR_TEXT";
        public string DimensionStandard { get; set; } = "RNR_STRUCT";
        public string TitleBlock { get; set; } = "STRUCTURAL";
        public string SheetSize { get; set; } = "A1";
        public string DrawingScale { get; set; } = "1:100";
        public EngineeringPrefs Engineering { get; set; } = new();
        public BoqPrefs Boq { get; set; } = new();
        public PlotPrefs Plot { get; set; } = new();

        /// <summary>Scale denominator of <see cref="DrawingScale"/> ("1:100" -> 100).</summary>
        [JsonIgnore]
        public double ScaleFactor
        {
            get
            {
                var parts = DrawingScale.Split(':');
                return parts.Length == 2 && double.TryParse(parts[1], System.Globalization.NumberStyles.Float,
                    System.Globalization.CultureInfo.InvariantCulture, out var d) && d > 0
                    ? d / (double.TryParse(parts[0], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var n) && n > 0 ? n : 1)
                    : 100;
            }
        }
    }
}
