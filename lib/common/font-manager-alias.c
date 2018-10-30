/* font-manager-alias.c
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

#include "font-manager-alias.h"
#include "font-manager-xml-writer.h"

struct _FontManagerAliasElement
{
    GObjectClass parent_class;
};

typedef struct
{
    gchar *family;
    StringHashset *prefer;
    StringHashset *accept;
    StringHashset *_default;
}
FontManagerAliasElementPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerAliasElement, font_manager_alias_element, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_FAMILY,
    PROP_PREFER,
    PROP_ACCEPT,
    PROP_DEFAULT,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

#define DEFAULT_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

static void
font_manager_alias_element_finalize (GObject *self)
{
    FontManagerAliasElement *_self = FONT_MANAGER_ALIAS_ELEMENT(self);
    g_return_if_fail(_self != NULL);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(_self);
    g_free(priv->family);
    g_clear_object(&priv->prefer);
    g_clear_object(&priv->accept);
    g_clear_object(&priv->_default);
    G_OBJECT_CLASS(font_manager_alias_element_parent_class)->finalize(self);
    return;
}

static void
font_manager_alias_element_get_property (GObject *gobject,
                                        guint property_id,
                                        GValue *value,
                                        GParamSpec *pspec)
{
    FontManagerAliasElement *self = FONT_MANAGER_ALIAS_ELEMENT(gobject);
    g_return_if_fail(self != NULL);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    switch (property_id) {
        case PROP_FAMILY:
            g_value_set_string(value, priv->family);
            break;
        case PROP_PREFER:
            g_value_set_object(value, priv->prefer);
            break;
        case PROP_ACCEPT:
            g_value_set_object(value, priv->accept);
            break;
        case PROP_DEFAULT:
            g_value_set_object(value, priv->_default);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_alias_element_set_property (GObject *gobject,
                                        guint property_id,
                                        const GValue *value,
                                        GParamSpec *pspec)
{
    FontManagerAliasElement *self = FONT_MANAGER_ALIAS_ELEMENT(gobject);
    g_return_if_fail(self != NULL);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    switch (property_id) {
        case PROP_FAMILY:
            g_free(priv->family);
            priv->family = g_value_dup_string(value);
            break;
        case PROP_PREFER:
            g_set_object(&priv->prefer, g_value_get_object(value));
            break;
        case PROP_ACCEPT:
            g_set_object(&priv->accept, g_value_get_object(value));
            break;
        case PROP_DEFAULT:
            g_set_object(&priv->_default, g_value_get_object(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_alias_element_class_init (FontManagerAliasElementClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = font_manager_alias_element_finalize;
    object_class->get_property = font_manager_alias_element_get_property;
    object_class->set_property = font_manager_alias_element_set_property;

    obj_properties[PROP_FAMILY] = g_param_spec_string("family", NULL, NULL,
                                                      NULL,
                                                      DEFAULT_PARAM_FLAGS);

    obj_properties[PROP_PREFER] = g_param_spec_object("prefer", NULL, NULL,
                                                     STRING_TYPE_HASHSET,
                                                     DEFAULT_PARAM_FLAGS);

    obj_properties[PROP_ACCEPT] = g_param_spec_object("accept", NULL, NULL,
                                                     STRING_TYPE_HASHSET,
                                                     DEFAULT_PARAM_FLAGS);

    obj_properties[PROP_DEFAULT] = g_param_spec_object("default", NULL, NULL,
                                                      STRING_TYPE_HASHSET,
                                                      DEFAULT_PARAM_FLAGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_alias_element_init (FontManagerAliasElement *self)
{
    g_return_if_fail(self != NULL);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    priv->prefer = string_hashset_new();
    priv->accept = string_hashset_new();
    priv->_default = string_hashset_new();
    return;
}

/**
 * font_manager_alias_element_get: (skip)
 * @priority:   "prefer", "accept" or "default"
 *
 * Returns: (transfer none): #StringHashset or %NULL on error
 */
StringHashset *
font_manager_alias_element_get (FontManagerAliasElement *self, const gchar *priority) {
    g_return_val_if_fail(self != NULL, NULL);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    if (g_strcmp0(priority, "prefer") == 0)
        return priv->prefer;
    else if (g_strcmp0(priority, "accept") == 0)
        return priv->accept;
    else if (g_strcmp0(priority, "default") == 0)
        return priv->_default;
    else
        g_warning("Requested invalid member : %s", priority);
    g_return_val_if_reached(NULL);
}

/**
 * font_manager_alias_element_new:
 * @family: (nullable): family name
 *
 * Returns: (transfer full): #FontManagerAliasElement
 * Use #g_object_unref() to free result.
 */
FontManagerAliasElement *
font_manager_alias_element_new (const gchar *family)
{
    GObject *_self = g_object_new(font_manager_alias_element_get_type(), NULL);
    FontManagerAliasElement *self = FONT_MANAGER_ALIAS_ELEMENT(_self);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    if (family != NULL)
        priv->family = g_strdup(family);
    return self;
}
