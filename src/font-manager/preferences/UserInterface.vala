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

    public class WaterfallSize : Object {

        public int predefined_size { get; set; }
        public double minimum { get; set; }
        public double maximum { get; set; }
        public double ratio { get; set; }

        public PreferenceRow row { get; private set; }

        Gtk.SpinButton min;
        Gtk.SpinButton max;
        Gtk.SpinButton rat;
        Gtk.DropDown selection;

        public WaterfallSize () {
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
            selection.notify["selected"].connect(on_selection_changed);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("minimum", min, "value", flags);
            bind_property("maximum", max, "value", flags);
            bind_property("ratio", rat, "value", flags);
            bind_property("predefined-size", selection, "selected", flags);
        }

        void on_selection_changed () {
            var selected_size = ((PredefinedWaterfallSize) selection.selected);
            double [] selected = selected_size.to_size_array();
            bool custom = selected[0] == 0.0;
            row.set_reveal_child(custom);
            if (custom)
                return;
            min.value = selected[0];
            max.value = selected[1];
            rat.value = selected[2];
            return;
        }

    }

    public class UserInterfacePreferences : PreferenceList {

        Gtk.Switch wide_layout;
        Gtk.Switch use_csd;
        Gtk.Switch enable_animations;
        Gtk.Switch prefer_dark_theme;
        Gtk.Switch show_line_size;
        Gtk.CheckButton on_maximize;
        Gtk.DropDown button_style;
        Gtk.Settings default_gtk_settings;

        WaterfallSize waterfall_size;

        public UserInterfacePreferences () {
            widget_set_name(this, "FontManagerUserInterfacePreferences");
            default_gtk_settings = Gtk.Settings.get_default();
            list.set_selection_mode(Gtk.SelectionMode.NONE);
            wide_layout = add_preference_switch(_("Wide Layout"));
            var widget = wide_layout.get_ancestor(typeof(PreferenceRow)) as PreferenceRow;
            on_maximize = new Gtk.CheckButton();
            var child = new PreferenceRow(_("Only When Maximized"), null, null, on_maximize);
            widget.append_child(child);
            use_csd = add_preference_switch(_("Client Side Decorations"));
            enable_animations = add_preference_switch(_("Enable Animations"));
            prefer_dark_theme = add_preference_switch(_("Prefer Dark Theme"));
            string button_styles [2] = { _("Raised"), _("Flat") };
            var style_list = new Gtk.StringList(button_styles);
            button_style = new Gtk.DropDown(style_list, null);
            append_row(new PreferenceRow(_("Titlebar Button Style"), null, null, button_style));
            show_line_size = add_preference_switch(_("Display line size in Waterfall Preview"));
            waterfall_size = new WaterfallSize();
            append_row(waterfall_size.row);
            bind_properties();
        }

        void bind_properties () {
            GLib.Settings? settings = get_gsettings(BUS_ID);
            return_if_fail(settings != null);
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("use-csd", use_csd, "active", flags);
            settings.bind("wide-layout", wide_layout, "active", flags);
            settings.bind("wide-layout-on-maximize", on_maximize, "active", flags);
            settings.bind("enable-animations", enable_animations, "active", flags);

            // XXX : FIXME! :
            // Here for testing purposes
            // This probably belongs in our application window class.
            // GLib.Settings? settings = get_gsettings(BUS_ID);
            Gtk.Settings? gtk_settings = Gtk.Settings.get_default();
            const string gtk_prefer_dark = "gtk-application-prefer-dark-theme";
            if (gtk_settings != null) {
                settings.bind("prefer-dark-theme", gtk_settings, gtk_prefer_dark, flags);
                settings.bind("enable-animations", gtk_settings, "gtk-enable-animations", flags);
            }
            warn_if_fail(gtk_settings != null);

            settings.bind("prefer-dark-theme", prefer_dark_theme, "active", flags);
            settings.bind("waterfall-show-line-size", show_line_size, "active", flags);
            settings.bind("min-waterfall-size", waterfall_size, "minimum", flags);
            settings.bind("max-waterfall-size", waterfall_size, "maximum", flags);
            settings.bind("waterfall-size-ratio", waterfall_size, "ratio", flags);
            settings.bind_with_mapping("title-button-style",
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
            settings.bind_with_mapping("predefined-waterfall-size",
                                       waterfall_size,
                                       "predefined-size",
                                       flags,
                                       PredefinedWaterfallSize.from_setting,
                                       PredefinedWaterfallSize.to_setting,
                                       null, null);

            return;
        }

    }

}

