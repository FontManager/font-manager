/* font-manager-font-info.h
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

#ifndef __FONT_MANAGER_TYPE_FONT_INFO_H__
#define __FONT_MANAGER_TYPE_FONT_INFO_H__

#include "font-manager-json-proxy.h"

G_BEGIN_DECLS

/* Order matters, adjust bind_from_properties to account for changes */
static const FontManagerProxyObjectProperties InfoProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST },
    { "filepath", G_TYPE_STRING },
    { "findex", G_TYPE_INT },
    { "family", G_TYPE_STRING },
    { "style", G_TYPE_STRING },
    { "owner", G_TYPE_INT },
    { "psname", G_TYPE_STRING },
    { "filetype", G_TYPE_STRING },
    { "n-glyphs", G_TYPE_INT },
    { "copyright", G_TYPE_STRING },
    { "version", G_TYPE_STRING },
    { "description", G_TYPE_STRING },
    { "license-data", G_TYPE_STRING },
    { "license-url", G_TYPE_STRING },
    { "vendor", G_TYPE_STRING },
    { "designer", G_TYPE_STRING },
    { "designer-url", G_TYPE_STRING },
    { "license-type", G_TYPE_STRING },
    { "fsType", G_TYPE_INT },
    { "filesize", G_TYPE_STRING },
    { "checksum", G_TYPE_STRING },
    { FONT_MANAGER_PROXY_OBJECT_SOURCE, G_TYPE_RESERVED_USER_FIRST },
    { "panose", G_TYPE_BOXED }
};

#define FONT_MANAGER_TYPE_FONT_INFO (font_manager_font_info_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFontInfo, font_manager_font_info, FONT_MANAGER, FONT_INFO, FontManagerJsonProxy)

FontManagerFontInfo * font_manager_font_info_new (void);

G_END_DECLS

#endif /* __FONT_MANAGER_TYPE_FONT_INFO_H__ */

