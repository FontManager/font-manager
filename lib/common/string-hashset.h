/* string-hashset.h
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

#ifndef __STRING_HASHSET_H__
#define __STRING_HASHSET_H__

#include <glib.h>
#include <gmodule.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define STRING_TYPE_HASHSET (string_hashset_get_type())
G_DECLARE_DERIVABLE_TYPE(StringHashset, string_hashset, STRING, HASHSET, GObject)

StringHashset * string_hashset_new (void);
guint string_hashset_size (StringHashset *self);
const gchar * string_hashset_get (StringHashset *self, guint index);
gboolean string_hashset_add (StringHashset *self, const gchar *str);
gboolean string_hashset_add_all (StringHashset *self, GList *add);
gboolean string_hashset_contains (StringHashset *self, const gchar *str);
gboolean string_hashset_contains_all (StringHashset *self, GList *contents);
gboolean string_hashset_remove (StringHashset *self, const gchar *str);
gboolean string_hashset_remove_all (StringHashset *self, GList *remove);
gboolean string_hashset_retain_all (StringHashset *self, GList *retain);
GList * string_hashset_list (StringHashset *self);
void string_hashset_clear (StringHashset *self);

G_END_DECLS

#endif /* __STRING_HASHSET_H__ */

