/* unicode-character-map.h
 *
 * Copyright (C) 2017-2022 Jerry Casiano
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

#include <math.h>
#include <glib.h>
#include <glib/gi18n-lib.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <graphene.h>

#include "font-manager-gtk-utils.h"
#include "regional-indicator-symbols.h"
#include "unicode-codepoint-list.h"
#include "unicode-info.h"

#define UNICODE_TYPE_CHARACTER_MAP (unicode_character_map_get_type())
G_DECLARE_FINAL_TYPE(UnicodeCharacterMap, unicode_character_map, UNICODE, CHARACTER_MAP, GtkDrawingArea)

GtkWidget * unicode_character_map_new (void);

gint unicode_character_map_get_active_cell (UnicodeCharacterMap *charmap);
PangoFontDescription * unicode_character_map_get_font_desc (UnicodeCharacterMap *charmap);
double unicode_character_map_get_preview_size (UnicodeCharacterMap *charmap);
UnicodeCodepointList * unicode_character_map_get_codepoint_list (UnicodeCharacterMap *charmap);
void unicode_character_map_set_active_cell (UnicodeCharacterMap *charmap, gint cell);
void unicode_character_map_set_codepoint_list (UnicodeCharacterMap *charmap, UnicodeCodepointList *codepoint_list);
void unicode_character_map_set_font_desc (UnicodeCharacterMap *charmap, PangoFontDescription *font_desc);
void unicode_character_map_set_preview_size (UnicodeCharacterMap *charmap, gdouble size);
