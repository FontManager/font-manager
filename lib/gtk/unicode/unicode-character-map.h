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
#include "font-manager-regional-indicator-symbols.h"
#include "unicode-info.h"

#define FONT_MANAGER_TYPE_UNICODE_CHARACTER_MAP (font_manager_unicode_character_map_get_type())
G_DECLARE_FINAL_TYPE(FontManagerUnicodeCharacterMap, font_manager_unicode_character_map, FONT_MANAGER, UNICODE_CHARACTER_MAP, GtkDrawingArea)

GtkWidget * font_manager_unicode_character_map_new (void);

gint font_manager_unicode_character_map_get_active_cell (FontManagerUnicodeCharacterMap *self);
PangoFontDescription * font_manager_unicode_character_map_get_font_desc (FontManagerUnicodeCharacterMap *self);
double font_manager_unicode_character_map_get_preview_size (FontManagerUnicodeCharacterMap *self);
gint font_manager_unicode_character_map_get_last_index (FontManagerUnicodeCharacterMap *self);
gint font_manager_unicode_character_map_get_index (FontManagerUnicodeCharacterMap *self, GSList *codepoints);
GSList * font_manager_unicode_character_map_get_codepoints (FontManagerUnicodeCharacterMap *self, gint index);
void font_manager_unicode_character_map_set_active_cell (FontManagerUnicodeCharacterMap *self, gint cell);
void font_manager_unicode_character_map_set_filter (FontManagerUnicodeCharacterMap *self, GList *filter);
void font_manager_unicode_character_map_set_font_desc (FontManagerUnicodeCharacterMap *self, PangoFontDescription *font_desc);
void font_manager_unicode_character_map_set_preview_size (FontManagerUnicodeCharacterMap *self, gdouble size);
