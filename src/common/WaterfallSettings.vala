/* WaterfallSettings.vala
 *
 * Copyright (C) 2022-2025 Jerry Casiano
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
        public int line_spacing { get; set; default = 0; }

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
            settings.bind("waterfall-line-spacing", this, "line-spacing", flags);
            settings.bind_with_mapping("predefined-waterfall-size",
                                       this,
                                       "predefined-size",
                                       flags,
                                       (GLib.SettingsBindGetMappingShared) PredefinedWaterfallSize.from_setting,
                                       (GLib.SettingsBindSetMappingShared) PredefinedWaterfallSize.to_setting,
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
            row.set_reveal_child(predefined_size == PredefinedWaterfallSize.CUSTOM);
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
            if (row != null)
                row.set_reveal_child(predefined_size == PredefinedWaterfallSize.CUSTOM);
            if (predefined_size == PredefinedWaterfallSize.CUSTOM)
                return;
            double [] selected = ((PredefinedWaterfallSize) predefined_size).to_size_array();
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

}
