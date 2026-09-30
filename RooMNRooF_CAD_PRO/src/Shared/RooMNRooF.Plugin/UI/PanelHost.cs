using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using Autodesk.AutoCAD.Windows;
using RooMNRooF.Core.Logging;
using RooMNRooF.Plugin.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;
using WpfColor = System.Windows.Media.Color;

namespace RooMNRooF.Plugin.UI
{
    /// <summary>A launcher entry. Every entry maps to a REAL registered command.</summary>
    public sealed record ToolDef(string Panel, string Command, string Label, string Glyph, string Tip);

    /// <summary>User UI state (favourites, recents, theme) in %APPDATA%\RooMNRooF\ui.json.</summary>
    public sealed class UiState
    {
        public List<string> Favorites { get; set; } = new();
        public List<string> Recent { get; set; } = new();
        public bool Dark { get; set; } = true;
        static string PathOf => System.IO.Path.Combine(Rnr.UserDir, "ui.json");
        public static UiState Load()
        {
            try { return File.Exists(PathOf) ? JsonSerializer.Deserialize<UiState>(File.ReadAllText(PathOf)) ?? new() : new(); }
            catch { return new(); }
        }
        public void Save()
        {
            try { Directory.CreateDirectory(Rnr.UserDir); File.WriteAllText(PathOf, JsonSerializer.Serialize(this)); } catch (Exception ex) { RnrLog.Warn("ui.json save failed: " + ex.Message); }
        }
    }

    /// <summary>
    /// Dockable RooMNRooF palette (AutoCAD PaletteSet hosting WPF). Built in code so there is no
    /// XAML/BAML dependency across AutoCAD versions.
    /// </summary>
    public static class PanelHost
    {
        static PaletteSet? _ps;
        static readonly UiState State = UiState.Load();

        public static readonly ToolDef[] Tools =
        {
            new("HOME", "RNR", "Command list", "⌂", "List every RooMNRooF command"),
            new("HOME", "RNRQA", "Drawing QA", "✔", "Run QA report (PASS/WARNING/ERROR)"),
            new("HOME", "RNRLOG", "Show log", "☰", "Last 30 log lines"),
            new("PROJECT", "RNRPROJECT", "Project config", "⚙", "RooMNRooF_Project.json (units, scale, engineering inputs)"),
            new("PROJECT", "RNRTEMPLATE", "Templates", "▦", "New/Save/Apply/Import/Export/Reset DWT"),
            new("PROJECT", "RNRUNITS", "Units", "⇄", "Exact mm/cm/m/in/ft/ft-in conversion"),
            new("ARCHITECTURE", "RNRWALL", "Wall", "▭", "Draw walls (new/existing/demolition)"),
            new("ARCHITECTURE", "RNRDOOR", "Door", "◜", "Parametric door by width"),
            new("ARCHITECTURE", "RNRWINDOW", "Window", "▤", "Parametric window by width/wall"),
            new("ARCHITECTURE", "RNRROOM", "Room generator", "□", "Walls + door + window + tag + area + dims"),
            new("ARCHITECTURE", "RNRFURN", "Furniture", "🛋", "Furniture/kitchen/bath/site blocks"),
            new("ARCHITECTURE", "RNRFLOOR", "Floor finish", "▩", "Floor finish hatch in picked area"),
            new("ARCHITECTURE", "RNRCEILING", "Ceiling grid", "#", "Reflected ceiling grid"),
            new("ARCHITECTURE", "RNRROOF", "Roof", "⌂", "Roof outline / roof slab / roof tank"),
            new("STRUCTURE", "RNRGRID", "Grid", "╋", "Structural grid with bubbles and dims"),
            new("STRUCTURE", "RNRCOLUMN", "Column", "■", "Rect/Square/Circular/L/T/Cross columns"),
            new("STRUCTURE", "RNRBEAM", "Beam", "═", "Pick start/end, 12 beam types"),
            new("STRUCTURE", "RNRSLAB", "Slab", "▢", "Slabs, drop panels, openings by corners"),
            new("STRUCTURE", "RNRFOOTING", "Footing", "▣", "Isolated/combined/strap/strip/wall"),
            new("STRUCTURE", "RNRPILE", "Pile", "◉", "Piles"),
            new("STRUCTURE", "RNRPILECAP", "Pile cap", "⊞", "Pile caps with pile layout"),
            new("STRUCTURE", "RNRRAFT", "Raft", "▥", "Raft by corners"),
            new("STRUCTURE", "RNRSWALL", "Wall/Core", "▮", "Shear/retaining/boundary/parapet/lift core/joints"),
            new("STRUCTURE", "RNRSTAIR", "Stair", "≣", "Dog-leg / straight stairs"),
            new("STRUCTURE", "RNRRAMP", "Ramp", "◢", "Ramps"),
            new("STRUCTURE", "RNRTANK", "Tank", "▯", "Water/underground/roof tanks"),
            new("STRUCTURE", "RNRMEMBER", "Any member (55)", "★", "Place any of the 55 member definitions"),
            new("RCC", "RNRSECTIONDETAIL", "Section detail", "⊡", "Column/beam cross-section with bars"),
            new("RCC", "RNRREBAR", "Rebar", "━", "Draw bar with call-out"),
            new("RCC", "RNRSTIRRUP", "Stirrup", "▢", "Stirrup detail"),
            new("RCC", "RNRREBARNOTE", "Rebar note", "✎", "Multileader reinforcement note"),
            new("RCC", "RNRSCHEDULE", "Schedules", "▤", "Column/beam/slab/footing/stair/rebar tables"),
            new("RCC", "RNRBBS", "BBS data", "∑", "Bar bending schedule CSV/XLSX/JSON"),
            new("RCC", "RNRBOQ", "BOQ", "₿", "CAD-derived quantity estimate"),
            new("RCC", "RNRETABS", "Exchange JSON", "⇪", "Neutral data for future analysis link"),
            new("MATERIALS", "RNRMATLIB", "Material browser", "▦", "Browse/search/apply/create materials"),
            new("MATERIALS", "RNRHATCH", "Hatch", "▨", "Apply material hatch"),
            new("MATERIALS", "RNRMATAPPLY", "Convert hatch", "↻", "Set existing hatches to a material"),
            new("MATERIALS", "RNRMATPREVIEW", "Swatches", "▦", "Draw all materials as swatches"),
            new("MATERIALS", "RNRMATLEGEND", "Legend", "☷", "Legend of materials used"),
            new("ANNOTATION", "RNRTAG", "Tag", "⌗", "Member/room tag"),
            new("ANNOTATION", "RNRLEVEL", "Level", "▽", "Level mark"),
            new("ANNOTATION", "RNRSECTIONMARK", "Section mark", "⊖", "Section mark"),
            new("ANNOTATION", "RNRDETAILMARK", "Detail mark", "⊙", "Detail mark"),
            new("ANNOTATION", "RNRELEVMARK", "Elevation mark", "△", "Elevation mark"),
            new("ANNOTATION", "RNRNORTH", "North arrow", "↑", "North arrow"),
            new("ANNOTATION", "RNRLEADER", "Leader", "↖", "Multileader in RNR style"),
            new("ANNOTATION", "RNRLAYOUT", "Layout + title", "▭", "Sheet layout with title block and viewport"),
            new("ANNOTATION", "RNRTITLE", "Edit title block", "✎", "Edit title block fields"),
            new("LAYERS", "RNRLAYERS", "Create layers", "≡", "Create/update standard layers + filters"),
            new("LAYERS", "RNRLA", "Layer audit", "⚑", "Compare layers with the standard"),
            new("LAYERS", "RNRCOLOR", "Colour manager", "🎨", "Palette list/apply/import/export/restore"),
            new("LAYERS", "RNRSTYLES", "Styles", "A", "Text/dim/mleader styles + scales"),
            new("LAYERS", "RNRARCH", "Isolate ARCH", "A", "Freeze all but architecture"),
            new("LAYERS", "RNRSTRUCT", "Isolate STRUCT", "S", "Freeze all but structure"),
            new("LAYERS", "RNRRCC", "Isolate RCC", "R", "Freeze all but RCC"),
            new("LAYERS", "RNRCIVIL", "Isolate CIVIL", "C", "Freeze all but civil"),
            new("LAYERS", "RNRANNO", "Isolate ANNO", "T", "Freeze all but annotation"),
            new("TOOLS", "RNRBLOCKS", "Load blocks", "▣", "Define all RooMNRooF blocks"),
            new("TOOLS", "RNRPLOTCOLOR", "PDF colour", "🖶", "Colour PDF (acad.ctb)"),
            new("TOOLS", "RNRPLOTBW", "PDF mono", "🖶", "Monochrome PDF (B&W safety mode)"),
            new("TOOLS", "RNRPLOTGRAY", "PDF grey", "🖶", "Greyscale PDF"),
            new("TOOLS", "RNRPREVIEW", "Plot preview", "👁", "Preview with chosen CTB"),
            new("TOOLS", "RNRDXFOUT", "DXF/DWG copy", "⇩", "Export a copy"),
            new("TOOLS", "RNRIMPORT", "Import DWG/DXF", "⇧", "Import with unit detection"),
            new("QA", "RNRQA", "QA report", "✔", "Full QA report saved to file"),
            new("QA", "RNRSTANDARD", "Standards check", "☑", "Standards files + drawing check"),
            new("QA", "RNRCLEAN", "Safe cleanup", "🧹", "Preview, backup, confirm, then clean"),
            new("QA", "RNRAUDIT", "Audit", "⚕", "AutoCAD AUDIT"),
        };

        public static void Run(string command)
        {
            var doc = AcApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return;
            var key = command.Split('\n')[0];
            State.Recent.Remove(key); State.Recent.Insert(0, key);
            if (State.Recent.Count > 8) State.Recent.RemoveAt(8);
            State.Save();
            // ESC ESC cancels any running command first; the command itself runs in document context
            doc.SendStringToExecute("\x03\x03" + command + (command.Contains('\n') ? "" : " "), true, false, true);
        }

        public static void ShowPalette()
        {
            if (_ps == null)
            {
                _ps = new PaletteSet("RooMNRooF CAD PRO", new Guid("6C0B1C3E-8F4A-4F0E-9E55-2A4B7C1D9E01"))
                {
                    Style = PaletteSetStyles.ShowAutoHideButton | PaletteSetStyles.ShowCloseButton | PaletteSetStyles.ShowPropertiesMenu,
                    MinimumSize = new System.Drawing.Size(280, 400),
                };
                _ps.AddVisual("Tools", BuildPanel());
            }
            _ps.Visible = true;
        }

        static Brush B(byte r, byte g, byte b) => new SolidColorBrush(WpfColor.FromRgb(r, g, b));

        static FrameworkElement BuildPanel()
        {
            var root = new DockPanel { LastChildFill = true };
            var bg = State.Dark ? B(33, 37, 43) : B(245, 246, 248);
            var fg = State.Dark ? B(230, 230, 230) : B(30, 30, 30);
            var accent = B(230, 57, 70);
            root.Background = bg;

            var header = new StackPanel { Margin = new Thickness(6) };
            header.Children.Add(new TextBlock { Text = "RooMNRooF CAD PRO", FontWeight = FontWeights.Bold, FontSize = 15, Foreground = accent });
            header.Children.Add(new TextBlock { Text = "Drafting automation – verify engineering independently", FontSize = 10, Foreground = fg, Opacity = 0.7 });
            var search = new TextBox { Margin = new Thickness(0, 6, 0, 0), ToolTip = "Search tools (Ctrl+F). Enter runs the first match." };
            header.Children.Add(search);
            var themeBtn = new Button { Content = State.Dark ? "Light theme" : "Dark theme", Margin = new Thickness(0, 4, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, Padding = new Thickness(6, 1, 6, 1) };
            header.Children.Add(themeBtn);
            DockPanel.SetDock(header, Dock.Top);
            root.Children.Add(header);

            var tabs = new TabControl { Background = bg, BorderThickness = new Thickness(0) };
            root.Children.Add(tabs);

            WrapPanel MakeGrid(IEnumerable<ToolDef> tools)
            {
                var wp = new WrapPanel { Margin = new Thickness(4) };
                foreach (var t in tools)
                {
                    var sp = new StackPanel { Orientation = Orientation.Horizontal };
                    sp.Children.Add(new TextBlock { Text = t.Glyph, Width = 22, FontSize = 14, Foreground = accent, VerticalAlignment = VerticalAlignment.Center });
                    sp.Children.Add(new TextBlock { Text = (State.Favorites.Contains(t.Command) ? "★ " : "") + t.Label, Foreground = fg, VerticalAlignment = VerticalAlignment.Center });
                    var btn = new Button
                    {
                        Content = sp, Width = 128, Height = 30, Margin = new Thickness(2), HorizontalContentAlignment = HorizontalAlignment.Left,
                        Background = State.Dark ? B(45, 50, 58) : B(255, 255, 255), BorderBrush = State.Dark ? B(70, 76, 86) : B(210, 210, 210),
                        ToolTip = $"{t.Tip}\nCommand: {t.Command}\nRight-click: toggle favourite",
                    };
                    btn.Click += (_, _) => Run(t.Command);
                    btn.MouseRightButtonUp += (_, _) =>
                    {
                        if (!State.Favorites.Remove(t.Command)) State.Favorites.Add(t.Command);
                        State.Save(); Rebuild();
                    };
                    wp.Children.Add(btn);
                }
                return wp;
            }

            void Fill(string filter)
            {
                tabs.Items.Clear();
                var match = Tools.Where(t => filter.Length == 0 || t.Label.Contains(filter, StringComparison.OrdinalIgnoreCase)
                                             || t.Command.Contains(filter, StringComparison.OrdinalIgnoreCase)
                                             || t.Tip.Contains(filter, StringComparison.OrdinalIgnoreCase)).ToList();
                if (filter.Length > 0)
                {
                    tabs.Items.Add(new TabItem { Header = $"RESULTS ({match.Count})", Content = new ScrollViewer { Content = MakeGrid(match.GroupBy(t => t.Command).Select(g => g.First())) } });
                    tabs.SelectedIndex = 0;
                    return;
                }
                var fav = Tools.Where(t => State.Favorites.Contains(t.Command)).GroupBy(t => t.Command).Select(g => g.First()).ToList();
                var rec = State.Recent.Select(c => Tools.FirstOrDefault(t => t.Command == c)).Where(t => t != null).Cast<ToolDef>().ToList();
                var home = new StackPanel();
                home.Children.Add(new TextBlock { Text = "FAVOURITES", Foreground = fg, Margin = new Thickness(6, 4, 0, 0), FontWeight = FontWeights.Bold });
                home.Children.Add(fav.Count > 0 ? MakeGrid(fav) : new TextBlock { Text = "Right-click any tool to add it.", Foreground = fg, Opacity = 0.6, Margin = new Thickness(8, 2, 0, 4) });
                home.Children.Add(new TextBlock { Text = "RECENT", Foreground = fg, Margin = new Thickness(6, 4, 0, 0), FontWeight = FontWeights.Bold });
                home.Children.Add(rec.Count > 0 ? MakeGrid(rec) : new TextBlock { Text = "No recent tools.", Foreground = fg, Opacity = 0.6, Margin = new Thickness(8, 2, 0, 4) });
                home.Children.Add(new TextBlock { Text = "START", Foreground = fg, Margin = new Thickness(6, 4, 0, 0), FontWeight = FontWeights.Bold });
                home.Children.Add(MakeGrid(Tools.Where(t => t.Panel == "HOME")));
                tabs.Items.Add(new TabItem { Header = "HOME", Content = new ScrollViewer { Content = home } });
                foreach (var g in Tools.Where(t => t.Panel != "HOME").GroupBy(t => t.Panel))
                    tabs.Items.Add(new TabItem { Header = g.Key, Content = new ScrollViewer { Content = MakeGrid(g) } });
                tabs.SelectedIndex = 0;
            }

            search.TextChanged += (_, _) => Fill(search.Text.Trim());
            search.KeyDown += (_, e) =>
            {
                if (e.Key != Key.Enter) return;
                var first = Tools.FirstOrDefault(t => t.Label.Contains(search.Text, StringComparison.OrdinalIgnoreCase) || t.Command.Contains(search.Text, StringComparison.OrdinalIgnoreCase));
                if (first != null) Run(first.Command);
            };
            root.InputBindings.Add(new KeyBinding(new RelayCommand(() => search.Focus()), Key.F, ModifierKeys.Control));
            themeBtn.Click += (_, _) => { State.Dark = !State.Dark; State.Save(); Rebuild(); };
            Fill("");
            return root;
        }

        static void Rebuild()
        {
            if (_ps == null) return;
            // PaletteSet cannot replace a palette's visual in place; remove + re-add
            while (_ps.Count > 0) _ps.Remove(0);
            _ps.AddVisual("Tools", BuildPanel());
        }

        public static void ShowMaterialBrowser() => Autodesk.AutoCAD.ApplicationServices.Application.ShowModelessWindow(new MaterialBrowser());
        public static void ShowColorBrowser() => Autodesk.AutoCAD.ApplicationServices.Application.ShowModelessWindow(new ColorBrowser());
    }

    sealed class RelayCommand : ICommand
    {
        readonly Action _a;
        public RelayCommand(Action a) => _a = a;
        public event EventHandler? CanExecuteChanged { add { } remove { } }
        public bool CanExecute(object? p) => true;
        public void Execute(object? p) => _a();
    }
}
