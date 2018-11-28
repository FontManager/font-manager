/* font-manager-fontconfig.h
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

#ifndef __FONTCONFIG_H__
#define __FONTCONFIG_H__

#include <glib.h>
#include <gmodule.h>
#include <fontconfig/fontconfig.h>
#include <json-glib/json-glib.h>

G_BEGIN_DECLS

void clear_application_fonts (void);
gboolean add_application_font (const gchar *filepath);
gboolean add_application_font_directory (const gchar *dir);
gboolean enable_user_font_configuration (gboolean enable);
gboolean load_font_configuration_file (const gchar *filepath);
gboolean update_font_configuration (void);
GList * list_available_font_files (void);
GList * list_available_font_families (void);
GList * list_font_directories (gboolean recursive);
GList * list_user_font_directories (gboolean recursive);
GList * get_charset_from_font_object (JsonObject *font_object);
GList * get_charset_from_filepath (const gchar *filepath, int index);
GList * get_charset_from_fontconfig_pattern (FcPattern *pattern);
GList * get_langs_from_fontconfig_pattern (FcPattern *pattern);

/* get_attributes_*:
 *
 * Returns a #JsonObject with the following structure:
 *
 * {
 *    "filepath"  : string,
 *    "findex"     : int,
 *    "family"    : string,
 *    "style"     : string,
 *    "spacing"   : int,
 *    "slant"     : int,
 *    "weight"    : int,
 *    "width"     : int,
 *    "description" : string,
 *    "_index"    : int
 * }
 *
 * If the environment variable DEBUG is set each object will also have
 * a member named pattern which will contain its FcPattern as a string.
 */
JsonObject * get_attributes_from_filepath (const gchar *filepath, int index);
JsonObject * get_attributes_from_fontconfig_pattern (FcPattern *pattern);

/* get_available_*:
 *
 * Returns a #JsonObject with the following structure:
 *
 *    "Family" : {
 *        "Style" : {
 *            "filepath"  : string,
 *            "findex"     : int,
 *            "family"    : string,
 *            "style"     : string,
 *            "spacing"   : int,
 *            "slant"     : int,
 *            "weight"    : int,
 *            "width"     : int,
 *            "description" : string,
 *            "_index"    : int
 *        },
 *        ...
 *    },
 *    ...
 */
JsonObject * get_available_fonts (const gchar *family_name);
JsonObject * get_available_fonts_for_chars (const gchar *chars);
JsonObject * get_available_fonts_for_lang (const gchar *lang_id);

/* sort_json_font_listing:
 *
 * Returns a #JsonArray with the following structure:
 *
 * [
 *    {
 *        "family"        : string,
 *        "n_variations   : int,
 *        "variations"    : [
 *            {
 *                "filepath"  : string,
 *                "findex"     : int,
 *                "family"    : string,
 *                "style"     : string,
 *                "spacing"   : int,
 *                "slant"     : int,
 *                "weight"    : int,
 *                "width"     : int,
 *                "description" : string,
 *                "_index"    : int
 *            },
 *            ...
 *        ],
 *        "description"   : string,
 *        "_index"        : int
 *    },
 *    ...
 * ]
 */
JsonArray * sort_json_font_listing (JsonObject *json_obj);

G_END_DECLS

#endif /* __FONTCONFIG_H__ */
