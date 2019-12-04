/* PreviewControls.vala
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
     * PreviewControls:
     *
     * Row like widget providing controls to justify, edit and reset preview text.
     *
     * -------------------------------------------------------------------
     * |                                                                 |
     * | justify controls           description             edit  reset  |
     * |                                                                 |
     * -------------------------------------------------------------------
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preview-controls.ui")]
    public class PreviewControls : Gtk.EventBox {

        /**
         * PreviewControls::justification_set:
         *
         * Emitted when the user toggles justification
         */
        public signal void justification_set (Gtk.Justification justification);

        /**
         * PreviewControls::editing:
         *
         * Emitted when editing mode has changed.
         */
        public signal void editing (bool enabled);

        /**
         * PreviewControls::on_clear_clicked:
         *
         * Emitted when user has requested text be reset to default
         */
        public signal void on_clear_clicked ();

        /**
         * PreviewControls:clear_is_sensitive:
         *
         * Whether reset function is available.
         */
        public bool clear_is_sensitive {
            get {
                return clear.get_sensitive();
            }
            set {
                clear.set_sensitive(value);
            }
        }

        public string title {
            get {
                return description.get_text();
            }
            set {
                description.set_text(value);
            }
        }

        [GtkChild] Gtk.Label description;
        [GtkChild] Gtk.Button clear;
        [GtkChild] Gtk.ToggleButton edit;
        [GtkChild] Gtk.RadioButton justify_left;
        [GtkChild] Gtk.RadioButton justify_center;
        [GtkChild] Gtk.RadioButton justify_fill;
        [GtkChild] Gtk.RadioButton justify_right;

        public override void constructed () {
            justify_center.set_active(true);
            justify_left.toggled.connect(() => { justification_set(Gtk.Justification.LEFT); });
            justify_center.toggled.connect(() => { justification_set(Gtk.Justification.CENTER); });
            justify_fill.toggled.connect(() => { justification_set(Gtk.Justification.FILL); });
            justify_right.toggled.connect(() => { justification_set(Gtk.Justification.RIGHT); });
            clear.clicked.connect(() => { on_clear_clicked(); });
            edit.toggled.connect(() => { editing(edit.get_active()); });
            base.constructed();
            return;
        }

    }

}

