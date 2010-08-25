/* fm-common.h
 *
 * Copyright (C) 2009, 2010 Jerry Casiano
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to:
 *
 *   Free Software Foundation, Inc.
 *   51 Franklin Street, Fifth Floor
 *   Boston, MA 02110-1301, USA
*/

#ifndef __FM_COMMON_H__
#define __FM_COMMON_H__

#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>

typedef struct _fontinfo FontInfo;
/*
 * All values in this stucture are initialized to "None"
 * Except for filetype and foundry which are initialized to "Unknown"
 */
struct _fontinfo
{
    gchar    *owner;
    gchar    *filepath;
    gchar    *filetype;
    gchar    *filesize;
    gchar    *checksum;
    gchar    *psname;
    gchar    *family;
    gchar    *style;
    gchar    *foundry;
    gchar    *copyright;
    gchar    *version;
    gchar    *description;
    gchar    *license;
    gchar    *license_url;
    /* gchar    *panose; */
};

void fontinfo_init(FontInfo *fontinfo);
void fontinfo_destroy(FontInfo *fontinfo);
void g_free_and_nullify(gpointer p);
gchar * natural_size(gsize filesize);

#endif
/* EOF */

