/* Families.vala
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

namespace FontConfig {

    internal Gee.ArrayList <string> sorted_list_from_collection (Gee.Collection <string> iter) {
        var l = new Gee.ArrayList <string> ();
        l.add_all(iter);
        l.sort((CompareDataFunc) natural_cmp);
        return l;
    }

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
                progress(_("Loading available font families"), processed, total);
            }
        }

        public string to_data () {
            var builder = new Json.Builder();
            builder.begin_object();
            foreach (var key in this.list()) {
                builder.set_member_name(key);
                builder.add_value(Json.gobject_serialize(this[key]));
            }
            builder.end_object();
            var generator = new JsonWriter(builder.get_root());
            size_t len;
            string res = generator.to_data(out len);
            return res;
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

        public Gee.HashSet <string> list_font_descriptions () {
            var l = list_fonts();
            var descriptions = new Gee.HashSet <string> ();
            foreach (var font in l) {
                descriptions.add(font.family);
                descriptions.add(font.description);
            }
            return descriptions;
        }

    }

}
