/* FontScale.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
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
        private Gtk.EventBox ev_min;
        private Gtk.EventBox ev_max;
        private Gtk.SpinButton spin;
        private Gtk.Scale scale;
        private Gdk.RGBA normal;
        private Gdk.RGBA hover;
        private Gtk.Label min;
        private Gtk.Label max;

        construct {
            Gdk.RGBA normal = Gdk.RGBA();
            Gdk.RGBA hover = Gdk.RGBA();
            ev_min = new Gtk.EventBox();
            ev_max = new Gtk.EventBox();
            scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5);
            scale.draw_value = false;
            scale.set_range(MIN_FONT_SIZE, MAX_FONT_SIZE);
            scale.set_increments(0.5, 1.0);
            spin = new Gtk.SpinButton.with_range(MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5);
            spin.set_adjustment(adjustment);
            min = new Gtk.Label(null);
            max = new Gtk.Label(null);
            min.set_markup("<span font=\"Serif Italic Bold\" size=\"small\"> A </span>");
            max.set_markup("<span font=\"Serif Italic Bold\" size=\"large\"> A </span>");
            ev_min.add(min);
            ev_max.add(max);
            container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            container.pack_start(ev_min, false, false, 2);
            container.pack_start(scale, true, true, 0);
            container.pack_start(ev_max, false, false, 2);
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
            ev_min.show();
            ev_max.show();
            spin.show();
            scale.show();
            container.show();
            base.show();
            return;
        }

        private void connect_signals () {
            ev_min.button_press_event.connect((w, e) => {
                scale.set_value(MIN_FONT_SIZE);
                return false;
            });
            ev_max.button_press_event.connect((w, e) => {
                scale.set_value(MAX_FONT_SIZE);
                return false;
            });
            ev_min.enter_notify_event.connect((w, e) => {
                ((Gtk.Bin) w).get_child().override_color(Gtk.StateFlags.NORMAL, hover);
                return false;
            });
            ev_min.leave_notify_event.connect((w, e) => {
                ((Gtk.Bin) w).get_child().override_color(Gtk.StateFlags.NORMAL, normal);
                return false;
            });
            ev_max.enter_notify_event.connect((w, e) => {
                ((Gtk.Bin) w).get_child().override_color(Gtk.StateFlags.NORMAL, hover);
                return false;
            });
            ev_max.leave_notify_event.connect((w, e) => {
                ((Gtk.Bin) w).get_child().override_color(Gtk.StateFlags.NORMAL, normal);
                return false;
            });
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

        public override void style_updated () {
            normal = hover = get_style_context().get_color(Gtk.StateFlags.NORMAL);
            normal.alpha = 0.65;
            ev_min.get_child().override_color(Gtk.StateFlags.NORMAL, normal);
            ev_max.get_child().override_color(Gtk.StateFlags.NORMAL, normal);
        }

    }

}
