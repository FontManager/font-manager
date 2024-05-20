/* font-manager-database-iterator.h
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

#include <glib.h>
#include <glib-object.h>
#include <sqlite3.h>

#include "font-manager-database.h"

#define FONT_MANAGER_TYPE_DATABASE_ITERATOR (font_manager_database_iterator_get_type())
G_DECLARE_FINAL_TYPE(FontManagerDatabaseIterator, font_manager_database_iterator, FONT_MANAGER, DATABASE_ITERATOR, GObject)

FontManagerDatabaseIterator * font_manager_database_iterator (FontManagerDatabase *db);

/* Standard Iterator protocol */
FontManagerDatabaseIterator * font_manager_database_iterator_new (FontManagerDatabase *db);
gboolean font_manager_database_iterator_next (FontManagerDatabaseIterator *self);
sqlite3_stmt * font_manager_database_iterator_get (FontManagerDatabaseIterator *self);


