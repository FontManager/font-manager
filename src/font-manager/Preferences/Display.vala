/* Display.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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
            pack_start(pane, true, true, 0);
            connect_signals();
        }

        public override void show () {
            pane.show();
            base.show();
            return;
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
            scale = new LabeledSpinButton(_("Scale factor"), 0, 1000, 0.1);
            string [] filters = {};
            for (int i = 0; i <= LCDFilter.LEGACY; i++)
                filters += ((LCDFilter) i).to_string();
            lcdfilter = new OptionScale(_("LCD Filter"), filters);
            spg = new SubpixelGeometry();
            widgets = { grid, dpi, scale, lcdfilter, spg };
            pack_components();
            bind_properties();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.foreach((w) => { w.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW); });
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            foreach (var widget in widgets)
                widget.show();
            base.show();
        }

        void pack_components () {
            for (int i = 1; i < widgets.length; i++)
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

        /**
         * SubpixelGeometry:
         *
         * https://en.wikipedia.org/wiki/Subpixel_rendering
         *
         * Widget allowing user to select pixel layout.
         */
        class SubpixelGeometry : Gtk.Box {

            public int rgba {
                get {
                    return _rgba;
                }
                set {
                    if (value < 0 || value >= ((int) options.length()))
                        return;
                    _rgba = value;
                    options.nth_data(_rgba).active = true;
                }
            }

            int _rgba;
            Gtk.Label label;
            Gtk.ButtonBox box;
            GLib.List <Gtk.RadioButton> options;

            public SubpixelGeometry () {

                Object(name: "SubpixelGeometry",
                        margin: DEFAULT_MARGIN_SIZE,
                        opacity: 0.75,
                        orientation: Gtk.Orientation.VERTICAL);

                label = new Gtk.Label(_("Subpixel Geometry"));
                label.set("halign", Gtk.Align.CENTER, "margin", DEFAULT_MARGIN_SIZE / 2, null);
                pack_start(label, false, true, 6);
                options = new GLib.List <Gtk.RadioButton> ();
                box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
                for (int i = 0; i < SubpixelOrder.NONE; i++) {
                    if (i == 0)
                        options.append(new Gtk.RadioButton(null));
                    else
                        options.append(new Gtk.RadioButton.from_widget(options.nth_data(0)));
                    Gtk.RadioButton button = options.nth_data(i);
                    var val = (SubpixelOrder) i;
                    var icon = new SubpixelGeometryIcon(val);
                    button.add(icon);
                    icon.show();
                    button.set_tooltip_text(val.to_string());
                    button.toggled.connect(() => {
                        if (button.active)
                            rgba = (int) val;
                    });
                    box.pack_start(button);
                }
                pack_start(box, true, true, 6);
            }

            /**
             * {@inheritDoc}
             */
            public override void show () {
                foreach (var widget in options)
                    widget.show();
                label.show();
                box.show();
                base.show();
                return;
            }

            class SubpixelGeometryIcon : Gtk.Box {

                public int size { get; set; default = 36; }

                Gtk.Label c1;
                Gtk.Label c2;
                Gtk.Label c3;
                Gtk.Label [] labels;

                public SubpixelGeometryIcon (SubpixelOrder rgba) {

                    Object(name: "SubpixelGeometryIcon",
                            margin: MINIMUM_MARGIN_SIZE * 3,
                            opacity: 1.0,
                            homogeneous: true,
                            halign: Gtk.Align.CENTER,
                            valign: Gtk.Align.CENTER);

                    string [] color = { "gray", "gray", "gray" };

                    switch (rgba) {
                        case SubpixelOrder.UNKNOWN:
                            break;
                        case SubpixelOrder.BGR:
                        case SubpixelOrder.VBGR:
                            color = { "blue", "green", "red" };
                            break;
                        default:
                            color = { "red", "green", "blue" };
                            break;
                    }

                    switch (rgba) {
                        case SubpixelOrder.VRGB:
                        case SubpixelOrder.VBGR:
                            orientation = Gtk.Orientation.VERTICAL;
                            break;
                        default:
                            orientation = Gtk.Orientation.HORIZONTAL;
                            break;
                    }

                    labels = { c1, c2, c3 };
                    for (int i = 0; i < labels.length; i++) {
                        labels[i] = new Gtk.Label(null);
                        pack_start(labels[i]);
                        /* @color: defined in data/FontManager.css */
                        labels[i].get_style_context().add_class(color[i]);
                    }

                }

                public override void show () {
                    foreach (Gtk.Label label in labels)
                        label.show();
                    base.show();
                }

                /* Used to force square widget */

                public override void get_preferred_width (out int minimum_size, out int natural_size) {
                    minimum_size = natural_size = size;
                    return;
                }

                public override void get_preferred_height (out int minimum_size, out int natural_size) {
                    minimum_size = natural_size = size;
                    return;
                }

                public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
                    minimum_height = natural_height = width;
                    return;
                }

                public override void get_preferred_width_for_height (int height, out int minimum_width, out int natural_width) {
                    minimum_width = natural_width = height;
                    return;
                }

            }

        }

    }

}
