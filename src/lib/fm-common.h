/* fm-common.h
 *
 * Font Manager, a font management application for the GNOME desktop
 *
 * Copyright (C) 2009, 2010 Jerry Casiano
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to:
 *
 *   Free Software Foundation, Inc.
 *   51 Franklin Street, Fifth Floor
 *   Boston, MA 02110-1301, USA
*/

#ifndef __FM_COMMON_H__
#define __FM_COMMON_H__

#define APPNAME "font-manager"
#define DBNAME "font-manager.sqlite"

typedef struct _fontinfo FontInfo;

struct _fontinfo
{
    char   *owner;
    char   *filepath;
    char   *filetype;
    char   *filesize;
    char   *checksum;
    char   *psname;
    char   *family;
    char   *style;
    char   *foundry;
    char   *copyright;
    char   *version;
    char   *description;
    char   *license;
    char   *license_url;
    char   *panose;
    char   *face;
    char   *pfamily;
    char   *pstyle;
    char   *pvariant;
    char   *pweight;
    char   *pstretch;
    char   *pdescr;
};

void fontinfo_init(FontInfo *fontinfo);
void fontinfo_destroy(FontInfo *fontinfo);
void g_free_and_nullify(void *p);

#endif /* __FM_COMMON_H__ */

