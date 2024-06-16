/* font-manager-database-iterator.c
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

#include "font-manager-database-iterator.h"

/**
 * SECTION: font-manager-database-iterator
 * @short_description: Database iterator
 * @title: Database
 * @include: font-manager-database-iterator.h
 *
 * Make looping through database results more convenient
 */

struct _FontManagerDatabaseIterator
{
    GObjectClass parent_class;

    FontManagerDatabase *db;
};

G_DEFINE_TYPE(FontManagerDatabaseIterator, font_manager_database_iterator, G_TYPE_OBJECT)

/**
 * font_manager_database_iterator:
 * @db:   #FontManagerDatabase
 *
 * Returns: (transfer full):   #FontManagerDatabaseIterator.
 * Free the return object using g_object_unref().
 */
FontManagerDatabaseIterator *
font_manager_database_iterator (FontManagerDatabase *db)
{
    return font_manager_database_iterator_new(db);
}

static void
font_manager_database_iterator_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerDatabaseIterator *self = FONT_MANAGER_DATABASE_ITERATOR(gobject);
    g_clear_object(&self->db);
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
 * font_manager_database_iterator_next:
 * @self:   #FontManagerDatabase
 *
 * Returns: %TRUE if there are more results in set
 */
gboolean
font_manager_database_iterator_next (FontManagerDatabaseIterator *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(self->db != NULL, FALSE);
    sqlite3_stmt *stmt = font_manager_database_get_cursor(self->db);
    return (sqlite3_step(stmt) == SQLITE_ROW);
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
    return font_manager_database_get_cursor(self->db);
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
    GObject *gobject = g_object_new(FONT_MANAGER_TYPE_DATABASE_ITERATOR, NULL);
    FontManagerDatabaseIterator *self = FONT_MANAGER_DATABASE_ITERATOR(gobject);
    self->db = g_object_ref(db);
    return self;
}

