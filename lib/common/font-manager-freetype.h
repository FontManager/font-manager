/* font-manager-freetype.h
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

#ifndef __FREETYPE_H__
#define __FREETYPE_H__

#include <glib.h>
#include <json-glib/json-glib.h>

G_BEGIN_DECLS

long font_manager_get_face_count (const gchar * filepath);

/* get_metadata:
 *
 * The returned object will have the following structure:
 *
 * {
 *      "filepath"      :   string,
 *      "findex"        :   int,
 *      "family"        :   string,
 *      "style"         :   string,
 *      "owner"         :   int,
 *      "psname"        :   string,
 *      "filetype"      :   string,
 *      "n_glyphs"      :   int,
 *      "panose"        :   array,
 *      "copyright"     :   string,
 *      "version"       :   string,
 *      "description"   :   string,
 *      "license_data"  :   string,
 *      "license_url"   :   string,
 *      "vendor"        :   string,
 *      "designer"      :   string,
 *      "designer_url   :   string,
 *      "license_type"  :   string,
 *      "fsType"        :   int,
 *      "filesize"      :   string,
 *      "checksum"      :   string
 * }
 */
JsonObject * font_manager_get_metadata (const gchar * filepath, gint index);

G_END_DECLS

#endif /* __FREETYPE_H__ */
