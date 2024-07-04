/* UserInterface.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public enum PredefinedWaterfallSize {

        LINEAR_48,
        72_11,
        LINEAR_96,
        96_11,
        120_12,
        144_13,
        192_14,
        CUSTOM;

        public string to_string () {
            switch (this) {
                case LINEAR_48:
                    return _("Up to 48 points (Linear Scaling)");
                case 72_11:
                    return _("Up to 72 points (1.1 Common Ratio)");
                case LINEAR_96:
                    return _("Up to 96 points (Linear Scaling)");
                case 96_11:
                    return _("Up to 96 points (1.1 Common Ratio)");
                case 120_12:
                    return _("Up to 120 points (1.2 Common Ratio)");
                case 144_13:
                    return _("Up to 144 points (1.3 Common Ratio)");
                case 192_14:
                    return _("Up to 192 points (1.4 Common Ratio)");
                default:
                    return _("Custom Size Settings");
            }
        }

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

        // GSettingsBind*Mapping functions

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

    public class WaterfallSettings : Object {

        public GLib.Settings? settings { get; set; default = null; }

        public int predefined_size { get; set; }
        public double minimum { get; set; }
        public double maximum { get; set; }
        public double ratio { get; set; }
        public bool show_line_size { get; set; default = true; }

        public Gtk.PopoverMenu context_menu {
            get {
                if (menu == null)
                    menu = new Gtk.PopoverMenu.from_model(get_context_menu_model());
                return menu;
            }
        }

        public PreferenceRow preference_row {
            get {
                if (row == null)
                    create_preference_row();
                return row;
            }
        }

        Gtk.SpinButton min;
        Gtk.SpinButton max;
        Gtk.SpinButton rat;
        Gtk.DropDown selection;
        Gtk.PopoverMenu? menu = null;

        PreferenceRow? row = null;

        public WaterfallSettings (GLib.Settings? settings) {
            this.settings = settings;
            bind_settings();
        }

        void bind_settings () {
            if (settings == null)
                settings = get_gsettings(BUS_ID);
            return_if_fail(settings != null);
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("waterfall-show-line-size", this, "show-line-size", flags);
            settings.bind("min-waterfall-size", this, "minimum", flags);
            settings.bind("max-waterfall-size", this, "maximum", flags);
            settings.bind("waterfall-size-ratio", this, "ratio", flags);
            settings.bind_with_mapping("predefined-waterfall-size",
                                       this,
                                       "predefined-size",
                                       flags,
                                       PredefinedWaterfallSize.from_setting,
                                       PredefinedWaterfallSize.to_setting,
                                       null, null);
            return;
        }

        void create_preference_row () {
            var selections = new GLib.Array <string> ();
            for (int i = 0; i <= PredefinedWaterfallSize.CUSTOM; i++)
                selections.append_val(((PredefinedWaterfallSize) i).to_string());
            var selection_list = new Gtk.StringList(selections.data);
            selection = new Gtk.DropDown(selection_list, null);
            row = new PreferenceRow(_("Waterfall Preview Size Settings"), null, null, selection);
            min = new Gtk.SpinButton.with_range(6.0, 48.0, 1.0) { value = 8.0 };
            max = new Gtk.SpinButton.with_range(24.0, 192.0, 1.0) {
                value = 48.0,
                tooltip_text = _("Higher values may adversely affect performance")
            };
            rat = new Gtk.SpinButton.with_range(1.0, 24.0, 0.10) { value = 48.0 };
            var child = new PreferenceRow(_("Minimum Waterfall Preview Point Size"), null, null, min);
            row.append_child(child);
            child = new PreferenceRow(_("Waterfall Preview Point Size Common Ratio"), null, null, rat);
            row.append_child(child);
            child = new PreferenceRow(_("Maximum Waterfall Preview Point Size"), null, null, max);
            row.append_child(child);
            selection.notify["selected"].connect(() => { predefined_size = (int) selection.selected; });
            notify["predefined-size"].connect_after(() => { on_selection_changed(); });
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("minimum", min, "value", flags);
            bind_property("maximum", max, "value", flags);
            bind_property("ratio", rat, "value", flags);
            bind_property("predefined-size", selection, "selected", flags);
            return;
        }

        public void on_selection_changed () {
            double [] selected = ((PredefinedWaterfallSize) predefined_size).to_size_array();
            bool custom = selected[0] == 0.0;
            if (row != null)
                row.set_reveal_child(custom);
            if (custom)
                return;
            minimum = selected[0];
            maximum = selected[1];
            ratio = selected[2];
            return;
        }

        GLib.MenuModel get_context_menu_model () {
            var section = new GLib.Menu();
            var line_size = new GLib.Menu();
            var line_size_menu_item = new GLib.MenuItem(_("Show line size"), "show-line-size");
            line_size.append_item(line_size_menu_item);
            section.prepend_section(null, line_size);
            var size_section = new GLib.Menu();
            for (int i = 0; i < PredefinedWaterfallSize.CUSTOM; i++) {
                var item = new MenuItem(((PredefinedWaterfallSize) i).to_string(), null);
                item.set_action_and_target("predefined-size", "i", i);
                size_section.append_item(item);
            }
            section.append_section(null, size_section);
            return (GLib.MenuModel) section;
        }

    }

    public class UserInterfacePreferences : PreferenceList {

        public GLib.Settings? settings { get; set; default = null; }
        public WaterfallSettings? waterfall_settings { get; set; default = null; }

        bool initialized = false;
        Gtk.Switch wide_layout;
        Gtk.Switch enable_animations;
        Gtk.Switch prefer_dark_theme;
#if HAVE_ADWAITA
        Gtk.Switch use_adwaita_stylesheet;
#endif
        Gtk.Switch show_line_size;
        Gtk.CheckButton on_maximize;
        Gtk.DropDown button_style;

        public UserInterfacePreferences (GLib.Settings? settings) {
            this.settings = settings;
            widget_set_name(this, "FontManagerUserInterfacePreferences");
            list.set_selection_mode(Gtk.SelectionMode.NONE);
        }

        void on_restart_required () {
            var title = _("Selected setting requires restart to apply");
            var body = _("Changes will take effect next time the application is started");
            var notification = new GLib.Notification(title);
            notification.set_body(body);
            var icon = new GLib.ThemedIcon(BUS_ID);
            notification.set_icon(icon);
            get_default_application().send_notification ("restart-required", notification);
            return;
        }

        void generate_options_list () {
            if (initialized)
                return;
            wide_layout = add_preference_switch(_("Wide Layout"));
            var widget = wide_layout.get_ancestor(typeof(PreferenceRow)) as PreferenceRow;
            on_maximize = new Gtk.CheckButton();
            var child = new PreferenceRow(_("Only When Maximized"), null, null, on_maximize);
            widget.append_child(child);
            enable_animations = add_preference_switch(_("Enable Animations"));
            prefer_dark_theme = add_preference_switch(_("Prefer Dark Theme"));
#if HAVE_ADWAITA
            use_adwaita_stylesheet = add_preference_switch(_("Use Adwaita Stylesheet"));
#endif
            string [] button_styles = { _("Raised"), _("Flat") };
            var style_list = new Gtk.StringList(button_styles);
            button_style = new Gtk.DropDown(style_list, null);
            append_row(new PreferenceRow(_("Titlebar Button Style"), null, null, button_style));
            show_line_size = add_preference_switch(_("Display line size in Waterfall Preview"));
            if (waterfall_settings == null)
                waterfall_settings = new WaterfallSettings(settings);
            append_row(waterfall_settings.preference_row);
            BindingFlags bind_flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            waterfall_settings.bind_property("show-line-size", show_line_size, "active", bind_flags);
            bind_settings();
            initialized = true;
            return;
        }

        protected override void on_map () {
            generate_options_list();
#if HAVE_ADWAITA
            use_adwaita_stylesheet.notify["active"].connect(() => { on_restart_required(); });
#endif
            return;
        }

        void bind_settings () {
            if (settings == null)
                settings = get_gsettings(BUS_ID);
            return_if_fail(settings != null);
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("wide-layout", wide_layout, "active", flags);
            settings.bind("wide-layout-on-maximize", on_maximize, "active", flags);
            settings.bind("enable-animations", enable_animations, "active", flags);

            Gtk.Settings? gtk_settings = Gtk.Settings.get_default();
            const string gtk_prefer_dark = "gtk-application-prefer-dark-theme";
            if (gtk_settings != null) {
#if HAVE_ADWAITA
                if (settings.get_boolean("use-adwaita-stylesheet")) {
                    prefer_dark_theme.notify["active"].connect(() => {
                        Adw.StyleManager style_manager = Adw.StyleManager.get_default();
                        Adw.ColorScheme color_scheme = prefer_dark_theme.active ?
                                                       Adw.ColorScheme.PREFER_DARK :
                                                       Adw.ColorScheme.PREFER_LIGHT;
                        style_manager.set_color_scheme(color_scheme);
                    });
                } else
                    settings.bind("prefer-dark-theme", gtk_settings, gtk_prefer_dark, flags);
#else
                settings.bind("prefer-dark-theme", gtk_settings, gtk_prefer_dark, flags);
#endif
                settings.bind("enable-animations", gtk_settings, "gtk-enable-animations", flags);
            }
            warn_if_fail(gtk_settings != null);

            settings.bind("prefer-dark-theme", prefer_dark_theme, "active", flags);
#if HAVE_ADWAITA
            settings.bind("use-adwaita-stylesheet", use_adwaita_stylesheet, "active", flags);
#endif
            settings.bind_with_mapping("headerbar-button-style",
                                       button_style,
                                       "selected",
                                       flags,
                                       (val, v) => {
                                           val.set_uint(((string) v) == "Normal" ? 0 : 1);
                                           return true;
                                       },
                                       (v, t) => {
                                           string val = v.get_uint() == 0 ? "Normal" : "Flat";
                                           return new Variant.string(val);
                                       },
                                       null, null);
            return;
        }

    }

}

