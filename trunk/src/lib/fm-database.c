/* fm-database.c
 *
 * Copyright (C) 2009, 2010 Jerry Casiano
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to:
 *
 *   Free Software Foundation, Inc.
 *   51 Franklin Street, Fifth Floor
 *   Boston, MA 02110-1301, USA
*/

#include "fm-database.h"

int main()
{
    sync_database(NULL, NULL);
    return 0;
}

/**
 * sync_database:
 *
 * @progress_message:   A string to display
 * @progress_callback:  A pointer to a function to call with progress
 *
 * Ignores errors, aside from printing them to stderr.
 */
void
sync_database(const gchar *progress_message,
                void (*progress_callback)
                (const gchar *msg, int total, int processed))
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
#ifdef DEBUG
    filelist = FcListFiles(TRUE);
#else
    filelist = FcListFiles(FALSE);
#endif
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
                                "(NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
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
                    {
                        g_warning("Failed to open file : %s\n",
                                            (char *) iter->data);
                    }
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
        processed++;
        if (pmsg != NULL && progress_callback != NULL)
            progress_callback((const gchar *) pmsg, total, processed);
        else if (pmsg == NULL && progress_callback != NULL)
            progress_callback((const gchar *) ' ', total, processed);
    }

    g_free_and_nullify(dbfile);
    g_slist_foreach(filelist, (GFunc) g_free_and_nullify, NULL);
    g_slist_foreach(indexed, (GFunc) g_free_and_nullify, NULL);
    g_slist_free(filelist);
    g_slist_free(indexed);
    g_slist_free(iter);
    g_free_and_nullify(pmsg);

    SQLITE_FINALIZE(stmt);
    SQLITE_CALL(prepare_v2(db, "COMMIT", -1, &stmt, NULL));
    SQLITE_EVAL(stmt);
    SQLITE_FINALIZE(stmt);
    SQLITE_CALL(close(db));
}

static int
HAVE_SQLITE_ROW(sqlite3_stmt *stmt)
{
    return (sqlite3_step(stmt) == SQLITE_ROW);
}
