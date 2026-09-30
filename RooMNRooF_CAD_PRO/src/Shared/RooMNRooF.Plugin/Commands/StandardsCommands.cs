using System;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Logging;
using RooMNRooF.Core.Units;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: CommandClass(typeof(RooMNRooF.Plugin.Commands.StandardsCommands))]

namespace RooMNRooF.Plugin.Commands
{
    /// <summary>Home, layers, colours, styles, units, templates, QA, standards checker, cleanup.</summary>
    public class StandardsCommands
    {
        [CommandMethod("RNR", "RNR", CommandFlags.Modal)]
        public void Home() => Rnr.RunNoTx("RNR", doc =>
        {
            var ed = doc.Editor;
            ed.WriteMessage($"\n==== RooMNRooF CAD PRO ULTIMATE {typeof(Rnr).Assembly.GetName().Version} ====");
            ed.WriteMessage($"\nResources: {Rnr.ResourceRoot}");
            ed.WriteMessage($"\nStandards: {Rnr.Repo.Colors.Colors.Count} colours, {Rnr.Repo.Layers.Layers.Count} layers, {Rnr.Repo.Members.Members.Count} members, {Rnr.Repo.Hatches.Hatches.Count} materials");
            ed.WriteMessage($"\nProject:   {Rnr.Project.ProjectName} ({Rnr.Project.DrawingScale}, {Rnr.Project.SheetSize})");
            ed.WriteMessage("\nSTANDARDS : RNRLAYERS RNRLA RNRARCH RNRSTRUCT RNRCIVIL RNRRCC RNRANNO RNRCOLOR RNRSTYLES RNRUNITS RNRTEMPLATE");
            ed.WriteMessage("\nRCC       : RNRGRID RNRCOLUMN RNRBEAM RNRSLAB RNRFOOTING RNRPILE RNRPILECAP RNRRAFT RNRSWALL RNRSTAIR RNRRAMP RNRROOF RNRMEMBER");
            ed.WriteMessage("\nREBAR     : RNRREBAR RNRSTIRRUP RNRREBARNOTE RNRSCHEDULE RNRBBS");
            ed.WriteMessage("\nARCH      : RNRWALL RNRDOOR RNRWINDOW RNRROOM RNRFURN RNRCEILING RNRFLOOR");
            ed.WriteMessage("\nMATERIALS : RNRHATCH RNRMATLIB RNRMATAPPLY RNRMATPREVIEW RNRMATLEGEND");
            ed.WriteMessage("\nANNOTATE  : RNRTAG RNRLEVEL RNRSECTIONMARK RNRDETAILMARK RNRELEVMARK RNRNORTH RNRLEADER RNRBLOCKS");
            ed.WriteMessage("\nSHEETS    : RNRLAYOUT RNRTITLE RNRPLOTCOLOR RNRPLOTBW RNRPLOTGRAY RNRPREVIEW");
            ed.WriteMessage("\nDATA      : RNRBOQ RNRETABS RNRPROJECT RNRAUDIT RNRDXFOUT");
            ed.WriteMessage("\nQA        : RNRQA RNRSTANDARD RNRCLEAN RNRLOG   |  UI: RNRPANEL");
            ed.WriteMessage("\nNOTE: Drafting automation only. Engineering design must be verified by the responsible engineer.");
        });

        // ------------------------------------------------------------------ layers
        [CommandMethod("RNR", "RNRLAYERS", CommandFlags.Modal)]
        public void Layers() => Rnr.Run("RNRLAYERS", (doc, tr) =>
        {
            var filter = Prompts.Keyword(doc.Editor, "Create/update layers for [ALL/ARCHITECTURE/STRUCTURE/CIVIL/MEP/ANNOTATION/REFERENCE]", "ALL",
                "ALL", "ARCHITECTURE", "STRUCTURE", "CIVIL", "MEP", "ANNOTATION", "REFERENCE");
            bool update = Prompts.YesNo(doc.Editor, "Reset properties of EXISTING standard layers to the standard?", false);
            var (c, u) = LayerService.ApplyStandard(doc.Database, tr, filter, update);
            int f = LayerService.CreateLayerFilters(doc.Database);
            Rnr.Msg($"{c} layer(s) created, {u} updated, {f} layer filter(s) added.");
            Rnr.Done();
        });

        [CommandMethod("RNR", "RNRLA", CommandFlags.Modal)]
        public void LayerAudit() => Rnr.Run("RNRLA", (doc, tr) =>
        {
            var issues = LayerService.Audit(doc.Database, tr);
            if (issues.Count == 0) { Rnr.Msg("Layer audit: all layers match the RooMNRooF standard."); return; }
            foreach (var (layer, issue, isError) in issues) doc.Editor.WriteMessage($"\n  [{(isError ? "ERROR" : "WARNING")}] {layer}: {issue}");
            Rnr.Msg($"{issues.Count} deviation(s). Run RNRLAYERS (reset = Yes) to fix standard layers.");
        }, modifiesDb: false);

        void Isolate(string cmd, string filter) => Rnr.Run(cmd, (doc, tr) =>
        {
            var mode = Prompts.Keyword(doc.Editor, $"{filter} layers [Isolate/Thaw all]", "Isolate", "Isolate", "Thaw");
            int n = LayerService.SetFrozenByFilter(doc.Database, tr, filter, mode == "Isolate");
            Rnr.Msg($"{n} layer(s) changed ({(mode == "Isolate" ? $"only {filter} visible" : "all thawed")}).");
            doc.Editor.Regen();
        });

        [CommandMethod("RNR", "RNRARCH", CommandFlags.Modal)] public void Arch() => Isolate("RNRARCH", "ARCHITECTURE");
        [CommandMethod("RNR", "RNRSTRUCT", CommandFlags.Modal)] public void Struct() => Isolate("RNRSTRUCT", "STRUCTURE");
        [CommandMethod("RNR", "RNRCIVIL", CommandFlags.Modal)] public void Civil() => Isolate("RNRCIVIL", "CIVIL");
        [CommandMethod("RNR", "RNRRCC", CommandFlags.Modal)] public void Rcc() => Isolate("RNRRCC", "RCC");
        [CommandMethod("RNR", "RNRANNO", CommandFlags.Modal)] public void Anno() => Isolate("RNRANNO", "ANNOTATION");
        [CommandMethod("RNR", "RNRMEP", CommandFlags.Modal)] public void Mep() => Isolate("RNRMEP", "MEP");

        // ------------------------------------------------------------------ colours
        [CommandMethod("RNR", "RNRCOLOR", CommandFlags.Modal)]
        public void Color() => Rnr.Run("RNRCOLOR", (doc, tr) =>
        {
            var ed = doc.Editor;
            var op = Prompts.Keyword(ed, "Color manager [List/Apply/Export/Import/Restore/Browser]", "List", "List", "Apply", "Export", "Import", "Restore", "Browser");
            switch (op)
            {
                case "List":
                    foreach (var g in Rnr.Repo.Colors.Colors.GroupBy(c => c.Category))
                    {
                        ed.WriteMessage($"\n--- {g.Key} ---");
                        foreach (var c in g) ed.WriteMessage($"\n  {c.Id,-28} {c.Hex}  RGB {c.Rgb[0],3},{c.Rgb[1],3},{c.Rgb[2],3}  ACI {c.Aci,3}  LW {c.Lineweight:0.00}  T{c.Transparency,2}%  plot {c.Plot}");
                    }
                    break;
                case "Apply":
                    var (cr, up) = LayerService.ApplyStandard(doc.Database, tr, "ALL", updateExisting: true);
                    Rnr.Msg($"Palette applied: {up} layer(s) updated, {cr} created.");
                    break;
                case "Export":
                    var ex = Prompts.Text(ed, "Export palette to", Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "RNR_Palette.json"));
                    LayerService.ExportPalette(ex); Rnr.Msg($"Palette exported: {ex}");
                    break;
                case "Import":
                    var im = Prompts.Text(ed, "Palette JSON to import", "");
                    if (!File.Exists(im)) throw new RnrInputException($"File not found: {im}");
                    Rnr.Msg($"{LayerService.ImportPalette(im)} colour(s) imported into user standards. Run RNRCOLOR > Apply to update the drawing.");
                    break;
                case "Restore":
                    if (Prompts.YesNo(ed, "Restore RooMNRooF default palette (user palette is backed up)?", false))
                    { LayerService.RestoreDefaults(); Rnr.Msg("Defaults restored. Run RNRCOLOR > Apply to update the drawing."); }
                    break;
                case "Browser":
                    UI.PanelHost.ShowColorBrowser();
                    break;
            }
        });

        [CommandMethod("RNR", "RNRSTYLES", CommandFlags.Modal)]
        public void Styles() => Rnr.Run("RNRSTYLES", (doc, tr) =>
        {
            StyleService.ApplyAll(doc.Database, tr);
            Rnr.Msg("Text styles, dimension styles, multileader style, linetypes and annotation scales applied.");
            Rnr.Done();
        });

        // ------------------------------------------------------------------ units
        [CommandMethod("RNR", "RNRUNITS", CommandFlags.Modal)]
        public void Units() => Rnr.Run("RNRUNITS", (doc, tr) =>
        {
            var ed = doc.Editor;
            var db = doc.Database;
            var cur = UnitConverter.FromInsUnits((int)db.Insunits);
            ed.WriteMessage($"\nDrawing INSUNITS = {db.Insunits} ({(cur?.ToString() ?? "unitless/other")}), MEASUREMENT = {db.Measurement}");
            var op = Prompts.Keyword(ed, "Units [Convert/FtIn/SetMetric]", "Convert", "Convert", "FtIn", "SetMetric");
            if (op == "Convert")
            {
                var v = (decimal)Prompts.Double(ed, "Value", 1000, true, true);
                var from = UnitConverter.Parse(Prompts.Keyword(ed, "From [mm/cm/m/in/ft]", "mm", "mm", "cm", "m", "in", "ft"));
                foreach (LengthUnit u in Enum.GetValues(typeof(LengthUnit)))
                    ed.WriteMessage($"\n  {UnitConverter.Convert(v, from, u):0.######} {u}");
                ed.WriteMessage($"\n  {UnitConverter.ToFeetInches(UnitConverter.Convert(v, from, LengthUnit.Millimeter), 16)} (ft-in, 1/16\")");
            }
            else if (op == "FtIn")
            {
                var s = Prompts.Text(ed, "Feet-inch value (e.g. 10'-6 1/2\")", "10'-0\"");
                ed.WriteMessage($"\n  = {UnitConverter.ParseFeetInches(s):0.###} mm");
            }
            else
            {
                // explicit, confirmed change of drawing unit settings only - geometry is NEVER scaled
                if (Prompts.YesNo(ed, "Set INSUNITS=mm, LUNITS=decimal, MEASUREMENT=metric? (geometry is NOT scaled)", false))
                { StyleService.SetMetricUnits(db); Rnr.Msg("Metric unit settings applied. Existing geometry unchanged."); }
            }
        });

        // ------------------------------------------------------------------ templates
        [CommandMethod("RNR", "RNRTEMPLATE", CommandFlags.Session)]
        public void Template() => Rnr.RunNoTx("RNRTEMPLATE", doc =>
        {
            var ed = doc.Editor;
            var op = Prompts.Keyword(ed, "Template [New/Save/Apply/All/Import/Export/Reset]", "New", "New", "Save", "Apply", "All", "Import", "Export", "Reset");
            string kind() => Prompts.Keyword(ed, "Kind [MASTER/ARCHITECTURAL/STRUCTURAL/RCC/CIVIL/SITE/MEP]", "MASTER", TemplateService.Kinds.Keys.ToArray());
            string userTpl = Path.Combine(Rnr.UserDir, "Templates");
            switch (op)
            {
                case "All":
                    foreach (var k in TemplateService.Kinds.Keys)
                        ed.WriteMessage($"\n  created {TemplateService.Create(k, userTpl, Prompts.YesNo(ed, $"Overwrite {k} if it exists?", false))}");
                    Rnr.Done();
                    break;
                case "Save":
                    {
                        var k = kind();
                        var path = TemplateService.Create(k, userTpl, Prompts.YesNo(ed, "Overwrite if exists?", false));
                        Rnr.Msg($"Template saved: {path}");
                        break;
                    }
                case "New":
                    {
                        var k = kind();
                        var path = Path.Combine(userTpl, TemplateService.FileName(k));
                        if (!File.Exists(path)) path = TemplateService.Create(k, userTpl, false);
                        var newDoc = AcApp.DocumentManager.Add(path);
                        AcApp.DocumentManager.MdiActiveDocument = newDoc;
                        Rnr.Msg($"New drawing from {Path.GetFileName(path)}.");
                        break;
                    }
                case "Apply":
                    {
                        var k = kind();
                        using (doc.LockDocument())
                        using (var tr = doc.Database.TransactionManager.StartTransaction())
                        { TemplateService.ApplyStandards(doc.Database, tr, k); tr.Commit(); }
                        Rnr.Msg($"{k} standards applied to current drawing (no geometry changed).");
                        break;
                    }
                case "Import":
                    {
                        var src = Prompts.Text(ed, "DWT file to import into user templates", "");
                        if (!File.Exists(src) || !src.EndsWith(".dwt", StringComparison.OrdinalIgnoreCase)) throw new RnrInputException("Select an existing .dwt file.");
                        Directory.CreateDirectory(userTpl);
                        var dst = Path.Combine(userTpl, Path.GetFileName(src));
                        if (File.Exists(dst) && !Prompts.YesNo(ed, $"{Path.GetFileName(dst)} exists. Overwrite (backup kept)?", false)) throw new RnrCancelled();
                        if (File.Exists(dst)) File.Copy(dst, dst + ".bak", true);
                        File.Copy(src, dst, true);
                        Rnr.Msg($"Imported {dst}");
                        break;
                    }
                case "Export":
                    {
                        var k = kind();
                        var src = Path.Combine(userTpl, TemplateService.FileName(k));
                        if (!File.Exists(src)) throw new RnrInputException("Template not generated yet (RNRTEMPLATE > Save).");
                        var dst = Prompts.Text(ed, "Export to folder", Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments));
                        var target = Path.Combine(dst, Path.GetFileName(src));
                        if (File.Exists(target)) throw new RnrInputException($"{target} already exists - not overwritten.");
                        File.Copy(src, target);
                        Rnr.Msg($"Exported {target}");
                        break;
                    }
                case "Reset":
                    {
                        var k = kind();
                        var path = TemplateService.Create(k, userTpl, overwrite: true);
                        Rnr.Msg($"{k} template regenerated from standards (previous copy backed up): {path}");
                        break;
                    }
            }
        });

        // ------------------------------------------------------------------ QA / standards
        [CommandMethod("RNR", "RNRQA", CommandFlags.Modal)]
        public void Qa() => Rnr.Run("RNRQA", (doc, tr) =>
        {
            var report = QaService.Run(doc.Database, tr, doc.Name);
            var text = report.ToText();
            doc.Editor.WriteMessage("\n" + text);
            var dir = Path.Combine(Rnr.UserDir, "QA");
            Directory.CreateDirectory(dir);
            var file = Path.Combine(dir, $"QA_{Path.GetFileNameWithoutExtension(doc.Name)}_{DateTime.Now:yyyyMMdd_HHmmss}.txt");
            File.WriteAllText(file, text);
            RnrLog.Info($"QA errors={report.Errors} warnings={report.Warnings} -> {file}");
            Rnr.Msg($"QA report saved: {file}");
        }, modifiesDb: false);

        [CommandMethod("RNR", "RNRSTANDARD", CommandFlags.Modal)]
        public void Standard() => Rnr.Run("RNRSTANDARD", (doc, tr) =>
        {
            var errs = Rnr.Repo.Validate();
            doc.Editor.WriteMessage($"\nStandards files: {(errs.Count == 0 ? "PASS" : "ERROR")}");
            foreach (var e in errs.Take(50)) doc.Editor.WriteMessage($"\n  [ERROR] {e}");
            var report = QaService.Run(doc.Database, tr, doc.Name);
            doc.Editor.WriteMessage("\n" + report.ToText());
        }, modifiesDb: false);

        [CommandMethod("RNR", "RNRCLEAN", CommandFlags.Modal)]
        public void Clean() => Rnr.RunNoTx("RNRCLEAN", doc =>
        {
            var ed = doc.Editor; var db = doc.Database;
            CleanPreview p;
            using (doc.LockDocument())
            using (var tr = db.TransactionManager.StartTransaction()) { p = CleanService.Preview(db, tr); tr.Commit(); }

            ed.WriteMessage("\n==== RNRCLEAN PREVIEW (nothing deleted yet) ====");
            foreach (var g in p.Purgeable.GroupBy(x => x.kind)) ed.WriteMessage($"\n  Unused {g.Key}s ({g.Count()}): {string.Join(", ", g.Select(x => x.name).Take(15))}{(g.Count() > 15 ? " ..." : "")}");
            ed.WriteMessage($"\n  Duplicate lines/circles: {p.Duplicates.Count}");
            ed.WriteMessage($"\n  Zero-length lines: {p.ZeroLength.Count}");
            ed.WriteMessage($"\n  Empty text: {p.EmptyTextIds.Count}");
            ed.WriteMessage("\n  (Standard RooMNRooF layers/styles/blocks are always kept.)");
            if (p.Total == 0) { Rnr.Msg("Nothing to clean."); return; }

            var what = Prompts.Keyword(ed, "Delete which [Unused/Duplicates/ZeroLength/EmptyText/All/None]", "None", "Unused", "Duplicates", "ZeroLength", "EmptyText", "All", "None");
            if (what == "None") { Rnr.Msg("No changes made."); return; }
            if (!Prompts.YesNo(ed, $"Confirm deletion of '{what}' items? A backup DWG is written first.", false)) throw new RnrCancelled();

            string backup;
            using (doc.LockDocument()) backup = CleanService.Backup(db);
            Rnr.Msg($"Backup: {backup}");
            int n = 0;
            using (doc.LockDocument())
            using (var tr = db.TransactionManager.StartTransaction())
            {
                if (what is "Duplicates" or "All") n += CleanService.Erase(tr, p.Duplicates.Select(x => x.id));
                if (what is "ZeroLength" or "All") n += CleanService.Erase(tr, p.ZeroLength.Select(x => x.id));
                if (what is "EmptyText" or "All") n += CleanService.Erase(tr, p.EmptyTextIds);
                if (what is "Unused" or "All") n += CleanService.Erase(tr, p.Purgeable.Select(x => x.id));
                tr.Commit();
            }
            Rnr.Msg($"{n} item(s) removed. Use UNDO to revert.");
        });

        [CommandMethod("RNR", "RNRAUDIT", CommandFlags.Modal)]
        public void Audit() => Rnr.RunNoTx("RNRAUDIT", doc =>
        {
            var fix = Prompts.YesNo(doc.Editor, "Fix detected errors (runs AutoCAD AUDIT)?", false);
            doc.SendStringToExecute($"_.AUDIT {(fix ? "_Y" : "_N")} ", true, false, true);
        });

        [CommandMethod("RNR", "RNRLOG", CommandFlags.Modal)]
        public void Log() => Rnr.RunNoTx("RNRLOG", doc =>
        {
            var f = RnrLog.LogFile;
            if (!File.Exists(f)) { Rnr.Msg("No log yet."); return; }
            var lines = File.ReadAllLines(f);
            foreach (var l in lines.Skip(Math.Max(0, lines.Length - 30))) doc.Editor.WriteMessage("\n" + l);
            Rnr.Msg($"Log file: {f}");
        });
    }
}
