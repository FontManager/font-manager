/* font-manager-utils.h
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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


#ifndef __UTILS_H__
#define __UTILS_H__

#include <glib.h>
#include <gio/gio.h>

G_BEGIN_DECLS

typedef struct
{
    guint processed;
    guint total;
    gchar *message;
}
FontManagerProgressData;

typedef gboolean (*FontManagerProgressCallback) (FontManagerProgressData *data);

FontManagerProgressData * font_manager_get_progress_data (const gchar *message, guint processed, guint total);
void font_manager_free_progress_data (gpointer data);

gint font_manager_get_file_owner (const gchar *filepath);
gint font_manager_natural_sort (const gchar *s1, const gchar *s2);
gboolean font_manager_exists (const gchar *filepath);
gboolean font_manager_is_dir (const gchar *filepath);
gchar * font_manager_get_file_extension (const gchar *filepath);
gchar * font_manager_get_local_time (void);
gchar * font_manager_get_user_font_directory (void);
gchar * font_manager_get_package_cache_directory (void);
gchar * font_manager_get_package_config_directory (void);
gchar * font_manager_get_user_fontconfig_directory (void);
gchar * font_manager_str_replace (const gchar *str, const gchar *target, const gchar *replacement);
gchar * font_manager_to_filename (const gchar *str);
GSettings * font_manager_get_gsettings (const gchar *schema_id);

G_END_DECLS

#endif /* __UTILS_H__ */

