/* LabeledSpinButton.vala
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
     * LabeledSpinButton:
     *
     * @label:      text to display in label
     * @min:        minimum value for #GtkSpinButton
     * @max:        maximum value for #GtkSpinButton
     * @step:       step increment for #GtkSpinButton.adjustment
     *
     * Row like widget containing a #GtkLabel and a #GtkSpinButton.
     *
     * ------------------------------------------------------------
     * |                                                          |
     * | label                                       spinbutton   |
     * |                                                          |
     * ------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-spin-button.ui")]
    public class LabeledSpinButton : Gtk.Box {

        /**
         * LabeledControl:label:
         *
         * #GtkLabel
         */
        [GtkChild] public Gtk.Label label { get; }

        /**
         * LabeledControl:description:
         *
         * Centered #GtkLabel with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        /**
         * LabeledSpinButton:value:
         *
         * Current value.
         */
        public double @value { get; set; default = 0.0; }

        [GtkChild] Gtk.SpinButton spin;

        public LabeledSpinButton (string? label, double min, double max, double step) {
            this.label.set_text(label != null ? label : "");
            spin.set_adjustment(new Gtk.Adjustment(0, min, max, step, 0, 0));
            bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

}

