/* unicode-character-map-zoom-window.h
 *
 * Copyright (C) 2019 - 2021 Jerry Casiano
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

#ifndef __UNICODE_CHARACTER_MAP_ZOOM_WINDOW_H__
#define __UNICODE_CHARACTER_MAP_ZOOM_WINDOW_H__

#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

#define UNICODE_TYPE_CHARACTER_MAP_ZOOM_WINDOW (unicode_character_map_zoom_window_get_type())
G_DECLARE_FINAL_TYPE(UnicodeCharacterMapZoomWindow, unicode_character_map_zoom_window, UNICODE, CHARACTER_MAP_ZOOM_WINDOW, GtkPopover)

UnicodeCharacterMapZoomWindow * unicode_character_map_zoom_window_new (void);

G_END_DECLS

#endif /* __UNICODE_CHARACTER_MAP_ZOOM_WINDOW_H__ */
