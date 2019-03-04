/* font-manager-properties.h
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

#ifndef __FONT_MANAGER_PROPERTIES_H_
#define __FONT_MANAGER_PROPERTIES_H_

#include <glib.h>
#include <glib-object.h>
#include <libxml/tree.h>

#include "font-manager-xml-writer.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_PROPERTIES (font_manager_properties_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerProperties, font_manager_properties, FONT_MANAGER, PROPERTIES, GObject)

struct _FontManagerPropertiesClass
{
    GObjectClass parent_class;

    gboolean (* load) (FontManagerProperties *self);
    gboolean (* save) (FontManagerProperties *self);

    void (* parse_test_node) (FontManagerProperties *self, xmlNode *test_node);
    void (* parse_edit_node) (FontManagerProperties *self, xmlNode *edit_node);
    void (* add_match_criteria) (FontManagerProperties *self, FontManagerXmlWriter *writer);
};

typedef enum
{
    FONT_MANAGER_PROPERTIES_TYPE_DEFAULT,
    FONT_MANAGER_PROPERTIES_TYPE_DISPLAY
}
FontManagerPropertiesType;

FontManagerProperties * font_manager_properties_new (void);
gboolean font_manager_properties_load (FontManagerProperties *self);
gboolean font_manager_properties_save (FontManagerProperties *self);
gboolean font_manager_properties_discard (FontManagerProperties *self);
gchar * font_manager_properties_get_filepath (FontManagerProperties *self);
void font_manager_properties_reset (FontManagerProperties *self);

G_END_DECLS

#endif /* __FONT_MANAGER_PROPERTIES_H_ */
