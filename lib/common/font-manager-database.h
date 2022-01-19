/* font-manager-database.h
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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
#include <glib/gstdio.h>
#include <gmodule.h>
#include <glib-object.h>
#include <json-glib/json-glib.h>
#include <sqlite3.h>

#include "font-manager-orthography.h"
#include "font-manager-fontconfig.h"
#include "font-manager-freetype.h"
#include "font-manager-json.h"
#include "font-manager-font.h"
#include "font-manager-family.h"
#include "font-manager-font-info.h"
#include "font-manager-progress-data.h"
#include "font-manager-string-set.h"
#include "font-manager-utils.h"

G_BEGIN_DECLS

#define FONT_MANAGER_CURRENT_DATABASE_VERSION 15

#define FONT_MANAGER_TYPE_DATABASE (font_manager_database_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerDatabase, font_manager_database, FONT_MANAGER, DATABASE, GObject)

#define FONT_MANAGER_TYPE_DATABASE_ITERATOR (font_manager_database_iterator_get_type())
G_DECLARE_FINAL_TYPE(FontManagerDatabaseIterator, font_manager_database_iterator, FONT_MANAGER, DATABASE_ITERATOR, GObject)

GQuark font_manager_database_error_quark ();
#define FONT_MANAGER_DATABASE_ERROR (font_manager_database_error_quark ())

/**
 * FontManagerDatabaseError:
 * @FONT_MANAGER_DATABASE_ERROR_OK:             SQLITE_OK
 * @FONT_MANAGER_DATABASE_ERROR_ERROR:          SQLITE_ERROR
 * @FONT_MANAGER_DATABASE_ERROR_INTERNAL:       SQLITE_INTERNAL
 * @FONT_MANAGER_DATABASE_ERROR_PERM:           SQLITE_PERM
 * @FONT_MANAGER_DATABASE_ERROR_ABORT:          SQLITE_ABORT
 * @FONT_MANAGER_DATABASE_ERROR_BUSY:           SQLITE_BUSY
 * @FONT_MANAGER_DATABASE_ERROR_LOCKED:         SQLITE_LOCKED
 * @FONT_MANAGER_DATABASE_ERROR_NOMEM:          SQLITE_NOMEM
 * @FONT_MANAGER_DATABASE_ERROR_READONLY:       SQLITE_READONLY
 * @FONT_MANAGER_DATABASE_ERROR_INTERRUPT:      SQLITE_INTERRUPT
 * @FONT_MANAGER_DATABASE_ERROR_IOERR:          SQLITE_IOERR
 * @FONT_MANAGER_DATABASE_ERROR_CORRUPT:        SQLITE_CORRUPT
 * @FONT_MANAGER_DATABASE_ERROR_NOTFOUND:       SQLITE_NOTFOUND
 * @FONT_MANAGER_DATABASE_ERROR_FULL:           SQLITE_FULL
 * @FONT_MANAGER_DATABASE_ERROR_CANTOPEN:       SQLITE_CANTOPEN
 * @FONT_MANAGER_DATABASE_ERROR_PROTOCOL:       SQLITE_PROTOCOL
 * @FONT_MANAGER_DATABASE_ERROR_EMPTY:          SQLITE_EMPTY
 * @FONT_MANAGER_DATABASE_ERROR_SCHEMA:         SQLITE_SCHEMA
 * @FONT_MANAGER_DATABASE_ERROR_TOOBIG:         SQLITE_TOOBIG
 * @FONT_MANAGER_DATABASE_ERROR_CONSTRAINT:     SQLITE_CONSTRAINT
 * @FONT_MANAGER_DATABASE_ERROR_MISMATCH:       SQLITE_MISMATCH
 * @FONT_MANAGER_DATABASE_ERROR_MISUSE:         SQLITE_MISUSE
 * @FONT_MANAGER_DATABASE_ERROR_NOLFS:          SQLITE_NOLFS
 * @FONT_MANAGER_DATABASE_ERROR_AUTH:           SQLITE_AUTH
 * @FONT_MANAGER_DATABASE_ERROR_FORMAT:         SQLITE_FORMAT
 * @FONT_MANAGER_DATABASE_ERROR_RANGE:          SQLITE_RANGE
 * @FONT_MANAGER_DATABASE_ERROR_NOTADB:         SQLITE_NOTADB
 * @FONT_MANAGER_DATABASE_ERROR_NOTICE:         SQLITE_NOTICE
 * @FONT_MANAGER_DATABASE_ERROR_WARNING:        SQLITE_WARNING
 * @FONT_MANAGER_DATABASE_ERROR_ROW:            SQLITE_ROW
 * @FONT_MANAGER_DATABASE_ERROR_DONE:           SQLITE_DONE
 *
 * These errors map directly to SQLite error codes.
 * See https://sqlite.org/rescode.html for more detailed information.
 */
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

GType font_manager_database_error_get_type (void);
#define FONT_MANAGER_TYPE_DATABASE_ERROR (font_manager_database_error_get_type ())

struct _FontManagerDatabase
{
    GObjectClass parent_class;

    sqlite3 *db;
    sqlite3_stmt *stmt;
};

/**
 * FontManagerDatabaseType:
 * @FONT_MANAGER_DATABASE_TYPE_BASE:        Base database file
 * @FONT_MANAGER_DATABASE_TYPE_FONT:        Font style information
 * @FONT_MANAGER_DATABASE_TYPE_METADATA:    Font metadata
 * @FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY: Orthography data
 */
typedef enum
{
    FONT_MANAGER_DATABASE_TYPE_BASE,
    FONT_MANAGER_DATABASE_TYPE_FONT,
    FONT_MANAGER_DATABASE_TYPE_METADATA,
    FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY
}
FontManagerDatabaseType;

GType font_manager_database_type_get_type (void);
#define FONT_MANAGER_TYPE_DATABASE_TYPE (font_manager_database_type_get_type ())

const gchar * font_manager_database_get_type_name (FontManagerDatabaseType type);
gchar * font_manager_database_get_file (FontManagerDatabaseType type);

FontManagerDatabase * font_manager_database_new (void);
void font_manager_database_open (FontManagerDatabase *self, GError **error);
void font_manager_database_begin_transaction (FontManagerDatabase *self, GError **error);
void font_manager_database_commit_transaction (FontManagerDatabase *self, GError **error);
void font_manager_database_execute_query (FontManagerDatabase *self, const gchar *sql, GError **error);
gint font_manager_database_get_version (FontManagerDatabase *self, GError **error);
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

gboolean font_manager_update_database_sync (FontManagerDatabase *db,
                                            FontManagerDatabaseType type,
                                            JsonObject *available_fonts,
                                            FontManagerStringSet *available_files,
                                            FontManagerProgressCallback progress,
                                            GCancellable *cancellable,
                                            GError **error);

void font_manager_update_database (FontManagerDatabase *db,
                                   FontManagerDatabaseType type,
                                   JsonObject *available_fonts,
                                   FontManagerStringSet *available_files,
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

G_END_DECLS

#endif /* __FONT_MANAGER_DATABASE_H__ */
