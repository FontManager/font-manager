/* CharacterMap.vala
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

    public class CharacterMap : Object {

        public signal void mode_set (int mode);
        public signal void active_character (unichar uc);

        public CharacterMapSideBar sidebar { get; private set; }
        public CharacterTable table { get; private set; }

        public double preview_size {
            get {
                return table.preview_size;
            }
            set {
                table.preview_size = value;
            }
        }

        public Pango.FontDescription font_desc {
            get {
                return table.font_desc;
            }
            set {
                table.font_desc = value;
            }
        }

        construct {
            sidebar = new CharacterMapSideBar();
            table = new CharacterTable();
            connect_signals();
        }

        internal void connect_signals () {
            sidebar.mode_set.connect((i) => { mode_set((int) i); });
            table.active_character.connect((uc) => { active_character(uc); });
            return;
        }

        public void show () {
            sidebar.show();
            table.show();
            return;
        }

    }

}
