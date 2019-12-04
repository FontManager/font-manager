/* ReactiveLabel.vala
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

    /**
     * ReactiveLabel:
     *
     * Label which reacts to mouseover and click events.
     * Is actually a #GtkEventBox containing a #GtkLabel since
     * events can not be added to widgets that have no window.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-reactive-label.ui")]
    public class ReactiveLabel : Gtk.EventBox {

        /**
         * ReactiveLabel::clicked:
         *
         * Emitted when the label is clicked
         */
        public signal void clicked ();

        /**
         * Reactivelabel:label:
         *
         * The actual #GtkLabel
         */
        [GtkChild] public Gtk.Label label { get; }

        /**
         * {@inheritDoc}
         */
        public override bool enter_notify_event (Gdk.EventCrossing event) {
            label.opacity = 0.95;
            return false;
        }

        /**
         * {@inheritDoc}
         */
        public override bool leave_notify_event (Gdk.EventCrossing event) {
            label.opacity = 0.65;
            return false;
        }

        /**
         * {@inheritDoc}
         */
        public override bool button_press_event (Gdk.EventButton event) {
            clicked();
            return false;
        }

    }

}
