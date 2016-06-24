/* Glue.vala
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

namespace FreeType {

    public int num_faces (string filepath) {
        return (int) get_face_count(filepath);
    }

    public int query_file_info (FontManager.FontInfo fileinfo, string filepath, int index = 0) {
        return (int) get_file_info(fileinfo, filepath, index);
    }

}

namespace FontConfig {

    public Font? get_font_from_file (string filepath, int index = 0) {
        /* Ensure absolute path */
        return FcGetFontFromFile(File.new_for_path(filepath).get_path(), index);
    }

    public Gee.ArrayList <Font> list_fonts (string? family_name = null) {
        return FcListFonts(family_name);
    }

}

/* Defined in _Glue_.c */
extern long get_face_count (string filepath);
extern int get_file_info (FontManager.FontInfo * fileinfo, string filepath, int index);
extern FontConfig.Font? FcGetFontFromFile (string filepath, int index);
extern Gee.ArrayList <FontConfig.Font> FcListFonts (string? family_name);

