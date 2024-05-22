/* font-manager-database.c
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

#include "font-manager-database.h"

#include "font-manager-database-iterator.h"
#include "font-manager-database-error.h"

/**
 * SECTION: font-manager-database
 * @short_description: Database related functions
 * @title: Database
 * @include: font-manager-database.h
 * @stability: Unstable
 *
 * Database class and related functions.
 */

#define CREATE_FONTS_TABLE "CREATE TABLE IF NOT EXISTS Fonts ( " \
"uid INTEGER PRIMARY KEY, filepath TEXT, findex INTEGER, family TEXT, " \
"style TEXT, spacing INTEGER, slant INTEGER, weight INTEGER, " \
"width INTEGER, description TEXT );\n"

#define CREATE_INFO_TABLE "CREATE TABLE IF NOT EXISTS Metadata ( " \
"uid INTEGER PRIMARY KEY, filepath TEXT, findex INTEGER, family TEXT, " \
"style TEXT, owner INTEGER, psname TEXT, filetype TEXT, 'n-glyphs' INTEGER, " \
"copyright TEXT, version TEXT, description TEXT, 'license-data' TEXT, " \
"'license-url' TEXT, vendor TEXT, designer TEXT, 'designer-url' TEXT, " \
"'license-type' TEXT, fsType INTEGER, filesize TEXT, checksum TEXT );\n"

#define CREATE_PANOSE_TABLE "CREATE TABLE IF NOT EXISTS Panose ( " \
"uid INTEGER PRIMARY KEY, P0 INTEGER, P1 INTEGER, P2 INTEGER, P3 INTEGER, " \
"P4 INTEGER, P5 INTEGER, P6 INTEGER, P7 INTEGER, P8 INTEGER, P9 INTEGER, " \
"filepath TEXT, findex INTEGER );\n"

#define CREATE_ORTH_TABLE "CREATE TABLE IF NOT EXISTS Orthography ( " \
"uid INTEGER PRIMARY KEY, filepath TEXT, findex INT, support TEXT, sample TEXT );\n"

#define CREATE_FONT_MATCH_INDEX "CREATE INDEX IF NOT EXISTS font_match_idx " \
"ON Fonts (filepath, findex, family, description);\n"

#define CREATE_INFO_MATCH_INDEX "CREATE INDEX IF NOT EXISTS info_match_idx " \
"ON Metadata (filepath, findex, owner, filetype, vendor, 'license-type');\n"

#define CREATE_PANOSE_MATCH_INDEX "CREATE INDEX IF NOT EXISTS panose_match_idx " \
"ON Panose (filepath, findex, P0);\n"

#define DROP_FONT_MATCH_INDEX "DROP INDEX IF EXISTS font_match_idx;\n"
#define DROP_INFO_MATCH_INDEX "DROP INDEX IF EXISTS info_match_idx;\n"
#define DROP_PANOSE_MATCH_INDEX "DROP INDEX IF EXISTS panose_match_idx;\n"

#define INSERT_FONT_ROW "INSERT OR REPLACE INTO Fonts VALUES (NULL,?,?,?,?,?,?,?,?,?);"
#define INSERT_INFO_ROW "INSERT OR REPLACE INTO Metadata VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);"
#define INSERT_PANOSE_ROW "INSERT OR REPLACE INTO Panose VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?);"
#define INSERT_ORTH_ROW "INSERT OR REPLACE INTO Orthography VALUES (NULL, ?, ?, ?, ?);"

#define FONT_PROPERTIES FontProperties
#define INFO_PROPERTIES InfoProperties

struct _FontManagerDatabase
{
    GObject parent_instance;

    sqlite3 *db;
    sqlite3_stmt *stmt;
    gboolean in_transaction;
    gchar *file;
};

G_DEFINE_TYPE(FontManagerDatabase, font_manager_database, G_TYPE_OBJECT)

static void
set_error (FontManagerDatabase *self, const gchar *ctx, GError **error)
{
    g_return_if_fail(error == NULL || *error == NULL);
    const gchar *msg_format = "Database Error : (%s) [%i] - %s";
    g_debug(msg_format, ctx, sqlite3_errcode(self->db), sqlite3_errmsg(self->db));
    g_set_error(error,
                FONT_MANAGER_DATABASE_ERROR,
                (FontManagerDatabaseError) sqlite3_errcode(self->db),
                msg_format, ctx, sqlite3_errcode(self->db), sqlite3_errmsg(self->db));
    return;
}

static gboolean
sqlite3_open_failed (FontManagerDatabase *self, GError **error)
{
    g_return_val_if_fail(self != NULL, TRUE);
    g_return_val_if_fail((error == NULL || *error == NULL), TRUE);
    if (self->db != NULL)
        return FALSE;
    GError *err = NULL;
    font_manager_database_open(self, &err);
    if (err != NULL) {
        g_propagate_error(error, err);
        g_warning("Database Error : Failed to open database.");
        return TRUE;
    }
    return FALSE;
}

static gboolean
sqlite3_step_succeeded (FontManagerDatabase *db, int expected_result)
{
    int actual_result = sqlite3_step(db->stmt);
    if (actual_result == expected_result)
        return TRUE;
    if (actual_result != SQLITE_OK && actual_result != SQLITE_ROW && actual_result != SQLITE_DONE)
        g_warning("SQLite Result Code %i : %s", sqlite3_errcode(db->db), sqlite3_errmsg(db->db));
    return FALSE;
}

/**
 * font_manager_database_close:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Close database.
 * It is not necessary to call this function in normal usage.
 */
void
font_manager_database_close (FontManagerDatabase *self, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    sqlite3_exec(self->db, "PRAGMA optimize;", NULL, NULL, NULL);
    if (self->db && (sqlite3_close(self->db) != SQLITE_OK))
        set_error(self, "sqlite3_close", error);
    self->db = NULL;
    return;
}

static void
font_manager_database_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerDatabase *self = FONT_MANAGER_DATABASE(gobject);
    font_manager_database_end_query(self);
    font_manager_database_close(self, NULL);
    g_clear_pointer(&self->file, g_free);
    G_OBJECT_CLASS(font_manager_database_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_database_class_init (FontManagerDatabaseClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = font_manager_database_dispose;
    return;
}

static void
font_manager_database_init (FontManagerDatabase *self)
{
    g_return_if_fail(self != NULL);
    g_autofree gchar *cache_dir = font_manager_get_package_cache_directory();
    g_autofree gchar *db_file = g_strdup_printf("%s.sqlite", PACKAGE_NAME);
    self->file = g_build_filename(cache_dir, db_file, NULL);
    font_manager_database_open(self, NULL);
    font_manager_database_initialize(self, NULL);
    return;
}

/**
 * font_manager_database_open:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Open database.
 *
 * Note: It is not necessary to call this function in normal usage.
 * The methods provided by this class will open the database if needed.
 */
void
font_manager_database_open (FontManagerDatabase *self, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (self->db != NULL)
        return;
    if (sqlite3_open(self->file, &self->db) != SQLITE_OK)
        set_error(self, "sqlite3_open", error);
    return;
}

/**
 * font_manager_database_begin_transaction:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Begin a transaction, this should be paired with
 * #font_manager_database_commit_transaction().
 */
void
font_manager_database_begin_transaction (FontManagerDatabase *self, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (self->in_transaction)
        return;
    if (sqlite3_open_failed(self, error))
        return;
    if (sqlite3_exec(self->db, "BEGIN;", NULL, NULL, NULL) != SQLITE_OK)
        set_error(self, "sqlite3_exec", error);
    self->in_transaction = TRUE;
    return;
}

/**
 * font_manager_database_get_cursor: (skip)
 * @self:   #FontManagerDatabase
 *
 * Returns: (transfer none) (nullable): #sqlite3_stmt or %NULL
 */
sqlite3_stmt *
font_manager_database_get_cursor (FontManagerDatabase *self) {
    g_return_val_if_fail(self != NULL, NULL);
    return self->stmt;
}

/**
 * font_manager_database_commit_transaction:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * End a transaction. It is an error to call this function without having
 * previously called #font_manager_database_begin_transaction().
 */
void
font_manager_database_commit_transaction (FontManagerDatabase *self, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (!self->in_transaction) {
        g_set_error(error, FONT_MANAGER_DATABASE_ERROR, FONT_MANAGER_DATABASE_ERROR_MISUSE,
                    G_STRLOC" : Not in transaction. Nothing to commit.");
        g_return_if_reached();
    }
    if (sqlite3_exec(self->db, "COMMIT;", NULL, NULL, NULL) != SQLITE_OK)
        set_error(self, "sqlite3_exec", error);
    self->in_transaction = FALSE;
    return;
}

/**
 * font_manager_database_execute_query:
 * @self:   #FontManagerDatabase
 * @sql:    Valid SQL query
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Calls to this function must be paired with a call to #font_manager_database_end_query
 */
void
font_manager_database_execute_query (FontManagerDatabase *self, const gchar *sql, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(sql != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (sqlite3_open_failed(self, error))
        return;
    if (sqlite3_prepare_v2(self->db, sql, -1, &self->stmt, NULL) != SQLITE_OK)
        set_error(self, sql, error);
    return;
}

/**
 * font_manager_database_end_query:
 * @self:   #fontManagerDatabase
 *
 * Finalize the prepared statement created by a previous call to #font_manager_database_execute_query
 */
void
font_manager_database_end_query (FontManagerDatabase *self)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->stmt, sqlite3_finalize);
    return;
}

/**
 * font_manager_database_get_version:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Returns: Database schema version or -1 on error.
 */
gint
font_manager_database_get_version (FontManagerDatabase *self, GError **error)
{
    int result = -1;
    g_return_val_if_fail(self != NULL, result);
    g_return_val_if_fail((error == NULL || *error == NULL), result);
    if (sqlite3_open_failed(self, error))
        return result;
    font_manager_database_execute_query(self, "PRAGMA user_version", error);
    g_return_val_if_fail(error == NULL || *error == NULL, result);
    if (sqlite3_step(self->stmt) == SQLITE_ROW)
        result = sqlite3_column_int(self->stmt, 0);
    font_manager_database_end_query(self);
    return result;
}

/**
 * font_manager_database_vacuum:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Run sqlite3 VACUUM command on currently selected database.
 */
void
font_manager_database_vacuum (FontManagerDatabase *self, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (sqlite3_open_failed(self, error))
        return;
    if (sqlite3_exec(self->db, "VACUUM", NULL, NULL, NULL) != SQLITE_OK)
        set_error(self, "sqlite3_exec", error);
    return;
}

/**
 * font_manager_database_initialize:
 * @self:   #FontManagerDatabase instance
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Ensures database is at latest schema version.
 * Creates required tables if needed.
 */
void
font_manager_database_initialize (FontManagerDatabase *self,
                                  GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(self));
    g_return_if_fail(error == NULL || *error == NULL);

    bool db_exists = font_manager_exists(self->file);
    int CURRENT_VERSION = FONT_MANAGER_CURRENT_DATABASE_VERSION;

    if (font_manager_database_get_version(self, NULL) == CURRENT_VERSION) {
        g_debug("Database version is current, skipping intialization");
        font_manager_database_close(self, error);
        return;
    } else if (db_exists) {
        g_debug("Database version is outdated, removing file");
        font_manager_database_close(self, error);
        if (g_remove(self->file) < 0)
            g_critical("Failed to remove outdated database file : %s", self->file);
    } else {
        g_debug("Database file not found, creating and initializing database");
    }
    if (self->db == NULL)
        font_manager_database_open(self, NULL);
    sqlite3_exec(self->db, "PRAGMA journal_mode = WAL;", NULL, 0, 0);
    sqlite3_exec(self->db, "PRAGMA synchronous = NORMAL;", NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_FONTS_TABLE, NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_INFO_TABLE, NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_PANOSE_TABLE, NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_ORTH_TABLE, NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_FONT_MATCH_INDEX, NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_INFO_MATCH_INDEX, NULL, 0, 0);
    sqlite3_exec(self->db, CREATE_PANOSE_MATCH_INDEX, NULL, 0, 0);
    g_autofree gchar *sql = g_strdup_printf("PRAGMA user_version = %i", CURRENT_VERSION);
    sqlite3_exec(self->db, sql, NULL, 0, 0);
    return;
}

/**
 * font_manager_database_get_object:
 * @self: #FontManagerDatabase
 * @sql: SQL query
 * @error: #GError or %NULL to ignore errors
 *
 * Returns: (transfer full) (nullable):
 * #JsonObject representation of first result,
 * %NULL if there were no results or there was an error.
 */
JsonObject *
font_manager_database_get_object (FontManagerDatabase *self, const gchar *sql, GError **error)
{
    g_return_val_if_fail(FONT_MANAGER_IS_DATABASE(self), NULL);
    g_return_val_if_fail(sql != NULL, NULL);
    g_return_val_if_fail((error == NULL || *error == NULL), NULL);

    font_manager_database_execute_query(self, sql, error);

    if (error != NULL && *error != NULL)
        return NULL;

    if (!sqlite3_step_succeeded(self, SQLITE_ROW))
        return NULL;

    JsonObject *obj = json_object_new();

    for (gint i = 0; i < sqlite3_column_count(self->stmt); i++) {
        const gchar *name = sqlite3_column_origin_name(self->stmt, i);
        gint int_column = -1;
        const unsigned char *text_column = NULL;
        switch (sqlite3_column_type(self->stmt, i)) {
            case SQLITE_INTEGER:
                int_column = sqlite3_column_int(self->stmt, i);
                json_object_set_int_member(obj, name, int_column);
                break;
            case SQLITE_TEXT:
                text_column = sqlite3_column_text(self->stmt, i);
                json_object_set_string_member(obj, name, (const gchar *) text_column);
                break;
            case SQLITE_NULL:
                json_object_set_null_member(obj, name);
                break;
            default:
                break;
        }
    }
    font_manager_database_end_query(self);
    if (json_object_get_size(obj) < 1)
        g_clear_pointer(&obj, json_object_unref);
    return obj;
}

/**
 * font_manager_database_new:
 *
 * Returns: (transfer full): #FontManagerDatabase
 */
FontManagerDatabase *
font_manager_database_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_DATABASE, NULL);
}

/* Related functions */

typedef struct
{
    FontManagerDatabase *db;
    JsonArray *available_fonts;
    FontManagerProgressCallback progress;
}
DatabaseSyncData;

static DatabaseSyncData *
sync_data_new (FontManagerDatabase *db,
               JsonArray *available_fonts,
               FontManagerProgressCallback progress)
{
    DatabaseSyncData *sync_data = g_new0(DatabaseSyncData, 1);
    sync_data->db = g_object_ref(db);
    sync_data->available_fonts = json_array_ref(available_fonts);
    sync_data->progress = progress;
    return sync_data;
}

static void
sync_data_free (DatabaseSyncData *data)
{
    g_clear_object(&data->db);
    g_clear_pointer(&data->available_fonts, json_array_unref);
    g_clear_pointer(&data, g_free);
    return;
}

static void
bind_from_properties (sqlite3_stmt *stmt,
                      JsonObject *json,
                      const FontManagerJsonProxyProperty *properties,
                      gint n_properties)
{
    for (gint i = 0; i < n_properties; i++) {
        const gchar *str = NULL;
        switch (properties[i].type) {
            case G_TYPE_INT64:
                g_assert(json_object_has_member(json, properties[i].name));
                gint val = json_object_get_int_member(json, properties[i].name);
                g_assert(val >= -1 && sqlite3_bind_int(stmt, i, val) == SQLITE_OK);
                break;
            case G_TYPE_STRING:
                if (g_strcmp0(properties[i].name, "preview-text") == 0)
                    break;
                if (json_object_has_member(json, properties[i].name))
                    str = json_object_get_string_member(json, properties[i].name);
                g_assert(sqlite3_bind_text(stmt, i, str, -1, SQLITE_STATIC) == SQLITE_OK);
                break;
            default:
                break;
        }
    }
    return;
}

static FontManagerStringSet *
get_known_files (FontManagerDatabase *db)
{
    FontManagerStringSet *result = font_manager_string_set_new();
    g_return_val_if_fail(FONT_MANAGER_IS_DATABASE(db), result);
    const gchar *sql = "SELECT DISTINCT filepath FROM Metadata";
    g_autoptr(GError) error = NULL;
    font_manager_database_execute_query(db, sql, &error);
    if (error != NULL) {
        g_critical("%s", error->message);
        return result;
    }
    g_autoptr(FontManagerDatabaseIterator) iter = font_manager_database_iterator(db);
    while (font_manager_database_iterator_next(iter)) {
        sqlite3_stmt *stmt = font_manager_database_iterator_get(iter);
        const gchar *val = (const gchar *) sqlite3_column_text(stmt, 0);
        if (val)
            font_manager_string_set_add(result, val);
    }
    font_manager_database_end_query(db);
    return result;
}

static const gchar *FONT_MANAGER_SKIP_ORTH_SCAN[] = {
     /* Adobe Blank can take several minutes to process due to number of codepoints. */
    "Adobe Blank",
    NULL
};

static void
update_available_fonts (DatabaseSyncData *data,
                        GCancellable *cancellable,
                        GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(data->db));
    g_return_if_fail(error == NULL || *error == NULL);

    FontManagerDatabase *db = FONT_MANAGER_DATABASE(data->db);

    uint processed = 0;
    uint total = json_array_get_length(data->available_fonts);
    const gchar *message = _("Updating Database…");
    g_autoptr(FontManagerStringSet) known_files = get_known_files(db);
    FontManagerProgressData *progress = font_manager_progress_data_new(message, processed, total);

    font_manager_database_begin_transaction(db, error);
    g_return_if_fail(error == NULL || *error == NULL);

    for (uint i = 0; i < total; i++) {
        if (g_cancellable_is_cancelled(cancellable))
            break;
        /* Stash results periodically so we don't lose everything if closed */
        if (processed > 0 && processed % 500 == 0) {
            font_manager_database_commit_transaction(db, error);
            g_return_if_fail(error == NULL || *error == NULL);
            font_manager_database_begin_transaction(db, error);
            g_return_if_fail(error == NULL || *error == NULL);
        }
        JsonObject *family = json_array_get_object_element(data->available_fonts, i);
        const gchar *family_name = json_object_get_string_member(family, "family");
        JsonArray *variations = json_object_get_array_member(family, "variations");
        uint n_variations = json_array_get_length(variations);
        for (uint v = 0; v < n_variations; v++) {
            // g_autofree gchar *json_data = font_manager_print_json_object(json, FALSE);
            // g_debug("Database.update_available_fonts : processing : %s", json_data);
            JsonObject *face = json_array_get_object_element(variations, v);
            int index = json_object_get_int_member(face, "findex");
            const gchar *filepath = json_object_get_string_member(face, "filepath");
            // Font table
            font_manager_database_execute_query(db, INSERT_FONT_ROW, error);
            g_return_if_fail(error == NULL || *error == NULL);
            bind_from_properties(db->stmt, face, FONT_PROPERTIES, G_N_ELEMENTS(FONT_PROPERTIES));
            g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
            g_return_if_fail(error == NULL || *error == NULL);
            font_manager_database_end_query(db);
            if (font_manager_string_set_contains(known_files, filepath)) {
                g_debug("Database.update_available_fonts : ignoring known font path : %i : %s", index, filepath);
                continue;
            } else {
                g_debug("Database.update_available_fonts : adding new font path : %i : %s", index, filepath);
                // Metadata table
                g_autoptr(JsonObject) _face = font_manager_get_metadata(filepath, index, error);
                if (error != NULL && *error != NULL) {
                    GError *err = *error;
                    g_critical("Failed to get metadata for %s::%i - %s", filepath, index, err->message);
                    g_return_if_fail(error == NULL || *error == NULL);
                }
                font_manager_database_execute_query(db, INSERT_INFO_ROW, error);
                g_return_if_fail(error == NULL || *error == NULL);
                bind_from_properties(db->stmt, _face, INFO_PROPERTIES, G_N_ELEMENTS(INFO_PROPERTIES));
                g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
                font_manager_database_end_query(db);
                // Panose table
                if (json_object_has_member(_face, "panose")) {
                    JsonArray *panose = json_object_get_array_member(_face, "panose");
                    if (panose && json_array_get_length(panose) > 0) {
                        font_manager_database_execute_query(db, INSERT_PANOSE_ROW, error);
                        g_return_if_fail(error == NULL || *error == NULL);
                        for (int i = 0; i < 10; i++) {
                            int _index = i + 1;
                            int val = (int) json_array_get_int_element(panose, i);
                            g_assert(sqlite3_bind_int(db->stmt, _index, val) == SQLITE_OK);
                        }
                        g_assert(sqlite3_bind_text(db->stmt, 11, filepath, -1, SQLITE_STATIC) == SQLITE_OK);
                        g_assert(sqlite3_bind_int(db->stmt, 12, index) == SQLITE_OK);
                        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
                        font_manager_database_end_query(db);
                    }
                }
                // Orthogaphy table
                gboolean blank_font = FALSE;
                if (g_strv_contains(FONT_MANAGER_SKIP_ORTH_SCAN, family_name))
                    blank_font = TRUE;
                g_autoptr(JsonObject) orth = font_manager_get_orthography_results(blank_font ? NULL : face);
                g_autofree gchar *json_obj = font_manager_print_json_object(orth, FALSE);
                const gchar *sample = json_object_get_string_member(orth, "sample");
                font_manager_database_execute_query(db, INSERT_ORTH_ROW, error);
                g_assert(sqlite3_bind_text(db->stmt, 1, filepath, -1, SQLITE_STATIC) == SQLITE_OK);
                g_assert(sqlite3_bind_int(db->stmt, 2, index) == SQLITE_OK);
                g_assert(sqlite3_bind_text(db->stmt, 3, json_obj, -1, SQLITE_STATIC) == SQLITE_OK);
                g_assert(sqlite3_bind_text(db->stmt, 4, sample, -1, SQLITE_STATIC) == SQLITE_OK);
                g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
                font_manager_database_end_query(db);
            }
        }
        processed++;
        if (data->progress) {
            g_object_ref(progress);
            g_object_set(progress, "processed", processed, "total", total, NULL);
            g_main_context_invoke_full(g_main_context_get_thread_default(),
                                       G_PRIORITY_HIGH_IDLE,
                                       (GSourceFunc) data->progress,
                                       progress,
                                       (GDestroyNotify) g_object_unref);
        }
    }
    font_manager_database_commit_transaction(db, error);
    g_object_unref(progress);
    return;
}

gboolean
font_manager_update_database_sync (DatabaseSyncData *data,
                                   GCancellable *cancellable,
                                   GError **error)
{
    g_return_val_if_fail(FONT_MANAGER_IS_DATABASE(data->db), FALSE);
    g_return_val_if_fail((error == NULL || *error == NULL), FALSE);

    if (g_cancellable_is_cancelled(cancellable))
        return FALSE;

    if (data->db->db == NULL)
        font_manager_database_open(data->db, NULL);

    sqlite3_exec(data->db->db, "DELETE FROM Fonts;", NULL, 0, 0);
    sqlite3_exec(data->db->db, CREATE_FONTS_TABLE, NULL, 0, 0);
    sqlite3_exec(data->db->db, CREATE_FONT_MATCH_INDEX, NULL, 0, 0);
    update_available_fonts(data, cancellable, error);
    g_return_val_if_fail(error == NULL || *error == NULL, FALSE);
    return TRUE;
}


static void
sync_database_thread (GTask *task,
                      G_GNUC_UNUSED gpointer source,
                      gpointer task_data,
                      GCancellable *cancellable)
{
    GError *error = NULL;
    gboolean result = FALSE;
    DatabaseSyncData *data = task_data;

    result = font_manager_update_database_sync(data, cancellable, &error);

    if (error == NULL)
        g_task_return_boolean(task, result);
    else
        g_task_return_error(task, error);
}

/**
 * font_manager_update_database:
 * @db: #FontManagerDatabase instance
 * @available_fonts: #JsonArray returned by #font_manager_sort_json_listing
 * @progress: (scope call) (nullable): #FontManagerProgressCallback
 * @cancellable: (nullable): #GCancellable or %NULL
 * @callback: (nullable) (scope async): #GAsyncReadyCallback or %NULL
 * @user_data: (nullable): user data passed to callback or %NULL
 *
 * Update application database as needed.
 */
void
font_manager_update_database (FontManagerDatabase *db,
                              JsonArray *available_fonts,
                              FontManagerProgressCallback progress,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
    g_return_if_fail(cancellable == NULL || G_IS_CANCELLABLE (cancellable));
    DatabaseSyncData *sync_data = sync_data_new(db, available_fonts, progress);
    g_autoptr(GTask) task = g_task_new(NULL, cancellable, callback, user_data);
    g_task_set_priority(task, G_PRIORITY_DEFAULT);
    g_task_set_return_on_cancel(task, FALSE);
    g_task_set_task_data(task, (gpointer) sync_data, (GDestroyNotify) sync_data_free);
    g_task_run_in_thread(task, sync_database_thread);
    return;
}

/**
 * font_manager_update_database_finish:
 * @result: #GAsyncResult
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_update_database_finish (GAsyncResult *result, GError **error)
{
    g_return_val_if_fail(g_task_is_valid(result, NULL), FALSE);
    g_return_val_if_fail(error == NULL || *error == NULL, FALSE);
    return g_task_propagate_boolean(G_TASK(result), error);
}

/**
 * font_manager_get_matching_families_and_fonts:
 * @db: #FontManagerDatabase
 * @families: #FontManagerStringSet
 * @fonts: #FontManagerStringSet
 * @sql: SQL query to execute
 * @error: #GError or %NULL to ignore errors
 *
 * Query MUST return two result columns. The first containing the family name
 * and the second containing the font description.
 */
void
font_manager_get_matching_families_and_fonts (FontManagerDatabase *db,
                                              FontManagerStringSet *families,
                                              FontManagerStringSet *fonts,
                                              const gchar *sql,
                                              GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(db));
    g_return_if_fail(FONT_MANAGER_IS_STRING_SET(families));
    g_return_if_fail(FONT_MANAGER_IS_STRING_SET(fonts));
    g_return_if_fail(sql != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    font_manager_database_execute_query(db, sql, error);
    g_return_if_fail(error == NULL || *error == NULL);
    g_autoptr(FontManagerDatabaseIterator) iter = font_manager_database_iterator(db);
    while (font_manager_database_iterator_next(iter)) {
        sqlite3_stmt *stmt = font_manager_database_iterator_get(iter);
        g_assert(sqlite3_column_count(stmt) >= 2);
        const gchar *family = (const gchar *) sqlite3_column_text(stmt, 0);
        const gchar *font = (const gchar *) sqlite3_column_text(stmt, 1);
        if (family == NULL || font == NULL)
            continue;
        font_manager_string_set_add(families, family);
        font_manager_string_set_add(fonts, font);
    }
    font_manager_database_end_query(db);
    return;
}

