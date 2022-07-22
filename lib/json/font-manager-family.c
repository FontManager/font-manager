/* font-manager-family.c
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

#include "font-manager-family.h"

/**
 * SECTION: font-manager-family
 * @short_description: Font family
 * @title: Family
 * @include: font-manager-family.h
 * @see_also: #FontManagerJsonProxy #FontManagerFont
 *
 * #FontManagerFamily holds information about a font family along with an array
 * of #JsonObject representing the fonts belonging to this font family.
 *
 * The #JsonObject backing this class should have the following structure:
 *
 * |[
 * {
 *   "family" : string,
 *   "description" : string,
 *   "n-variations" : int,
 *   "active" : bool,
 *   "variations" : [ ]
 * }
 *]|
 *
 * variations is a #JsonArray of #JsonObjects representing individual fonts.
 * See #FontManagerFont for object description.
 */

struct _FontManagerFamily
{
    GObject parent_instance;
};

G_DEFINE_TYPE(FontManagerFamily, font_manager_family, FONT_MANAGER_TYPE_JSON_PROXY)

#define PROPERTIES FamilyProperties
#define N_PROPERTIES G_N_ELEMENTS(PROPERTIES)
static GParamSpec *obj_properties[N_PROPERTIES] = {0};

static gboolean
is_valid (FontManagerJsonProxy *self)
{
    g_autoptr(JsonObject) source = NULL;
    g_object_get(self, "source-object", &source, NULL);
    if (source == NULL)
        return FALSE;
    for (gint i = 0; i < N_PROPERTIES; i++) {
        const gchar *prop_name = PROPERTIES[i].name;
        switch (PROPERTIES[i].type) {
            case G_TYPE_RESERVED_GLIB_FIRST:
            case G_TYPE_RESERVED_USER_FIRST:
                break;
            default:
                if (json_object_has_member(source, prop_name))
                    break;
                else
                    return FALSE;
        }
    }
    return TRUE;
}

static void
font_manager_family_class_init (FontManagerFamilyClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GObjectClass *parent_class = G_OBJECT_CLASS(font_manager_family_parent_class);
    object_class->get_property = parent_class->get_property;
    object_class->set_property = parent_class->set_property;
    FONT_MANAGER_JSON_PROXY_CLASS(klass)->is_valid = is_valid;
    font_manager_json_proxy_generate_properties(obj_properties, PROPERTIES, N_PROPERTIES);
    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_family_init (FontManagerFamily *self)
{
    g_return_if_fail(self != NULL);
}

/**
 * font_manager_family_get_default_variant:
 * @self:   #FontManagerFamily
 *
 * Returns: (transfer none): #JsonObject which should not be freed.
 */
JsonObject *
font_manager_family_get_default_variant (FontManagerFamily *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    g_autoptr(JsonObject) source = NULL;
    g_object_get(self, "source-object", &source, NULL);
    const gchar *family_desc = json_object_get_string_member(source, "description");
    JsonArray *arr = json_object_get_array_member(source, "variations");
    guint i, arr_length = json_array_get_length(arr);
    for (i = 0; i < arr_length; i++) {
        JsonObject *font = json_array_get_object_element(arr, i);
        const gchar *font_desc = json_object_get_string_member(font, "description");
        if (g_strcmp0(family_desc, font_desc) == 0)
            return font;
    }
    g_return_val_if_reached(json_array_get_object_element(arr, 0));
}

/**
 * font_manager_family_new:
 *
 * Returns: (transfer full): A newly created #FontManagerFamily.
 * Free the returned object using #g_object_unref().
 */
FontManagerFamily *
font_manager_family_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_FAMILY, NULL);
}

