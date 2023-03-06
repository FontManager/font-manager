/* font-manager-reject.c
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

#include "font-manager-reject.h"

/**
 * SECTION: font-manager-reject
 * @short_description: Fontconfig font selection configuration
 * @title: Disabled Fonts
 * @include: font-manager-reject.h
 *
 * Set of font families that should be excluded from the set of fonts used to resolve
 * list and match requests as if they didn't exist in the system.
 */

struct _FontManagerReject
{
    FontManagerSelections parent_instance;
};

G_DEFINE_TYPE(FontManagerReject, font_manager_reject, FONT_MANAGER_TYPE_SELECTIONS)

static void
font_manager_reject_class_init (FontManagerRejectClass *klass)
{
    return;
}

static gboolean
reload (gpointer self)
{
    g_return_val_if_fail(FONT_MANAGER_IS_REJECT(self), FALSE);
    return !(font_manager_selections_load(FONT_MANAGER_SELECTIONS(self)));
}

static void
on_changed (FontManagerReject *self)
{
    g_timeout_add_seconds(3, (GSourceFunc) reload, self);
    return;
}

static void
font_manager_reject_init (FontManagerReject *self)
{
    g_autofree gchar *config_dir = font_manager_get_user_fontconfig_directory();
    g_object_set(G_OBJECT(self),
                 "config-dir", config_dir,
                 "target-element", "rejectfont",
                 "target-file", "78-Reject.conf",
                 NULL);
    g_signal_connect(self, "changed", G_CALLBACK(on_changed), self);
    return;
}

/**
 * font_manager_reject_get_rejected_files:
 * @self:       #FontManagerReject
 * @error:      #GError or %NULL to ignore errors
 *
 * Returns: (transfer full) (nullable):
 * A set of filepaths for all currently blacklisted fonts or %NULL if there was an error.
 * Free the returned object using #g_object_unref().
 */
FontManagerStringSet *
font_manager_reject_get_rejected_files (FontManagerReject *self, GError **error)
{
    g_return_val_if_fail(self != NULL, NULL);
    g_return_val_if_fail((error == NULL || *error == NULL), NULL);
    g_autoptr(FontManagerStringSet) rejected_files = font_manager_string_set_new();
    g_autoptr(FontManagerDatabase) db = font_manager_database_get_default(FONT_MANAGER_DATABASE_TYPE_FONT, error);
    g_return_val_if_fail(error == NULL || *error == NULL, NULL);
    guint len_rejected = font_manager_string_set_size(FONT_MANAGER_STRING_SET(self));
    for (guint i = 0; i < len_rejected; i++) {
        const gchar *_sql = "SELECT DISTINCT filepath FROM Fonts WHERE family = %s";
        const gchar *data = font_manager_string_set_get(FONT_MANAGER_STRING_SET(self), i);
        char *family = sqlite3_mprintf("%Q", (char *) data);
        g_autofree gchar *sql = g_strdup_printf(_sql, family);
        sqlite3_free(family);
        font_manager_database_execute_query(db, sql, error);
        g_return_val_if_fail(error == NULL || *error == NULL, NULL);
        g_autoptr(FontManagerDatabaseIterator) db_iter = font_manager_database_iterator_new(db);
        while (font_manager_database_iterator_next(db_iter)) {
            sqlite3_stmt *stmt = font_manager_database_iterator_get(db_iter);
            const gchar *path = (const gchar *) sqlite3_column_text(stmt, 0);
            if (font_manager_exists(path))
                font_manager_string_set_add(rejected_files, path);
        }
    }
    return g_steal_pointer(&rejected_files);
}

/**
 * font_manager_reject_new:
 *
 * Returns: (transfer full): A newly created #FontManagerReject.
 * Free the returned object using #g_object_unref().
 */
FontManagerReject *
font_manager_reject_new (void)
{

    return g_object_new(FONT_MANAGER_TYPE_REJECT, NULL);
}
