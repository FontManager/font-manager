/* CollectionControls.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    public class CollectionControls : Gtk.EventBox {

        public signal void add_selected ();
        public signal void remove_selected ();

        Gtk.Button add_collection;
        Gtk.Button remove_collection;

        public CollectionControls () {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.border_width = 2;
            add_collection = new Gtk.Button();
            add_collection.set_image(new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU));
            add_collection.set_tooltip_text("Add new collection");
            remove_collection = new Gtk.Button();
            remove_collection.set_image(new Gtk.Image.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU));
            remove_collection.set_tooltip_text("Remove selected collection");
            box.pack_start(add_collection, false, false, 0);
            box.pack_start(remove_collection, false, false, 0);
            set_default_button_relief(box);
            box.show_all();
            add(box);
            connect_signals();
        }

        internal void connect_signals () {
            add_collection.clicked.connect((w) => { add_selected(); });
            remove_collection.clicked.connect(() => { remove_selected(); });
            return;
        }

    }

}
