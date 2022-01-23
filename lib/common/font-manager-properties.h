/* font-manager-properties.h
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

#ifndef __FONT_MANAGER_PROPERTIES_H_
#define __FONT_MANAGER_PROPERTIES_H_

#include <locale.h>
#include <stdlib.h>
#include <gio/gio.h>
#include <glib.h>
#include <glib-object.h>
#include <fontconfig/fontconfig.h>
#include <libxml/tree.h>

#include "font-manager-json-proxy.h"
#include "font-manager-xml-writer.h"

G_BEGIN_DECLS

static const FontManagerJsonProxyProperties PROPERTIES [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST, NULL },
    { "hintstyle", G_TYPE_INT, "Fontconfig hintstyle" },
    { "antialias", G_TYPE_BOOLEAN, "Whether to use anti-aliasing or not" },
    { "hinting", G_TYPE_BOOLEAN, "Whether to use hinting or not" },
    { "autohint", G_TYPE_BOOLEAN, "Whether to use autohinting or not" },
    { "embeddedbitmap", G_TYPE_BOOLEAN, "Whether to use embedded bitmaps or not" },
    { "less", G_TYPE_DOUBLE, "Lower size limit" },
    { "more", G_TYPE_DOUBLE, "Upper size limit" },
    { "rgba", G_TYPE_INT, "Fontconfig RGBA" },
    { "lcdfilter", G_TYPE_INT, "Fontconfig LCD filter" },
    { "scale", G_TYPE_DOUBLE, "Scale factor" },
    { "dpi", G_TYPE_DOUBLE, "Screen DPI" },
    { "config-dir", G_TYPE_STRING, "Fontconfig configuration directory" },
    { "target-file", G_TYPE_STRING, "Name of fontconfig configuration file" },
    { "type", G_TYPE_INT, "FontManagerPropertiesType" }
};

#define FONT_MANAGER_TYPE_PROPERTIES (font_manager_properties_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerProperties, font_manager_properties, FONT_MANAGER, PROPERTIES, GObject)

/**
 * FontManagerPropertiesClass:
 * @load:                   load configuration from file
 * @save:                   save configuration to file
 * @parse_test_node:        parse a fontconfig test node
 * @parse_edit_node:        parse a fontconfig edit node
 * @add_match_criteria:     add additional test elements
 */
struct _FontManagerPropertiesClass
{
    GObjectClass parent_class;

    gboolean (* load) (FontManagerProperties *self);
    gboolean (* save) (FontManagerProperties *self);

    void (* parse_test_node) (FontManagerProperties *self, xmlNode *test_node);
    void (* parse_edit_node) (FontManagerProperties *self, xmlNode *edit_node);
    void (* add_match_criteria) (FontManagerProperties *self, FontManagerXmlWriter *writer);
};

/**
 * FontManagerPropertiesType:
 * @FONT_MANAGER_PROPERTIES_TYPE_DEFAULT:   fontconfig font properties
 * @FONT_MANAGER_PROPERTIES_TYPE_DISPLAY:   fontconfig display properties
 */
typedef enum
{
    FONT_MANAGER_PROPERTIES_TYPE_DEFAULT,
    FONT_MANAGER_PROPERTIES_TYPE_DISPLAY
}
FontManagerPropertiesType;

GType font_manager_properties_type_get_type (void);
#define FONT_MANAGER_TYPE_PROPERTIES_TYPE (font_manager_properties_type_get_type ())

FontManagerProperties * font_manager_properties_new (void);
gboolean font_manager_properties_load (FontManagerProperties *self);
gboolean font_manager_properties_save (FontManagerProperties *self);
gboolean font_manager_properties_discard (FontManagerProperties *self);
gchar * font_manager_properties_get_filepath (FontManagerProperties *self);
void font_manager_properties_reset (FontManagerProperties *self);

G_END_DECLS

#endif /* __FONT_MANAGER_PROPERTIES_H_ */
