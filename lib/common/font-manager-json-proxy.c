/* font-manager-json-proxy.c
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

#include "font-manager-json-proxy.h"

typedef struct
{
    JsonObject *source_object;
}
FontManagerJsonProxyPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerJsonProxy, font_manager_json_proxy, G_TYPE_OBJECT)

static void
font_manager_json_proxy_finalize (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerJsonProxy *self = FONT_MANAGER_JSON_PROXY(gobject);
    FontManagerJsonProxyPrivate *priv = font_manager_json_proxy_get_instance_private(self);
    if (priv->source_object)
        json_object_unref(priv->source_object);
    G_OBJECT_CLASS(font_manager_json_proxy_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_json_proxy_set_property (GObject *gobject,
                                      guint property_id,
                                      const GValue *value,
                                      GParamSpec *pspec)
{
    FontManagerJsonProxy *self = FONT_MANAGER_JSON_PROXY(gobject);
    g_return_if_fail(self != NULL);
    FontManagerJsonProxyPrivate *priv = font_manager_json_proxy_get_instance_private(self);

    if (G_PARAM_SPEC_VALUE_TYPE(pspec) == JSON_TYPE_OBJECT) {
        JsonObject *json_obj = g_value_get_boxed(value);
        if (priv->source_object == json_obj)
            return;
        if (priv->source_object != NULL)
            json_object_unref(priv->source_object);
        priv->source_object = json_obj ? json_object_ref(json_obj) : NULL;
        return;
    }

    G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    return;
}

static void
font_manager_json_proxy_get_property (GObject *gobject,
                                      guint property_id,
                                      GValue *value,
                                      GParamSpec *pspec)
{
    FontManagerJsonProxy *self = FONT_MANAGER_JSON_PROXY(gobject);
    g_return_if_fail(self != NULL);
    FontManagerJsonProxyPrivate *priv = font_manager_json_proxy_get_instance_private(self);

    if (priv->source_object == NULL)
        return;

    GType val_type  = G_PARAM_SPEC_VALUE_TYPE(pspec);

    if (!json_object_get_member(priv->source_object, pspec->name) && val_type != JSON_TYPE_OBJECT)
        return;

    if (val_type == G_TYPE_STRING) {
        g_value_set_string(value, json_object_get_string_member(priv->source_object, pspec->name));
    } else if (val_type == G_TYPE_INT) {
        g_value_set_int(value, json_object_get_int_member(priv->source_object, pspec->name));
    } else if (val_type == JSON_TYPE_ARRAY) {
        g_value_set_boxed(value, json_object_get_array_member(priv->source_object, pspec->name));
    } else if (val_type == JSON_TYPE_OBJECT) {
        g_value_set_boxed(value, priv->source_object);
    } else {
        G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }

    return;
}

/* font_manager_json_proxy_generate_class_properties:
 * @pspec:          empty array of #GParamSpec
 * @properties:     array of #FontManagerProxyObjectProperties
 * @num_properties: # of entries in properties
 */
static void
font_manager_json_proxy_generate_properties (GParamSpec *pspec[],
                                             const FontManagerProxyObjectProperties *properties,
                                             gint num_properties)
{
    GParamFlags OBJECT_PARAM_FLAGS = (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
    GParamFlags FONT_MANAGER_PROXY_OBJECT_SOURCE_PARAM_FLAGS = (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    for (gint i = 0; i < num_properties; i++) {
        const gchar *prop_name = properties[i].name;
        switch (properties[i].type) {
            case G_TYPE_INT:
                pspec[i] = g_param_spec_int(prop_name,
                                            NULL, NULL,
                                            G_MININT, G_MAXINT, G_MININT,
                                            OBJECT_PARAM_FLAGS);
                break;
            case G_TYPE_STRING:
                pspec[i] = g_param_spec_string(prop_name,
                                               NULL, NULL, NULL,
                                               OBJECT_PARAM_FLAGS);
                break;
            case G_TYPE_BOXED:
                pspec[i] = g_param_spec_boxed(prop_name, NULL, NULL,
                                              JSON_TYPE_ARRAY,
                                              OBJECT_PARAM_FLAGS);
                break;
            case G_TYPE_RESERVED_USER_FIRST:
                pspec[i] = g_param_spec_boxed(prop_name, NULL, NULL,
                                              JSON_TYPE_OBJECT,
                                              FONT_MANAGER_PROXY_OBJECT_SOURCE_PARAM_FLAGS);
                break;
            case G_TYPE_RESERVED_GLIB_FIRST:
                pspec[i] = NULL;
                break;
            default:
                break;
        }
    }
    return;
}

static void
font_manager_json_proxy_class_init (FontManagerJsonProxyClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = font_manager_json_proxy_finalize;
    object_class->get_property = font_manager_json_proxy_get_property;
    object_class->set_property = font_manager_json_proxy_set_property;
    klass->generate_properties = font_manager_json_proxy_generate_properties;
    return;
}

static void
font_manager_json_proxy_init (FontManagerJsonProxy *self)
{
    g_return_if_fail(self != NULL);
    return;
}

/**
 * font_manager_json_proxy_is_valid:
 * @self: (nullable): #FontManagerJsonProxy
 *
 * Returns %TRUE if source_object is not %NULL
 */
gboolean
font_manager_json_proxy_is_valid (FontManagerJsonProxy *self)
{
    if (self == NULL) { return FALSE; }
    FontManagerJsonProxyPrivate *priv = font_manager_json_proxy_get_instance_private(self);
    return (priv->source_object != NULL);
}

/**
 * font_manager_json_proxy_new:
 *
 * Returns: (transfer full): the newly-created #FontManagerJsonProxy.
 * Use g_object_unref() to free the result.
 **/
FontManagerJsonProxy *
font_manager_json_proxy_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_JSON_PROXY, NULL);
}
