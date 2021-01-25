/* unicode-codepoint-list.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017 - 2021 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
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

#include <glib.h>

#include "unicode-codepoint-list.h"

/**
 * SECTION: unicode-codepoint-list
 * @short_description: List interface for Unicode code points
 * @title: Codepoint List
 * @include: unicode-codepoint-list.h
 * @see_also: UnicodeCharacterMap
 *
 * Interface for a list of unicode codepoints.
 */

G_DEFINE_INTERFACE (UnicodeCodepointList, unicode_codepoint_list, G_TYPE_OBJECT)


static void
unicode_codepoint_list_default_init (G_GNUC_UNUSED UnicodeCodepointListInterface *iface)
{
    return;
}

/**
 * unicode_codepoint_list_get_char:
 * @self: a #UnicodeCodepointList
 * @index: index indicating which character to get
 *
 * Returns: Code point at @index in the codepoint list, or
 *   (gunichar)(-1) if @index is beyond the last code point in list.
 **/
gunichar
unicode_codepoint_list_get_char (UnicodeCodepointList *self, gint index)
{
    g_return_val_if_fail(UNICODE_IS_CODEPOINT_LIST(self), (gunichar)(-1));
    UnicodeCodepointListInterface *iface = UNICODE_CODEPOINT_LIST_GET_IFACE(self);
    g_return_val_if_fail(iface->get_char != NULL, (gunichar)(-1));
    return iface->get_char(self, index);
}

/**
 * unicode_codepoint_list_get_index:
 * @self: a #UnicodeCodepointList
 * @wc: character for which to find the index
 *
 * Returns: Index of @wc, or -1 if @wc is not in this codepoint list.
 **/
gint
unicode_codepoint_list_get_index (UnicodeCodepointList *self, gunichar wc)
{
    g_return_val_if_fail(UNICODE_IS_CODEPOINT_LIST(self), -1);
    UnicodeCodepointListInterface *iface = UNICODE_CODEPOINT_LIST_GET_IFACE(self);
    g_return_val_if_fail(iface->get_index != NULL, -1);
    return iface->get_index(self, wc);
}

/**
 * unicode_codepoint_list_get_last_index:
 * @self: a #UnicodeCodepointList
 *
 * Returns: Last index in this codepoint list.
 **/
gint
unicode_codepoint_list_get_last_index (UnicodeCodepointList *self)
{
    g_return_val_if_fail(UNICODE_IS_CODEPOINT_LIST(self), -1);
    UnicodeCodepointListInterface *iface = UNICODE_CODEPOINT_LIST_GET_IFACE(self);
    g_return_val_if_fail(iface->get_last_index != NULL, -1);
    return iface->get_last_index(self);
}

