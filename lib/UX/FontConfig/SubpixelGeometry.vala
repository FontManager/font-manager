/* SubpixelGeometry.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    /**
     * SubpixelGeometry:
     *
     * https://en.wikipedia.org/wiki/Subpixel_rendering
     */
    public class SubpixelGeometry : Gtk.Box {

        public int rgba {
            get {
                return _rgba;
            }
            set {
                if (value < 0 || value >= options.size)
                    return;
                _rgba = value;
                options[_rgba].active = true;
            }
        }

        int _rgba;
        Gtk.Label label;
        Gtk.ButtonBox box;
        Gee.ArrayList <Gtk.RadioButton> options;

        public SubpixelGeometry () {
            Object(name: "SubpixelGeometry", margin: 24, opacity: 0.75, orientation: Gtk.Orientation.VERTICAL);
            get_style_context().add_class(Gtk.STYLE_CLASS_ENTRY);
            label = new Gtk.Label(_("Subpixel Geometry"));
            label.halign = Gtk.Align.CENTER;
            label.margin = 12;
            pack_start(label, false, true, 6);
            options = new Gee.ArrayList <Gtk.RadioButton> ();
            box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
            for (int i = 0; i < 5; i++) {
                if (i == 0)
                    options.add(new Gtk.RadioButton(null));
                else
                    options.add(new Gtk.RadioButton.from_widget(options[0]));
                var button = options[i];
                var val = (FontConfig.SubpixelOrder) i;
                var icon = new SubpixelGeometryIcon(val);
                button.add(icon);
                icon.show();
                button.set_tooltip_text(val.to_string());
                button.toggled.connect(() => {
                    if (button.active)
                        rgba = (int) val;
                });
                box.pack_start(button, true, true, 0);
            }
            foreach (var widget in options)
                widget.margin = 6;
            pack_start(box, true, true, 6);
        }

        public override void show () {
            foreach (var widget in options)
                widget.show();
            label.show();
            box.show();
            base.show();
            return;
        }

    }

    /**
     * SubpixelGeometryIcon:
     *
     * Icon representing subpixel layout.
     */
    public class SubpixelGeometryIcon : Gtk.Box {

        int _size;
        Gtk.Label c1 = new Gtk.Label(null);
        Gtk.Label c2 = new Gtk.Label(null);
        Gtk.Label c3 = new Gtk.Label(null);
        Gtk.Label [] labels;

        construct {
            labels = { c1, c2, c3 };
        }

        public SubpixelGeometryIcon (FontConfig.SubpixelOrder rgba, int size = 36) {
            Object(name: "SubpixelGeometryIcon", margin: 6, opacity: 1.0,
                    homogeneous: true, orientation: Gtk.Orientation.HORIZONTAL,
                    halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER);
            _size = size;
            string []? color = null;
            if (rgba == FontConfig.SubpixelOrder.RGB || rgba == FontConfig.SubpixelOrder.VRGB)
                color = { "red", "green", "blue" };
            else if (rgba == FontConfig.SubpixelOrder.BGR || rgba == FontConfig.SubpixelOrder.VBGR)
                color = { "blue", "green", "red" };
            else
                color = { "gray", "gray", "gray" };
            if (rgba == FontConfig.SubpixelOrder.VRGB || rgba == FontConfig.SubpixelOrder.VBGR)
                orientation = Gtk.Orientation.VERTICAL;
            for (int i = 0; i < labels.length; i++) {
                pack_start(labels[i], true, true, 0);
                labels[i].get_style_context().add_class(color[i]);
            }
        }

        public override void show () {
            foreach (var label in labels)
                label.show();
            base.show();
        }

        public override void get_preferred_width (out int minimum_size, out int natural_size) {
            minimum_size = natural_size = _size;
            return;
        }

        public override void get_preferred_height (out int minimum_size, out int natural_size) {
            minimum_size = natural_size = _size;
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
