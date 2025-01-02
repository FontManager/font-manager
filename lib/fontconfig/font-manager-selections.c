/* font-manager-selections.c
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

#include "font-manager-selections.h"

/**
 * SECTION: font-manager-selections
 * @short_description: Fontconfig font selection configuration
 * @title: Font Selection
 * @include: font-manager-selections.h
 *
 * Base class for generating fontconfig configuration files which modify
 * font selections.
 */

typedef struct
{
    gchar *config_dir;
    gchar *target_file;
    gchar *target_element;
}
FontManagerSelectionsPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerSelections, font_manager_selections, FONT_MANAGER_TYPE_STRING_SET)

enum
{
    PROP_RESERVED,
    PROP_CONFIG_DIR,
    PROP_TARGET_FILE,
    PROP_TARGET_ELEMENT,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

#define DEFAULT_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

static void
font_manager_selections_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerSelections *self = FONT_MANAGER_SELECTIONS(gobject);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);
    g_clear_pointer(&priv->config_dir, g_free);
    g_clear_pointer(&priv->target_file, g_free);
    g_clear_pointer(&priv->target_element, g_free);
    G_OBJECT_CLASS(font_manager_selections_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_selections_get_property (GObject *gobject,
                                     guint property_id,
                                     GValue *value,
                                     GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerSelections *self = FONT_MANAGER_SELECTIONS(gobject);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);

    switch (property_id) {
        case PROP_CONFIG_DIR:
            g_value_set_string(value, priv->config_dir);
            break;
        case PROP_TARGET_FILE:
            g_value_set_string(value, priv->target_file);
            break;
        case PROP_TARGET_ELEMENT:
            g_value_set_string(value, priv->target_element);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }

    return;
}

static void
font_manager_selections_set_property (GObject *gobject,
                                     guint property_id,
                                     const GValue *value,
                                     GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerSelections *self = FONT_MANAGER_SELECTIONS(gobject);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);

    switch (property_id) {
        case PROP_CONFIG_DIR:
            g_free(priv->config_dir);
            priv->config_dir = g_value_dup_string(value);
            break;
        case PROP_TARGET_FILE:
            g_free(priv->target_file);
            priv->target_file = g_value_dup_string(value);
            break;
        case PROP_TARGET_ELEMENT:
            g_free(priv->target_element);
            priv->target_element = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }

    return;
}

static void
font_manager_selections_parse_selections (FontManagerSelections *self,
                                         xmlNode *selections)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(selections != NULL);
    for (xmlNode *iter = selections; iter != NULL; iter = iter->next) {
        if (iter->type != XML_ELEMENT_NODE)
            continue;
        xmlChar *content = xmlNodeGetContent(iter);
        if (!content)
            continue;
        content = (xmlChar *) g_strstrip((gchar *) content);
        if (content && g_strcmp0((const char *) content, "") != 0)
            font_manager_string_set_add(FONT_MANAGER_STRING_SET(self), (const gchar *) content);
        xmlFree(content);
    }
    return;
}

static void
font_manager_selections_write_selections (FontManagerSelections *self,
                                         FontManagerXmlWriter *writer)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(writer != NULL);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);
    GList *selections = font_manager_string_set_list(FONT_MANAGER_STRING_SET(self));
    font_manager_xml_writer_add_selections(writer, priv->target_element, selections);
    g_list_free_full(selections, g_free);
    return;
}

static xmlNodePtr
font_manager_selections_get_selections (FontManagerSelections *self, xmlDocPtr doc)
{
    g_return_val_if_fail(self != NULL, NULL);
    g_return_val_if_fail(doc != NULL, NULL);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);
    xmlNode *root = xmlDocGetRootElement(doc);
    if (root == NULL)
        return NULL;
    for (xmlNode *iter = root->children; iter != NULL; iter = iter->next) {
        if (iter->type != XML_ELEMENT_NODE)
            continue;
        if (g_strcmp0((const char *) iter->name, "selectfont") == 0) {
            for (xmlNode *result = iter->children; result != NULL; result = result->next) {
                if (g_strcmp0((const char *) result->name, (const char *) priv->target_element) == 0)
                    return result->children;
            }
        }
    }
    return NULL;
}

static void
font_manager_selections_class_init (FontManagerSelectionsClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->get_property = font_manager_selections_get_property;
    object_class->set_property = font_manager_selections_set_property;
    object_class->dispose = font_manager_selections_dispose;

    klass->load = font_manager_selections_load;
    klass->save = font_manager_selections_save;
    klass->parse_selections = font_manager_selections_parse_selections;
    klass->write_selections = font_manager_selections_write_selections;
    klass->get_selections = font_manager_selections_get_selections;

    /**
     * FontManagerSelections:config-dir:
     *
     * Should be set to one of the directories monitored by Fontconfig
     * for configuration files and writeable by the user.
     */
    obj_properties[PROP_CONFIG_DIR] = g_param_spec_string("config-dir",
                                                          NULL,
                                                          "Fontconfig configuration directory",
                                                          NULL,
                                                          DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSelections:target-file:
     *
     * Should be set to a filename in the form \[7\]\[0-9\]-*.conf
     */
    obj_properties[PROP_TARGET_FILE] = g_param_spec_string("target-file",
                                                           NULL,
                                                           "Name of fontconfig configuration file",
                                                           NULL,
                                                           DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSelections:target-element:
     *
     * Valid values: acceptfont or rejectfont
     */
    obj_properties[PROP_TARGET_ELEMENT] = g_param_spec_string("target-element",
                                                              NULL,
                                                              "A valid selectfont element",
                                                              NULL,
                                                              DEFAULT_PARAM_FLAGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_selections_init (FontManagerSelections *self)
{
    g_return_if_fail(self != NULL);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);
    priv->config_dir = NULL;
    priv->target_element = NULL;
    priv->target_file = NULL;
    return;
}

/**
 * font_manager_selections_load:
 * @self:   #FontManagerSelections
 *
 * Load @target_file from @config_dir
 *
 * Returns: %TRUE if configuration was loaded successfully.
 */
gboolean
font_manager_selections_load (FontManagerSelections *self)
{
    g_return_val_if_fail(self != NULL, FALSE);

    font_manager_string_set_clear(FONT_MANAGER_STRING_SET(self));

    g_autofree gchar *filepath = font_manager_selections_get_filepath(self);
    if (filepath == NULL || !font_manager_exists(filepath))
        return FALSE;

    xmlDoc *doc = xmlReadFile(filepath, NULL, 0);

    /* Empty file */
    if (doc == NULL)
        return FALSE;

    xmlNode *selections = FONT_MANAGER_SELECTIONS_GET_CLASS(self)->get_selections(self, doc);
    if (selections != NULL)
        FONT_MANAGER_SELECTIONS_GET_CLASS(self)->parse_selections(self, selections);

    xmlFreeDoc(doc);

    return TRUE;
}

/**
 * font_manager_selections_save:
 * @self:   #FontManagerSelections
 *
 * Saves current selections to @target_file in @config_dir
 *
 * Returns: %TRUE if configuration was saved successfully.
 */
gboolean
font_manager_selections_save (FontManagerSelections *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_autofree gchar * filepath = font_manager_selections_get_filepath(self);
    g_return_val_if_fail(filepath != NULL, FALSE);
    g_autoptr(FontManagerXmlWriter) writer = font_manager_xml_writer_new();
    font_manager_xml_writer_open(writer, filepath);
    if (font_manager_string_set_size(FONT_MANAGER_STRING_SET(self)))
        FONT_MANAGER_SELECTIONS_GET_CLASS(self)->write_selections(self, writer);
    gboolean result = font_manager_xml_writer_close(writer);
    return result;
}

/**
 * font_manager_selections_get_filepath:
 * @self:   #FontManagerSelections
 *
 * Returns: (transfer full) (nullable): A newly allocated string containing the full
 * filepath to current configuration file or %NULL. Free the result using #g_free().
 */
gchar *
font_manager_selections_get_filepath (FontManagerSelections *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);
    if (priv->config_dir == NULL || priv->target_file == NULL)
        return NULL;
    return g_build_filename(priv->config_dir, priv->target_file, NULL);
}

/**
 * font_manager_selections_new:
 *
 * Returns: (transfer full): A newly created #FontManagerSelections.
 * Free the returned object using #g_object_unref().
 */
FontManagerSelections *
font_manager_selections_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_SELECTIONS, NULL);
}

