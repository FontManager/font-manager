/* font-manager-json-proxy.h
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
#include <glib-object.h>
#include <json-glib/json-glib.h>

#include "font-manager-utils.h"

#define FONT_MANAGER_JSON_PROXY_SOURCE "source-object"

/**
 * FontManagerJsonProxyProperty
 * @name:   Property name
 * @type:   #GType of property
 * @desc:   Description of property
 *
 * This struct provides the information required to map a member of a
 * #JsonObject to a gobject property in a #FontManagerJsonProxy subclass.
 */
typedef struct _ObjectProperty FontManagerJsonProxyProperty;

#define FONT_MANAGER_TYPE_JSON_PROXY (font_manager_json_proxy_get_type ())
G_DECLARE_DERIVABLE_TYPE (FontManagerJsonProxy, font_manager_json_proxy, FONT_MANAGER, JSON_PROXY, GObject)

/**
 * FontManagerJsonProxyClass:
 * @n_properties:   # of members in the #JsonObject backing this class
 * @properties:     an array of #FontManagerJsonProxyProperty describing the members
 */
struct _FontManagerJsonProxyClass
{
    GObjectClass parent_class;

    gint n_properties;
    const FontManagerJsonProxyProperty *properties;
};

FontManagerJsonProxy * font_manager_json_proxy_new (void);
gboolean font_manager_json_proxy_is_valid (FontManagerJsonProxy *self);
void font_manager_json_proxy_install_properties (FontManagerJsonProxyClass *klass);

