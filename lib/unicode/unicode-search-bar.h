/* unicode-search-bar.h
 *
 * Copyright (C) 2018-2022 Jerry Casiano
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

#ifndef __UNICODE_SEARCH_BAR_H__
#define __UNICODE_SEARCH_BAR_H__

#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>

#include "unicode-character-map.h"
#include "unicode-codepoint-list.h"
#include "unicode-info.h"

G_BEGIN_DECLS

#define UNICODE_TYPE_SEARCH_BAR (unicode_search_bar_get_type())
G_DECLARE_FINAL_TYPE(UnicodeSearchBar, unicode_search_bar, UNICODE, SEARCH_BAR, GtkSearchBar)

GtkWidget * unicode_search_bar_new (void);
void unicode_search_bar_set_character_map (UnicodeSearchBar *self, UnicodeCharacterMap *character_map);

G_END_DECLS

#endif /* __UNICODE_SEARCH_BAR_H__ */
