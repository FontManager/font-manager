/* SubpixelGeometry.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    /**
     * Widget allowing user to select pixel layout.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-subpixel-geometry.ui")]
    public class SubpixelGeometry : Gtk.Box {

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

        public GLib.List <Gtk.RadioButton> options;

        int _rgba;

        [GtkChild] Gtk.ButtonBox button_box;

        public SubpixelGeometry () {
            options = new GLib.List <Gtk.RadioButton> ();
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
                button.set_data("rgba", i);
                button.toggled.connect(() => {
                    if (button.active)
                        rgba = button.get_data("rgba");
                });
                button_box.pack_start(button);
                button.show();
            }
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-subpixel-geometry-icon.ui")]
    public class SubpixelGeometryIcon : Gtk.Box {

        public int size { get; set; default = 36; }

        [GtkChild] Gtk.Label l1;
        [GtkChild] Gtk.Label l2;
        [GtkChild] Gtk.Label l3;

        public SubpixelGeometryIcon (SubpixelOrder rgba) {

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

            Gtk.Label [] labels = { l1, l2, l3 };
            for (int i = 0; i < labels.length; i++) {
                /* @color: defined in data/FontManager.css */
                labels[i].get_style_context().add_class(color[i]);
            }

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
