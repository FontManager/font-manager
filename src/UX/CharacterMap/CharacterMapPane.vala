/* CharacterMapPane.vala
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

    public class CharacterMapPane : Gtk.Box {

        public CharacterTable table { get; private set; }
        public CharacterDetails details { get; private set; }

        public CharacterMapPane () {
            orientation = Gtk.Orientation.VERTICAL;
            table = new CharacterTable();
            details = new CharacterDetails();
            pack_start(details, false, true, 0);
            pack_start(table, true, true, 0);
            table.active_character.connect((ch) => { details.active_character = ch; });
        }

        public override void show () {
            table.show();
            details.show();
            base.show();
            return;
        }

    }

}
