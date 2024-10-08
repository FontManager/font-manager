/* font-manager-json-proxy.c
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

#include "font-manager-json-proxy.h"

/**
 * SECTION: font-manager-json-proxy
 * @short_description: Wrapper class for JsonObjects
 * @title: JSON Proxy
 * @include: font-manager-json-proxy.h
 *
 * Simple wrapper around a #JsonObject which maps object members to gobject properties.
 */

typedef struct
{
    JsonObject *source_object;
}
FontManagerJsonProxyPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerJsonProxy, font_manager_json_proxy, G_TYPE_OBJECT)

static void
font_manager_json_proxy_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerJsonProxy *self = FONT_MANAGER_JSON_PROXY(gobject);
    FontManagerJsonProxyPrivate *priv;
    priv = font_manager_json_proxy_get_instance_private(self);
    g_clear_pointer(&priv->source_object, json_object_unref);
    G_OBJECT_CLASS(font_manager_json_proxy_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_json_proxy_set_property (GObject      *gobject,
                                      guint         property_id,
                                      const GValue *value,
                                      GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerJsonProxy *self = FONT_MANAGER_JSON_PROXY(gobject);
    FontManagerJsonProxyPrivate *priv;
    priv = font_manager_json_proxy_get_instance_private(self);
    GType val_type  = G_PARAM_SPEC_VALUE_TYPE(pspec);
    JsonObject *src = priv->source_object;

    if (val_type == JSON_TYPE_OBJECT) {
        JsonObject *json_obj = g_value_get_boxed(value);
        if (src == json_obj)
            return;
        if (src != NULL)
            json_object_unref(src);
        priv->source_object = json_obj ? json_object_ref(json_obj) : NULL;
        return;
    }

    if (src == NULL)
        return;

    if (val_type == G_TYPE_STRING) {
        json_object_set_string_member(src, pspec->name, g_value_get_string(value));
    } else if (val_type == G_TYPE_INT64) {
        json_object_set_int_member(src, pspec->name, g_value_get_int64(value));
    } else if (val_type == G_TYPE_DOUBLE) {
        json_object_set_double_member(src, pspec->name, g_value_get_double(value));
    } else if (val_type == G_TYPE_BOOLEAN) {
        json_object_set_boolean_member(src, pspec->name, g_value_get_boolean(value));
    } else if (val_type == JSON_TYPE_ARRAY) {
        json_object_set_array_member(src, pspec->name, g_value_get_boxed(value));
    } else {
        G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }

    return;
}

static void
font_manager_json_proxy_get_property (GObject    *gobject,
                                      guint       property_id,
                                      GValue     *value,
                                      GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerJsonProxy *self = FONT_MANAGER_JSON_PROXY(gobject);
    FontManagerJsonProxyPrivate *priv;
    priv = font_manager_json_proxy_get_instance_private(self);
    GType val_type  = G_PARAM_SPEC_VALUE_TYPE(pspec);
    JsonObject *src = priv->source_object;

    if (src == NULL)
        return;

    if (!json_object_has_member(src, pspec->name) && val_type != JSON_TYPE_OBJECT)
        return;

    if (val_type == G_TYPE_STRING) {
        g_value_set_string(value, json_object_get_string_member(src, pspec->name));
    } else if (val_type == G_TYPE_INT64) {
        g_value_set_int64(value, json_object_get_int_member(src, pspec->name));
    } else if (val_type == G_TYPE_DOUBLE) {
        g_value_set_double(value, json_object_get_double_member(src, pspec->name));
    } else if (val_type == G_TYPE_BOOLEAN) {
        g_value_set_boolean(value, json_object_get_boolean_member(src, pspec->name));
    } else if (val_type == JSON_TYPE_ARRAY) {
        g_value_set_boxed(value, json_object_get_array_member(src, pspec->name));
    } else if (val_type == JSON_TYPE_OBJECT) {
        g_value_set_boxed(value, src);
    } else {
        G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }

    return;
}


static void
font_manager_json_proxy_class_init (FontManagerJsonProxyClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = font_manager_json_proxy_dispose;
    object_class->get_property = font_manager_json_proxy_get_property;
    object_class->set_property = font_manager_json_proxy_set_property;
    return;
}

static void
font_manager_json_proxy_init (FontManagerJsonProxy *self)
{
    g_return_if_fail(self != NULL);
}

/**
 * font_manager_json_proxy_install_properties: (skip)
 * @klass:          #FontManagerJsonProxyClass
 *
 * properties and n_properties MUST be set before calling this method.
 *
 * A property with type G_TYPE_BOXED is assumed to be a #JsonArray.
 * A property with type JSON_TYPE_OBJECT is assumed to be the @source-object.
 */
void
font_manager_json_proxy_install_properties (FontManagerJsonProxyClass *klass)
{

    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GParamFlags OBJECT_PARAM_FLAGS = (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    for (gint i = 0; i < klass->n_properties; i++) {
        switch (klass->properties[i].type) {
            case G_TYPE_INT64:
                g_object_class_install_property(object_class, i,
                                                g_param_spec_int64(klass->properties[i].name,
                                                                   NULL,
                                                                   klass->properties[i].desc,
                                                                   G_MININT, G_MAXINT, 0,
                                                                   OBJECT_PARAM_FLAGS));
                break;
            case G_TYPE_DOUBLE:
                g_object_class_install_property(object_class, i,
                                                g_param_spec_double(klass->properties[i].name,
                                                                    NULL,
                                                                    klass->properties[i].desc,
                                                                    -G_MAXDOUBLE, G_MAXDOUBLE, 0.0,
                                                                    OBJECT_PARAM_FLAGS));
                break;
            case G_TYPE_BOOLEAN:
                g_object_class_install_property(object_class, i,
                                                g_param_spec_boolean(klass->properties[i].name,
                                                                     NULL,
                                                                     klass->properties[i].desc,
                                                                     FALSE,
                                                                     OBJECT_PARAM_FLAGS));
                break;
            case G_TYPE_STRING:
                g_object_class_install_property(object_class, i,
                                                g_param_spec_string(klass->properties[i].name,
                                                                    NULL,
                                                                    klass->properties[i].desc,
                                                                    NULL,
                                                                    OBJECT_PARAM_FLAGS));
                break;
            case G_TYPE_BOXED:
                g_object_class_install_property(object_class, i,
                                                g_param_spec_boxed(klass->properties[i].name,
                                                                   NULL,
                                                                   klass->properties[i].desc,
                                                                   JSON_TYPE_ARRAY,
                                                                   OBJECT_PARAM_FLAGS));
                break;
            case G_TYPE_RESERVED_USER_FIRST:
                g_object_class_install_property(object_class, i,
                                                g_param_spec_boxed(klass->properties[i].name,
                                                                   NULL,
                                                                   klass->properties[i].desc,
                                                                   JSON_TYPE_OBJECT,
                                                                   OBJECT_PARAM_FLAGS));
                break;
            default:
                break;
        }
    }
    return;
}

/**
 * font_manager_json_proxy_new:
 *
 * Returns: (transfer full): A newly created #FontManagerJsonProxy.
 * Free the returned object using #g_object_unref().
 **/
FontManagerJsonProxy *
font_manager_json_proxy_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_JSON_PROXY, NULL);
}
