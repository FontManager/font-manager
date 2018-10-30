/* font-manager-database.h
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

#ifndef __FONT_MANAGER_DATABASE_H__
#define __FONT_MANAGER_DATABASE_H__

#include <glib.h>
#include <gmodule.h>
#include <glib-object.h>
#include <json-glib/json-glib.h>
#include <sqlite3.h>

#include "string-hashset.h"
#include "utils.h"

G_BEGIN_DECLS

#define FONT_MANAGER_CURRENT_DATABASE_VERSION 1

#define FONT_MANAGER_TYPE_DATABASE (font_manager_database_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerDatabase, font_manager_database, FONT_MANAGER, DATABASE, GObject)

#define FONT_MANAGER_TYPE_DATABASE_ITERATOR (font_manager_database_iterator_get_type())
G_DECLARE_FINAL_TYPE(FontManagerDatabaseIterator, font_manager_database_iterator, FONT_MANAGER, DATABASE_ITERATOR, GObject)

GQuark font_manager_database_error_quark ();
#define FONT_MANAGER_DATABASE_ERROR (font_manager_database_error_quark ())

/* These map directly to SQLite primary result codes */
typedef enum
{
    FONT_MANAGER_DATABASE_ERROR_OK,
    FONT_MANAGER_DATABASE_ERROR_ERROR,
    FONT_MANAGER_DATABASE_ERROR_INTERNAL,
    FONT_MANAGER_DATABASE_ERROR_PERM,
    FONT_MANAGER_DATABASE_ERROR_ABORT,
    FONT_MANAGER_DATABASE_ERROR_BUSY,
    FONT_MANAGER_DATABASE_ERROR_LOCKED,
    FONT_MANAGER_DATABASE_ERROR_NOMEM,
    FONT_MANAGER_DATABASE_ERROR_READONLY,
    FONT_MANAGER_DATABASE_ERROR_INTERRUPT,
    FONT_MANAGER_DATABASE_ERROR_IOERR,
    FONT_MANAGER_DATABASE_ERROR_CORRUPT,
    FONT_MANAGER_DATABASE_ERROR_NOTFOUND,
    FONT_MANAGER_DATABASE_ERROR_FULL,
    FONT_MANAGER_DATABASE_ERROR_CANTOPEN,
    FONT_MANAGER_DATABASE_ERROR_PROTOCOL,
    FONT_MANAGER_DATABASE_ERROR_EMPTY,
    FONT_MANAGER_DATABASE_ERROR_SCHEMA,
    FONT_MANAGER_DATABASE_ERROR_TOOBIG,
    FONT_MANAGER_DATABASE_ERROR_CONSTRAINT,
    FONT_MANAGER_DATABASE_ERROR_MISMATCH,
    FONT_MANAGER_DATABASE_ERROR_MISUSE,
    FONT_MANAGER_DATABASE_ERROR_NOLFS,
    FONT_MANAGER_DATABASE_ERROR_AUTH,
    FONT_MANAGER_DATABASE_ERROR_FORMAT,
    FONT_MANAGER_DATABASE_ERROR_RANGE,
    FONT_MANAGER_DATABASE_ERROR_NOTADB,
    FONT_MANAGER_DATABASE_ERROR_NOTICE,
    FONT_MANAGER_DATABASE_ERROR_WARNING,
    FONT_MANAGER_DATABASE_ERROR_ROW = 100,
    FONT_MANAGER_DATABASE_ERROR_DONE = 101
}
FontManagerDatabaseError;

struct _FontManagerDatabase
{
    GObjectClass parent_class;

    sqlite3 *db;
    sqlite3_stmt *stmt;
};

typedef enum
{
    FONT_MANAGER_DATABASE_TYPE_BASE,
    FONT_MANAGER_DATABASE_TYPE_FONT,
    FONT_MANAGER_DATABASE_TYPE_METADATA,
    FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY
}
FontManagerDatabaseType;

const gchar * font_manager_database_get_type_name (FontManagerDatabaseType type);
gchar * font_manager_database_get_file (FontManagerDatabaseType type);

FontManagerDatabase * font_manager_database_new (void);
void font_manager_database_open (FontManagerDatabase *self, GError **error);
void font_manager_database_begin_transaction (FontManagerDatabase *self, GError **error);
void font_manager_database_commit_transaction (FontManagerDatabase *self, GError **error);
void font_manager_database_execute_query (FontManagerDatabase *self, const gchar *sql, GError **error);
int font_manager_database_get_version (FontManagerDatabase *self, GError **error);
void font_manager_database_set_version (FontManagerDatabase *self, int version, GError **error);
void font_manager_database_vacuum (FontManagerDatabase *self, GError **error);
void font_manager_database_initialize (FontManagerDatabase *self, FontManagerDatabaseType type, GError **error);
void font_manager_database_attach (FontManagerDatabase *self, FontManagerDatabaseType type, GError **error);
void font_manager_database_detach (FontManagerDatabase *self, FontManagerDatabaseType type, GError **error);
JsonObject * font_manager_database_get_object (FontManagerDatabase *self, const gchar *sql, GError **error);
FontManagerDatabaseIterator * font_manager_database_iterator (FontManagerDatabase *self);

/* Standard Iterator protocol */
FontManagerDatabaseIterator * font_manager_database_iterator_new (FontManagerDatabase *db);
gboolean font_manager_database_iterator_next (FontManagerDatabaseIterator *self);
sqlite3_stmt * font_manager_database_iterator_get (FontManagerDatabaseIterator *self);

/* Related functions */

FontManagerDatabase * font_manager_get_database (FontManagerDatabaseType type, GError **error);

void font_manager_sync_database (FontManagerDatabase *db,
                                  FontManagerDatabaseType type,
                                  FontManagerProgressCallback progress,
                                  GCancellable *cancellable,
                                  GAsyncReadyCallback callback,
                                  gpointer user_data);

gboolean font_manager_sync_database_finish (GAsyncResult *result, GError **error);

void font_manager_get_matching_families_and_fonts (FontManagerDatabase *db,
                                                    StringHashset *families,
                                                    StringHashset *fonts,
                                                    const gchar *sql,
                                                    GError **error);

G_END_DECLS

#endif /* __FONT_MANAGER_DATABASE_H__ */
