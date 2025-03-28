/* font-manager-font-info.c
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

#include "font-manager-font-info.h"

/**
 * SECTION: font-manager-font-info
 * @short_description: Font metadata
 * @title: Font Info
 * @include: font-manager-font-info.h
 * @see_also: #FontManagerJsonProxy
 *
 * #FontManagerFontInfo holds detailed metadata for a single font.
 *
 * The #JsonObject backing this class should have the following structure:
 *
 * |[
 * {
 *   "filepath" : string,
 *   "findex" : int,
 *   "family" : string,
 *   "style" : string,
 *   "owner" : int,
 *   "psname" : string,
 *   "filetype" : string,
 *   "n-glyphs" : int,
 *   "copyright" : string,
 *   "version" : string,
 *   "description" : string,
 *   "license-data" : string,
 *   "license-url" : string,
 *   "vendor" : string,
 *   "designer" : string,
 *   "designer-url" : string,
 *   "license-type" : string,
 *   "fsType" : int,
 *   "filesize" : string,
 *   "checksum" : string,
 *   "panose": [ ],
 * }
 * ]|
 *
 * panose is a #JsonArray of integers
 */

struct _FontManagerFontInfo
{
    FontManagerJsonProxy parent;
};

G_DEFINE_TYPE(FontManagerFontInfo, font_manager_font_info, FONT_MANAGER_TYPE_JSON_PROXY)

static void
font_manager_font_info_class_init (FontManagerFontInfoClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GObjectClass *parent_class = G_OBJECT_CLASS(font_manager_font_info_parent_class);
    FontManagerJsonProxyClass *proxy_class = FONT_MANAGER_JSON_PROXY_CLASS(klass);
    object_class->get_property = parent_class->get_property;
    object_class->set_property = parent_class->set_property;
    proxy_class->properties = InfoProperties;
    proxy_class->n_properties = G_N_ELEMENTS(InfoProperties);
    font_manager_json_proxy_install_properties(proxy_class);
    return;
}

static void
font_manager_font_info_init (FontManagerFontInfo *self)
{
    g_return_if_fail(self != NULL);
}

/**
 * font_manager_font_info_new:
 *
 * Returns: (transfer full): A newly created #FontManagerFontInfo.
 * Free the returned object using #g_object_unref().
 */
FontManagerFontInfo *
font_manager_font_info_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_FONT_INFO, NULL);
}
