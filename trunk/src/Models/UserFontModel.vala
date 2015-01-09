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

    public class UserFontModel : FontModel {

        public weak Database db { get; set; }

        private Category user_fonts;

        public UserFontModel (FontConfig.Families families, Database db) {
            this.db = db;
            user_fonts = new Category("", "", "", "owner=0 AND filepath LIKE \"%s%\"".printf(get_user_font_dir()));
            user_fonts.update(db);
            this.families = families;
            this.update(user_fonts);
        }

    }

}
