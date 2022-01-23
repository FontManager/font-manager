/* font-manager-string-set.h
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

#ifndef __FONT_MANAGER_STRING_SET_H__
#define __FONT_MANAGER_STRING_SET_H__

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_STRING_SET (font_manager_string_set_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerStringSet, font_manager_string_set, FONT_MANAGER, STRING_SET, GObject)

FontManagerStringSet * font_manager_string_set_new (void);
guint font_manager_string_set_size (FontManagerStringSet *self);
const gchar * font_manager_string_set_get (FontManagerStringSet *self, guint index);
void font_manager_string_set_add (FontManagerStringSet *self, const gchar *str);
void font_manager_string_set_add_all (FontManagerStringSet *self, FontManagerStringSet *add);
gboolean font_manager_string_set_contains (FontManagerStringSet *self, const gchar *str);
gboolean font_manager_string_set_contains_all (FontManagerStringSet *self, FontManagerStringSet *contents);
void font_manager_string_set_remove (FontManagerStringSet *self, const gchar *str);
void font_manager_string_set_remove_all (FontManagerStringSet *self, FontManagerStringSet *remove);
void font_manager_string_set_retain_all (FontManagerStringSet *self, FontManagerStringSet *retain);
GList * font_manager_string_set_list (FontManagerStringSet *self);
void font_manager_string_set_foreach(FontManagerStringSet *self, GFunc func, gpointer user_data);
void font_manager_string_set_sort(FontManagerStringSet *self, GCompareFunc func);
void font_manager_string_set_clear (FontManagerStringSet *self);

G_END_DECLS

#endif /* __FONT_MANAGER_STRING_SET_H__ */

