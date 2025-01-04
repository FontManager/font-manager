/* Disabled.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

    public class Disabled : Category {

        public Reject disabled_families { get; set; default = new Reject(); }

        public Disabled () {
            base(_("Disabled"),
                 _("Fonts which have been disabled"),
                 "list-remove-symbolic",
                 null,
                 CategoryIndex.DISABLED);
            disabled_families.load();
        }

        public override async void update () {
            families.clear();
            variations.clear();
            try {
                Database db = DatabaseProxy.get_default_db();
                foreach (var family in disabled_families) {
                    family = family.replace("'", "''");
                    string sql = @"$SELECT_FROM_FONTS WHERE family='$family';";
                    get_matching_families_and_fonts(db, families, variations, sql);
                }
            } catch (Error e) {
                warning(e.message);
            }
            changed();
            return;
        }

    }

}

