/* font-manager-database.h
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

#include <locale.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <gmodule.h>
#include <glib-object.h>
#include <json-glib/json-glib.h>
#include <sqlite3.h>

#include "font-manager-orthographies.h"
#include "font-manager-fontconfig.h"
#include "font-manager-freetype.h"
#include "font-manager-json.h"
#include "font-manager-font.h"
#include "font-manager-family.h"
#include "font-manager-font-info.h"
#include "font-manager-progress-data.h"
#include "font-manager-string-set.h"
#include "font-manager-utils.h"

#define FONT_MANAGER_CURRENT_DATABASE_VERSION 1

#define FONT_MANAGER_TYPE_DATABASE font_manager_database_get_type()
G_DECLARE_FINAL_TYPE(FontManagerDatabase, font_manager_database, FONT_MANAGER, DATABASE, GObject)

FontManagerDatabase * font_manager_database_new (void);
void font_manager_database_open (FontManagerDatabase *self, GError **error);
void font_manager_database_close (FontManagerDatabase *self, GError **error);
void font_manager_database_begin_transaction (FontManagerDatabase *self, GError **error);
void font_manager_database_commit_transaction (FontManagerDatabase *self, GError **error);
void font_manager_database_execute_query (FontManagerDatabase *self, const gchar *sql, GError **error);
void font_manager_database_end_query (FontManagerDatabase *self);
sqlite3_stmt * font_manager_database_get_cursor (FontManagerDatabase *self);
void font_manager_database_vacuum (FontManagerDatabase *self, GError **error);
void font_manager_database_initialize (FontManagerDatabase *self, GError **error);
JsonObject * font_manager_database_get_object (FontManagerDatabase *self, const gchar *sql, GError **error);

/* Related functions */

void font_manager_update_database (FontManagerDatabase *db,
                                   JsonArray *available_fonts,
                                   FontManagerProgressCallback progress,
                                   GCancellable *cancellable,
                                   GAsyncReadyCallback callback,
                                   gpointer user_data);

gboolean font_manager_update_database_finish (GAsyncResult *result, GError **error);

void font_manager_get_matching_families_and_fonts (FontManagerDatabase *db,
                                                    FontManagerStringSet *families,
                                                    FontManagerStringSet *fonts,
                                                    const gchar *sql,
                                                    GError **error);


