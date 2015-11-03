/* Vendor.c
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

#include <glib.h>
#include <glib/gprintf.h>

#include "Vendor.h"

static gboolean
vendor_matches(const gchar vendor[MAX_VENDOR_ID_LENGTH], const gchar * vendor_id)
{
    gboolean    result;
    GString     * a, * b;
    /* vendor is not necessarily NUL-terminated. */
    a = g_string_new_len((const gchar *) vendor, MAX_VENDOR_ID_LENGTH);
    b = g_string_new_len((const gchar *) vendor_id, MAX_VENDOR_ID_LENGTH);
    result = g_string_equal(a, b);
    g_string_free(a, TRUE);
    g_string_free(b, TRUE);
    return result;
}

gchar *
get_vendor_from_notice(const gchar * notice)
{
    gint i;
    if (notice)
        for(i = 0; i < NOTICE_ENTRIES; i++)
            if (g_strrstr(notice, NoticeData[i].vendor_id))
                return g_strdup(NoticeData[i].vendor);
    return NULL;
}

gchar *
get_vendor_from_vendor_id(const gchar vendor[MAX_VENDOR_ID_LENGTH])
{
    gint i;
    if (vendor)
        for(i = 0; i < VENDOR_ENTRIES; i++)
            if (vendor_matches(vendor, VendorData[i].vendor_id))
                return g_strdup(VendorData[i].vendor);
    return NULL;
}
