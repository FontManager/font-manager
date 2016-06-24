/* Query.vala
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

    namespace Library {

        public static bool is_installed (FontData font_data) {
            var filelist = FontConfig.list_files();
            if (font_data.font.filepath in filelist) {
                debug("Font already installed : Filepath match : %s", font_data.font.filepath);
                return true;
            }
            var _filelist = db_match_checksum(font_data.fontinfo.checksum);
            foreach (var f in _filelist)
                if (filelist.contains(f)) {
                    debug("Font already installed : Checksum match");
                    return true;
                }
            return false;
        }

        public static int conflicts (FontData font_data) {
            var unique = db_match_unique_names(font_data);
            var filelist = FontConfig.list_files();
            foreach (var f in unique.keys)
                if (filelist.contains(f)) {
                    debug("%s conflicts with %s", font_data.font.filepath, f);
                    return natural_cmp(unique[f], font_data.fontinfo.version);
                }
            return -1;
        }

        static Gee.ArrayList <string> db_match_checksum (string checksum) {
            var results = new Gee.ArrayList <string> ();
            Database? db = null;
            try {
                db = get_database();
                db.reset();
                db.table = "Fonts";
                db.select = "filepath";
                db.search = "checksum=\"%s\"".printf(checksum);
                db.execute_query();
                foreach (var row in db)
                    results.add(row.column_text(0));
            } catch (DatabaseError e) {
                critical("Database Error : %s", e.message);
                //show_error_message(_("There was an error accessing the database"), e);
            }
            if (db != null)
                db.close();
            return results;
        }

        static Gee.HashMap <string, string> db_match_unique_names (FontData font_data) {
            var results = new Gee.HashMap <string, string> ();
            Database? db = null;
            try {
                db = get_database();
                db.reset();
                db.table = "Fonts";
                db.select = "filepath, version";
                db.search = "psname=\"%s\" OR font_description=\"%s\"".printf(font_data.fontinfo.psname, font_data.font.description);
                db.execute_query();
                foreach (var row in db)
                    results[row.column_text(0)] = row.column_text(1);
            } catch (DatabaseError e) {
                critical("Database Error : %s", e.message);
                //show_error_message(_("There was an error accessing the database"), e);
            }
            if (db != null)
                db.close();
            return results;
        }

    }

}
