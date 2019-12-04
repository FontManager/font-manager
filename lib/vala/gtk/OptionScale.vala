/* OptionScale.vala
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

    /**
     * OptionScale:
     *
     * @heading:    string to display centered above scale
     * @options:    string [] of options to create marks for
     *
     * Row like widget containing a #GtkLabel displayed centered
     * above the scale.
     *
     * ---------------------------------------------------------------
     * |                          heading                            |
     * |                                                             |
     * |   options[0] ---------- options[1] ----------- options[2]   |
     * |                                                             |
     * ---------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-option-scale.ui")]
    public class OptionScale : Gtk.Box {

        /**
         * OptionScale:value:
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
        }

        /**
         * OptionScale:options:
         */
        public string [] options { get; construct set;}

        [GtkChild] Gtk.Label label;
        [GtkChild] Gtk.Scale scale;

        public OptionScale (string? heading, string [] options) {
            this.options = options;
            label.set_text(heading);
            scale.set_adjustment(new Gtk.Adjustment(0.0, 0.0, ((double) options.length - 1), 1.0, 1.0, 0.0));
            for (int i = 0; i < options.length; i++)
                scale.add_mark(i, Gtk.PositionType.BOTTOM, options[i]);
            scale.value_changed.connect(() => {
                scale.set_value(Math.round(scale.adjustment.get_value()));
            });
            bind_property("value", scale.adjustment, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

}
