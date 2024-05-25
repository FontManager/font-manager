/* Display.vala
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

    internal struct PreviousDisplaySettings {

        int filter;
        int rgba;
        double dpi;
        double scale;

        public PreviousDisplaySettings (FontProperties properties) {
            dpi = properties.dpi;
            scale = properties.scale;
            filter = properties.lcdfilter;
            rgba = properties.rgba;
        }

        public bool changed (FontProperties properties) {
            return properties.lcdfilter != filter ||
                   properties.rgba != rgba ||
                   properties.dpi != dpi ||
                   properties.scale != scale;
        }

        public void load (FontProperties properties) {
            properties.set("lcdfilter", filter, "rgba", rgba, "dpi", dpi, "scale", scale);
            return;
        }

    }

    public class DisplayPreferences : PreferenceList {

        public FontProperties properties { get; private set; }

        bool initialized = false;
        Gtk.SpinButton dpi;
        Gtk.SpinButton scale;
        Gtk.DropDown lcdfilter;
        SubpixelGeometry spg;
        PreviousDisplaySettings settings;

        public DisplayPreferences () {
            widget_set_name(this, "FontManagerDisplayPreferences");
            list.set_selection_mode(Gtk.SelectionMode.NONE);
            properties = new FontProperties () {
                type = FontPropertiesType.DISPLAY,
                target_file = "19-DisplayProperties.conf"
            };
        }

        void generate_options_list () {
            if (initialized)
                return;
            dpi = new Gtk.SpinButton.with_range(0.0, 1000.0, 1.0);
            append_row(new PreferenceRow(_("Target DPI"), null, null, dpi));
            scale = new Gtk.SpinButton.with_range(0.0, 1000.0, 0.1);
            append_row(new PreferenceRow(_("Scale Factor"), null, null, scale));
            var filters = new GLib.Array <string> ();
            for (int i = 0; i <= LCDFilter.LEGACY; i++)
                filters.append_val(((LCDFilter) i).to_string());
            var filter_list = new Gtk.StringList(filters.data);
            lcdfilter = new Gtk.DropDown(filter_list, null);
            append_row(new PreferenceRow(_("LCD Filter"), null, null, lcdfilter));
            spg = new SubpixelGeometry();
            spg.options[SubpixelOrder.UNKNOWN].hide();
            spg.options[SubpixelOrder.NONE].hide();
            spg.margin_end = 0;
            spg.hexpand = false;
            spg.halign = Gtk.Align.END;
            spg.get_last_child().margin_end = 0;
            append_row(new PreferenceRow(_("Subpixel Geometry"), null, null, spg));
            bind_properties();
            // Store previous settings
            settings = PreviousDisplaySettings(properties);
            var footer = new FontconfigFooter();
            footer.reset_requested.connect(on_reset);
            append(footer);
            initialized = true;
            return;
        }

        void bind_properties () {
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            properties.bind_property("dpi", dpi, "value", flags);
            properties.bind_property("scale", scale, "value", flags);
            properties.bind_property("rgba", spg, "selected", flags);
            properties.bind_property("lcdfilter", lcdfilter, "selected", flags);
            return;
        }

        void on_reset () {
            properties.discard();
            settings.load(properties);
            return;
        }

        public override void on_map () {
            generate_options_list();
            properties.load();
            return;
        }

        public override void on_unmap () {
            // Avoid saving unless there's been changes to at least one value.
            if (settings.changed(properties))
                properties.save();
            return;
        }

    }

}


