/* font-manager-orthography.h
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
#include <json-glib/json-glib.h>

#include "font-manager-json-proxy.h"

static const FontManagerJsonProxyProperty OrthographyProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST, NULL },
    { "name", G_TYPE_STRING, "English name for orthography" },
    { "native", G_TYPE_STRING, "Native name for orthography" },
    { "sample", G_TYPE_STRING, "Pangram or sample string"},
    { "coverage", G_TYPE_DOUBLE, "Coverage as a percentage" },
    { FONT_MANAGER_JSON_PROXY_SOURCE, G_TYPE_RESERVED_USER_FIRST, "JsonObject source for this class" }
};


#define FONT_MANAGER_TYPE_ORTHOGRAPHY (font_manager_orthography_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerOrthography, font_manager_orthography, FONT_MANAGER, ORTHOGRAPHY, FontManagerJsonProxy)

FontManagerOrthography * font_manager_orthography_new (JsonObject *orthography);
GList * font_manager_orthography_get_filter (FontManagerOrthography *self);

