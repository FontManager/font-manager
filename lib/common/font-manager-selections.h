/* font-manager-selections.h
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

#ifndef __FONT_MANAGER_SELECTIONS_H__
#define __FONT_MANAGER_SELECTIONS_H__

#include <glib.h>
#include <glib-object.h>
#include <libxml/tree.h>

#include "font-manager-xml-writer.h"
#include "font-manager-string-hashset.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_SELECTIONS (font_manager_selections_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerSelections, font_manager_selections, FONT_MANAGER, SELECTIONS, FontManagerStringHashset)

struct _FontManagerSelectionsClass
{
    GObjectClass parent_class;

    void (* changed) (FontManagerSelections *self);

    gboolean (* load) (FontManagerSelections *self);
    gboolean (* save) (FontManagerSelections *self);
    void (* parse_selections) (FontManagerSelections *self, xmlNode *selections);
    void (* write_selections) (FontManagerSelections *self, FontManagerXmlWriter *writer);
    xmlNodePtr (* get_selections) (FontManagerSelections *self, xmlDocPtr doc);
};

FontManagerSelections * font_manager_selections_new (void);
gboolean font_manager_selections_load (FontManagerSelections *self);
gboolean font_manager_selections_save (FontManagerSelections *self);
gchar * font_manager_selections_get_filepath (FontManagerSelections *self);

G_END_DECLS

#endif /* __FONT_MANAGER_SELECTIONS_H__ */
