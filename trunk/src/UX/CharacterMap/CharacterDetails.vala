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
        private Gtk.Label name_label;

        public CharacterDetails () {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            name_label = new Gtk.Label(null);
            name_label.margin = 9;
            name_label.opacity = 0.9;
            box.pack_start(name_label, true, true, 0);
            add(box);
            name_label.show();
            box.show();
        }

        private void set_details () {
            name_label.set_markup(Markup.printf_escaped("<b>%s</b>", Gucharmap.get_unicode_name(ac)));
        }

    }

}
