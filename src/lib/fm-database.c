/* fm-database.c
 *
 * Font Manager, a font management application for the GNOME desktop
 *
 * Copyright (C) 2009, 2010 Jerry Casiano
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to:
 *
 *   Free Software Foundation, Inc.
 *   51 Franklin Street, Fifth Floor
 *   Boston, MA 02110-1301, USA
*/

#include <ft2build.h>
#include FT_FREETYPE_H
#include <glib.h>
#include <glib/gprintf.h>
#include <sqlite3.h>

#include "fm-common.h"
#include "fm-database.h"
#include "fm-fontutils.h"


enum Columns
{
    OWNER = 1,
    FILEPATH,
    FILETYPE,
    FILESIZE,
    CHECKSUM,
    PSNAME,
    FAMILY,
    STYLE,
    FOUNDRY,
    COPYRIGHT,
    VERSION,
    DESCRIPTION,
    LICENSE,
    LICENSE_URL,
    PANOSE,
    FACE,
    PFAMILY,
    PSTYLE,
    PVARIANT,
    PWEIGHT,
    PSTRETCH,
    PDESCR,
};

#define INIT_TABLE                                                             \
"CREATE TABLE IF NOT EXISTS Fonts\n"                                           \
"(\n"                                                                          \
"uid INTEGER PRIMARY KEY,\n"                                                   \
"owner TEXT,\n"                                                                \
"filepath TEXT,\n"                                                             \
"filetype TEXT,\n"                                                             \
"filesize TEXT,\n"                                                             \
"checksum TEXT,\n"                                                             \
"psname TEXT,\n"                                                               \
"family TEXT,\n"                                                               \
"style TEXT,\n"                                                                \
"foundry TEXT,\n"                                                              \
"copyright TEXT,\n"                                                            \
"version TEXT,\n"                                                              \
"description TEXT,\n"                                                          \
"license TEXT,\n"                                                              \
"license_url TEXT,\n"                                                          \
"panose TEXT,\n"                                                               \
"face TEXT,\n"                                                                 \
"pfamily TEXT,\n"                                                              \
"pstyle TEXT,\n"                                                               \
"pvariant TEXT,\n"                                                             \
"pweight TEXT,\n"                                                              \
"pstretch TEXT,\n"                                                             \
"pdescr TEXT\n"                                                                \
");\n"                                                                         \

#define SQLITE_OPEN(db, dbhandle)                                              \
    {                                                                          \
        if (sqlite3_open(db, dbhandle) = SQLITE_OK)                            \
        {                                                                      \
            g_critical("sqlite3_open failed with: %s\n",                       \
                        sqlite3_errmsg(db));                                   \
        }                                                                      \
    }                                                                          \

#define SQLITE_CLOSE(db)                                                       \
    {                                                                          \
        if (sqlite3_close(db) = SQLITE_OK)                                     \
        {                                                                      \
            g_critical("sqlite3_close failed with: %s\n",                      \
                        sqlite3_errmsg(db));                                   \
        }                                                                      \
    }                                                                          \

#define SQLITE_CALL(call)                                                      \
    {                                                                          \
        if (sqlite3_##call != SQLITE_OK)                                       \
        {                                                                      \
            g_warning("sqlite3_%s failed with: %s\n",                          \
                        #call, sqlite3_errmsg(db));                            \
        }                                                                      \
    }                                                                          \

#define SQLITE_EVAL(stmt)                                                      \
    {                                                                          \
        sqlite3_step(stmt);                                                    \
        sqlite3_clear_bindings(stmt);                                          \
                                                                               \
        if (sqlite3_reset(stmt) != SQLITE_OK)                                  \
        {                                                                      \
            g_warning("sqlite3_step failed!");                                 \
        }                                                                      \
    }                                                                          \

#define SQLITE_BIND_TEXT(stmt, index, val)                                     \
    sqlite3_bind_text(stmt, index, val, -1, SQLITE_STATIC)

#define SQLITE_INSERT_FONT_ROW(stmt, fontinfo)                                 \
    {                                                                          \
        int i, columns = 23;                                                   \
                                                                               \
        for (i = 1; i < columns; i++)                                          \
        {                                                                      \
            switch(i)                                                         \
            {                                                                  \
                case OWNER:                                                   \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->owner);                \
                    break;                                                    \
                case FILEPATH:                                                \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->filepath);             \
                    break;                                                    \
                case FILETYPE:                                                \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->filetype);             \
                    break;                                                    \
                case FILESIZE:                                                \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->filesize);             \
                    break;                                                    \
                case CHECKSUM:                                                \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->checksum);             \
                    break;                                                    \
                case PSNAME:                                                  \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->psname);               \
                    break;                                                    \
                case FAMILY:                                                  \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->family);               \
                    break;                                                    \
                case STYLE:                                                   \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->style);                \
                    break;                                                    \
                case FOUNDRY:                                                 \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->foundry);              \
                    break;                                                    \
                case COPYRIGHT:                                               \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->copyright);            \
                    break;                                                    \
                case VERSION:                                                 \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->version);              \
                    break;                                                    \
                case DESCRIPTION:                                             \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->description);          \
                    break;                                                    \
                case LICENSE:                                                 \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->license);              \
                    break;                                                    \
                case LICENSE_URL:                                             \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->license_url);          \
                    break;                                                    \
                case PANOSE:                                                  \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->panose);               \
                    break;                                                    \
                case FACE:                                                    \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->face);                 \
                    break;                                                    \
                case PFAMILY:                                                 \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->pfamily);              \
                    break;                                                    \
                case PSTYLE:                                                  \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->pstyle);               \
                    break;                                                    \
                case PVARIANT:                                                \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->pvariant);             \
                    break;                                                    \
                case PWEIGHT:                                                 \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->pweight);              \
                    break;                                                    \
                case PSTRETCH:                                                \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->pstretch);             \
                    break;                                                    \
                case PDESCR:                                                  \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->pdescr);               \
                    break;                                                    \
            }                                                                  \
        }                                                                      \
    }                                                                          \

#define SQLITE_FINALIZE(stmt)                                                  \
    {                                                                          \
        if (sqlite3_finalize(stmt) != SQLITE_OK)                               \
        {                                                                      \
            g_critical("sqlite3_finalize failed!");                            \
        }                                                                      \
    }                                                                          \

static int
HAVE_SQLITE_ROW(sqlite3_stmt *stmt)
{
    return (sqlite3_step(stmt) == SQLITE_ROW);
}


/**
 * sync_database:
 *
 * @progress_message:   A string to display, i.e. in a progressbar
 * @progress_callback:  A pointer to a function to call with progress
 *
 * Ignores errors, aside from printing them to stderr.
 */
void
sync_database(const char *progress_message,
    void (*progress_callback) (const char *msg, int total, int processed))
{
    sqlite3         *db;
    sqlite3_stmt    *stmt;
    gint            total, processed = 0;
    gchar           *dbfile = NULL,
                    *pmsg = NULL;
    GSList          *iter = NULL,
                    *filelist = NULL,
                    *indexed = NULL;

    dbfile = g_build_filename(g_get_user_cache_dir(), APPNAME, DBNAME, NULL);
    if (progress_message != NULL)
        pmsg = g_strdup(progress_message);

    /* Get a list of installed font files from FontConfig */
    filelist = FcListFiles();

    total = g_slist_length(filelist);

    /* Open our database, create tables if needed and begin transaction */
    SQLITE_CALL(open(dbfile, &db));
    SQLITE_CALL(prepare_v2(db, INIT_TABLE, -1, &stmt, NULL));
    SQLITE_EVAL(stmt);
    SQLITE_FINALIZE(stmt);
    SQLITE_CALL(prepare_v2(db, "BEGIN", -1, &stmt, NULL));
    SQLITE_EVAL(stmt);
    SQLITE_FINALIZE(stmt);

    /* Get known files from the database */
    SQLITE_CALL(prepare_v2(db, "SELECT filepath FROM Fonts", -1, &stmt, NULL));
    while ((HAVE_SQLITE_ROW(stmt)))
    {
        indexed = g_slist_prepend(indexed,
                        g_strdup((const gchar *) sqlite3_column_text(stmt, 0)));
    }
    SQLITE_FINALIZE(stmt);

    /* Update database */
    SQLITE_CALL(prepare_v2(db, "INSERT OR REPLACE INTO Fonts VALUES "
                            "(NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                            -1, &stmt, NULL));
    for (iter = filelist; iter; iter = iter->next)
    {
        if (!g_slist_find_custom(indexed, iter->data, (GCompareFunc) g_strcmp0))
        {
            int index, num_faces = FT_Get_Face_Count(iter->data);

            for (index = 0; index < num_faces; index++)
            {
                FT_Error    error;
                FontInfo   f, *fontinfo;

                fontinfo = &f;
                /* Fill with default values */
                fontinfo_init(fontinfo);

                error = FT_Get_Font_Info(fontinfo, iter->data, index);
                if (error)
                {
                    if (error == FT_Err_Cannot_Open_Resource)
                        g_warning("Failed to open file : %s\n",
                                            (char *) iter->data);
                    fontinfo_destroy(fontinfo);
                    processed++;
                    continue;
                }

                SQLITE_INSERT_FONT_ROW(stmt, fontinfo);
                SQLITE_EVAL(stmt);
                /* Free structure */
                fontinfo_destroy(fontinfo);
            }
        }
        /* Shorten the list */
        indexed = g_slist_remove_all(indexed, iter->data);
        processed++;
        if (pmsg != NULL && progress_callback != NULL)
            progress_callback((const gchar *) pmsg, total, processed);
        else if (progress_callback != NULL)
            progress_callback((const gchar *) ' ', total, processed);
    }

    g_free_and_nullify(dbfile);
    g_free_and_nullify(pmsg);
    g_slist_foreach(filelist, (GFunc) g_free_and_nullify, NULL);
    g_slist_foreach(indexed, (GFunc) g_free_and_nullify, NULL);
    g_slist_free(filelist);
    g_slist_free(indexed);
    g_slist_free(iter);

    SQLITE_FINALIZE(stmt);
    SQLITE_CALL(prepare_v2(db, "COMMIT", -1, &stmt, NULL));
    SQLITE_EVAL(stmt);
    SQLITE_FINALIZE(stmt);
    SQLITE_CALL(close(db));
}
