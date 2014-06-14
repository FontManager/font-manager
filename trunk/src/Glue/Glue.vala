/* Glue.vala
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

namespace FreeType {

    public int num_faces (string filepath) {
        return (int) get_face_count(filepath);
    }

    public int query_file_info (FontManager.FontInfo fileinfo, string filepath, int index = 0) {
        return (int) get_file_info(fileinfo, filepath, index);
    }

}

namespace FontConfig {

    public string get_version_string () {
        string raw = FcGetVersion().to_string();
        if (raw.length == 5)
            return "%c.%c%c.%s".printf(raw.get(0), raw.get(1), raw.get(2), raw.substring(3));
        else
            return raw;
    }

    public bool update_cache () {
        return FcCacheUpdate();
    }

    public Font? get_font_from_file (string filepath, int index = 0) {
        /* Ensure absolute path */
        return FcGetFontFromFile(File.new_for_path(filepath).get_path(), index);
    }

    public Gee.ArrayList <Font> list_fonts (string? family_name = null) {
        return FcListFonts(family_name);
    }

    public Gee.ArrayList <string> list_families () {
        return FcListFamilies();
    }

    public Gee.ArrayList <string> list_files () {
        return FcListFiles();
    }

    public Gee.ArrayList <string> list_dirs (bool recursive = true) {
        return FcListDirs(recursive);
    }

    public Gee.ArrayList <string> list_user_dirs () {
        return FcListUserDirs();
    }

    public bool enable_user_config (bool enable = true) {
        return FcEnableUserConfig(enable);
    }

    public bool add_app_font (string filepath) {
        return FcAddAppFont(filepath);
    }

    public bool add_app_font_dir (string dir) {
        return FcAddAppFontDir(dir);
    }

    public void clear_app_fonts () {
        FcClearAppFonts();
        return;
    }

    public bool load_config (string filepath) {
        return FcLoadConfig(filepath);
    }

}

/* Defined in fontconfig.h */
extern int FcGetVersion();
/* Defined in _Glue_.c */
extern long get_face_count (string filepath);
extern FontConfig.Font? FcGetFontFromFile (string filepath, int index);
extern Gee.ArrayList <FontConfig.Font> FcListFonts (string? family_name);
extern Gee.ArrayList <string> FcListFamilies ();
extern Gee.ArrayList <string> FcListFiles ();
extern Gee.ArrayList <string> FcListDirs (bool recursive);
extern Gee.ArrayList <string> FcListUserDirs ();
extern bool FcEnableUserConfig (bool enable);
extern bool FcAddAppFont (string filepath);
extern bool FcAddAppFontDir (string dir);
extern void FcClearAppFonts ();
extern bool FcLoadConfig (string filepath);
extern bool FcCacheUpdate ();
extern int get_file_info (FontManager.FontInfo * fileinfo, string filepath, int index);

