using System;
using System.IO;
using System.Reflection;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Logging;
using RooMNRooF.Core.Models;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace RooMNRooF.Plugin.Core
{
    /// <summary>Thrown by prompt helpers when the user presses ESC / cancels.</summary>
    public sealed class RnrCancelled : Exception { public RnrCancelled() : base("Operation cancelled.") { } }

    /// <summary>User-facing validation error (message shown as "[RNR] Invalid input. ...").</summary>
    public sealed class RnrInputException : Exception { public RnrInputException(string m) : base(m) { } }

    /// <summary>
    /// Global plugin context: install paths, standards repository, project configuration,
    /// and the safe command execution wrapper used by EVERY command.
    /// </summary>
    public static class Rnr
    {
        public const string Prefix = "[RNR] ";
        static StandardsRepository? _repo;
        static ProjectConfig? _project;

        /// <summary>Folder containing RooMNRooF.CAD.dll (bundle: ...\Contents\Win64).</summary>
        public static string AssemblyDir => Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? ".";

        /// <summary>Resource root: walks up from the DLL looking for a Standards folder (bundle or MSI layout).</summary>
        public static string ResourceRoot
        {
            get
            {
                var dir = new DirectoryInfo(AssemblyDir);
                for (int i = 0; i < 4 && dir != null; i++, dir = dir.Parent)
                    if (Directory.Exists(Path.Combine(dir.FullName, "Standards"))) return dir.FullName;
                return AssemblyDir;
            }
        }

        public static string StandardsDir => Path.Combine(ResourceRoot, "Standards");
        public static string HatchDir => Path.Combine(ResourceRoot, "Hatch");
        public static string TemplatesDir => Path.Combine(ResourceRoot, "Templates");
        public static string UserDir => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "RooMNRooF");

        public static StandardsRepository Repo
        {
            get
            {
                if (_repo == null) _repo = new StandardsRepository(StandardsDir, Path.Combine(UserDir, "Standards")).Load();
                return _repo;
            }
        }

        public static void ReloadStandards() { _repo = null; _ = Repo; }

        /// <summary>
        /// Project config: RooMNRooF_Project.json next to the current drawing if present,
        /// else the user copy, else the installed default. Never auto-written next to drawings.
        /// </summary>
        public static ProjectConfig Project
        {
            get
            {
                var local = ProjectFileForActiveDrawing();
                if (local != null && File.Exists(local)) return StandardsRepository.LoadFile<ProjectConfig>(local);
                if (_project != null) return _project;
                var user = Path.Combine(UserDir, "RooMNRooF_Project.json");
                _project = StandardsRepository.LoadFile<ProjectConfig>(File.Exists(user) ? user : Path.Combine(StandardsDir, "RooMNRooF_Project.json"));
                return _project;
            }
        }

        public static void ResetProjectCache() => _project = null;

        public static string? ProjectFileForActiveDrawing()
        {
            var doc = AcApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return null;
            var name = doc.Database.Filename;
            if (string.IsNullOrEmpty(name) || !Path.IsPathRooted(name)) return null;
            var dir = Path.GetDirectoryName(name);
            return dir == null ? null : Path.Combine(dir, "RooMNRooF_Project.json");
        }

        public static Document? Doc => AcApp.DocumentManager.MdiActiveDocument;
        public static Editor? Ed => Doc?.Editor;

        public static void Msg(string text) => Ed?.WriteMessage("\n" + Prefix + text);

        /// <summary>
        /// Runs a command body with: document lock, one outer transaction (committed only on success),
        /// undo grouping, cancel handling, logging and a catch-all so AutoCAD never sees an unhandled exception.
        /// </summary>
        public static void Run(string command, Action<Document, Transaction> body, bool modifiesDb = true)
        {
            var doc = Doc;
            if (doc == null) { RnrLog.Warn($"{command}: no active document"); return; }
            var ed = doc.Editor;
            RnrLog.Command(command, "start");
            try
            {
                using (modifiesDb ? doc.LockDocument() : null)
                {
                    using var tr = doc.Database.TransactionManager.StartTransaction();
                    body(doc, tr);
                    tr.Commit();
                }
                RnrLog.Command(command, "ok");
            }
            catch (RnrCancelled)
            {
                ed.WriteMessage("\n" + Prefix + "Operation cancelled.");
                RnrLog.Command(command, "cancelled");
            }
            catch (RnrInputException ex)
            {
                ed.WriteMessage("\n" + Prefix + "Invalid input. " + ex.Message);
                RnrLog.Command(command, "invalid input: " + ex.Message);
            }
            catch (Autodesk.AutoCAD.Runtime.Exception ex)
            {
                ed.WriteMessage($"\n{Prefix}AutoCAD error in {command}: {ex.ErrorStatus} - {ex.Message}");
                RnrLog.Error($"{command} AutoCAD error {ex.ErrorStatus}", ex);
            }
            catch (System.Exception ex)
            {
                ed.WriteMessage($"\n{Prefix}Error in {command}: {ex.Message}  (details in {RnrLog.LogFile})");
                RnrLog.Error($"{command} failed", ex);
            }
        }

        /// <summary>Same safety wrapper for commands that do not need a transaction (file/UI operations).</summary>
        public static void RunNoTx(string command, Action<Document> body)
        {
            var doc = Doc;
            if (doc == null) return;
            RnrLog.Command(command, "start");
            try { body(doc); RnrLog.Command(command, "ok"); }
            catch (RnrCancelled) { doc.Editor.WriteMessage("\n" + Prefix + "Operation cancelled."); RnrLog.Command(command, "cancelled"); }
            catch (RnrInputException ex) { doc.Editor.WriteMessage("\n" + Prefix + "Invalid input. " + ex.Message); }
            catch (System.Exception ex)
            {
                doc.Editor.WriteMessage($"\n{Prefix}Error in {command}: {ex.Message}");
                RnrLog.Error($"{command} failed", ex);
            }
        }

        public static void Done() => Msg("Command completed successfully.");
    }
}
