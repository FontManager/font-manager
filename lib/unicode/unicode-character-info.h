/* unicode-character-info.h
 *
 * Copyright (C) 2020 Jerry Casiano
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

#include "unicode-character-map.h"

#define UNICODE_TYPE_CHARACTER_INFO (unicode_character_info_get_type())
G_DECLARE_FINAL_TYPE(UnicodeCharacterInfo, unicode_character_info, UNICODE, CHARACTER_INFO, GtkWidget)

GtkWidget * unicode_character_info_new (void);
void unicode_character_info_set_character_map (UnicodeCharacterInfo *self, UnicodeCharacterMap *character_map);
