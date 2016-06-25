/* Controls.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    /**
     * Controls:
     *
     * #Gtk.Actionbar containing a save and discard button along with a notice
     * informing the user that changes may not take effect immediately.
     * Intended for use in dialogs which generate Fontconfig configuration files.
     */
    public class Controls : Gtk.ActionBar {

        /**
         * Controls::save_selected:
         *
         * Emitted when the user clicks Save
         */
        public signal void save_selected ();

        /**
         * Controls::discard_selected:
         *
         * Emitted when the user clicks Discard
         */
        public signal void discard_selected ();

        /**
         * Controls:note:
         *
         * Informational notice displayed between discard and save buttons.
         */
        public Gtk.Label note { get; private set; }

        Gtk.Button save;
        Gtk.Button discard;

        public Controls () {
            save = new Gtk.Button.with_label(_("Save"));
            save.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            discard = new Gtk.Button.with_label(_("Discard"));
            discard.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            note = new Gtk.Label(_("Running applications may require a restart to reflect any changes."));
            note.opacity = 0.75;
            note.wrap = true;
            note.justify = Gtk.Justification.CENTER;
            pack_end(save);
            pack_start(discard);
            set_center_widget(note);
            connect_signals();
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            save.show();
            discard.show();
            note.show();
            base.show();
            return;
        }

        void connect_signals () {
            save.clicked.connect(() => {
                save_selected();
            });
            discard.clicked.connect(() => {
                discard_selected();
            });
            return;
        }

    }

}
