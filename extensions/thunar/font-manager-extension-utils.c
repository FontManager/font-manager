/* font-manager-extension-utils.h
 *
 * Copyright (C) 2020 - 2021 Jerry Casiano
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

#include "font-manager-extension-utils.h"

#define N_MIMETYPES 7

static const gchar *MIMETYPES [N_MIMETYPES] = {
    "font/ttf",
    "font/ttc",
    "font/otf",
    "font/collection",
    "application/x-font-ttf",
    "application/x-font-ttc",
    "application/x-font-otf",
};

gboolean
thunarx_file_info_is_font_file (ThunarxFileInfo *fileinfo)
{
    for (gint i = 0; i < N_MIMETYPES; i++)
        if (thunarx_file_info_has_mime_type(fileinfo, MIMETYPES[i]))
            return TRUE;
    return FALSE;
}

gboolean
file_list_contains_font_files (GList *thunarx_file_info_list)
{
    for (GList *iter = thunarx_file_info_list; iter != NULL; iter = iter->next)
        if (thunarx_file_info_is_font_file(iter->data))
            return TRUE;
    return FALSE;
}
