/* CharacterDetails.vala
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

    public class CharacterDetails : Gtk.EventBox {

        public unichar active_character {
            get {
                return ac;
            }
            set {
                ac = value;
                set_details();
            }
        }

        private unichar ac;
        private Gtk.Label unicode_label;
        private Gtk.Label name_label;

        public CharacterDetails () {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            unicode_label = new Gtk.Label(null);
            unicode_label.halign = Gtk.Align.END;
            unicode_label.selectable = true;
            name_label = new Gtk.Label(null);
            name_label.halign = Gtk.Align.START;
            name_label.opacity = unicode_label.opacity = 0.9;
            unicode_label.margin = name_label.margin = 8;
            box.pack_start(unicode_label, true, true, 2);
            box.pack_end(name_label, true, true, 2);
            add(box);
            unicode_label.show();
            name_label.show();
            box.show();
        }

        private void set_details () {
            unicode_label.set_markup(Markup.printf_escaped("<b>U+%4.4X</b>", ac));
            name_label.set_markup(Markup.printf_escaped("<b>%s</b>", Gucharmap.get_unicode_name(ac)));
            return;
        }

    }

}
