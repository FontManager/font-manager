/* fm-fontutils.h
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

#ifndef __FM_FONTUTILS_H__
#define __FM_FONTUTILS_H__

#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
#include FT_TYPES_H
#include FT_TYPE1_TABLES_H
#include FT_XFREE86_H

#include "fm-common.h"

GSList * FcListFiles(int Fini);
GSList * FcListUserDirs();
FT_Long FT_Get_Face_Count(const gchar *filepath);
FT_Error FT_Get_Font_Info(FontInfo *fontinfo, const gchar *filepath, int index);

#endif
/* EOF */

