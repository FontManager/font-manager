/* json-proxy-object-properties.h
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

#ifndef __JSON_PROXY_OBJECT_PROPERTIES_H__
#define __JSON_PROXY_OBJECT_PROPERTIES_H__

#include <glib.h>
#include <glib-object.h>

#define SOURCE "source-object"

typedef struct
{
    const gchar *name;
    GType type;
}
JsonProxyObjectProperties;

static const JsonProxyObjectProperties FamilyProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST },
    { "family", G_TYPE_STRING },
    { "n-variations", G_TYPE_INT },
    { "description", G_TYPE_STRING },
    { SOURCE, G_TYPE_RESERVED_USER_FIRST },
    { "variations", G_TYPE_BOXED }
};

static const JsonProxyObjectProperties FontProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST },
    { "filepath", G_TYPE_STRING },
    { "findex", G_TYPE_INT },
    { "family", G_TYPE_STRING },
    { "style", G_TYPE_STRING },
    { "spacing", G_TYPE_INT },
    { "slant", G_TYPE_INT },
    { "weight", G_TYPE_INT },
    { "width", G_TYPE_INT },
    { "description", G_TYPE_STRING },
    { SOURCE, G_TYPE_RESERVED_USER_FIRST },
};

static const JsonProxyObjectProperties InfoProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST },
    { "filepath", G_TYPE_STRING },
    { "findex", G_TYPE_INT },
    { "family", G_TYPE_STRING },
    { "style", G_TYPE_STRING },
    { "owner", G_TYPE_INT },
    { "psname", G_TYPE_STRING },
    { "filetype", G_TYPE_STRING },
    { "n-glyphs", G_TYPE_INT },
    { "copyright", G_TYPE_STRING },
    { "version", G_TYPE_STRING },
    { "description", G_TYPE_STRING },
    { "license-data", G_TYPE_STRING },
    { "license-url", G_TYPE_STRING },
    { "vendor", G_TYPE_STRING },
    { "designer", G_TYPE_STRING },
    { "designer-url", G_TYPE_STRING },
    { "license-type", G_TYPE_STRING },
    { "fsType", G_TYPE_INT },
    { "filesize", G_TYPE_STRING },
    { "checksum", G_TYPE_STRING },
    { SOURCE, G_TYPE_RESERVED_USER_FIRST },
    { "panose", G_TYPE_BOXED }
};

#define JSON_OBJECT_PARAM_FLAGS (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS)
#define JSON_SOURCE_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

G_GNUC_UNUSED static void
generate_class_properties (GParamSpec *pspec[],
                           const JsonProxyObjectProperties *properties,
                           gint num_properties)
{
    gint i;
    for (i = 0; i < num_properties; i++) {
        const gchar *prop_name = properties[i].name;
        switch (properties[i].type) {
            case G_TYPE_INT:
                pspec[i] = g_param_spec_int(prop_name,
                                            NULL, NULL,
                                            G_MININT, G_MAXINT, G_MININT,
                                            JSON_OBJECT_PARAM_FLAGS);
                break;
            case G_TYPE_STRING:
                pspec[i] = g_param_spec_string(prop_name,
                                               NULL, NULL, NULL,
                                               JSON_OBJECT_PARAM_FLAGS);
                break;
            case G_TYPE_BOXED:
                pspec[i] = g_param_spec_boxed(prop_name, NULL, NULL,
                                              JSON_TYPE_ARRAY,
                                              JSON_OBJECT_PARAM_FLAGS);
                break;
            case G_TYPE_RESERVED_USER_FIRST:
                pspec[i] = g_param_spec_boxed(prop_name, NULL, NULL,
                                              JSON_TYPE_OBJECT,
                                              JSON_SOURCE_PARAM_FLAGS);
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

G_GNUC_UNUSED static void
get_json_source_property (JsonObject *source_object,
                          GObject *gobject,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
    if (source_object == NULL)
        return;

    GType val_type  = G_PARAM_SPEC_VALUE_TYPE(pspec);

    if (json_object_get_member(source_object, pspec->name) == NULL && val_type != JSON_TYPE_OBJECT) {
        g_critical("Source object does not have a member named %s", pspec->name);
        return;
    }

    if (val_type == G_TYPE_STRING) {
        g_value_set_string(value, json_object_get_string_member(source_object, pspec->name));
    } else if (val_type == G_TYPE_INT) {
        g_value_set_int(value, json_object_get_int_member(source_object, pspec->name));
    } else if (val_type == JSON_TYPE_ARRAY) {
        g_value_set_boxed(value, json_object_get_array_member(source_object, pspec->name));
    } else if (val_type == JSON_TYPE_OBJECT) {
        g_value_set_boxed(value, source_object);
    } else {
        G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }

    return;
}

#endif /* __JSON_PROXY_OBJECT_PROPERTIES_H__ */

