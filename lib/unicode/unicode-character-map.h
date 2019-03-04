/* unicode-character-map.h
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017 - 2019 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
 * Copyright © 2007 Christian Persch
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

#ifndef __CHARACTER_MAP_H__
#define __CHARACTER_MAP_H__

#include <glib.h>
#include <gtk/gtk.h>

#include "unicode-codepoint-list.h"

G_BEGIN_DECLS

#define UNICODE_TYPE_CHARACTER_MAP (unicode_character_map_get_type())
G_DECLARE_DERIVABLE_TYPE(UnicodeCharacterMap, unicode_character_map, UNICODE, CHARACTER_MAP, GtkDrawingArea)

struct _UnicodeCharacterMapClass
{
    GtkDrawingAreaClass parent_class;

    void    (* activate)                (UnicodeCharacterMap *charmap);
    void    (* copy_clipboard)          (UnicodeCharacterMap *charmap);
    void    (* paste_clipboard)         (UnicodeCharacterMap *charmap);
    void    (* set_active_char)         (UnicodeCharacterMap *charmap, guint ch);
    void    (* status_message)          (UnicodeCharacterMap *charmap, const gchar *message);
    void    (* set_scroll_adjustments)  (UnicodeCharacterMap *charmap,
                                          GtkAdjustment *hadjustment,
                                          GtkAdjustment *vadjustment);
    gboolean    (* move_cursor)         (UnicodeCharacterMap *charmap,
                                          GtkMovementStep step,
                                          gint count);
};

GtkWidget * unicode_character_map_new (void);
void unicode_character_map_set_active_character (UnicodeCharacterMap *charmap, gunichar wc);
void unicode_character_map_set_codepoint_list (UnicodeCharacterMap *charmap, UnicodeCodepointList *codepoint_list);
void unicode_character_map_set_font_desc (UnicodeCharacterMap *charmap, PangoFontDescription *font_desc);
void unicode_character_map_set_preview_size (UnicodeCharacterMap *charmap, double size);
double unicode_character_map_get_preview_size (UnicodeCharacterMap *charmap);
gunichar unicode_character_map_get_active_character (UnicodeCharacterMap *charmap);
PangoFontDescription * unicode_character_map_get_font_desc (UnicodeCharacterMap *charmap);
UnicodeCodepointList * unicode_character_map_get_codepoint_list (UnicodeCharacterMap *charmap);

G_END_DECLS

#endif  /* #ifndef __CHARACTER_MAP_H__ */
