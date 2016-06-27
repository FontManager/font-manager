/* License.c
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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
 * along with Font Manager.  If not, see <https://opensource.org/licenses/GPL-3.0>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

#include <glib.h>
#include <glib/gprintf.h>

#include "License.h"

gint
get_license_type(const gchar * license, const gchar * copyright, const gchar * url)
{
    gint i;
    for (i = 0; i < LICENSE_ENTRIES; i++) {
        gint l = 0;
        while (LicenseData[i].keywords[l]) {
            if ((copyright && g_strrstr(copyright, LicenseData[i].keywords[l]))
                || (license && g_strrstr(license, LicenseData[i].keywords[l]))
                || (url && g_strrstr(url, LicenseData[i].keywords[l])))
                return i;
            l++;
        }
    }
    return LICENSE_ENTRIES - 1;
}

gchar *
get_license_name (gint license_type)
{
    return g_strdup(LicenseData[license_type].license);
}

gchar *
get_license_url (gint license_type)
{
    return g_strdup(LicenseData[license_type].license_url);
}
