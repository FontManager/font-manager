/* font-manager-character-map.h
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

#ifndef __FONT_MANAGER_CHARACTER_MAP_H__
#define __FONT_MANAGER_CHARACTER_MAP_H__

#include <gtk/gtk.h>

#include "font-manager-font.h"
#include "font-manager-font-scale.h"
#include "font-manager-codepoint-list.h"
#include "font-manager-orthography.h"
#include "font-manager-gtk-utils.h"
#include "unicode-character-map.h"
#include "unicode-search-bar.h"
#include "unicode-info.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_CHARACTER_MAP (font_manager_character_map_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerCharacterMap, font_manager_character_map, FONT_MANAGER, CHARACTER_MAP, GtkBox)

GtkWidget * font_manager_character_map_new (void);

void font_manager_character_map_set_font (FontManagerCharacterMap *self, FontManagerFont *font);
void font_manager_character_map_set_filter (FontManagerCharacterMap *self, FontManagerOrthography *orthography);

G_END_DECLS

#endif /* __FONT_MANAGER_CHARACTER_MAP_H__ */

