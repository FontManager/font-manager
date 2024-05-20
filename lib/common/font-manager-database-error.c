/* font-manager-database-error.c
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

#include "font-manager-database-error.h"

/**
 * SECTION: font-manager-database-error
 * @short_description: Database error codes
 * @title: Database Error
 * @include: font-manager-database-error.h
 *
 * Error codes returned by database related functions
 */

G_DEFINE_QUARK(font-manager-database-error-quark, font_manager_database_error)

GType
font_manager_database_error_get_type (void)
{
  static gsize g_define_type_id__volatile = 0;

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

