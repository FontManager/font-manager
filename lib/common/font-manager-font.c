/* font-manager-font.c
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

#include <json-glib/json-glib.h>

#include "font-manager-font.h"
#include "font-manager-json-proxy.h"
#include "json-proxy-object-properties.h"

struct _FontManagerFont
{
    GObject parent_instance;

    JsonObject *source_object;
};

G_DEFINE_TYPE_WITH_CODE(FontManagerFont, font_manager_font, G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(FONT_MANAGER_TYPE_JSON_PROXY, NULL))

#define PROPERTIES FontProperties
#define N_PROPERTIES G_N_ELEMENTS(PROPERTIES)
static GParamSpec *obj_properties[N_PROPERTIES] = {0};

static void
font_manager_font_finalize (GObject *gobject)
{
    FontManagerFont *self = FONT_MANAGER_FONT(gobject);
    if (self && self->source_object != NULL)
        json_object_unref(self->source_object);
    G_OBJECT_CLASS(font_manager_font_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_font_get_property (GObject *gobject,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
    FontManagerFont *self = FONT_MANAGER_FONT(gobject);
    g_return_if_fail(self != NULL);
    get_json_source_property(self->source_object, gobject, property_id, value, pspec);
    return;
}

static void
set_source (GObject *gobject, JsonObject *value)
{
    FontManagerFont *self = FONT_MANAGER_FONT(gobject);
    g_return_if_fail(self != NULL);
    if (self->source_object == value)
        return;
    if (self->source_object != NULL)
        json_object_unref(self->source_object);
    self->source_object = value ? json_object_ref(value) : NULL;
    return;
}

static void
font_manager_font_set_property (GObject *gobject,
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
font_manager_font_class_init (FontManagerFontClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->get_property = font_manager_font_get_property;
    object_class->set_property = font_manager_font_set_property;
    object_class->finalize = font_manager_font_finalize;
    generate_class_properties(obj_properties, PROPERTIES, N_PROPERTIES);
    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_font_init (G_GNUC_UNUSED FontManagerFont *self)
{
    return;
}

/**
 * font_manager_font_new:
 *
 * Returns: (transfer full): a new #FontManagerFont
 */
FontManagerFont *
font_manager_font_new (void)
{
    return FONT_MANAGER_FONT(g_object_new(font_manager_font_get_type(), NULL));
}

