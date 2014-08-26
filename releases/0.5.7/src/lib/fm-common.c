/* fm-common.c
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

#include <glib.h>
#include <glib/gprintf.h>

#include "fm-common.h"

void
g_free_and_nullify(void *p)
{
    g_free(p);
    g_nullify_pointer(&p);
}

void
fontinfo_init(FontInfo *fontinfo)
{
    fontinfo->owner         = g_strdup("System");
    fontinfo->filepath      = g_strdup("None");
    fontinfo->filetype      = g_strdup("Unknown");
    fontinfo->filesize      = g_strdup("None");
    fontinfo->checksum      = g_strdup("None");
    fontinfo->psname        = g_strdup("None");
    fontinfo->family        = g_strdup("None");
    fontinfo->style         = g_strdup("None");
    fontinfo->foundry       = g_strdup("Unknown");
    fontinfo->copyright     = g_strdup("None");
    fontinfo->version       = g_strdup("1.0");
    fontinfo->description   = g_strdup("None");
    fontinfo->license       = g_strdup("None");
    fontinfo->license_url   = g_strdup("None");
    fontinfo->panose        = g_strdup("0:0:0:0:0:0:0:0:0:0");
    fontinfo->face          = g_strdup("0");
    fontinfo->pfamily       = g_strdup("None");
    fontinfo->pstyle        = g_strdup("None");
    fontinfo->pvariant      = g_strdup("None");
    fontinfo->pweight       = g_strdup("None");
    fontinfo->pstretch      = g_strdup("None");
    fontinfo->pdescr        = g_strdup("None");
}

void
fontinfo_destroy(FontInfo *fontinfo)
{
    g_free_and_nullify(fontinfo->owner);
    g_free_and_nullify(fontinfo->filepath);
    g_free_and_nullify(fontinfo->filetype);
    g_free_and_nullify(fontinfo->filesize);
    g_free_and_nullify(fontinfo->checksum);
    g_free_and_nullify(fontinfo->psname);
    g_free_and_nullify(fontinfo->family);
    g_free_and_nullify(fontinfo->style);
    g_free_and_nullify(fontinfo->foundry);
    g_free_and_nullify(fontinfo->copyright);
    g_free_and_nullify(fontinfo->version);
    g_free_and_nullify(fontinfo->description);
    g_free_and_nullify(fontinfo->license);
    g_free_and_nullify(fontinfo->license_url);
    g_free_and_nullify(fontinfo->panose);
    g_free_and_nullify(fontinfo->face);
    g_free_and_nullify(fontinfo->pfamily);
    g_free_and_nullify(fontinfo->pstyle);
    g_free_and_nullify(fontinfo->pvariant);
    g_free_and_nullify(fontinfo->pweight);
    g_free_and_nullify(fontinfo->pstretch);
    g_free_and_nullify(fontinfo->pdescr);
}

