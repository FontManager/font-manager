/* FontConfigControls.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontConfig {

    public class Controls : Gtk.ActionBar {

        public signal void save_selected ();
        public signal void discard_selected ();

        Gtk.Button save;
        Gtk.Button discard;
        Gtk.Label note;

        public Controls () {
            save = new Gtk.Button.with_label(_("Save"));
            save.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            discard = new Gtk.Button.with_label(_("Discard"));
            discard.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            note = new Gtk.Label(_("Running applications may require a restart to reflect any changes."));
            note.opacity = 0.75;
            note.margin_start = note.margin_end = 6;
            note.wrap = true;
            note.justify = Gtk.Justification.CENTER;
            pack_end(save);
            pack_start(discard);
            set_center_widget(note);
            connect_signals();
        }

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
