/* font-manager-codepoint-list.h
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

#ifndef __FONT_MANAGER_CODEPOINT_LIST_H__
#define __FONT_MANAGER_CODEPOINT_LIST_H__

#include <hb.h>
#include <glib.h>
#include <glib-object.h>
#include <json-glib/json-glib.h>

#include "font-manager-regional-indicator-symbols.h"
#include "unicode-codepoint-list.h"
#include "unicode-info.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_CODEPOINT_LIST (font_manager_codepoint_list_get_type())
G_DECLARE_FINAL_TYPE(FontManagerCodepointList, font_manager_codepoint_list, FONT_MANAGER, CODEPOINT_LIST, GObject)

FontManagerCodepointList * font_manager_codepoint_list_new (void);
void font_manager_codepoint_list_set_filter (FontManagerCodepointList *self, GList *filter);
void font_manager_codepoint_list_set_font (FontManagerCodepointList *self, JsonObject *font);

G_END_DECLS

#endif /* #ifndef __FONT_MANAGER_CODEPOINT_LIST_H__ */

