using System;
using System.IO;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.PlottingServices;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace RooMNRooF.Plugin.Services
{
    public enum PlotMode { Color, Monochrome, Grayscale }

    /// <summary>
    /// Plots the current layout to PDF with the chosen plot style table (CTB). Lineweights are always
    /// printed. Colourful TrueColor screen graphics become black/grey in Monochrome/Grayscale mode,
    /// so drawings remain legible (BLACK &amp; WHITE SAFETY MODE).
    /// </summary>
    public static class PlotService
    {
        public static string CtbFor(PlotMode mode) => mode switch
        {
            PlotMode.Monochrome => Rnr.Project.Plot.MonoCtb,
            PlotMode.Grayscale => Rnr.Project.Plot.GrayCtb,
            _ => Rnr.Project.Plot.ColorCtb,
        };

        public static string PlotCurrentLayoutToPdf(Document doc, PlotMode mode, string pdfPath)
        {
            if (PlotFactory.ProcessPlotState != ProcessPlotState.NotPlotting)
                throw new InvalidOperationException("Another plot is in progress.");
            var db = doc.Database;
            object oldBg = AcApp.GetSystemVariable("BACKGROUNDPLOT");
            AcApp.SetSystemVariable("BACKGROUNDPLOT", 0);
            try
            {
                using var tr = db.TransactionManager.StartTransaction();
                var layoutId = LayoutManager.Current.GetLayoutId(LayoutManager.Current.CurrentLayout);
                var layout = (Layout)tr.GetObject(layoutId, OpenMode.ForRead);

                var ps = new PlotSettings(layout.ModelType);
                ps.CopyFrom(layout);
                var psv = PlotSettingsValidator.Current;
                psv.SetPlotConfigurationName(ps, Rnr.Project.Plot.Device, null);
                psv.RefreshLists(ps);
                if (string.IsNullOrEmpty(ps.CanonicalMediaName) || layout.ModelType)
                {
                    psv.SetPlotConfigurationName(ps, Rnr.Project.Plot.Device, LayoutService.PdfMedia["A3"]);
                    if (layout.ModelType)
                    {
                        psv.SetPlotType(ps, Autodesk.AutoCAD.DatabaseServices.PlotType.Extents);
                        psv.SetUseStandardScale(ps, true);
                        psv.SetStdScaleType(ps, StdScaleType.ScaleToFit);
                        psv.SetPlotCentered(ps, true);
                    }
                }
                psv.SetCurrentStyleSheet(ps, CtbFor(mode));
                ps.PrintLineweights = true;
                ps.PlotPlotStyles = true;

                var pi = new PlotInfo { Layout = layoutId, OverrideSettings = ps };
                var piv = new PlotInfoValidator { MediaMatchingPolicy = MatchingPolicy.MatchEnabled };
                piv.Validate(pi);

                Directory.CreateDirectory(Path.GetDirectoryName(pdfPath)!);
                using (var pe = PlotFactory.CreatePublishEngine())
                using (var ppd = new PlotProgressDialog(false, 1, true))
                {
                    ppd.set_PlotMsgString(PlotMessageIndex.DialogTitle, "RooMNRooF PDF Plot");
                    ppd.set_PlotMsgString(PlotMessageIndex.SheetProgressCaption, "Plotting sheet");
                    ppd.LowerPlotProgressRange = 0; ppd.UpperPlotProgressRange = 100; ppd.PlotProgressPos = 0;
                    ppd.OnBeginPlot(); ppd.IsVisible = true;
                    pe.BeginPlot(ppd, null);
                    pe.BeginDocument(pi, doc.Name, null, 1, true, pdfPath);
                    ppd.OnBeginSheet();
                    var ppi = new PlotPageInfo();
                    pe.BeginPage(ppi, pi, true, null);
                    pe.BeginGenerateGraphics(null);
                    pe.EndGenerateGraphics(null);
                    pe.EndPage(null);
                    ppd.OnEndSheet();
                    pe.EndDocument(null);
                    ppd.PlotProgressPos = 100;
                    ppd.OnEndPlot();
                    pe.EndPlot(null);
                }
                tr.Commit();
                RnrLog.Info($"Plotted {mode} PDF: {pdfPath}");
                return pdfPath;
            }
            finally
            {
                AcApp.SetSystemVariable("BACKGROUNDPLOT", oldBg);
            }
        }

        public static string DefaultPdfPath(Document doc, PlotMode mode)
        {
            var name = doc.Database.Filename;
            var dir = !string.IsNullOrEmpty(name) && Path.IsPathRooted(name) && !name.EndsWith(".dwt", StringComparison.OrdinalIgnoreCase)
                ? Path.GetDirectoryName(name)!
                : Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            var baseName = Path.GetFileNameWithoutExtension(string.IsNullOrEmpty(name) ? "Drawing" : name);
            var file = Path.Combine(dir, $"{baseName}_{LayoutManager.Current.CurrentLayout}_{mode}.pdf");
            // never overwrite silently: add a counter
            int i = 1;
            while (File.Exists(file)) file = Path.Combine(dir, $"{baseName}_{LayoutManager.Current.CurrentLayout}_{mode}_{i++}.pdf");
            return file;
        }
    }
}
