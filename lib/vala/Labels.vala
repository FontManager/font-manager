/* Labels.vala
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
     * PlaceHolder:
     *
     * It's intended use is to provide helpful information about an area
     * which is empty and the user may not yet be familiar with.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-place-holder.ui")]
    public class PlaceHolder : Gtk.Box {

        [GtkChild] public Gtk.Image image { get; }
        [GtkChild] public Gtk.Label label { get; }

        public PlaceHolder (string? str, string? icon) {
            label.set_markup(str);
            image.set_from_icon_name(icon, Gtk.IconSize.DIALOG);
        }

    }

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


