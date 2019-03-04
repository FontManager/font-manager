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

G_DEFINE_INTERFACE (FontManagerJsonProxy, font_manager_json_proxy, G_TYPE_OBJECT)

static void
font_manager_json_proxy_default_init (FontManagerJsonProxyInterface *iface)
{
    g_object_interface_install_property(iface,
                                        g_param_spec_boxed("source-object",
                                                           NULL, NULL,
                                                           JSON_TYPE_OBJECT,
                                                           G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));
    return;
}

