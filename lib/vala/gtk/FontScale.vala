/* FontScale.vala
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
     * FontScale:
     *
     * Row like widget which displays a #GtkScale and a #GtkSpinButton
     * for adjusting font display size.
     *
     * ------------------------------------------------------------------
     * |                                                                |
     * |  a  |------------------------------------------|  A   [  +/-]  |
     * |                                                                |
     * ------------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-scale.ui")]
    public class FontScale : Gtk.EventBox {

        /**
         * FontScale:value:
         *
         * Current value.
         */
        public double @value { get; set; default = 0.0; }

        /**
         * FontScale:adjustment:
         *
         * #GtkAdjustment in use
         */
        public Gtk.Adjustment adjustment {
            get {
                return scale.get_adjustment();
            }
            set {
                scale.set_adjustment(value);
                spin.set_adjustment(value);
            }
        }

        [GtkChild] Gtk.Scale scale;
        [GtkChild] Gtk.SpinButton spin;
        [GtkChild] ReactiveLabel min;
        [GtkChild] ReactiveLabel max;

        public override void constructed () {
            adjustment = new Gtk.Adjustment(DEFAULT_PREVIEW_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5, 1.0, 0);
            min.label.set_markup("<span font=\"Serif Italic Bold\" size=\"small\"> A </span>");
            max.label.set_markup("<span font=\"Serif Italic Bold\" size=\"large\"> A </span>");
            min.clicked.connect(() => { scale.set_value(MIN_FONT_SIZE); });
            max.clicked.connect(() => { scale.set_value(MAX_FONT_SIZE); });
            bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            base.constructed();
            return;
        }

    }

}

