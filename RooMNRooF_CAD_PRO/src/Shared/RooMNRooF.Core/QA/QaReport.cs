using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RooMNRooF.Core.QA
{
    /// <summary>NOT_CHECKED is used whenever a check could not actually run - never PASS by default.</summary>
    public enum QaStatus { PASS, WARNING, ERROR, NOT_CHECKED }

    public sealed class QaFinding
    {
        public string Category { get; set; } = "";
        public QaStatus Status { get; set; }
        public string Message { get; set; } = "";
        public string? Handle { get; set; }
    }

    public sealed class QaReport
    {
        public static readonly string[] Categories =
        {
            "Layers", "Linetypes", "Colors", "Lineweights", "Text Styles", "Dimensions", "Blocks", "Hatches",
            "Units", "Layouts", "Title Block", "Annotation", "Plot Configuration",
        };

        public string AutoCadVersion { get; set; } = "";
        public string Template { get; set; } = "";
        public string Drawing { get; set; } = "";
        public DateTime Timestamp { get; set; } = DateTime.Now;
        public List<QaFinding> Findings { get; } = new();
        readonly HashSet<string> _checked = new(StringComparer.OrdinalIgnoreCase);

        /// <summary>Record that a category's check actually executed (even with zero findings).</summary>
        public void MarkChecked(string category) => _checked.Add(category);

        public void Add(string category, QaStatus status, string message, string? handle = null)
        {
            _checked.Add(category);
            Findings.Add(new QaFinding { Category = category, Status = status, Message = message, Handle = handle });
        }

        public QaStatus StatusOf(string category)
        {
            if (!_checked.Contains(category)) return QaStatus.NOT_CHECKED;
            var f = Findings.Where(x => x.Category.Equals(category, StringComparison.OrdinalIgnoreCase)).ToList();
            if (f.Any(x => x.Status == QaStatus.ERROR)) return QaStatus.ERROR;
            if (f.Any(x => x.Status == QaStatus.WARNING)) return QaStatus.WARNING;
            return QaStatus.PASS;
        }

        public int Errors => Findings.Count(f => f.Status == QaStatus.ERROR);
        public int Warnings => Findings.Count(f => f.Status == QaStatus.WARNING);
        public int NotChecked => Categories.Count(c => StatusOf(c) == QaStatus.NOT_CHECKED);

        public string ToText()
        {
            var sb = new StringBuilder();
            var bar = new string('=', 45);
            sb.AppendLine(bar).AppendLine("RooMNRooF CAD QA REPORT").AppendLine(bar);
            sb.AppendLine($"AutoCAD Version: {AutoCadVersion}");
            sb.AppendLine($"Drawing:  {Drawing}");
            sb.AppendLine($"Template: {Template}");
            sb.AppendLine($"Date:     {Timestamp:yyyy-MM-dd HH:mm}");
            sb.AppendLine();
            foreach (var c in Categories) sb.AppendLine($"{c,-22}{StatusOf(c)}");
            sb.AppendLine();
            sb.AppendLine($"Errors: {Errors}");
            sb.AppendLine($"Warnings: {Warnings}");
            sb.AppendLine($"Not checked: {NotChecked}");
            sb.AppendLine(bar);
            if (Findings.Count > 0)
            {
                sb.AppendLine("DETAILS");
                foreach (var f in Findings.Where(f => f.Status != QaStatus.PASS))
                    sb.AppendLine($"[{f.Status}] {f.Category}: {f.Message}{(f.Handle != null ? $" (handle {f.Handle})" : "")}");
                sb.AppendLine(bar);
            }
            return sb.ToString();
        }
    }
}
