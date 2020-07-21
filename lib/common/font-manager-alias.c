/* font-manager-alias.c
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

/**
 * SECTION: font-manager-alias
 * @short_description: Font substitution elements
 * @title: Alias Elements
 * @include: font-manager-alias.h
 *
 * #FontManagerAlias represents an &lt;alias&gt; element in a fontconfig
 * configuration file.
 *
 * Alias elements provide a shorthand notation for
 * the set of common match operations needed to substitute one font
 * family for another.
 *
 * Fonts matching @family are edited to prepend the list of &lt;@prefer&gt;ed
 * families before the matching @family, append the &lt;@accept&gt;able
 * families after the matching @family and append the &lt;@default&gt;
 * families to the end of the family list.
 */

struct _FontManagerAliasElement
{
    GObjectClass parent_class;
};

typedef struct
{
    gchar *family;
    FontManagerStringHashset *prefer;
    FontManagerStringHashset *accept;
    FontManagerStringHashset *_default;
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
font_manager_alias_element_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerAliasElement *self = FONT_MANAGER_ALIAS_ELEMENT(gobject);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    g_clear_pointer(&priv->family, g_free);
    g_clear_object(&priv->prefer);
    g_clear_object(&priv->accept);
    g_clear_object(&priv->_default);
    G_OBJECT_CLASS(font_manager_alias_element_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_alias_element_get_property (GObject *gobject,
                                        guint property_id,
                                        GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerAliasElement *self = FONT_MANAGER_ALIAS_ELEMENT(gobject);
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
    g_return_if_fail(gobject != NULL);
    FontManagerAliasElement *self = FONT_MANAGER_ALIAS_ELEMENT(gobject);
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
    object_class->dispose = font_manager_alias_element_dispose;
    object_class->get_property = font_manager_alias_element_get_property;
    object_class->set_property = font_manager_alias_element_set_property;

    /**
     * FontManagerAliasElement:family:
     *
     * Family targeted for substitution.
     */
    obj_properties[PROP_FAMILY] = g_param_spec_string("family",
                                                      NULL,
                                                      "Target font family",
                                                      NULL,
                                                      DEFAULT_PARAM_FLAGS);
    /**
     * FontManagerAliasElement:prefer:
     *
     * Set of font families which should be preferred over @family.
     */
    obj_properties[PROP_PREFER] = g_param_spec_object("prefer",
                                                     NULL,
                                                     "List of preferred font families",
                                                     FONT_MANAGER_TYPE_STRING_HASHSET,
                                                     DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerAliasElement:accept:
     *
     * Set of font families which are acceptable substitutes for @family.
     */
    obj_properties[PROP_ACCEPT] = g_param_spec_object("accept",
                                                     NULL,
                                                     "List of acceptable font families",
                                                     FONT_MANAGER_TYPE_STRING_HASHSET,
                                                     DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerAliasElement:default:
     *
     * Set of font families to be used as a fallback.
     */
    obj_properties[PROP_DEFAULT] = g_param_spec_object("default",
                                                      NULL,
                                                      "List of fallback fonts",
                                                      FONT_MANAGER_TYPE_STRING_HASHSET,
                                                      DEFAULT_PARAM_FLAGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_alias_element_init (FontManagerAliasElement *self)
{
    g_return_if_fail(self != NULL);
    FontManagerAliasElementPrivate *priv = font_manager_alias_element_get_instance_private(self);
    priv->prefer = font_manager_string_hashset_new();
    priv->accept = font_manager_string_hashset_new();
    priv->_default = font_manager_string_hashset_new();
    return;
}

/**
 * font_manager_alias_element_get: (skip)
 * @self:       #FontManagerAliasElement
 * @priority:   "prefer", "accept" or "default"
 *
 * Returns: (transfer none) (nullable): A #FontManagerStringHashset or %NULL on error
 */
FontManagerStringHashset *
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
 * Returns: (transfer full): A newly created #FontManagerAliasElement.
 * Free the returned object using #g_object_unref().
 */
FontManagerAliasElement *
font_manager_alias_element_new (const gchar *family)
{
    return g_object_new(FONT_MANAGER_TYPE_ALIAS_ELEMENT, "family", family, NULL);
}
