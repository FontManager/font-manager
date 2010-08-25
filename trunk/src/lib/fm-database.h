/* fm-database.h
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

#ifndef __FM_DATABASE_H__
#define __FM_DATABASE_H__

#include <sqlite3.h>

#include "fm-common.h"
#include "fm-fontutils.h"

#define APPNAME "font-manager"
#define DBNAME "font-manager.sqlite"

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
"license_url TEXT\n"                                                           \
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
        int i, columns = 15;                                                   \
                                                                               \
        for (i = 1; i < columns; i++)                                          \
        {                                                                      \
            switch(i)                                                         \
            {                                                                  \
                case 1:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->owner);                \
                    break;                                                    \
                case 2:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->filepath);             \
                    break;                                                    \
                case 3:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->filetype);             \
                    break;                                                    \
                case 4:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->filesize);             \
                    break;                                                    \
                case 5:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->checksum);             \
                    break;                                                    \
                case 6:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->psname);               \
                    break;                                                    \
                case 7:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->family);               \
                    break;                                                    \
                case 8:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->style);                \
                    break;                                                    \
                case 9:                                                       \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->foundry);              \
                    break;                                                    \
                case 10:                                                      \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->copyright);            \
                    break;                                                    \
                case 11:                                                      \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->version);              \
                    break;                                                    \
                case 12:                                                      \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->description);          \
                    break;                                                    \
                case 13:                                                      \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->license);              \
                    break;                                                    \
                case 14:                                                      \
                    SQLITE_BIND_TEXT(stmt, i, fontinfo->license_url);          \
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

/* Just for consistency */
static int HAVE_SQLITE_ROW(sqlite3_stmt *stmt);
void sync_database(const gchar *progress_message,
    void (*progress_callback) (const gchar *msg, int total, int processed));

#endif
/* EOF */
