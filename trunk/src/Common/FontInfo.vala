/* FontInfo.vala
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
            if (status != 0)
                warning("Failed to gather information for %s : %i", filepath, status);
            else
                post(filepath);
            return;
        }

        void post (string filepath) {
            /* Strip commonly found words from version string so that
             * we're left with just a number whenever possible.*/
             if (version == null) {
                version = "1.0";
                return;
            }
            foreach (var e in VERSION_STRING_EXCLUDES)
                version = version.replace(e, "");
            version = version.strip();
            /* CFF doesn't really mean much... */
            if (filetype == "CFF" && (filepath.has_suffix(".otf") || filepath.has_suffix(".ttf")))
                filetype = "OpenType";
            return;
        }

    }

}
