/* font-manager-font.h
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

#ifndef __FONT_MANAGER_TYPE_FONT_H__
#define __FONT_MANAGER_TYPE_FONT_H__

#include "font-manager-json-proxy.h"

G_BEGIN_DECLS

/* Order matters, adjust bind_from_properties to account for changes */
static const FontManagerJsonProxyProperties FontProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST, NULL },
    { "filepath", G_TYPE_STRING, "Font filepath" },
    { "findex", G_TYPE_INT, "Font face index" },
    { "family", G_TYPE_STRING, "Fontconfig family name" },
    { "style", G_TYPE_STRING, "Fontconfig style name"},
    { "spacing", G_TYPE_INT, "Fontconfig spacing" },
    { "slant", G_TYPE_INT, "Fontconfig slant" },
    { "weight", G_TYPE_INT, "Fontconfig weight" },
    { "width", G_TYPE_INT, "Fontconfig width" },
    { "description", G_TYPE_STRING, "Pango font description" },
    { FONT_MANAGER_JSON_PROXY_SOURCE, G_TYPE_RESERVED_USER_FIRST, "JsonObject source for this class" }
};

#define FONT_MANAGER_TYPE_FONT (font_manager_font_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFont, font_manager_font, FONT_MANAGER, FONT, FontManagerJsonProxy)

FontManagerFont * font_manager_font_new (void);

G_END_DECLS

#endif /* __FONT_MANAGER_TYPE_FONT_H__ */
