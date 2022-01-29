/* Interface.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

namespace FontManager {

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-title-button-style.ui")]
    public class TitleButtonStyle : Gtk.Box {

        [GtkChild] unowned Gtk.ComboBoxText combo;

        public string active {
            get {
                return combo.get_active() == 0 ? "Normal" : "Flat";
            }
            set {
                combo.set_active(value == "Normal" ? 0 : 1);
            }
        }

        construct {
            combo.changed.connect(() => {
                this.notify_property("active");
                MainWindow? main_window = get_default_application().main_window;
                if (main_window != null) {
                    var style = active == "Normal" ? Gtk.ReliefStyle.NORMAL : Gtk.ReliefStyle.NONE;
                    main_window.titlebar.set_button_style(style);
                }
            });
        }

    }

    internal enum PredefinedWaterfallSize {

        LINEAR_48,
        72_11,
        LINEAR_96,
        96_11,
        120_12,
        144_13,
        192_14,
        CUSTOM;

        public double [] to_size_array () {
            switch (this) {
                case LINEAR_48:
                    return { 8.0, 48.0, 1.0 };
                case 72_11:
                    return { 8.0, 72.0, 1.1 };
                case LINEAR_96:
                    return { 8.0, 96.0, 1.0 };
                case 96_11:
                    return { 8.0, 96.0, 1.1 };
                case 120_12:
                    return { 8.0, 120.0, 1.2 };
                case 144_13:
                    return { 8.0, 144.0, 1.3 };
                case 192_14:
                    return { 8.0, 192.0, 1.4 };
                default:
                    return { 0.0, 0.0, 0.0 };
            }
        }

        /* GSettingsBind*Mapping functions */

        public static Variant to_setting (Value val, VariantType type) {
            switch (val.get_int()) {
                case 0:
                    return new Variant.string("48 Points Linear");
                case 1:
                    return new Variant.string("72 Points 1.1 Ratio");
                case 2:
                    return new Variant.string("96 Points Linear");
                case 3:
                    return new Variant.string("96 Points 1.1 Ratio");
                case 4:
                    return new Variant.string("120 Points 1.2 Ratio");
                case 5:
                    return new Variant.string("144 Points 1.3 Ratio");
                case 6:
                    return new Variant.string("192 Points 1.4 Ratio");
                default:
                    return new Variant.string("Custom");
            }
        }

        public static bool from_setting (Value val, Variant variant) {
            switch (variant.get_string()) {
                case "48 Points Linear":
                    val.set_int(0);
                    break;
                case "72 Points 1.1 Ratio":
                    val.set_int(1);
                    break;
                case "96 Points Linear":
                    val.set_int(2);
                    break;
                case "96 Points 1.1 Ratio":
                    val.set_int(3);
                    break;
                case "120 Points 1.2 Ratio":
                    val.set_int(4);
                    break;
                case "144 Points 1.3 Ratio":
                    val.set_int(5);
                    break;
                case "192 Points 1.4 Ratio":
                    val.set_int(6);
                    break;
                default:
                    val.set_int(7);
                    break;
            }
            return true;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-waterfall-size.ui")]
    public class WaterfallSize : Gtk.Box {

        [GtkChild] public unowned Gtk.SpinButton min { get; }
        [GtkChild] public unowned Gtk.SpinButton max { get; }
        [GtkChild] public unowned Gtk.SpinButton ratio { get; }
        [GtkChild] public unowned Gtk.ComboBoxText selection { get; }
        [GtkChild] public unowned Gtk.Revealer revealer { get; }
        [GtkChild] public unowned Gtk.Switch show_line_size { get; }

        [GtkCallback]
        bool on_show_line_size_state_set () {
            MainWindow? main_window = get_default_application().main_window;
            if (main_window != null) {
                main_window.preview_pane.show_line_size = show_line_size.active;
#if HAVE_WEBKIT
                var google_fonts_pane = (GoogleFonts.Catalog) main_window.web_pane.get_child();
                google_fonts_pane.preview_pane.show_line_size = show_line_size.active;
#endif /* HAVE_WEBKIT */
            }
            return Gdk.EVENT_PROPAGATE;
        }

        [GtkCallback]
        void on_value_changed () {
            MainWindow? main_window = get_default_application().main_window;
            if (main_window != null) {
                main_window.preview_pane.set_waterfall_size(min.value, max.value, ratio.value);
#if HAVE_WEBKIT
                var google_fonts_pane = (GoogleFonts.Catalog) main_window.web_pane.get_child();
                google_fonts_pane.preview_pane.set_waterfall_size(min.value, max.value, ratio.value);
#endif /* HAVE_WEBKIT */
            }
            return;
        }

        [GtkCallback]
        void on_selection_changed () {
            double [] selected = ((PredefinedWaterfallSize) selection.active).to_size_array();
            bool custom = selected[0] == 0.0;
            revealer.set_reveal_child(custom);
            if (custom)
                return;
            min.value = selected[0];
            max.value = selected[1];
            ratio.value = selected[2];
            on_value_changed();
            return;
        }

    }

    public class UserInterfacePreferences : SettingsPage {

        public LabeledSwitch wide_layout { get; private set; }
        public LabeledSwitch use_csd { get; private set; }
        public LabeledSwitch enable_animations { get; private set; }
        public LabeledSwitch prefer_dark_theme { get; private set; }
        public TitleButtonStyle button_style { get; private set; }
        public WaterfallSize waterfall_size { get; private set; }

        Gtk.Settings default_gtk_settings;
        Gtk.Revealer wide_layout_options;
        Gtk.CheckButton on_maximize;

        public UserInterfacePreferences () {
            wide_layout = new LabeledSwitch(_("Wide Layout"));
            wide_layout_options = new Gtk.Revealer();
            wide_layout_options.set_transition_duration(450);
            on_maximize = new Gtk.CheckButton.with_label(_("Only When Maximized"));
            on_maximize.margin = DEFAULT_MARGIN / 2;
            on_maximize.margin_start = on_maximize.margin_end = DEFAULT_MARGIN * 4;
            use_csd = new LabeledSwitch(_("Client Side Decorations"));
            wide_layout_options.add(on_maximize);
            on_maximize.show();
            wide_layout_options.show();
            enable_animations = new LabeledSwitch(_("Enable Animations"));
            prefer_dark_theme = new LabeledSwitch(_("Prefer Dark Theme"));
            button_style = new TitleButtonStyle();
            waterfall_size = new WaterfallSize();
            var scroll = new Gtk.ScrolledWindow(null, null);
            var list = new Gtk.ListBox();
            Gtk.Widget [] widgets = { wide_layout, wide_layout_options, use_csd, enable_animations,
                                                 prefer_dark_theme, button_style, waterfall_size };
            foreach (var widget in widgets) {
                var row = new Gtk.ListBoxRow() {
                    activatable = false,
                    selectable = false
                };
                row.add(widget);
                list.add(row);
                widget.show();
                row.show();
            }
            box.pack_end(scroll);
            scroll.add(list);
            list.show();
            scroll.show();
            default_gtk_settings = Gtk.Settings.get_default();
            connect_signals();
            bind_properties();
            revealer.set_reveal_child(false);
        }

        void bind_properties () {
            GLib.Settings? settings = get_default_application().settings;
            return_if_fail(settings != null);
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("use-csd", use_csd.toggle, "active", flags);
            settings.bind("wide-layout", wide_layout.toggle, "active", flags);
            settings.bind("wide-layout-on-maximize", on_maximize, "active", flags);
            settings.bind("enable-animations", enable_animations.toggle, "active", flags);
            settings.bind("prefer-dark-theme", prefer_dark_theme.toggle, "active", flags);
            settings.bind("title-button-style", button_style, "active", flags);
            settings.bind("min-waterfall-size", waterfall_size.min, "value", flags);
            settings.bind("max-waterfall-size", waterfall_size.max, "value", flags);
            settings.bind("waterfall-size-ratio", waterfall_size.ratio, "value", flags);
            settings.bind("waterfall-show-line-size", waterfall_size.show_line_size, "active", flags);
            settings.bind_with_mapping("predefined-waterfall-size", waterfall_size.selection,
                                        "active", flags, PredefinedWaterfallSize.from_setting,
                                        PredefinedWaterfallSize.to_setting, null, null);
            return;
        }

        void connect_signals () {
            wide_layout.toggle.state_set.connect((active) => {
                wide_layout_options.set_reveal_child(active);
                return false;
            });
            use_csd.toggle.state_set.connect((active) => {
                if (active)
                    show_message(_("CSD enabled. Change will take effect next time the application is started."));
                else
                    show_message(_("CSD disabled. Change will take effect next time the application is started."));
                return false;
            });
            enable_animations.toggle.state_set.connect((active) => {
                default_gtk_settings.gtk_enable_animations = active;
                return false;
            });
            prefer_dark_theme.toggle.state_set.connect((active) => {
                default_gtk_settings.gtk_application_prefer_dark_theme = active;
                return false;
            });
            return;

        }

    }

}
