/* font-manager-json-proxy.h
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

#ifndef __FONT_MANAGER_JSON_PROXY_H__
#define __FONT_MANAGER_JSON_PROXY_H__

#include <glib.h>
#include <glib-object.h>
#include <json-glib/json-glib.h>

G_BEGIN_DECLS

#define FONT_MANAGER_PROXY_OBJECT_SOURCE "source-object"

typedef struct
{
    const gchar *name;
    const GType type;
}
FontManagerProxyObjectProperties;

#define FONT_MANAGER_TYPE_JSON_PROXY (font_manager_json_proxy_get_type ())
G_DECLARE_DERIVABLE_TYPE (FontManagerJsonProxy, font_manager_json_proxy, FONT_MANAGER, JSON_PROXY, GObject)

struct _FontManagerJsonProxyClass
{
    GObjectClass parent_class;

    void (* generate_properties) (GParamSpec *pspec[],
                                  const FontManagerProxyObjectProperties *properties,
                                  gint num_properties);
};

FontManagerJsonProxy * font_manager_json_proxy_new (void);
gboolean font_manager_json_proxy_is_valid (FontManagerJsonProxy *self);

G_END_DECLS

#endif /* __FONT_MANAGER_JSON_PROXY_H__ */
