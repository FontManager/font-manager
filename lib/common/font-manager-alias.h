/* font-manager-alias.h
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

#ifndef __FONT_MANAGER_ALIAS_H__
#define __FONT_MANAGER_ALIAS_H__

#include <glib.h>
#include <glib-object.h>

#include "font-manager-string-set.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_ALIAS_ELEMENT (font_manager_alias_element_get_type())
G_DECLARE_FINAL_TYPE(FontManagerAliasElement, font_manager_alias_element, FONT_MANAGER, ALIAS_ELEMENT, GObject)

FontManagerAliasElement * font_manager_alias_element_new (const gchar *family);
FontManagerStringSet * font_manager_alias_element_get (FontManagerAliasElement *self, const gchar *priority);

G_END_DECLS

#endif /* __FONT_MANAGER_ALIAS_H__ */
