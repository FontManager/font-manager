/* FontScale.vala
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

namespace FontManager {

    public class FontScale : Gtk.EventBox {

        public Gtk.Adjustment adjustment {
            get {
                return scale.get_adjustment();
            }
            set {
                scale.set_adjustment(value);
                spin.set_adjustment(value);
            }
        }

        private Gtk.Box container;
        private Gtk.SpinButton spin;
        private Gtk.Scale scale;
        private ReactiveLabel min;
        private ReactiveLabel max;

        construct {
            scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5);
            scale.draw_value = false;
            scale.set_range(MIN_FONT_SIZE, MAX_FONT_SIZE);
            scale.set_increments(0.5, 1.0);
            spin = new Gtk.SpinButton.with_range(MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5);
            spin.set_adjustment(adjustment);
            min = new ReactiveLabel(null);
            max = new ReactiveLabel(null);
            min.set_markup("<span font=\"Serif Italic Bold\" size=\"small\"> A </span>");
            max.set_markup("<span font=\"Serif Italic Bold\" size=\"large\"> A </span>");
            container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            container.pack_start(min, false, true, 2);
            container.pack_start(scale, true, true, 0);
            container.pack_start(max, false, true, 2);
            container.pack_end(spin, false, true, 8);
            container.border_width = 5;
            add(container);
            style_updated();
            connect_signals();
        }

        public override void show () {
            container.show();
            min.show();
            max.show();
            spin.show();
            scale.show();
            container.show();
            base.show();
            return;
        }

        private void connect_signals () {
            min.clicked.connect(() => { scale.set_value(MIN_FONT_SIZE); });
            max.clicked.connect(() => { scale.set_value(MAX_FONT_SIZE); });
        }

        public void add_style_class (string gtk_style_class) {
            container.forall((w) => {
                if ((w is Gtk.SpinButton) || (w is Gtk.Scale))
                    return;
                w.get_style_context().add_class(gtk_style_class);
            });
            get_style_context().add_class(gtk_style_class);
            return;
        }

    }

}
