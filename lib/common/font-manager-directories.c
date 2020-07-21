/* font-manager-directories.c
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

#include "font-manager-directories.h"

/**
 * SECTION: font-manager-directories
 * @short_description: Fontconfig font selection configuration
 * @title: Font Directories
 * @include: font-manager-directories.h
 *
 * Set of directories which will be scanned for font files to include in the set of available fonts.
 */

G_DEFINE_TYPE(FontManagerDirectories, font_manager_directories, FONT_MANAGER_TYPE_SELECTIONS)

xmlNodePtr
font_manager_directories_get_selections (FontManagerSelections *self, xmlDocPtr doc)
{
    xmlNodePtr root = xmlDocGetRootElement(doc);
    return (root != NULL) ? root->children : NULL;
}

static void
font_manager_directories_write_selections (FontManagerSelections *self,
                                           FontManagerXmlWriter *writer)
{
    g_return_if_fail(FONT_MANAGER_IS_SELECTIONS(self));
    g_return_if_fail(FONT_MANAGER_IS_XML_WRITER(writer));
    GList *directories = font_manager_string_hashset_list(FONT_MANAGER_STRING_HASHSET(self));
    g_autofree gchar *element = NULL;
    g_object_get(G_OBJECT(self), "target-element", &element, NULL);
    font_manager_xml_writer_add_elements(writer, element, directories);
    g_list_free_full(directories, g_free);
    return;
}

static void
font_manager_directories_class_init (FontManagerDirectoriesClass *klass)
{
    FontManagerSelectionsClass *parent_class = (FontManagerSelectionsClass *) klass;
    parent_class->get_selections = font_manager_directories_get_selections;
    parent_class->write_selections = font_manager_directories_write_selections;
    return;
}

static void
font_manager_directories_init (FontManagerDirectories *self)
{
    g_return_if_fail(self != NULL);
    g_autofree gchar *config_dir = font_manager_get_user_fontconfig_directory();
    g_object_set(G_OBJECT(self),
                 "config-dir", config_dir,
                 "target-element", "dir",
                 "target-file", "09-Directories.conf",
                 NULL);
    return;
}

/**
 * font_manager_directories_new:
 *
 * Returns: (transfer full): A newly created #FontManagerDirectories.
 * Free the returned object using #g_object_unref().
 */
FontManagerDirectories *
font_manager_directories_new (void)
{

    return g_object_new(FONT_MANAGER_TYPE_DIRECTORIES, NULL);
}

