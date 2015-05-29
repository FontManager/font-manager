/* Font.vala
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
 */

namespace FontConfig {

    public int sort_fonts (Font a, Font b) {
        if (a.weight != b.weight)
            return a.weight - b.weight;
        else if (a.slant != b.slant)
            return a.slant - b.slant;
        else if (a.width != b.width)
            return a.width - b.width;
        else if (a.style != b.style)
            return natural_cmp(a.style, b.style);
        else
            return 0;
    }

    public class Font : Cacheable {

        public string? filepath { get; set; default = null; }
        public int index { get; set; default = 0; }
        public string? family { get; set; default = null;}
        public string? style { get; set; default = null; }
        public int slant { get; set; default = 0; }
        public int weight { get; set; default = 80; }
        public int width { get; set; default = 100; }
        public int spacing { get; set; default = 0; }
        public int owner { get; set; default = -1; }

        public string? description { get; set; default = null; }

        public string to_filename () {
            return to_string().replace(" ", "_").replace("-", "_");
        }

        public string to_string () {
            var builder = new StringBuilder(family);
            builder_append(builder, ((Weight) weight).to_string());
            builder_append(builder, ((Slant) slant).to_string());
            builder_append(builder, ((Width) width).to_string());
            var result = builder.str.strip();
            if (result == family)
                result = "%s %s".printf(result, style);
            return result;
        }

    }

}
