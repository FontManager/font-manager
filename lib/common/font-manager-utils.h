/* font-manager-utils.h
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

#pragma once

#include "config.h"

#include <glib/gi18n-lib.h>
#include <locale.h>
#include <unistd.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <gio/gio.h>

#include <fontconfig/fontconfig.h>
#include <freetype/freetype.h>
#include <gtk/gtk.h>
#include <hb.h>
#include <json-glib/json-glib.h>
#include <pango/pango.h>
#include <libxml/xmlversion.h>
#include <sqlite3.h>

#include "font-manager-freetype.h"
#include "font-manager-string-set.h"

#define FONT_MANAGER_TMP_TMPL "font-manager_XXXXXX"

/**
 * FontManagerObjectProperty:
 * @name:   Property name
 * @type:   #GType of property
 * @desc:   Description of property
 *
 * This struct contains the bare minimum amount of information necessary to
 * programmatically construct a GObject property.
 */
typedef struct _ObjectProperty
{
    const gchar *name;
    const GType type;
    const gchar *desc;
}
FontManagerObjectProperty;

void font_manager_setup_i18n (void);
void font_manager_print_os_info (void);
void font_manager_print_library_versions (void);
gint font_manager_get_file_owner (const gchar *filepath);
gint font_manager_natural_sort (const gchar *str1, const gchar *str2) G_GNUC_PURE;
gint font_manager_timecmp (GFile *file_a, GFile *file_b);
gboolean font_manager_exists (const gchar *filepath);
gboolean font_manager_is_dir (const gchar *filepath);
gboolean font_manager_install_file (GFile *file, GFile *directory, GError **error);
gchar * font_manager_get_file_extension (const gchar *filepath) G_GNUC_PURE;
gchar * font_manager_get_local_time (void);
gchar * font_manager_get_user_font_directory (void);
gchar * font_manager_get_package_cache_directory (void);
gchar * font_manager_get_package_config_directory (void);
gchar * font_manager_get_user_fontconfig_directory (void);
gchar * font_manager_str_replace (const gchar *str, const gchar *target, const gchar *replacement) G_GNUC_PURE;
gchar * font_manager_to_filename (const gchar *str) G_GNUC_PURE;
GSettings * font_manager_get_gsettings (const gchar *schema_id);
void font_manager_free_gsettings ();
FontManagerStringSet * font_manager_get_command_line_files (GApplicationCommandLine *cmdline);

