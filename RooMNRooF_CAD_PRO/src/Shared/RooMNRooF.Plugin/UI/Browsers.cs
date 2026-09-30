using System;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using RooMNRooF.Core.Configuration;
using RooMNRooF.Core.Models;
using RooMNRooF.Plugin.Core;
using RooMNRooF.Plugin.Services;
using WpfColor = System.Windows.Media.Color;

namespace RooMNRooF.Plugin.UI
{
    /// <summary>
    /// WPF Material Browser: preview swatch, name, category, pattern, scale, colour, transparency.
    /// Actions: Apply, Favourite, Search, Filter, Create custom, Edit, Delete custom, Export, Import.
    /// </summary>
    public sealed class MaterialBrowser : Window
    {
        readonly ListBox _list = new() { Margin = new Thickness(6) };
        readonly TextBox _search = new() { Margin = new Thickness(6, 6, 6, 0), ToolTip = "Search materials" };
        readonly ComboBox _cat = new() { Margin = new Thickness(6, 6, 6, 0) };
        readonly CheckBox _favOnly = new() { Content = "Favourites only", Margin = new Thickness(6, 6, 6, 0) };

        public MaterialBrowser()
        {
            Title = "RooMNRooF Material Browser";
            Width = 560; Height = 620;
            var dock = new DockPanel();
            var top = new StackPanel();
            top.Children.Add(_search);
            _cat.Items.Add("ALL");
            foreach (var c in Rnr.Repo.Hatches.Hatches.Select(h => h.Category).Distinct()) _cat.Items.Add(c);
            _cat.SelectedIndex = 0;
            top.Children.Add(_cat);
            top.Children.Add(_favOnly);
            DockPanel.SetDock(top, Dock.Top);
            dock.Children.Add(top);

            var buttons = new WrapPanel { Margin = new Thickness(6) };
            void Btn(string text, Action a, string tip) { var b = new Button { Content = text, Margin = new Thickness(2), Padding = new Thickness(8, 2, 8, 2), ToolTip = tip }; b.Click += (_, _) => Safe(a); buttons.Children.Add(b); }
            Btn("Apply", Apply, "Hatch a picked area with the selected material (RNRHATCHNAME)");
            Btn("★ Favourite", ToggleFav, "Toggle favourite");
            Btn("Create custom", () => Edit(null), "Create a user material");
            Btn("Edit", () => Edit(Selected), "Edit selected user material");
            Btn("Delete custom", Delete, "Delete selected user material");
            Btn("Export", Export, "Export library JSON");
            Btn("Import", Import, "Import library JSON into user standards");
            DockPanel.SetDock(buttons, Dock.Bottom);
            dock.Children.Add(buttons);
            dock.Children.Add(_list);
            Content = dock;

            _search.TextChanged += (_, _) => Refresh();
            _cat.SelectionChanged += (_, _) => Refresh();
            _favOnly.Checked += (_, _) => Refresh();
            _favOnly.Unchecked += (_, _) => Refresh();
            _list.MouseDoubleClick += (_, _) => Safe(Apply);
            Refresh();
        }

        HatchDef? Selected => (_list.SelectedItem as FrameworkElement)?.Tag as HatchDef;

        void Safe(Action a)
        {
            try { a(); }
            catch (Exception ex) { MessageBox.Show(this, ex.Message, "RooMNRooF", MessageBoxButton.OK, MessageBoxImage.Warning); }
        }

        void Refresh()
        {
            _list.Items.Clear();
            var q = _search.Text.Trim();
            foreach (var h in Rnr.Repo.Hatches.Hatches)
            {
                if (_cat.SelectedIndex > 0 && h.Category != (string)_cat.SelectedItem) continue;
                if (_favOnly.IsChecked == true && !h.Favorite) continue;
                if (q.Length > 0 && !h.Name.Contains(q, StringComparison.OrdinalIgnoreCase) && !h.Pattern.Contains(q, StringComparison.OrdinalIgnoreCase)) continue;
                _list.Items.Add(Row(h));
            }
        }

        static FrameworkElement Row(HatchDef h)
        {
            var color = WpfColor.FromArgb((byte)(255 * (100 - h.Transparency) / 100), (byte)h.Rgb[0], (byte)h.Rgb[1], (byte)h.Rgb[2]);
            var swatch = new Canvas { Width = 56, Height = 32, Background = Brushes.White, ClipToBounds = true, Margin = new Thickness(0, 0, 8, 0) };
            // simple pattern preview: diagonal lines at the material angle
            double ang = (h.Angle + 45) * Math.PI / 180;
            for (int i = -6; i < 12; i++)
            {
                var off = i * 6;
                swatch.Children.Add(new Line { X1 = off, Y1 = 32, X2 = off + 32 / Math.Tan(ang == 0 ? 0.01 : ang), Y2 = 0, Stroke = new SolidColorBrush(color), StrokeThickness = 1 });
            }
            var sp = new StackPanel { Orientation = Orientation.Horizontal, Tag = h, Margin = new Thickness(2) };
            sp.Children.Add(new Border { Child = swatch, BorderBrush = Brushes.Gray, BorderThickness = new Thickness(1) });
            var txt = new StackPanel();
            txt.Children.Add(new TextBlock { Text = (h.Favorite ? "★ " : "") + h.Name + (h.UserDefined ? "  (custom)" : ""), FontWeight = FontWeights.Bold });
            txt.Children.Add(new TextBlock { Text = $"{h.Category} · {h.Pattern} · scale {h.Scale:0.##} · angle {h.Angle:0}° · RGB {string.Join(",", h.Rgb)} · T{h.Transparency}%", FontSize = 11, Opacity = 0.75 });
            sp.Children.Add(txt);
            return sp;
        }

        void Apply()
        {
            var h = Selected ?? throw new InvalidOperationException("Select a material first.");
            PanelHost.Run("RNRHATCHNAME\n" + h.Name + "\n");
        }

        void ToggleFav()
        {
            var h = Selected ?? throw new InvalidOperationException("Select a material first.");
            HatchService.SetFavorite(h.Name, !h.Favorite);
            Rnr.ReloadStandards();
            Refresh();
        }

        void Edit(HatchDef? existing)
        {
            if (existing != null && !existing.UserDefined) throw new InvalidOperationException("Built-in materials cannot be edited. Create a custom copy instead.");
            var dlg = new MaterialEditor(existing) { Owner = this };
            if (dlg.ShowDialog() == true) { HatchService.SaveCustom(dlg.Result!); Refresh(); }
        }

        void Delete()
        {
            var h = Selected ?? throw new InvalidOperationException("Select a material first.");
            if (!h.UserDefined) throw new InvalidOperationException("Only custom materials can be deleted.");
            if (MessageBox.Show(this, $"Delete custom material '{h.Name}'?", "RooMNRooF", MessageBoxButton.YesNo) != MessageBoxResult.Yes) return;
            HatchService.DeleteCustom(h.Name);
            Refresh();
        }

        void Export()
        {
            var dlg = new Microsoft.Win32.SaveFileDialog { FileName = "RNR_Materials.json", Filter = "JSON|*.json" };
            if (dlg.ShowDialog(this) == true) StandardsRepository.SaveFile(dlg.FileName, Rnr.Repo.Hatches);
        }

        void Import()
        {
            var dlg = new Microsoft.Win32.OpenFileDialog { Filter = "JSON|*.json" };
            if (dlg.ShowDialog(this) != true) return;
            var incoming = StandardsRepository.LoadFile<HatchFile>(dlg.FileName);
            int n = 0;
            foreach (var h in incoming.Hatches.Where(h => Rnr.Repo.Hatch(h.Name) == null || Rnr.Repo.Hatch(h.Name)!.UserDefined))
            {
                if (h.Scale <= 0 || h.Rgb.Length != 3) continue;
                HatchService.SaveCustom(h); n++;
            }
            MessageBox.Show(this, $"{n} material(s) imported as custom materials.", "RooMNRooF");
            Refresh();
        }
    }

    /// <summary>Small modal editor for a custom material.</summary>
    public sealed class MaterialEditor : Window
    {
        public HatchDef? Result { get; private set; }
        public MaterialEditor(HatchDef? h)
        {
            Title = h == null ? "New material" : $"Edit {h.Name}";
            Width = 360; SizeToContent = SizeToContent.Height; WindowStartupLocation = WindowStartupLocation.CenterOwner;
            var g = new StackPanel { Margin = new Thickness(10) };
            TextBox F(string label, string value) { g.Children.Add(new TextBlock { Text = label }); var t = new TextBox { Text = value, Margin = new Thickness(0, 0, 0, 6) }; g.Children.Add(t); return t; }
            var name = F("Name", h?.Name ?? "My Material");
            var cat = F("Category", h?.Category ?? "ARCHITECTURE");
            var pat = F("Pattern (predefined e.g. ANSI31, AR-CONC, or custom RNR_*)", h?.Pattern ?? "ANSI31");
            var scale = F("Scale", (h?.Scale ?? 1).ToString(System.Globalization.CultureInfo.InvariantCulture));
            var angle = F("Angle (deg)", (h?.Angle ?? 0).ToString(System.Globalization.CultureInfo.InvariantCulture));
            var rgb = F("RGB (r,g,b)", string.Join(",", h?.Rgb ?? new[] { 160, 160, 160 }));
            var tr = F("Transparency %", (h?.Transparency ?? 0).ToString());
            var layer = F("Layer", h?.LayerHint ?? "A-HATCH");
            var ok = new Button { Content = "Save", IsDefault = true, Padding = new Thickness(10, 2, 10, 2), HorizontalAlignment = HorizontalAlignment.Right };
            ok.Click += (_, _) =>
            {
                try
                {
                    var inv = System.Globalization.CultureInfo.InvariantCulture;
                    var parts = rgb.Text.Split(',').Select(s => int.Parse(s.Trim(), inv)).ToArray();
                    if (parts.Length != 3 || parts.Any(v => v < 0 || v > 255)) throw new FormatException("RGB must be three values 0-255.");
                    var sc = double.Parse(scale.Text, inv);
                    if (sc <= 0) throw new FormatException("Scale must be > 0.");
                    var t = int.Parse(tr.Text, inv);
                    if (t < 0 || t > 90) throw new FormatException("Transparency must be 0-90.");
                    if (string.IsNullOrWhiteSpace(name.Text)) throw new FormatException("Name required.");
                    Result = new HatchDef
                    {
                        Name = name.Text.Trim(), Category = cat.Text.Trim().ToUpperInvariant(), Pattern = pat.Text.Trim().ToUpperInvariant(),
                        Custom = pat.Text.Trim().StartsWith("RNR_", StringComparison.OrdinalIgnoreCase), Scale = sc, Angle = double.Parse(angle.Text, inv),
                        Rgb = parts, Transparency = t, LayerHint = layer.Text.Trim(), ColorId = "HATC-CONCRETE", UserDefined = true,
                        PatFile = pat.Text.Trim().StartsWith("RNR_", StringComparison.OrdinalIgnoreCase) ? pat.Text.Trim().ToUpperInvariant() + ".pat" : null,
                    };
                    DialogResult = true;
                }
                catch (Exception ex) { MessageBox.Show(this, ex.Message, "Invalid input"); }
            };
            g.Children.Add(ok);
            Content = g;
        }
    }

    /// <summary>Colour palette browser (read-only preview + apply/export shortcuts).</summary>
    public sealed class ColorBrowser : Window
    {
        public ColorBrowser()
        {
            Title = $"RooMNRooF Colour Palette ({Rnr.Repo.Colors.Colors.Count})";
            Width = 640; Height = 680;
            var list = new ListBox();
            foreach (var grp in Rnr.Repo.Colors.Colors.GroupBy(c => c.Category))
            {
                list.Items.Add(new TextBlock { Text = grp.Key, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 8, 0, 2) });
                foreach (var c in grp)
                {
                    var sp = new StackPanel { Orientation = Orientation.Horizontal };
                    sp.Children.Add(new Rectangle { Width = 40, Height = 18, Fill = new SolidColorBrush(WpfColor.FromRgb((byte)c.Rgb[0], (byte)c.Rgb[1], (byte)c.Rgb[2])), Stroke = Brushes.Gray, Margin = new Thickness(0, 0, 8, 0) });
                    sp.Children.Add(new TextBlock { Text = $"{c.Name,-18} {c.Hex}  ACI {c.Aci}  LW {c.Lineweight:0.00}  T{c.Transparency}%  plot {c.Plot}  [{c.ObjectCategory}]", FontFamily = new FontFamily("Consolas") });
                    list.Items.Add(sp);
                }
            }
            var dock = new DockPanel();
            var bar = new WrapPanel { Margin = new Thickness(6) };
            var apply = new Button { Content = "Apply palette to drawing layers", Padding = new Thickness(8, 2, 8, 2) };
            apply.Click += (_, _) => PanelHost.Run("RNRCOLOR\nApply\n");
            bar.Children.Add(apply);
            DockPanel.SetDock(bar, Dock.Bottom);
            dock.Children.Add(bar);
            dock.Children.Add(list);
            Content = dock;
        }
    }
}
