/* UserFonts.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    public class UserFonts : Category {

        public UserFonts () {
            string user_font_dir = get_user_font_directory();
            string sql = "%s filepath LIKE \"%s%\";".printf(SELECT_FROM_METADATA_WHERE, user_font_dir);
            base(_("User"), _("Fonts available only to you"), "avatar-default", sql);
        }

        public new void update () {
            base.update.begin((obj, res) => { base.update.end(res); });
            return;
        }

    }

}
