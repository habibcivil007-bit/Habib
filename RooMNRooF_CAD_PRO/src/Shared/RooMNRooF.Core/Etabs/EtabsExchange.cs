using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Schedules;

namespace RooMNRooF.Core.Etabs
{
    /// <summary>
    /// Neutral exchange model for a FUTURE ETABS link. No ETABS API is called or claimed.
    /// Export this JSON and map it with a separate tool (e.g. the CSI OAPI) when available.
    /// </summary>
    public sealed class ExchangeModel
    {
        public string Schema { get; set; } = "RooMNRooF.Exchange/1.0";
        public string Units { get; set; } = "mm";
        public List<ExGrid> Grids { get; set; } = new();
        public List<ExStory> Stories { get; set; } = new();
        public List<ExFrame> Columns { get; set; } = new();
        public List<ExFrame> Beams { get; set; } = new();
        public List<ExArea> Slabs { get; set; } = new();
        public List<ExArea> Walls { get; set; } = new();
        public List<ExArea> Foundations { get; set; } = new();
        public string Note { get; set; } = "CAD drafting data - not an analysis model. Sections/materials must be defined in the analysis software.";
    }
    public sealed class ExGrid { public string Label { get; set; } = ""; public string Axis { get; set; } = "X"; public double Ordinate { get; set; } }
    public sealed class ExStory { public string Name { get; set; } = ""; public double Elevation { get; set; } public double Height { get; set; } }
    public sealed class ExFrame
    {
        public string Mark { get; set; } = ""; public string Section { get; set; } = ""; public string Material { get; set; } = "";
        public double[] Start { get; set; } = new double[2]; public double[] End { get; set; } = new double[2]; public string Story { get; set; } = "";
    }
    public sealed class ExArea
    {
        public string Mark { get; set; } = ""; public double Thickness { get; set; } public string Material { get; set; } = "";
        public List<double[]> Boundary { get; set; } = new(); public string Story { get; set; } = "";
    }

    public interface IStructuralExchange
    {
        void Export(ExchangeModel model, string path);
        ExchangeModel Import(string path);
    }

    public sealed class JsonStructuralExchange : IStructuralExchange
    {
        public void Export(ExchangeModel model, string path) => File.WriteAllText(path, JsonSerializer.Serialize(model, StandardsRepository.Json));
        public ExchangeModel Import(string path) => JsonSerializer.Deserialize<ExchangeModel>(File.ReadAllText(path), StandardsRepository.Json) ?? new ExchangeModel();

        public static string SectionName(DraftedMember m) => $"{m.Code}_{m.SizeText()}";
    }
}
