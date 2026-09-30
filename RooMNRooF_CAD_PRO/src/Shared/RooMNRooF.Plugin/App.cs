using System;
using Autodesk.AutoCAD.Runtime;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: ExtensionApplication(typeof(RooMNRooF.Plugin.App))]

namespace RooMNRooF.Plugin
{
    /// <summary>Plugin entry point. Keeps Initialize light: standards are loaded lazily on first use.</summary>
    public sealed class App : IExtensionApplication
    {
        public void Initialize()
        {
            try
            {
                RnrLog.Info($"RooMNRooF CAD PRO {typeof(App).Assembly.GetName().Version} loading in AutoCAD {AcApp.Version} from {Rnr.AssemblyDir}");
                var errors = Rnr.Repo.Validate();
                if (errors.Count > 0) RnrLog.Warn($"Standards validation: {errors.Count} issue(s): {string.Join(" | ", errors)}");
                var ed = Rnr.Ed;
                ed?.WriteMessage($"\n{Rnr.Prefix}RooMNRooF CAD PRO ULTIMATE loaded ({Rnr.Repo.Layers.Layers.Count} layers, {Rnr.Repo.Members.Members.Count} members). Type RNR for commands, RNRPANEL for the palette.");
                if (errors.Count > 0) ed?.WriteMessage($"\n{Rnr.Prefix}WARNING: standards files have {errors.Count} issue(s). Run RNRSTANDARD.");
            }
            catch (System.Exception ex)
            {
                // never let a load problem crash AutoCAD
                RnrLog.Error("Initialize failed", ex);
                try { Rnr.Ed?.WriteMessage($"\n{Rnr.Prefix}RooMNRooF failed to initialise: {ex.Message}. See {RnrLog.LogFile}"); } catch { }
            }
        }

        public void Terminate()
        {
            RnrLog.Info("RooMNRooF CAD PRO unloading");
        }
    }
}
