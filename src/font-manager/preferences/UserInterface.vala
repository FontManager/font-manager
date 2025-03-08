/* UserInterface.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

    public enum ButtonStyle {

        NORMAL,
        FLAT;

        // GSettingsBind*Mapping functions

        public static Variant to_setting (Value val, VariantType type) {

            switch (((ButtonStyle) val.get_uint())) {
                case ButtonStyle.FLAT:
                    return new Variant.string("Flat");
                default:
                    return new Variant.string("Normal");
            }
        }

        public static bool from_setting (Value val, Variant variant) {
            switch (variant.get_string()) {
                case "Flat":
                    val.set_uint((uint) ButtonStyle.FLAT);
                    break;
                default:
                    val.set_uint((uint) ButtonStyle.NORMAL);
                    break;
            }
            return true;
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

#if HAVE_ADWAITA
        void on_restart_required () {
            var title = _("Selected setting requires restart to apply");
            var body = _("Changes will take effect next time the application is started");
            var icon = new GLib.ThemedIcon(BUS_ID);
            var notification = new GLib.Notification(title);
            notification.set_body(body);
            notification.set_icon(icon);
            get_default_application().send_notification("restart-required", notification);
            return;
        }
#endif

        void generate_options_list () {
            if (initialized)
                return;
            wide_layout = add_preference_switch(_("Wide Layout"), _("Use three column layout"));
            var widget = wide_layout.get_ancestor(typeof(PreferenceRow)) as PreferenceRow;
            on_maximize = new Gtk.CheckButton();
            var child = new PreferenceRow(_("Only When Maximized"), null, null, on_maximize);
            widget.append_child(child);
            enable_animations = add_preference_switch(_("Enable Animations"));
            prefer_dark_theme = add_preference_switch(_("Prefer Dark Theme"));
#if HAVE_ADWAITA
            use_adwaita_stylesheet = add_preference_switch(_("Use Adwaita Stylesheet"));
#endif
            var style_list = new Gtk.StringList(null);
            style_list.append(_("Raised"));
            style_list.append(_("Flat"));
            button_style = new Gtk.DropDown(style_list, null);
            append_row(new PreferenceRow(_("Titlebar Button Style"), null, null, button_style));
            show_line_size = add_preference_switch(_("Display line size in Waterfall Preview"));
            if (waterfall_settings == null)
                waterfall_settings = new WaterfallSettings(settings);
            var adjustment = new Gtk.Adjustment(0.0, 0.0, double.MAX, 1.0, 1.0, 1.0);
            var spacing = new Gtk.SpinButton(adjustment, 1.0, 0);
            var spacing_row = new PreferenceRow(_("Waterfall Line Spacing"), null, null, spacing);
            append_row(spacing_row);
            spacing_row.set_tooltip_text(_("Padding in pixels to insert above and below rows"));
            spacing.set_value((double) waterfall_settings.line_spacing);
            spacing.value_changed.connect(() => {
                waterfall_settings.line_spacing = (int) spacing.value;
            });
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
                                       (GLib.SettingsBindGetMappingShared) ButtonStyle.from_setting,
                                       (GLib.SettingsBindSetMappingShared) ButtonStyle.to_setting,
                                       null, null);
            return;
        }

    }

}

