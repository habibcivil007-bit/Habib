using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security;
using System.Text;
using System.Text.Json;
using RooMNRooF.Core.Configuration;

namespace RooMNRooF.Core.Export
{
    /// <summary>Tabular data: header row + string/number cells. Numbers are written as numbers in XLSX.</summary>
    public sealed class DataSheet
    {
        public string Name { get; set; } = "Sheet1";
        public List<string> Headers { get; set; } = new();
        public List<object?[]> Rows { get; set; } = new();
        public List<string> Notes { get; set; } = new();
    }

    public static class CsvExporter
    {
        public static string ToCsv(DataSheet sheet)
        {
            var sb = new StringBuilder();
            foreach (var n in sheet.Notes) sb.Append("# ").AppendLine(n);
            sb.AppendLine(string.Join(",", sheet.Headers.Select(Esc)));
            foreach (var r in sheet.Rows) sb.AppendLine(string.Join(",", r.Select(c => Esc(Cell(c)))));
            return sb.ToString();
        }

        public static void Write(string path, DataSheet sheet) => File.WriteAllText(path, ToCsv(sheet), new UTF8Encoding(true));

        internal static string Cell(object? c) => c switch
        {
            null => "",
            double d => d.ToString("0.###", CultureInfo.InvariantCulture),
            float f => f.ToString("0.###", CultureInfo.InvariantCulture),
            decimal m => m.ToString("0.###", CultureInfo.InvariantCulture),
            IFormattable fm => fm.ToString(null, CultureInfo.InvariantCulture),
            _ => c.ToString() ?? "",
        };

        static string Esc(string s) => s.IndexOfAny(new[] { ',', '"', '\n', '\r' }) >= 0 ? "\"" + s.Replace("\"", "\"\"") + "\"" : s;
    }

    public static class JsonExporter
    {
        public static void Write<T>(string path, T data) => File.WriteAllText(path, JsonSerializer.Serialize(data, StandardsRepository.Json));
    }

    /// <summary>
    /// Minimal, dependency-free Office Open XML (.xlsx) writer. Produces a valid workbook
    /// (inline strings, numeric cells, bold header via a single cell style).
    /// </summary>
    public static class XlsxExporter
    {
        public static void Write(string path, params DataSheet[] sheets)
        {
            if (sheets.Length == 0) throw new ArgumentException("At least one sheet required");
            if (File.Exists(path)) File.Delete(path);
            using var fs = new FileStream(path, FileMode.CreateNew);
            using var zip = new ZipArchive(fs, ZipArchiveMode.Create);

            Put(zip, "[Content_Types].xml",
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">" +
                "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>" +
                "<Default Extension=\"xml\" ContentType=\"application/xml\"/>" +
                "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>" +
                "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>" +
                string.Concat(sheets.Select((s, i) => $"<Override PartName=\"/xl/worksheets/sheet{i + 1}.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>")) +
                "</Types>");
            Put(zip, "_rels/.rels",
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
                "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>" +
                "</Relationships>");
            Put(zip, "xl/workbook.xml",
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\"><sheets>" +
                string.Concat(sheets.Select((s, i) => $"<sheet name=\"{X(SheetName(s.Name))}\" sheetId=\"{i + 1}\" r:id=\"rId{i + 1}\"/>")) +
                "</sheets></workbook>");
            Put(zip, "xl/_rels/workbook.xml.rels",
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
                string.Concat(sheets.Select((s, i) => $"<Relationship Id=\"rId{i + 1}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet{i + 1}.xml\"/>")) +
                $"<Relationship Id=\"rId{sheets.Length + 1}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>" +
                "</Relationships>");
            Put(zip, "xl/styles.xml",
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
                "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">" +
                "<fonts count=\"2\"><font><sz val=\"11\"/><name val=\"Calibri\"/></font><font><b/><sz val=\"11\"/><name val=\"Calibri\"/></font></fonts>" +
                "<fills count=\"2\"><fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill></fills>" +
                "<borders count=\"1\"><border><left/><right/><top/><bottom/><diagonal/></border></borders>" +
                "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>" +
                "<cellXfs count=\"2\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/><xf numFmtId=\"0\" fontId=\"1\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyFont=\"1\"/></cellXfs>" +
                "</styleSheet>");

            for (int i = 0; i < sheets.Length; i++) Put(zip, $"xl/worksheets/sheet{i + 1}.xml", SheetXml(sheets[i]));
        }

        static string SheetXml(DataSheet s)
        {
            var sb = new StringBuilder();
            sb.Append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetData>");
            int r = 1;
            foreach (var n in s.Notes) { sb.Append($"<row r=\"{r}\">").Append(Cell(0, r, n, false)).Append("</row>"); r++; }
            sb.Append($"<row r=\"{r}\">");
            for (int c = 0; c < s.Headers.Count; c++) sb.Append(Cell(c, r, s.Headers[c], true));
            sb.Append("</row>"); r++;
            foreach (var row in s.Rows)
            {
                sb.Append($"<row r=\"{r}\">");
                for (int c = 0; c < row.Length; c++) sb.Append(Cell(c, r, row[c], false));
                sb.Append("</row>"); r++;
            }
            sb.Append("</sheetData></worksheet>");
            return sb.ToString();
        }

        static string Cell(int col, int row, object? v, bool bold)
        {
            var refName = ColName(col) + row;
            var style = bold ? " s=\"1\"" : "";
            return v switch
            {
                null => $"<c r=\"{refName}\"{style}/>",
                int or long or double or float or decimal =>
                    $"<c r=\"{refName}\"{style}><v>{Convert.ToDouble(v, CultureInfo.InvariantCulture).ToString("R", CultureInfo.InvariantCulture)}</v></c>",
                _ => $"<c r=\"{refName}\"{style} t=\"inlineStr\"><is><t xml:space=\"preserve\">{X(CsvExporter.Cell(v))}</t></is></c>",
            };
        }

        public static string ColName(int index)
        {
            var s = "";
            index++;
            while (index > 0) { int m = (index - 1) % 26; s = (char)('A' + m) + s; index = (index - 1) / 26; }
            return s;
        }

        static string SheetName(string n)
        {
            foreach (var ch in new[] { ':', '\\', '/', '?', '*', '[', ']' }) n = n.Replace(ch, '_');
            return n.Length > 31 ? n.Substring(0, 31) : (n.Length == 0 ? "Sheet" : n);
        }

        static string X(string s) => SecurityElement.Escape(s) ?? "";

        static void Put(ZipArchive zip, string name, string content)
        {
            var e = zip.CreateEntry(name, CompressionLevel.Optimal);
            using var w = new StreamWriter(e.Open(), new UTF8Encoding(false));
            w.Write(content);
        }
    }
}
