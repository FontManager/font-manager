/* font-manager-xml-writer.h
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

#include <libxml/xmlwriter.h>
#include <glib.h>
#include <glib-object.h>

#include "font-manager-utils.h"

#define FONT_MANAGER_TYPE_XML_WRITER (font_manager_xml_writer_get_type())
G_DECLARE_FINAL_TYPE(FontManagerXmlWriter, font_manager_xml_writer, FONT_MANAGER, XML_WRITER, GObject)

FontManagerXmlWriter * font_manager_xml_writer_new (void);

gboolean font_manager_xml_writer_open (FontManagerXmlWriter *self,
                                       const gchar *filepath);

gboolean font_manager_xml_writer_close (FontManagerXmlWriter *self);
void font_manager_xml_writer_discard (FontManagerXmlWriter *self);

gint font_manager_xml_writer_start_element (FontManagerXmlWriter *self,
                                            const gchar *name);

gint font_manager_xml_writer_end_element (FontManagerXmlWriter *self);

gint font_manager_xml_writer_write_element (FontManagerXmlWriter *self,
                                            const gchar *name,
                                            const gchar *content);

gint font_manager_xml_writer_write_attribute (FontManagerXmlWriter *self,
                                              const gchar *name,
                                              const gchar *content);

void font_manager_xml_writer_add_assignment (FontManagerXmlWriter *self,
                                             const gchar *a_name,
                                             const gchar *a_type,
                                             const gchar *a_val);

void font_manager_xml_writer_add_elements (FontManagerXmlWriter *self,
                                           const gchar *e_type,
                                           GList *elements);

void font_manager_xml_writer_add_patelt (FontManagerXmlWriter *self,
                                         const gchar *p_name,
                                         const gchar *p_type,
                                         const gchar *p_val);

void font_manager_xml_writer_add_selections (FontManagerXmlWriter *self,
                                             const gchar *selection_type,
                                             GList *selections);

void font_manager_xml_writer_add_test_element (FontManagerXmlWriter *self,
                                               const gchar *t_name,
                                               const gchar *t_test,
                                               const gchar *t_type,
                                               const gchar *t_val);

