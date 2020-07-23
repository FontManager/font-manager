/* font-manager-database.c
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

/**
 * SECTION: font-manager-database
 * @short_description: Database related functions
 * @title: Database
 * @include: font-manager-database.h
 * @stability: Unstable
 *
 * Database class and related functions.
 *
 * The current design uses a three separate database files.
 * The first holds information required for basic font identification,
 * the second holds all the metadata extracted from the font file
 * itself and the third has information related to orthography support.
 *
 * These are then attached to the "base" database for access.
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

typedef struct
{
    gboolean in_transaction;
    gchar *file;
}
FontManagerDatabasePrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerDatabase, font_manager_database, G_TYPE_OBJECT)
G_DEFINE_QUARK(font-manager-database-error-quark, font_manager_database_error)

enum
{
    PROP_RESERVED,
    PROP_FILE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

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
    sqlite3_finalize(self->stmt);
    self->stmt = NULL;
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

/* font_manager_database_close:
 * @self:   #FontManagerDatabase
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Close database.
 * It is not necessary to call this function in normal usage.
 */
static void
font_manager_database_close (FontManagerDatabase *self, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    sqlite3_finalize(self->stmt);
    self->stmt = NULL;
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
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    font_manager_database_close(self, NULL);
    g_clear_pointer(&priv->file, g_free);
    G_OBJECT_CLASS(font_manager_database_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_database_get_property (GObject *gobject,
                                    guint property_id,
                                    GValue *value,
                                    GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerDatabase *self = FONT_MANAGER_DATABASE(gobject);
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    switch (property_id) {
        case PROP_FILE:
            g_value_set_string(value, priv->file);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_database_set_property (GObject *gobject,
                                    guint property_id,
                                    const GValue *value,
                                    GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerDatabase *self = FONT_MANAGER_DATABASE(gobject);
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    switch (property_id) {
        case PROP_FILE:
            font_manager_database_close(self, NULL);
            g_free(priv->file);
            priv->file = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_database_class_init (FontManagerDatabaseClass *klass)
{

    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = font_manager_database_dispose;
    object_class->get_property = font_manager_database_get_property;
    object_class->set_property = font_manager_database_set_property;

    /**
     * FontManagerDatabase:file:
     *
     * Filepath to database.
     */
    obj_properties[PROP_FILE] = g_param_spec_string("file",
                                                    NULL,
                                                    "Database file",
                                                    NULL,
                                                    G_PARAM_READWRITE |
                                                    G_PARAM_STATIC_STRINGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_database_init (FontManagerDatabase *self)
{
    g_return_if_fail(self != NULL);
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    priv->file = g_strdup(":memory:");
    return;
}

/**
 * font_manager_database_get_type_name:
 * @type: #FontManagerDatabaseType
 *
 * Returns: Database type name
 */
const gchar *
font_manager_database_get_type_name (FontManagerDatabaseType type)
{
    switch (type) {
        case FONT_MANAGER_DATABASE_TYPE_FONT:
            return "Fonts";
        case FONT_MANAGER_DATABASE_TYPE_METADATA:
            return "Metadata";
        case FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY:
            return "Orthography";
        default:
            return "";
    }
}

/**
 * font_manager_database_get_file:
 * @type: #FontManagerDatabaseType
 *
 * Returns: (nullable): A newly allocated string or %NULL
 */
gchar *
font_manager_database_get_file (FontManagerDatabaseType type)
{
    g_autofree gchar *cache_dir = font_manager_get_package_cache_directory();
    g_autofree gchar *filename = g_strdup_printf("%s.sqlite", font_manager_database_get_type_name(type));
    return g_build_filename(cache_dir, filename, NULL);
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
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    if (sqlite3_open(priv->file, &self->db) != SQLITE_OK)
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
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    if (priv->in_transaction)
        return;
    if (sqlite3_open_failed(self, error))
        return;
    if (sqlite3_exec(self->db, "BEGIN;", NULL, NULL, NULL) != SQLITE_OK)
        set_error(self, "sqlite3_exec", error);
    priv->in_transaction = TRUE;
    return;
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
    FontManagerDatabasePrivate *priv = font_manager_database_get_instance_private(self);
    if (!priv->in_transaction) {
        g_set_error(error, FONT_MANAGER_DATABASE_ERROR, FONT_MANAGER_DATABASE_ERROR_MISUSE,
                    G_STRLOC" : Not in transaction. Nothing to commit.");
        g_return_if_reached();
    }
    if (sqlite3_exec(self->db, "COMMIT;", NULL, NULL, NULL) != SQLITE_OK)
        set_error(self, "sqlite3_exec", error);
    priv->in_transaction = FALSE;
    return;
}

/**
 * font_manager_database_execute_query:
 * @self:   #FontManagerDatabase
 * @sql:    Valid SQL query
 * @error: (nullable): #GError or %NULL to ignore errors
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
    return result;
}

/**
 * font_manager_database_set_version:
 * @self:       #FontManagerDatabase
 * @version:    version number
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Set database schema version.
 */
void
font_manager_database_set_version (FontManagerDatabase *self, int version, GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (sqlite3_open_failed(self, error))
        return;
    g_autofree gchar *sql = g_strdup_printf("PRAGMA user_version = %i", version);
    font_manager_database_execute_query(self, sql, error);
    g_return_if_fail(error == NULL || *error == NULL);
    if (!sqlite3_step_succeeded(self, SQLITE_DONE))
        set_error(self, "sqlite3_step", error);
    return;
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
 * font_manager_database_detach:
 * @self:   #FontManagerDatabase instance
 * @type:   #FontManagerDatabaseType
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Detaches speficied database.
 */
void
font_manager_database_detach (FontManagerDatabase *self,
                              FontManagerDatabaseType type,
                              GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (sqlite3_open_failed(self, error))
        return;
    const gchar *sql = "DETACH DATABASE %s;";
    const gchar *type_name = font_manager_database_get_type_name(type);
    g_autofree gchar *query = g_strdup_printf(sql, type_name);
    int result = sqlite3_exec(self->db, query, NULL, NULL, NULL);
    /* Ignore most errors here, more than likely means db is not attached */
    if (result != SQLITE_OK && result != SQLITE_ERROR)
        set_error(self, "sqlite3_exec", error);
    return;
}

/**
 * font_manager_database_attach:
 * @self:   #FontManagerDatabase instance
 * @type:   #FontManagerDatabaseType
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Attaches speficied database.
 */
void
font_manager_database_attach (FontManagerDatabase *self,
                              FontManagerDatabaseType type,
                              GError **error)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    if (sqlite3_open_failed(self, error))
        return;
    const gchar *sql = "ATTACH DATABASE '%s' AS %s;";
    const gchar *type_name = font_manager_database_get_type_name(type);
    g_autofree gchar *filepath = font_manager_database_get_file(type);
    g_autofree gchar *query = g_strdup_printf(sql, filepath, type_name);
    if (sqlite3_exec(self->db, query, NULL, NULL, NULL) != SQLITE_OK)
        set_error(self, "sqlite3_exec", error);
    return;
}

/**
 * font_manager_database_initialize:
 * @self:   #FontManagerDatabase instance
 * @type:   #FontManagerDatabaseType
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Ensures database is at latest schema version.
 * Creates required tables if needed.
 */
void
font_manager_database_initialize (FontManagerDatabase *self,
                                  FontManagerDatabaseType type,
                                  GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(self));
    g_return_if_fail(error == NULL || *error == NULL);

    if (font_manager_database_get_version(self, NULL) == FONT_MANAGER_CURRENT_DATABASE_VERSION)
        return;

    font_manager_database_close(self, error);
    g_return_if_fail(error == NULL || *error == NULL);

    g_autofree gchar *db_file = NULL;
    g_object_get(self, "file", &db_file, NULL);
    if (db_file != NULL && g_file_test(db_file, G_FILE_TEST_EXISTS))
        if (g_remove(db_file) == -1)
            g_critical("Failed to remove outdated database file : %s", db_file);

    if (type != FONT_MANAGER_DATABASE_TYPE_BASE) {
        font_manager_database_execute_query(self, "PRAGMA journal_mode=WAL;\n", NULL);
        g_assert(sqlite3_step_succeeded(self, SQLITE_ROW));
        g_assert(sqlite3_strnicmp((const char *) sqlite3_column_text(self->stmt, 0), "wal", 3) == 0);
    }

    if (type == FONT_MANAGER_DATABASE_TYPE_FONT) {

        font_manager_database_execute_query(self, CREATE_FONTS_TABLE, error);
        g_return_if_fail(error == NULL || *error == NULL);
        if (!sqlite3_step_succeeded(self, SQLITE_DONE))
            set_error(self, "sqlite3_step", error);
        g_return_if_fail(error == NULL || *error == NULL);

    } else if (type == FONT_MANAGER_DATABASE_TYPE_METADATA) {

        font_manager_database_execute_query(self, CREATE_INFO_TABLE, error);
        g_return_if_fail(error == NULL || *error == NULL);
        if (!sqlite3_step_succeeded(self, SQLITE_DONE))
            set_error(self, "sqlite3_step", error);
        g_return_if_fail(error == NULL || *error == NULL);

        font_manager_database_execute_query(self, CREATE_PANOSE_TABLE, error);
        g_return_if_fail(error == NULL || *error == NULL);
        if (!sqlite3_step_succeeded(self, SQLITE_DONE))
            set_error(self, "sqlite3_step", error);
        g_return_if_fail(error == NULL || *error == NULL);

    } else if (type == FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY) {

        font_manager_database_execute_query(self, CREATE_ORTH_TABLE, error);
        g_return_if_fail(error == NULL || *error == NULL);
        if (!sqlite3_step_succeeded(self, SQLITE_DONE))
            set_error(self, "sqlite3_step", error);
        g_return_if_fail(error == NULL || *error == NULL);

    }

    font_manager_database_set_version(self, FONT_MANAGER_CURRENT_DATABASE_VERSION, NULL);
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
        switch (sqlite3_column_type(self->stmt, i)) {
            case SQLITE_INTEGER:
                json_object_set_int_member(obj, name, sqlite3_column_int(self->stmt, i));
                break;
            case SQLITE_TEXT:
                json_object_set_string_member(obj, name, (const gchar *) sqlite3_column_text(self->stmt, i));
                break;
            case SQLITE_NULL:
                json_object_set_null_member(obj, name);
                break;
            default:
                break;
        }
    }

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

/**
 * font_manager_database_iterator:
 * @self:   #FontManagerDatabase
 *
 * Returns: (transfer full):   #FontManagerDatabaseIterator.
 * Free the return object using g_object_unref().
 */
FontManagerDatabaseIterator *
font_manager_database_iterator (FontManagerDatabase *self)
{
    return font_manager_database_iterator_new(self);
}

struct _FontManagerDatabaseIterator
{
    GObjectClass parent_class;

    FontManagerDatabase *db;
};

G_DEFINE_TYPE(FontManagerDatabaseIterator, font_manager_database_iterator, G_TYPE_OBJECT)

static void
font_manager_database_iterator_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerDatabaseIterator *self = FONT_MANAGER_DATABASE_ITERATOR(gobject);
    sqlite3_finalize(self->db->stmt);
    self->db->stmt = NULL;
    g_object_unref(self->db);
    G_OBJECT_CLASS(font_manager_database_iterator_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_database_iterator_class_init (FontManagerDatabaseIteratorClass *klass)
{
    G_OBJECT_CLASS(klass)->dispose = font_manager_database_iterator_dispose;
    return;
}

static void
font_manager_database_iterator_init (G_GNUC_UNUSED FontManagerDatabaseIterator *self)
{
    return;
}

/**
 * font_manager_database_next:
 * @self:   #FontManagerDatabase
 *
 * Returns: %TRUE if there are more results in set
 */
gboolean
font_manager_database_iterator_next (FontManagerDatabaseIterator *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(self->db->stmt != NULL, FALSE);
    return sqlite3_step_succeeded(self->db, SQLITE_ROW);
}

/**
 * font_manager_database_iterator_get: (skip)
 * @self:   #FontManagerDatabase
 *
 * Returns: (transfer none): #sqlite3_stmt
 */
sqlite3_stmt *
font_manager_database_iterator_get (FontManagerDatabaseIterator *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return self->db->stmt;
}

/**
 * font_manager_database_iterator_new:
 * @db: #FontManagerDatabase
 *
 * Returns: (transfer full): A newly created #FontManagerDatabaseIterator.
 * Free the returned object using g_object_unref().
 */
FontManagerDatabaseIterator *
font_manager_database_iterator_new (FontManagerDatabase *db)
{
    g_return_val_if_fail(db != NULL, NULL);
    g_return_val_if_fail(db->stmt != NULL, NULL);
    GObject *gobject = g_object_new(FONT_MANAGER_TYPE_DATABASE_ITERATOR, NULL);
    FontManagerDatabaseIterator *self = FONT_MANAGER_DATABASE_ITERATOR(gobject);
    self->db = g_object_ref(db);
    return self;
}

/* Related functions */

typedef void (*InsertCallback) (FontManagerDatabase *db, JsonObject *face, gpointer data);

typedef struct
{
    gchar *table;
    gchar *sql;
    InsertCallback callback;
    FontManagerProgressCallback progress;
    gpointer data;
}
InsertData;

static InsertData *
get_insert_data (const gchar *table, const gchar *sql,
                 InsertCallback callback, FontManagerProgressCallback progress,
                 gpointer data)
{
    InsertData *res = g_new0(InsertData, 1);
    res->table = g_strdup(table);
    res->sql = g_strdup(sql);
    res->callback = callback;
    res->progress = progress;
    res->data = data;
    return res;
}

static void
free_insert_data (InsertData *data)
{
    g_free(data->table);
    g_free(data->sql);
    g_free(data);
    data = NULL;
    return;
}

typedef struct
{
    FontManagerDatabase *db;
    FontManagerDatabaseType type;
    FontManagerProgressCallback progress;
}
DatabaseSyncData;

static DatabaseSyncData *
get_sync_data (FontManagerDatabase *db,
               FontManagerDatabaseType type,
               FontManagerProgressCallback progress)
{
    DatabaseSyncData *sync_data = g_new0(DatabaseSyncData, 1);
    sync_data->db = g_object_ref(db);
    sync_data->type = type;
    sync_data->progress = progress;
    return sync_data;
}

static void
free_sync_data (DatabaseSyncData *data)
{
    g_object_unref(data->db);
    g_free(data);
    data = NULL;
}

static void
bind_from_properties (sqlite3_stmt *stmt,
                      JsonObject *json,
                      const FontManagerJsonProxyProperties *properties,
                      gint n_properties)
{
    for (gint i = 0; i < n_properties; i++) {
        const gchar *str = NULL;
        switch (properties[i].type) {
            case G_TYPE_INT:
                g_assert(json_object_has_member(json, properties[i].name));
                gint val = json_object_get_int_member(json, properties[i].name);
                g_assert(val >= -1 && sqlite3_bind_int(stmt, i, val) == SQLITE_OK);
                break;
            case G_TYPE_STRING:
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

static FontManagerStringHashset *
get_known_files (FontManagerDatabase *db, const gchar *table)
{
    FontManagerStringHashset *result = font_manager_string_hashset_new();
    g_return_val_if_fail(FONT_MANAGER_IS_DATABASE(db), result);
    g_return_val_if_fail(table != NULL, result);
    g_autofree gchar *sql = g_strdup_printf("SELECT DISTINCT filepath FROM %s", table);
    GError *error = NULL;
    font_manager_database_execute_query(db, sql, &error);
    if (error != NULL) {
        g_critical("%s", error->message);
        g_error_free(error);
        return result;
    }
    FontManagerDatabaseIterator *iter = font_manager_database_iterator(db);
    while (font_manager_database_iterator_next(iter)) {
        sqlite3_stmt *stmt = font_manager_database_iterator_get(iter);
        const gchar *val = (const gchar *) sqlite3_column_text(stmt, 0);
        if (val)
            font_manager_string_hashset_add(result, val);
    }
    g_object_unref(iter);
    return result;
}

static void
sync_fonts_table (FontManagerDatabase *db, JsonObject *face, G_GNUC_UNUSED gpointer data)
{
    bind_from_properties(db->stmt, face, FONT_PROPERTIES, G_N_ELEMENTS(FONT_PROPERTIES));
    g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
    sqlite3_clear_bindings(db->stmt);
    sqlite3_reset(db->stmt);
    return;
}

static void
sync_metadata_table (FontManagerDatabase *db, JsonObject *face, gpointer data)
{
    JsonArray *panose_info = data;
    int index = json_object_get_int_member(face, "findex");
    const gchar *filepath = json_object_get_string_member(face, "filepath");
    GError *error = NULL;
    JsonObject *_face = font_manager_get_metadata(filepath, index, &error);
    if (error != NULL) {
        g_critical("Failed to get metadata for %s::%i - %s", filepath, index, error->message);
        json_object_unref(_face);
        return;
    }
    bind_from_properties(db->stmt, _face, INFO_PROPERTIES, G_N_ELEMENTS(INFO_PROPERTIES));
    g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
    sqlite3_clear_bindings(db->stmt);
    sqlite3_reset(db->stmt);
    JsonNode *_panose = json_object_dup_member(_face, "panose");
    if (_panose) {
        JsonObject *panose = json_object_new();
        json_object_set_string_member(panose, "filepath", filepath);
        json_object_set_int_member(panose, "findex", index);
        json_object_set_member(panose, "panose", _panose);
        json_array_add_object_element(panose_info, panose);
    }
    json_object_unref(_face);
    return;
}

static void
sync_panose_table (FontManagerDatabase *db,
                   JsonArray *panose,
                   GCancellable *cancellable,
                   GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(db));
    g_return_if_fail(panose != NULL);
    g_return_if_fail(error == NULL || *error == NULL);

    guint total = json_array_get_length(panose);
    if (total == 0)
        return;
    font_manager_database_begin_transaction(db, error);
    g_return_if_fail(error == NULL || *error == NULL);
    font_manager_database_execute_query(db, INSERT_PANOSE_ROW, error);
    g_return_if_fail(error == NULL || *error == NULL);
    for (guint processed = 0; processed < total; processed++) {
        if (g_cancellable_is_cancelled(cancellable))
            break;
        int val;
        JsonObject *obj = json_array_get_object_element(panose, processed);
        JsonArray *_panose = json_object_get_array_member(obj, "panose");
        for (int i = 0; i < 10; i++) {
            int index = i + 1;
            val = (int) json_array_get_int_element(_panose, i);
            g_assert(sqlite3_bind_int(db->stmt, index, val) == SQLITE_OK);
        }
        const gchar *filepath = json_object_get_string_member(obj, "filepath");
        g_assert(sqlite3_bind_text(db->stmt, 11, filepath, -1, SQLITE_STATIC) == SQLITE_OK);
        val = json_object_get_int_member(obj, "findex");
        g_assert(sqlite3_bind_int(db->stmt, 12, val) == SQLITE_OK);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
        sqlite3_clear_bindings(db->stmt);
        sqlite3_reset(db->stmt);
    }
    font_manager_database_commit_transaction(db, error);
    return;
}

static const gchar *FONT_MANAGER_SKIP_ORTH_SCAN[] = {
     /* Adobe Blank can take several minutes to process due to number of codepoints. */
    "Adobe Blank",
    NULL
};

static void
sync_orth_table (FontManagerDatabase *db, JsonObject *face, G_GNUC_UNUSED gpointer data)
{
    int index = json_object_get_int_member(face, "findex");
    const gchar *filepath = json_object_get_string_member(face, "filepath");
    const gchar *family = json_object_get_string_member(face, "family");
    gboolean blank_font = FALSE;
    if (g_strv_contains(FONT_MANAGER_SKIP_ORTH_SCAN, family))
        blank_font = TRUE;
    g_autoptr(JsonObject) orth = font_manager_get_orthography_results(blank_font ? NULL : face);
    g_autofree gchar *json_obj = font_manager_print_json_object(orth, FALSE);
    const gchar *sample = json_object_get_string_member(orth, "sample");
    g_assert(sqlite3_bind_text(db->stmt, 1, filepath, -1, SQLITE_STATIC) == SQLITE_OK);
    g_assert(sqlite3_bind_int(db->stmt, 2, index) == SQLITE_OK);
    g_assert(sqlite3_bind_text(db->stmt, 3, json_obj, -1, SQLITE_STATIC) == SQLITE_OK);
    g_assert(sqlite3_bind_text(db->stmt, 4, sample, -1, SQLITE_STATIC) == SQLITE_OK);
    g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
    sqlite3_clear_bindings(db->stmt);
    sqlite3_reset(db->stmt);
    return;
}

static void
update_available_fonts (FontManagerDatabase *db,
                        InsertData *insert,
                        GCancellable *cancellable,
                        GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(db));
    g_return_if_fail(error == NULL || *error == NULL);

    JsonObject *all_fonts = NULL;
    FontManagerProgressData *progress = NULL;

    FontManagerStringHashset *known_files = get_known_files(db, insert->table);
    GList *available_files = font_manager_list_available_font_files();
    if (font_manager_string_hashset_contains_all(known_files, available_files))
        goto cleanup;

    all_fonts = font_manager_get_available_fonts(NULL);
    guint processed = 0, total = json_object_get_size(all_fonts);

    font_manager_database_begin_transaction(db, error);
    if (error != NULL && *error != NULL)
        goto cleanup;

    font_manager_database_execute_query(db, insert->sql, error);
    if (error != NULL && *error != NULL)
        goto cleanup;

    JsonObjectIter f_iter;
    const gchar *f_name;
    JsonNode *f_node;
    json_object_iter_init(&f_iter, all_fonts);
    while (json_object_iter_next(&f_iter, &f_name, &f_node)) {
        if (g_cancellable_is_cancelled(cancellable))
            break;
        /* Stash results periodically so we don't lose everything if closed */
        if (processed > 0 && processed % 500 == 0) {
            font_manager_database_commit_transaction(db, error);
            g_return_if_fail(error == NULL || *error == NULL);
            font_manager_database_begin_transaction(db, error);
            g_return_if_fail(error == NULL || *error == NULL);
            /* Previous call frees the prepared statement we were using */
            font_manager_database_execute_query(db, insert->sql, error);
            if (error != NULL && *error != NULL)
                goto cleanup;
        }
        if (insert->progress) {

            if (!progress)
                progress = font_manager_progress_data_new(insert->table, processed, total);

            g_object_ref(progress);
            g_object_set(progress, "message", insert->table, "processed", processed, "total", total, NULL);

            g_main_context_invoke_full(g_main_context_get_thread_default(),
                                       G_PRIORITY_HIGH_IDLE,
                                       (GSourceFunc) insert->progress,
                                       progress,
                                       (GDestroyNotify) g_object_unref);

        }
        JsonObject *family = json_node_get_object(f_node);
        JsonObjectIter s_iter;
        const gchar *s_name;
        JsonNode *s_node;
        json_object_iter_init(&s_iter, family);
        while (json_object_iter_next(&s_iter, &s_name, &s_node)) {
            JsonObject *face = json_node_get_object(s_node);
            const gchar *filepath = json_object_get_string_member(face, "filepath");
            if (font_manager_string_hashset_contains(known_files, filepath))
                continue;
            else
                insert->callback(db, face, insert->data);
        }
        processed++;
    }

    font_manager_database_commit_transaction(db, error);

cleanup:
    g_object_unref(known_files);
    g_list_free_full(available_files, g_free);
    if (all_fonts)
        json_object_unref(all_fonts);
    if (progress)
        g_object_unref(progress);
    return;
}

/**
 * font_manager_update_database_sync:
 * @db: #FontManagerDatabase instance
 * @type: #FontManagerDatabaseType
 * @progress: (scope call) (nullable): #FontManagerProgressCallback
 * @cancellable: (nullable): #GCancellable or %NULL
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Update application database as needed.
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_update_database_sync (FontManagerDatabase *db,
                                    FontManagerDatabaseType type,
                                    FontManagerProgressCallback progress,
                                    GCancellable *cancellable,
                                    GError **error)
{
    g_return_val_if_fail(FONT_MANAGER_IS_DATABASE(db), FALSE);
    g_return_val_if_fail(type != FONT_MANAGER_DATABASE_TYPE_BASE, FALSE);
    g_return_val_if_fail((error == NULL || *error == NULL), FALSE);

    InsertData *data = NULL;
    JsonArray *panose = NULL;
    const gchar *table = font_manager_database_get_type_name(type);

    if (g_cancellable_is_cancelled(cancellable))
        return FALSE;

    if (type == FONT_MANAGER_DATABASE_TYPE_FONT) {

        font_manager_database_execute_query(db, DROP_FONT_MATCH_INDEX, NULL);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));

        data = get_insert_data(table, INSERT_FONT_ROW, (InsertCallback) sync_fonts_table, progress, NULL);
        update_available_fonts(db, data, cancellable, error);

        if (error != NULL && *error != NULL)
            goto cleanup;

        font_manager_database_execute_query(db, CREATE_FONT_MATCH_INDEX, NULL);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));

    } else if (type == FONT_MANAGER_DATABASE_TYPE_METADATA) {

        font_manager_database_execute_query(db, DROP_INFO_MATCH_INDEX, NULL);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
        font_manager_database_execute_query(db, DROP_PANOSE_MATCH_INDEX, NULL);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
        panose = json_array_new();
        data = get_insert_data(table, INSERT_INFO_ROW, (InsertCallback) sync_metadata_table, progress, panose);
        update_available_fonts(db, data, cancellable, error);

        if (error != NULL && *error != NULL)
            goto cleanup;

        sync_panose_table(db, panose, cancellable, error);
        if (error != NULL && *error != NULL)
            goto cleanup;

        font_manager_database_execute_query(db, CREATE_INFO_MATCH_INDEX, NULL);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));
        font_manager_database_execute_query(db, CREATE_PANOSE_MATCH_INDEX, NULL);
        g_assert(sqlite3_step_succeeded(db, SQLITE_DONE));

    } else if (type == FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY) {

        data = get_insert_data(table, INSERT_ORTH_ROW, (InsertCallback) sync_orth_table, progress, NULL);
        update_available_fonts(db, data, cancellable, error);

    }

cleanup:
    if (panose)
        json_array_unref(panose);
    if (data)
        free_insert_data(data);
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

    result = font_manager_update_database_sync(data->db, data->type, data->progress, cancellable, &error);

    if (error == NULL)
        g_task_return_boolean(task, result);
    else
        g_task_return_error(task, error);
}

/**
 * font_manager_update_database:
 * @db: #FontManagerDatabase instance
 * @type: #FontManagerDatabaseType
 * @progress: (scope call) (nullable): #FontManagerProgressCallback
 * @cancellable: (nullable): #GCancellable or %NULL
 * @callback: (nullable) (scope async): #GAsyncReadyCallback or %NULL
 * @user_data: (nullable): user data passed to callback or %NULL
 *
 * Update application database as needed.
 */
void
font_manager_update_database (FontManagerDatabase *db,
                              FontManagerDatabaseType type,
                              FontManagerProgressCallback progress,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
    g_return_if_fail(cancellable == NULL || G_IS_CANCELLABLE (cancellable));
    DatabaseSyncData *sync_data = get_sync_data(db, type, progress);
    GTask *task = g_task_new(NULL, cancellable, callback, user_data);
    g_task_set_priority(task, G_PRIORITY_DEFAULT);
    g_task_set_return_on_cancel(task, FALSE);
    g_task_set_task_data(task, (gpointer) sync_data, (GDestroyNotify) free_sync_data);
    g_task_run_in_thread(task, sync_database_thread);
    g_object_unref(task);
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
 * @families: #FontManagerStringHashset
 * @fonts: #FontManagerStringHashset
 * @sql: SQL query to execute
 * @error: #GError or %NULL to ignore errors
 *
 * Query MUST return two result columns. The first containing the family name
 * and the second containing the font description.
 */
void
font_manager_get_matching_families_and_fonts (FontManagerDatabase *db,
                                              FontManagerStringHashset *families,
                                              FontManagerStringHashset *fonts,
                                              const gchar *sql,
                                              GError **error)
{
    g_return_if_fail(FONT_MANAGER_IS_DATABASE(db));
    g_return_if_fail(FONT_MANAGER_IS_STRING_HASHSET(families));
    g_return_if_fail(FONT_MANAGER_IS_STRING_HASHSET(fonts));
    g_return_if_fail(sql != NULL);
    g_return_if_fail(error == NULL || *error == NULL);
    font_manager_database_execute_query(db, sql, error);
    g_return_if_fail(error == NULL || *error == NULL);
    FontManagerDatabaseIterator *iter = font_manager_database_iterator(db);
    while (font_manager_database_iterator_next(iter)) {
        sqlite3_stmt *stmt = font_manager_database_iterator_get(iter);
        g_assert(sqlite3_column_count(stmt) >= 2);
        const gchar *family = (const gchar *) sqlite3_column_text(stmt, 0);
        const gchar *font = (const gchar *) sqlite3_column_text(stmt, 1);
        if (family == NULL || font == NULL)
            continue;
        font_manager_string_hashset_add(families, family);
        font_manager_string_hashset_add(fonts, font);
    }
    g_object_unref(iter);
    return;
}

static FontManagerDatabase *main_database = NULL;

/**
 * font_manager_get_database:
 * @type:   #FontManagerDatabaseType
 * @error: (nullable): #GError or %NULL to ignore errors
 *
 * Convenience function which initializes the database and sets default options.
 *
 * Returns: (transfer full) (nullable): The requested #FontManagerDatabase or %NULL on error.
 * Free the returned object using #g_object_unref().
 */
FontManagerDatabase *
font_manager_get_database (FontManagerDatabaseType type, GError **error)
{
    g_return_val_if_fail((error == NULL || *error == NULL), NULL);
    if (type == FONT_MANAGER_DATABASE_TYPE_BASE && main_database != NULL)
        return g_object_ref(main_database);
    FontManagerDatabase *db = font_manager_database_new();
    g_autofree gchar *db_file = font_manager_database_get_file(type);
    g_object_set(db, "file", db_file, NULL);
    font_manager_database_initialize(db, type, error);
    if (type == FONT_MANAGER_DATABASE_TYPE_BASE && main_database == NULL)
        main_database = g_object_ref(db);
    return db;
}

GType
font_manager_database_error_get_type (void)
{
  static volatile gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_DATABASE_ERROR_OK, "FONT_MANAGER_DATABASE_ERROR_OK", "ok" },
        { FONT_MANAGER_DATABASE_ERROR_ERROR, "FONT_MANAGER_DATABASE_ERROR_ERROR", "error" },
        { FONT_MANAGER_DATABASE_ERROR_INTERNAL, "FONT_MANAGER_DATABASE_ERROR_INTERNAL", "internal" },
        { FONT_MANAGER_DATABASE_ERROR_PERM, "FONT_MANAGER_DATABASE_ERROR_PERM", "perm" },
        { FONT_MANAGER_DATABASE_ERROR_ABORT, "FONT_MANAGER_DATABASE_ERROR_ABORT", "abort" },
        { FONT_MANAGER_DATABASE_ERROR_BUSY, "FONT_MANAGER_DATABASE_ERROR_BUSY", "busy" },
        { FONT_MANAGER_DATABASE_ERROR_LOCKED, "FONT_MANAGER_DATABASE_ERROR_LOCKED", "locked" },
        { FONT_MANAGER_DATABASE_ERROR_NOMEM, "FONT_MANAGER_DATABASE_ERROR_NOMEM", "nomem" },
        { FONT_MANAGER_DATABASE_ERROR_READONLY, "FONT_MANAGER_DATABASE_ERROR_READONLY", "readonly" },
        { FONT_MANAGER_DATABASE_ERROR_INTERRUPT, "FONT_MANAGER_DATABASE_ERROR_INTERRUPT", "interrupt" },
        { FONT_MANAGER_DATABASE_ERROR_IOERR, "FONT_MANAGER_DATABASE_ERROR_IOERR", "ioerr" },
        { FONT_MANAGER_DATABASE_ERROR_CORRUPT, "FONT_MANAGER_DATABASE_ERROR_CORRUPT", "corrupt" },
        { FONT_MANAGER_DATABASE_ERROR_NOTFOUND, "FONT_MANAGER_DATABASE_ERROR_NOTFOUND", "notfound" },
        { FONT_MANAGER_DATABASE_ERROR_FULL, "FONT_MANAGER_DATABASE_ERROR_FULL", "full" },
        { FONT_MANAGER_DATABASE_ERROR_CANTOPEN, "FONT_MANAGER_DATABASE_ERROR_CANTOPEN", "cantopen" },
        { FONT_MANAGER_DATABASE_ERROR_PROTOCOL, "FONT_MANAGER_DATABASE_ERROR_PROTOCOL", "protocol" },
        { FONT_MANAGER_DATABASE_ERROR_EMPTY, "FONT_MANAGER_DATABASE_ERROR_EMPTY", "empty" },
        { FONT_MANAGER_DATABASE_ERROR_SCHEMA, "FONT_MANAGER_DATABASE_ERROR_SCHEMA", "schema" },
        { FONT_MANAGER_DATABASE_ERROR_TOOBIG, "FONT_MANAGER_DATABASE_ERROR_TOOBIG", "toobig" },
        { FONT_MANAGER_DATABASE_ERROR_CONSTRAINT, "FONT_MANAGER_DATABASE_ERROR_CONSTRAINT", "constraint" },
        { FONT_MANAGER_DATABASE_ERROR_MISMATCH, "FONT_MANAGER_DATABASE_ERROR_MISMATCH", "mismatch" },
        { FONT_MANAGER_DATABASE_ERROR_MISUSE, "FONT_MANAGER_DATABASE_ERROR_MISUSE", "misuse" },
        { FONT_MANAGER_DATABASE_ERROR_NOLFS, "FONT_MANAGER_DATABASE_ERROR_NOLFS", "nolfs" },
        { FONT_MANAGER_DATABASE_ERROR_AUTH, "FONT_MANAGER_DATABASE_ERROR_AUTH", "auth" },
        { FONT_MANAGER_DATABASE_ERROR_FORMAT, "FONT_MANAGER_DATABASE_ERROR_FORMAT", "format" },
        { FONT_MANAGER_DATABASE_ERROR_RANGE, "FONT_MANAGER_DATABASE_ERROR_RANGE", "range" },
        { FONT_MANAGER_DATABASE_ERROR_NOTADB, "FONT_MANAGER_DATABASE_ERROR_NOTADB", "notadb" },
        { FONT_MANAGER_DATABASE_ERROR_NOTICE, "FONT_MANAGER_DATABASE_ERROR_NOTICE", "notice" },
        { FONT_MANAGER_DATABASE_ERROR_WARNING, "FONT_MANAGER_DATABASE_ERROR_WARNING", "warning" },
        { FONT_MANAGER_DATABASE_ERROR_ROW, "FONT_MANAGER_DATABASE_ERROR_ROW", "row" },
        { FONT_MANAGER_DATABASE_ERROR_DONE, "FONT_MANAGER_DATABASE_ERROR_DONE", "done" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerDatabaseError"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}

GType
font_manager_database_type_get_type (void)
{
  static volatile gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_DATABASE_TYPE_BASE, "FONT_MANAGER_DATABASE_TYPE_BASE", "base" },
        { FONT_MANAGER_DATABASE_TYPE_FONT, "FONT_MANAGER_DATABASE_TYPE_FONT", "font" },
        { FONT_MANAGER_DATABASE_TYPE_METADATA, "FONT_MANAGER_DATABASE_TYPE_METADATA", "metadata" },
        { FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY, "FONT_MANAGER_DATABASE_TYPE_ORTHOGRAPHY", "orthography" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerDatabaseType"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}
