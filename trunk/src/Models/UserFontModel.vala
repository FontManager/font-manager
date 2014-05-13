/* UserFontModel.vala
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

    public class UserFontModel : Gtk.TreeStore {

        construct {
            set_column_types({typeof(Object), typeof(string)});
        }

        public UserFontModel (FontConfig.Families families, Database db) {
            var _families = new Gee.HashSet <string> ();
            var descriptions = new Gee.HashSet <string> ();
            get_matching_families_and_fonts(db, _families, descriptions, "owner=0");
            bool visible = true;
            foreach(var entry in families.list()) {
                var family = families[entry];
                visible = (family.name in _families);
                if (visible) {
                    foreach(var face in family.list_faces()) {
                        visible = true;
                        if (!(face.description in descriptions))
                            visible = false;
                        if (visible) {
                            Gtk.TreeIter iter;
                            this.append(out iter, null);
                            this.set(iter, 0, face, 1, face.description, -1);
                        }
                    }
                }
            }
        }

    }

}
