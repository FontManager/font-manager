/* fm-common.c
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

#include "fm-common.h"

void
g_free_and_nullify(gpointer p)
{
    g_free(p);
    g_nullify_pointer(&p);
}

/**
 * fontinfo_init:
 *
 * @fontinfo:   A FontInfo structure to initialize.
 */
void
fontinfo_init(FontInfo *fontinfo)
{
    fontinfo->owner         = g_strdup("None");
    fontinfo->filepath      = g_strdup("None");
    fontinfo->filetype      = g_strdup("Unknown");
    fontinfo->filesize      = g_strdup("None");
    fontinfo->checksum      = g_strdup("None");
    fontinfo->psname        = g_strdup("None");
    fontinfo->family        = g_strdup("None");
    fontinfo->style         = g_strdup("None");
    fontinfo->foundry       = g_strdup("Unknown");
    fontinfo->copyright     = g_strdup("None");
    fontinfo->version       = g_strdup("None");
    fontinfo->description   = g_strdup("None");
    fontinfo->license       = g_strdup("None");
    fontinfo->license_url   = g_strdup("None");
    /* fontinfo->panose        = g_strdup("0:0:0:0:0:0:0:0:0:0"); */
}

/**
 * fontinfo_destroy:
 *
 * @fontinfo:   A FontInfo structure to free.
 */
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
    /* g_free_and_nullify(fontinfo->panose); */
}

const gchar *suffix[] =
{
    "bytes",
    "kB",
    "MB",
    "GB",
    "TB"
};

#define SIZE_UNITS (int) (sizeof (suffix) / sizeof (suffix[0]))

/**
 * natural_size:
 *
 * @filesize: Filesize in bytes.
 *
 * Returns: A "human readable" filesize as a string. The returned string should
 *          be freed with g_free() when no longer needed.
 */
gchar *
natural_size(gsize filesize)
{
    int     i;
    double  fs = filesize;

    for (i = 0; i < SIZE_UNITS; i++)
    {
        if (fs < 1000.0)
            return g_strdup_printf("%3.1f %s", fs, suffix[i]);
        else
            fs /= 1000;
    }
    /* We should never get here */
    return g_strdup("");
}

