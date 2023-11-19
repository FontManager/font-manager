/* font-manager-orthography.c
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

#include "font-manager-orthography.h"

/**
 * SECTION: font-manager-orthography
 * @short_description: Font language support
 * @title: Orthography
 * @include: font-manager-orthography.h
 *
 * A #FontManagerOrthography holds information about the extent to which a
 * font supports a particular language.
 *
 * In addition to the english name, it includes the untranslated name of the
 * orthography along with a pangram or sample string for the language, if available.
 *
 * |[
 * {
 *   "name" : string,
 *   "native" : string,
 *   "sample" : string,
 *   "coverage" : double,
 *   "filter" : [ ]
 * }
 * ]|
 *
 * filter is a #JsonArray of available codepoints
 */

struct _FontManagerOrthography
{
    FontManagerJsonProxy parent;
};

G_DEFINE_TYPE(FontManagerOrthography, font_manager_orthography, FONT_MANAGER_TYPE_JSON_PROXY)

static void
font_manager_orthography_class_init (FontManagerOrthographyClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GObjectClass *parent_class = G_OBJECT_CLASS(font_manager_orthography_parent_class);
    FontManagerJsonProxyClass *proxy_class = FONT_MANAGER_JSON_PROXY_CLASS(klass);
    object_class->get_property = parent_class->get_property;
    object_class->set_property = parent_class->set_property;
    proxy_class->properties = OrthographyProperties;
    proxy_class->n_properties = G_N_ELEMENTS(OrthographyProperties);
    font_manager_json_proxy_install_properties(proxy_class);
    return;
}

static void
font_manager_orthography_init (G_GNUC_UNUSED FontManagerOrthography *self)
{
    g_return_if_fail(self != NULL);
}

/**
 * font_manager_orthography_get_filter:
 * @self: (nullable): #FontManagerOrthography
 *
 * Returns: (element-type uint) (transfer container) (nullable): #GList containing codepoints.
 * Free the returned #GList using #g_list_free().
 */
GList *
font_manager_orthography_get_filter (FontManagerOrthography *self)
{
    if (self == NULL)
        return NULL;
    GList *charlist = NULL;
    g_autoptr(JsonObject) source = NULL;
    g_object_get(self, FONT_MANAGER_JSON_PROXY_SOURCE, &source, NULL);
    g_return_val_if_fail(source != NULL, charlist);
    if (json_object_has_member(source, "filter")) {
        JsonArray *arr = json_object_get_array_member(source, "filter");
        guint arr_length = json_array_get_length(arr);
        for (guint index = 0; index < arr_length; index++) {
            gunichar uc = (gunichar) json_array_get_int_element(arr, index);
            charlist = g_list_prepend(charlist, GINT_TO_POINTER(uc));
        }
        charlist = g_list_reverse(charlist);
    }
    return charlist;
}

/**
 * font_manager_orthography_new:
 * @orthography:    #JsonObject containing orthography results
 *
 * @orthography should be one of the members of the object returned
 * by #font_manager_get_orthography_results()
 *
 * Returns: (transfer full): A newly created #FontManagerOrthography.
 * Free the returned object using #g_object_unref().
 */
FontManagerOrthography *
font_manager_orthography_new (JsonObject *orthography)
{
    return g_object_new(FONT_MANAGER_TYPE_ORTHOGRAPHY,
                        FONT_MANAGER_JSON_PROXY_SOURCE, orthography,
                        NULL);
}
