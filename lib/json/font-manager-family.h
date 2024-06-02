/* font-manager-family.h
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

#include "font-manager-json-proxy.h"

static const FontManagerJsonProxyProperty FamilyProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST, NULL },
    { "family", G_TYPE_STRING, "Family name" },
    { "n-variations", G_TYPE_INT64, "Number of font variations" },
    { "active", G_TYPE_BOOLEAN, "Whether family is active"},
    { "description", G_TYPE_STRING, "Pango font description" },
    { "preview-text", G_TYPE_STRING, "Sample text" },
    { FONT_MANAGER_JSON_PROXY_SOURCE, G_TYPE_RESERVED_USER_FIRST, "JsonObject source for this class" },
    { "variations", G_TYPE_BOXED, "JsonArray of JsonObjects" }
};

#define FONT_MANAGER_TYPE_FAMILY (font_manager_family_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFamily, font_manager_family, FONT_MANAGER, FAMILY, FontManagerJsonProxy)

FontManagerFamily * font_manager_family_new (void);
gint font_manager_family_get_default_index (FontManagerFamily *self);
JsonObject * font_manager_family_get_default_variant (FontManagerFamily *self);

