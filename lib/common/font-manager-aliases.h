/* font-manager-aliases.h
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

#ifndef __FONT_MANAGER_ALIASES_H__
#define __FONT_MANAGER_ALIASES_H__

#include <glib.h>
#include <gmodule.h>
#include <glib-object.h>

#include "font-manager-alias.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_ALIASES (font_manager_aliases_get_type())
G_DECLARE_FINAL_TYPE(FontManagerAliases, font_manager_aliases, FONT_MANAGER, ALIASES, GObject)

FontManagerAliases * font_manager_aliases_new (void);
FontManagerAliasElement * font_manager_aliases_get (FontManagerAliases *self, const gchar *family);
gboolean font_manager_aliases_contains (FontManagerAliases *self, const gchar *family);
gboolean font_manager_aliases_add (FontManagerAliases *self, const gchar *family);
gboolean font_manager_aliases_add_element (FontManagerAliases *self, FontManagerAliasElement *element);
gboolean font_manager_aliases_remove (FontManagerAliases *self, const gchar *family);
gboolean font_manager_aliases_load (FontManagerAliases *self);
gboolean font_manager_aliases_save (FontManagerAliases *self);
gchar * font_manager_aliases_get_filepath (FontManagerAliases *self);
GList * font_manager_aliases_list (FontManagerAliases *self);

G_END_DECLS

#endif /* __FONT_MANAGER_ALIASES_H__ */

