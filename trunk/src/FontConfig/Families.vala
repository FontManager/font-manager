/* Families.vala
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

namespace FontConfig {

    public class Families : Gee.HashMap <string, Family> {

        public signal void progress (string? message, int processed, int total);

        public void update () {
            this.clear();
            var families = list_families();
            var total = families.size;
            var processed = 0;
            foreach (var family in families) {
                this[family] = new Family(family);
                processed++;
                progress(null, processed, total);
            }
        }

        public Gee.ArrayList <string> list () {
            return sorted_list_from_collection(keys);
        }

        public Gee.ArrayList <Font> list_fonts () {
            var fonts = new Gee.ArrayList <Font> ();
            foreach (var family in this.values)
                fonts.add_all(family.faces.values);
            return fonts;
        }

    }

}
