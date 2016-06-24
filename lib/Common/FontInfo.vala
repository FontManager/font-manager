/* FontInfo.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    /* Words commonly found in font version strings, exclude these */
    internal const string [] VERSION_STRING_EXCLUDES = {
        "Version",
        "version",
        "Revision",
        "revision",
        ";FFEdit",
        "$Revision",
        "$:",
        "$"
    };

    public class FontInfo : Cacheable {

        public int owner { get; set; default = 0; }
        public string? filetype { get; set; default = null; }       /* FreeType file type */
        public string? filesize { get; set; default = null; }       /* Suitable for display */
        public string? checksum { get; set; default = null; }       /* MD5 */
        public string? version { get; set; default = null; }
        public string? psname { get; set; default = null; }         /* PostScript name */
        public string? description { get; set; default = null; }    /* Design description */
        public string? vendor { get; set; default = null; }
        public string? copyright { get; set; default = null; }
        public string? license_type { get; set; default = null; }
        public string? license_data { get; set; default = null; }   /* Embedded license data  */
        public string? license_url { get; set; default = null; }
        public string panose { get; set; default = null; }

        public int status;

        public FontInfo.from_filepath (string filepath, int index = 0) {
            status = FreeType.query_file_info(this, filepath, index);
            post(filepath);
            return;
        }

        void post (string filepath) {
            if (status != 0) {
                warning("Failed to gather information for %s : %i", filepath, status);
                return;
            }
            /* A lot of font files have garbage in their version string so ... */
            do_version_mangling();
            /* CFF doesn't really mean much... */
            if (filetype == "CFF" && (filepath.has_suffix(".otf") || filepath.has_suffix(".ttf")))
                filetype = "OpenType";
            return;
        }

        void do_version_mangling () {
            if (version == null) {
                version = "1.0";
                return;
            }
            /*
             * Strip commonly found words from version string so that
             * we're left with just a number whenever possible.
             */
            foreach (var e in VERSION_STRING_EXCLUDES)
                version = version.replace(e, "");
            version = version.strip();
            /*
             * If version contains ; or : it's likely to contain other info
             * Try to grab just the version number
             */
            if (version.contains(";")) {
                string [] v_array = version.split(";");
                version = v_array[0];
                if (!version.contains("."))
                    foreach (string s in v_array)
                        if (s.contains(".") && !(s.get_char().isalpha()))
                            version = s;
            } else if (version.contains(":")) {
                string [] v_array = version.split(" ");
                version = "1.0";
                foreach (string s in v_array)
                    if (s.contains(".") && !(s.get_char().isalpha()))
                        version = s;
            }
            return;
        }

    }

}
