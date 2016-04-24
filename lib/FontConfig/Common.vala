/* Common.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    public string get_version_string () {
        string raw = FcGetVersion().to_string();
        return "%c.%c%c.%s".printf(raw.get(0), raw.get(1), raw.get(2), raw.substring(3));
    }

    public string get_config_dir () {
        string config_dir = Path.build_filename(Environment.get_user_config_dir(), "fontconfig", "conf.d");
        if (DirUtils.create_with_parents(config_dir, 0755) != 0)
            critical("Failed to create %s!".printf(config_dir));
        return config_dir;
    }

    /*
     * This function loads any user configuration files which do not
     * interfere with our ability to render fonts properly.
     */
    public void load_user_fontconfig_files () {
        string [] exclude = { "39-Alias.conf", "78-Reject.conf" };
        try {
            string config_dir = get_config_dir();
            File directory = File.new_for_path(config_dir);
            FileEnumerator enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
            GLib.FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                string filename = file_info.get_name();
                if (filename.has_suffix(".conf")) {
                    if (filename in exclude)
                        continue;
                    string filepath = Path.build_filename(config_dir, filename);
                    if (!load_config(filepath))
                        warning("Fontconfig : Failed to parse file : %s", filepath);
                }
            }
        } catch (Error e) {
            critical(e.message);
        }
        return;
    }

    /*
     * This function adds user configured font sources (directories)
     * to our FcConfig so that we can render fonts which are not
     * actually "installed". It also ensures the default font directory
     * is included.
     */
    public bool load_user_font_sources (Source [] sources) {
        clear_app_fonts();
        bool res = true;
        foreach (var source in sources) {
            if (source.available && !add_app_font_dir(source.path)) {
                res = false;
                warning("Failed to register user font source! : %s", source.path);
            } else {
                verbose("Added source to configuration : %s", source.path);
            }
        }
        string default_user_font_dir_path = Path.build_filename(Environment.get_user_data_dir(), "fonts");
        {
            File default_user_font_dir = File.new_for_path(default_user_font_dir_path);
            if (!default_user_font_dir.query_exists())
                /* Means the user does not have a default font directory yet, create it */
                try {
                    default_user_font_dir.make_directory_with_parents();
                } catch (Error e) {
                    warning("Attempt to create default font directory failed : %s", default_user_font_dir_path);
                    critical(e.message);
                }
        }
        if (!add_app_font_dir(default_user_font_dir_path)) {
            res = false;
            warning("Failed to register user font source! : %s", default_user_font_dir_path);
        } else {
            verbose("Added default user font directory to configuration");
        }
        return res;
    }

    public bool update_cache () {
        return FcCacheUpdate();
    }

    public Gee.ArrayList <string> list_families () {
        return FcListFamilies();
    }

    public Gee.ArrayList <string> list_files () {
        return FcListFiles();
    }

    public Gee.ArrayList <string> list_dirs (bool recursive = false) {
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
/* Defined in _Common_.c */
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
