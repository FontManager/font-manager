/* font-manager-family.c
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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
#include "font-manager-json-proxy.h"
#include "json-proxy-object-properties.h"

struct _FontManagerFamily
{
    GObject parent_instance;

    JsonObject *source_object;
};

static void iface_init (G_GNUC_UNUSED FontManagerJsonProxyInterface *iface)
{
    return;
}

G_DEFINE_TYPE_WITH_CODE(FontManagerFamily, font_manager_family, G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(FONT_MANAGER_TYPE_JSON_PROXY, iface_init))

#define PROPERTIES FamilyProperties
#define N_PROPERTIES G_N_ELEMENTS(PROPERTIES)
static GParamSpec *obj_properties[N_PROPERTIES] = {0};

static void
font_manager_family_finalize (GObject *gobject)
{
    FontManagerFamily *self = FONT_MANAGER_FAMILY(gobject);
    if (self && self->source_object != NULL)
        json_object_unref(self->source_object);
    G_OBJECT_CLASS(font_manager_family_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_family_get_property (GObject *gobject,
                                  guint property_id,
                                  GValue *value,
                                  GParamSpec *pspec)
{
    FontManagerFamily *self = FONT_MANAGER_FAMILY(gobject);
    g_return_if_fail(self != NULL);
    get_json_source_property(self->source_object, gobject, property_id, value, pspec);
    return;
}

static void
set_source (GObject *gobject, JsonObject *value)
{
    FontManagerFamily *self = FONT_MANAGER_FAMILY(gobject);
    g_return_if_fail(self != NULL);
    if (self->source_object == value)
        return;
    if (self->source_object != NULL)
        json_object_unref(self->source_object);
    self->source_object = value ? json_object_ref(value) : NULL;
    return;
}

static void
font_manager_family_set_property (GObject *gobject,
                                  guint property_id,
                                  const GValue *value,
                                  GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);

    if (G_PARAM_SPEC_VALUE_TYPE(pspec) == JSON_TYPE_OBJECT)
        set_source(gobject, g_value_get_boxed(value));
    else
        G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);

    return;
}

static void
font_manager_family_class_init (FontManagerFamilyClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->get_property = font_manager_family_get_property;
    object_class->set_property = font_manager_family_set_property;
    object_class->finalize = font_manager_family_finalize;
    generate_class_properties(obj_properties, PROPERTIES, N_PROPERTIES);
    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_family_init (G_GNUC_UNUSED FontManagerFamily *self)
{
    return;
}

/**
 * font_manager_family_get_default_variant:
 *
 * Returns: (transfer none): #JsonObject
 */
JsonObject *
font_manager_family_get_default_variant (FontManagerFamily *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    const gchar *family_desc = json_object_get_string_member(self->source_object, "description");
    JsonArray *arr = json_object_get_array_member(self->source_object, "variations");
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
 * Returns: (transfer full): a new #FontManagerFont
 */
FontManagerFamily *
font_manager_family_new (void)
{
    return FONT_MANAGER_FAMILY(g_object_new(font_manager_family_get_type(), NULL));
}

