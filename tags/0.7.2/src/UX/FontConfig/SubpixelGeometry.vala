/* SubpixelGeometry.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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

        private int _rgba;
        private Gtk.Label label;
        private Gtk.ButtonBox box;
        private Gee.ArrayList <Gtk.RadioButton> options;

        public SubpixelGeometry () {
            margin_top = 12;
            orientation = Gtk.Orientation.VERTICAL;
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

        private class SubpixelGeometryIcon : Gtk.Box {

            private int _size;
            private Gtk.Label c1 = new Gtk.Label(null);
            private Gtk.Label c2 = new Gtk.Label(null);
            private Gtk.Label c3 = new Gtk.Label(null);
            private Gtk.Label [] labels;
            private Gdk.RGBA r = Gdk.RGBA();
            private Gdk.RGBA g = Gdk.RGBA();
            private Gdk.RGBA b = Gdk.RGBA();
            private Gdk.RGBA n = Gdk.RGBA();

            construct {
                homogeneous = true;
                halign = valign = Gtk.Align.CENTER;
                orientation = Gtk.Orientation.HORIZONTAL;
                labels = { c1, c2, c3 };
                r.parse("Red");
                g.parse("Green");
                b.parse("Blue");
                n.parse("Gray");
            }

            public SubpixelGeometryIcon (FontConfig.SubpixelOrder rgba, int size = 36) {
                _size = size;
                Gdk.RGBA []? order = null;
                if (rgba == FontConfig.SubpixelOrder.RGB || rgba == FontConfig.SubpixelOrder.VRGB)
                    order = {r, g, b};
                else if (rgba == FontConfig.SubpixelOrder.BGR || rgba == FontConfig.SubpixelOrder.VBGR)
                    order = {b, g, r};
                else
                    order = {n, n, n};
                if (rgba == FontConfig.SubpixelOrder.VRGB || rgba == FontConfig.SubpixelOrder.VBGR)
                    orientation = Gtk.Orientation.VERTICAL;
                for (int i = 0; i < labels.length; i++) {
                    labels[i].override_background_color(Gtk.StateFlags.NORMAL, order[i]);
                    pack_start(labels[i], true, true, 0);
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



}
