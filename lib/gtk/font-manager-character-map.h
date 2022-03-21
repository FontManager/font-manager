/* font-manager-character-map.h
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

#pragma once

#include <gtk/gtk.h>

#include "font-manager-font.h"
#include "font-manager-font-scale.h"
#include "font-manager-gtk-utils.h"
#include "unicode-character-info.h"
#include "unicode-character-map.h"
#include "unicode-search-bar.h"
#include "unicode-info.h"

#define FONT_MANAGER_TYPE_CHARACTER_MAP (font_manager_character_map_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerCharacterMap, font_manager_character_map, FONT_MANAGER, CHARACTER_MAP, GtkWidget)

GtkWidget * font_manager_character_map_new (void);

void font_manager_character_map_set_font_desc (FontManagerCharacterMap *self, PangoFontDescription *font_desc);
void font_manager_character_map_set_filter (FontManagerCharacterMap *self, GList *filter);
void font_manager_character_map_restore_state (FontManagerCharacterMap *self, GSettings *settings);

