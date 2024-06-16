/* font-manager-properties.h
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

#include <locale.h>
#include <stdlib.h>
#include <gio/gio.h>
#include <glib.h>
#include <glib-object.h>
#include <fontconfig/fontconfig.h>
#include <libxml/tree.h>

#include "font-manager-fontconfig.h"
#include "font-manager-utils.h"
#include "font-manager-xml-writer.h"

static const FontManagerObjectProperty PROPERTIES [] =
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
    { "type", G_TYPE_INT, "FontManagerFontPropertiesType" }
};

#define FONT_MANAGER_TYPE_FONT_PROPERTIES (font_manager_font_properties_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerFontProperties, font_manager_font_properties, FONT_MANAGER, FONT_PROPERTIES, GObject)

/**
 * FontManagerFontPropertiesClass:
 * @load:                   load configuration from file
 * @save:                   save configuration to file
 * @parse_test_node:        parse a fontconfig test node
 * @parse_edit_node:        parse a fontconfig edit node
 * @add_match_criteria:     add additional test elements
 */
struct _FontManagerFontPropertiesClass
{
    GObjectClass parent_class;

    gboolean (* load) (FontManagerFontProperties *self);
    gboolean (* save) (FontManagerFontProperties *self);

    void (* parse_test_node) (FontManagerFontProperties *self, xmlNode *test_node);
    void (* parse_edit_node) (FontManagerFontProperties *self, xmlNode *edit_node);
    void (* add_match_criteria) (FontManagerFontProperties *self, FontManagerXmlWriter *writer);
};

/**
 * FontManagerFontPropertiesType:
 * @FONT_MANAGER_FONT_PROPERTIES_TYPE_DEFAULT:   Fontconfig font properties
 * @FONT_MANAGER_FONT_PROPERTIES_TYPE_DISPLAY:   Fontconfig display properties
 */
typedef enum
{
    FONT_MANAGER_FONT_PROPERTIES_TYPE_DEFAULT,
    FONT_MANAGER_FONT_PROPERTIES_TYPE_DISPLAY
}
FontManagerFontPropertiesType;

GType font_manager_font_properties_type_get_type (void);
#define FONT_MANAGER_TYPE_PROPERTIES_TYPE (font_manager_font_properties_type_get_type ())

FontManagerFontProperties * font_manager_font_properties_new (void);
gboolean font_manager_font_properties_load (FontManagerFontProperties *self);
gboolean font_manager_font_properties_save (FontManagerFontProperties *self);
gboolean font_manager_font_properties_discard (FontManagerFontProperties *self);
gchar * font_manager_font_properties_get_filepath (FontManagerFontProperties *self);
void font_manager_font_properties_reset (FontManagerFontProperties *self);

