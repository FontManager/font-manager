/* CollectionControls.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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

namespace FontManager {

    public class BaseControls : Gtk.EventBox {

        public signal void add_selected ();
        public signal void remove_selected ();

        public Gtk.Box box { get; protected set; }
        public Gtk.Button add_button { get; protected set; }
        public Gtk.Button remove_button { get; protected set; }

        construct {
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
            box.border_width = 2;
            set_size_request(0, 0);
            add_button = new Gtk.Button();
            add_button.set_image(new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU));
            remove_button = new Gtk.Button();
            remove_button.set_image(new Gtk.Image.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU));
            box.pack_start(add_button, false, false, 0);
            box.pack_start(remove_button, false, false, 0);
            set_default_button_relief(box);
            add(box);
            connect_signals();
        }

        public override void show () {
            add_button.show();
            remove_button.show();
            box.show();
            base.show();
            return;
        }

        private void connect_signals () {
            add_button.clicked.connect((w) => { add_selected(); });
            remove_button.clicked.connect(() => { remove_selected(); });
            return;
        }

    }

}
