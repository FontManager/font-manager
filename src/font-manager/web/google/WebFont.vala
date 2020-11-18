/* WebFont.vala
 *
 * Copyright (C) 2020 Jerry Casiano
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

namespace FontManager.GoogleFonts {

    const string FONT_FACE = "@font-face { font-family: '%s'; font-style: %s; font-weight: %i; src: local('%s'), local('%s'), url(%s) format('truetype'); }";

    public class Family : Object {

        public string family { get; set; }
        public string category { get; set; }
        public GenericArray <Font> variants { get; set; }
        public GenericSet <string> subsets { get; set; }
        public int count { get; private set; default = 0; }

        public Family (Json.Object source) {
            family = source.get_string_member("family");
            category = source.get_string_member("category");
            variants = new GenericArray <Font> ();
            subsets = new GenericSet <string> (str_hash, str_equal, null);
            var filelist = source.get_object_member("files");
            source.get_array_member("variants").foreach_element((array, index, node) => {
                var entry = node.get_string();
                var variant = new Font(family, entry, filelist.get_string_member(entry));
                variants.insert((int) index, variant);
                count++;
            });
            source.get_array_member("subsets").foreach_element((array, index, node) => {
                subsets.add(node.get_string());
            });
        }

        public Font get_default_variant () {
            Font result = variants[0];
            variants.foreach((variant) => {
                if (variant.italic)
                    return;
                if ((Weight) variant.weight == Weight.REGULAR)
                    result = variant;
            });
            return result;
        }

        public string to_stylesheet () {
            var builder = new StringBuilder();
            variants.foreach((variant) => { builder.append(variant.to_font_face_rule()); });
            return builder.str;
        }

    }

    public class Font : Object {

        public string family { get; set; }
        public string url { get; set; }
        public int weight { get; set; }
        public bool italic { get; set; }
        public string style { get { return italic ? "italic" : "normal"; } }

        public Font (string family, string variant, string url) {
            Object(family: family, url: url);
            italic = variant.contains("italic");
            if (variant == "regular" || variant == "italic")
                weight = (int) Weight.REGULAR;
            else
                weight = int.parse(italic ? variant.replace("italic", "") : variant);
        }

        public string to_display_name () {
            string ital = italic ? _("Italic") : "";
            if (italic && weight == Weight.REGULAR)
                return ital;
            return "%s %s".printf(((Weight) weight).to_translatable_string(), ital).strip();
        }

        public string to_description () {
            string ital = italic ? "Italic" : "";
            if (italic && (Weight) weight == Weight.REGULAR)
                return ital;
            return "%s %s".printf(((Weight) weight).to_string(), ital).strip();
        }

        public string to_font_face_rule () {
            string description = to_description();
            string local = "%s %s".printf(family, description);
            string _local = "%s-%s".printf(family.replace(" ", ""), description.replace(" ", ""));
            string style = italic ? "italic" : "normal";
            return FONT_FACE.printf(family, style, weight, local, _local, url);
        }

    }

}
