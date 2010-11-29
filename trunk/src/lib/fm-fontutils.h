/* fm-fontutils.h
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

#ifndef __FM_FONTUTILS_H__
#define __FM_FONTUTILS_H__

#include <glib.h>
#include <ft2build.h>
#include FT_FREETYPE_H

#include "fm-common.h"

GSList * FcListFiles();
GSList * FcListUserDirs();
FT_Long FT_Get_Face_Count(const char *filepath);
FT_Error FT_Get_Font_Info(FontInfo *fontinfo, const char *filepath, int index);

#endif /* __FM_FONTUTILS_H__ */
