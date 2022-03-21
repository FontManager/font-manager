/* font-manager-font-info.h
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

#pragma once

#include <glib.h>
#include <glib-object.h>

#include "font-manager-json-proxy.h"

/* Order matters, adjust bind_from_properties to account for changes */
static const FontManagerJsonProxyProperty InfoProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST, NULL },
    { "filepath", G_TYPE_STRING, "Filepath" },
    { "findex", G_TYPE_INT, "Face index" },
    { "family", G_TYPE_STRING, "Family name" },
    { "style", G_TYPE_STRING, "Style" },
    { "owner", G_TYPE_INT, "Whether file is writable by user" },
    { "psname", G_TYPE_STRING, "PostScript name" },
    { "filetype", G_TYPE_STRING, "Font format" },
    { "n-glyphs", G_TYPE_INT, "Number of glyphs" },
    { "copyright", G_TYPE_STRING, "Copyright notice" },
    { "version", G_TYPE_STRING, "Font version" },
    { "description", G_TYPE_STRING, "Design description" },
    { "license-data", G_TYPE_STRING, "Embedded license data" },
    { "license-url", G_TYPE_STRING, "License URL" },
    { "vendor", G_TYPE_STRING, "Font foundry name" },
    { "designer", G_TYPE_STRING, "Name of font designer" },
    { "designer-url", G_TYPE_STRING, "Designer homepage" },
    { "license-type", G_TYPE_STRING, "License type" },
    { "fsType", G_TYPE_INT, "Embedding restrictions" },
    { "filesize", G_TYPE_STRING, "Size on disk" },
    { "checksum", G_TYPE_STRING, "MD5 checksum" },
    { FONT_MANAGER_JSON_PROXY_SOURCE, G_TYPE_RESERVED_USER_FIRST, "JsonObject source for this class" },
    { "panose", G_TYPE_BOXED, "Panose information as a JsonArray" }
};

#define FONT_MANAGER_TYPE_FONT_INFO (font_manager_font_info_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFontInfo, font_manager_font_info, FONT_MANAGER, FONT_INFO, FontManagerJsonProxy)

FontManagerFontInfo * font_manager_font_info_new (void);

