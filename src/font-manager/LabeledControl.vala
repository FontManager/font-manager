/* LabeledControl.vala
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
     * Row like widget containing two #GtkLabel and a #GtkSwitch.
     * Use #GtkLabel.set_text() / #GtkLabel.set_markup()
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-switch.ui")]
    public class LabeledSwitch : Gtk.Box {

        [GtkChild] public Gtk.Label label { get; }

        /**
         * Centered Label with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        [GtkChild] public Gtk.Switch toggle { get; }

        public LabeledSwitch (string? label = null) {
            this.label.set_text(label != null ? label : "");
        }

    }

    /**
     * Row like widget containing a #GtkLabel and a #GtkSpinButton.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-spin-button.ui")]
    public class LabeledSpinButton : Gtk.Box {

        [GtkChild] public Gtk.Label label { get; }

        /**
         * Centered Label with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        public double @value { get; set; default = 0.0; }

        [GtkChild] Gtk.SpinButton spin;

        public LabeledSpinButton (string? label, double min, double max, double step) {
            this.label.set_text(label != null ? label : "");
            spin.set_adjustment(new Gtk.Adjustment(0, min, max, step, 0, 0));
            bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

    /**
     * Row like widget containing two #GtkLabel and a #GtkSwitch.
     * Use #GtkLabel.set_text() / #GtkLabel.set_markup()
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-labeled-font-button.ui")]
    public class LabeledFontButton : Gtk.Box {

        [GtkChild] public Gtk.Label label { get; }

        /**
         * Centered Label with dim-label style class
         */
        [GtkChild] public Gtk.Label description { get; }

        [GtkChild] public Gtk.FontButton button { get; private set; }

        public string font { get; set; default = DEFAULT_FONT; }

        public LabeledFontButton (string? label = null) {
            this.label.set_text(label != null ? label : "");
            bind_property("font", button, "font", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        }

    }

}
