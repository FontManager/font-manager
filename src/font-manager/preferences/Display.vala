/* Display.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    public class DisplayPreferences : FontConfigSettingsPage {

        DisplayPropertiesPane pane;

        public DisplayPreferences () {
            pane = new DisplayPropertiesPane();
            box.pack_start(pane, true, true, 0);
            connect_signals();
            pane.show();
        }

        void connect_signals () {
            controls.save_selected.connect(() => {
                if (pane.properties.save())
                    show_message(_("Settings saved to file."));
            });
            controls.discard_selected.connect(() => {
                if (pane.properties.discard())
                    show_message(_("Removed configuration file."));
            });
            return;
        }

    }

    /**
     * DisplayPropertiesPane:
     *
     * Preference pane allowing configuration of display related Fontconfig properties
     */
    class DisplayPropertiesPane : Gtk.ScrolledWindow {

        public DisplayProperties properties { get; private set; }

        Gtk.Grid grid;
        LabeledSpinButton dpi;
        LabeledSpinButton scale;
        OptionScale lcdfilter;
        SubpixelGeometry spg;
        Gtk.Widget [] widgets;

        public DisplayPropertiesPane () {
            set_size_request(480, 420);
            grid = new Gtk.Grid();
            properties = new DisplayProperties();
            properties.config_dir = FontManager.get_user_fontconfig_directory();
            properties.load();
            dpi = new LabeledSpinButton(_("Target DPI"), 0, 1000, 1);
            scale = new LabeledSpinButton(_("Scale Factor"), 0, 1000, 0.1);
            string [] filters = {};
            for (int i = 0; i <= LCDFilter.LEGACY; i++)
                filters += ((LCDFilter) i).to_string();
            lcdfilter = new OptionScale(_("LCD Filter"), filters);
            spg = new SubpixelGeometry();
            widgets = { dpi, scale, lcdfilter, spg };
            pack_components();
            bind_properties();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.foreach((w) => { w.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW); });
            grid.show();
        }

        void pack_components () {
            for (int i = 0; i < widgets.length; i++)
                grid.attach(widgets[i], 0, i - 1, 2, 1);
            add(grid);
            return;
        }

        void bind_properties () {
            properties.bind_property("dpi", dpi, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("scale", scale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("lcdfilter", lcdfilter, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("rgba", spg, "rgba", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            return;
        }

    }

}
