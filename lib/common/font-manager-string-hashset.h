/* font-manager-string-hashset.h
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

#ifndef __FONT_MANAGER_STRING_HASHSET_H__
#define __FONT_MANAGER_STRING_HASHSET_H__

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_STRING_HASHSET (font_manager_string_hashset_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerStringHashset, font_manager_string_hashset, FONT_MANAGER, STRING_HASHSET, GObject)

FontManagerStringHashset * font_manager_string_hashset_new (void);
guint font_manager_string_hashset_size (FontManagerStringHashset *self);
const gchar * font_manager_string_hashset_get (FontManagerStringHashset *self, guint index);
gboolean font_manager_string_hashset_add (FontManagerStringHashset *self, const gchar *str);
gboolean font_manager_string_hashset_add_all (FontManagerStringHashset *self, GList *add);
gboolean font_manager_string_hashset_contains (FontManagerStringHashset *self, const gchar *str);
gboolean font_manager_string_hashset_contains_all (FontManagerStringHashset *self, GList *contents);
gboolean font_manager_string_hashset_remove (FontManagerStringHashset *self, const gchar *str);
gboolean font_manager_string_hashset_remove_all (FontManagerStringHashset *self, GList *remove);
gboolean font_manager_string_hashset_retain_all (FontManagerStringHashset *self, GList *retain);
GList * font_manager_string_hashset_list (FontManagerStringHashset *self);
void font_manager_string_hashset_clear (FontManagerStringHashset *self);

G_END_DECLS

#endif /* __FONT_MANAGER_STRING_HASHSET_H__ */

