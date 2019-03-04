/* font-manager-selections.c
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

#include <gio/gio.h>

#include "font-manager-selections.h"

typedef struct
{
    gchar *config_dir;
    gchar *target_file;
    gchar *target_element;
    GFileMonitor *monitor;
}
FontManagerSelectionsPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerSelections, font_manager_selections, STRING_TYPE_HASHSET)

enum
{
    PROP_RESERVED,
    PROP_CONFIG_DIR,
    PROP_TARGET_FILE,
    PROP_TARGET_ELEMENT,
    N_PROPERTIES
};

enum
{
    CHANGED,
    N_SIGNALS
};

static guint signals[N_SIGNALS];
static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

#define DEFAULT_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

static void
font_manager_selections_finalize (GObject *gobject)
{
    FontManagerSelections *self = FONT_MANAGER_SELECTIONS(gobject);
    g_return_if_fail(self != NULL);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);
    g_free(priv->config_dir);
    g_free(priv->target_file);
    g_free(priv->target_element);
    if (priv->monitor != NULL)
        g_clear_object(&priv->monitor);
    G_OBJECT_CLASS(font_manager_selections_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_selections_get_property (GObject *gobject,
                                     guint property_id,
                                     GValue *value,
                                     GParamSpec *pspec)
{
    FontManagerSelections *self = FONT_MANAGER_SELECTIONS(gobject);
    g_return_if_fail(self != NULL);
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
    FontManagerSelections *self = FONT_MANAGER_SELECTIONS(gobject);
    g_return_if_fail(self != NULL);
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
        if (content == NULL)
            continue;
        content = (xmlChar *) g_strstrip((gchar *) content);
        if (g_strcmp0((const char *) content, "") != 0)
            string_hashset_add(STRING_HASHSET(self), (const gchar *) content);
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
    GList *selections = string_hashset_list(STRING_HASHSET(self));
    font_manager_xml_writer_add_selections(writer, priv->target_element, selections);
    g_list_free(selections);
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
    object_class->finalize = font_manager_selections_finalize;

    klass->load = font_manager_selections_load;
    klass->save = font_manager_selections_save;
    klass->parse_selections = font_manager_selections_parse_selections;
    klass->write_selections = font_manager_selections_write_selections;
    klass->get_selections = font_manager_selections_get_selections;

    /**
     * FontManagerSelections:changed:
     *
     * Emitted whenever the underlying configuration file has changed on disk
     */
    signals[CHANGED] = g_signal_new(g_intern_static_string("changed"),
                                    G_OBJECT_CLASS_TYPE(object_class),
                                    G_SIGNAL_RUN_LAST,
                                    G_STRUCT_OFFSET(FontManagerSelectionsClass, changed),
                                    NULL, NULL, NULL,
                                    G_TYPE_NONE, 0);

    /**
     * FontManagerSelections:config-dir:
     *
     * Should be set to one of the directories monitored by Fontconfig
     * for configuration files and writeable by the user.
     */
    obj_properties[PROP_CONFIG_DIR] = g_param_spec_string("config-dir",
                                                          NULL, NULL, NULL,
                                                          DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSelections:target-file:
     *
     * Should be set to a filename in the form [7][0-9]*.conf
     */
    obj_properties[PROP_TARGET_FILE] = g_param_spec_string("target-file",
                                                           NULL, NULL, NULL,
                                                           DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSelections:target-element:
     *
     * Valid values: <acceptfont> or <rejectfont>
     */
    obj_properties[PROP_TARGET_ELEMENT] = g_param_spec_string("target-element",
                                                              NULL, NULL, NULL,
                                                              DEFAULT_PARAM_FLAGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_selections_init (G_GNUC_UNUSED FontManagerSelections *self)
{
    return;
}

static void
font_manager_selections_emit_changed (G_GNUC_UNUSED GFileMonitor *monitor,
                                      G_GNUC_UNUSED GFile *file,
                                      G_GNUC_UNUSED GFile *other_file,
                                      G_GNUC_UNUSED GFileMonitorEvent  event_type,
                                      G_GNUC_UNUSED gpointer user_data)
{
    g_signal_emit(FONT_MANAGER_SELECTIONS(user_data), signals[CHANGED], 0);
    return;
}

/**
 * font_manager_selections_load:
 * @self:   #FontManagerSelections
 *
 * Load @target_file from @config_dir
 *
 * Returns: #TRUE if configuration was loaded successfully
 */
gboolean
font_manager_selections_load (FontManagerSelections *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerSelectionsPrivate *priv = font_manager_selections_get_instance_private(self);

    string_hashset_clear(STRING_HASHSET(self));
    if (priv->monitor != NULL)
        g_clear_object(&priv->monitor);

    gchar *filepath = font_manager_selections_get_filepath(self);
    if (filepath == NULL)
        return FALSE;

    GFile *file = g_file_new_for_path(filepath);

    priv->monitor = g_file_monitor(file, G_FILE_MONITOR_NONE, NULL, NULL);
    if (priv->monitor != NULL)
        g_signal_connect(priv->monitor, "changed", G_CALLBACK(font_manager_selections_emit_changed), self);
    else
        g_critical(G_STRLOC ": Failed to create file monitor for %s", filepath);

    if (!g_file_query_exists(file, NULL)) {
        g_object_unref(file);
        g_free(filepath);
        return FALSE;
    }

    xmlInitParser();
    xmlDoc *doc = xmlReadFile(filepath, NULL, 0);

    if (doc == NULL) {
        /* Empty file */
        xmlCleanupParser();
        g_object_unref(file);
        g_free(filepath);
        return FALSE;
    }

    xmlNode *selections = FONT_MANAGER_SELECTIONS_GET_CLASS(self)->get_selections(self, doc);
    if (selections != NULL)
        FONT_MANAGER_SELECTIONS_GET_CLASS(self)->parse_selections(self, selections);

    xmlFreeDoc(doc);
    xmlCleanupParser();
    g_object_unref(file);
    g_free(filepath);
    return TRUE;
}

/**
 * font_manager_selections_save:
 * @self:   #FontManagerSelections
 *
 * Saves current selections to @target_file in @config_dir
 *
 * Returns: #TRUE if configuration was saved successfully
 */
gboolean
font_manager_selections_save (FontManagerSelections *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    gchar * filepath = font_manager_selections_get_filepath(self);
    g_return_val_if_fail(filepath != NULL, FALSE);
    FontManagerXmlWriter *writer = font_manager_xml_writer_new();
    font_manager_xml_writer_open(writer, filepath);
    if (string_hashset_size(STRING_HASHSET(self)))
        FONT_MANAGER_SELECTIONS_GET_CLASS(self)->write_selections(self, writer);
    gboolean result = font_manager_xml_writer_close(writer);
    g_object_unref(writer);
    g_free(filepath);
    return result;
}

/**
 * font_manager_selections_get_filepath:
 * @self:   #FontManagerSelections
 *
 * Returns: (transfer full) (nullable): a newly allocated string containing the full
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
 * Returns: (transfer full): #FontManagerSelections
 * Use #g_object_unref() to free result.
 */
FontManagerSelections *
font_manager_selections_new (void)
{
    return FONT_MANAGER_SELECTIONS(g_object_new(font_manager_selections_get_type(), NULL));
}

