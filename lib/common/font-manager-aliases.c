/* font-manager-aliases.c
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
#include <libxml/tree.h>
#include <libxml/xpath.h>

#include "font-manager-alias.h"
#include "font-manager-aliases.h"
#include "font-manager-xml-writer.h"
#include "font-manager-string-hashset.h"

struct _FontManagerAliases
{
    GObjectClass parent_class;
};

typedef struct
{
    gchar *config_dir;
    gchar *target_file;

    GHashTable *hash_table;
}
FontManagerAliasesPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerAliases, font_manager_aliases, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_CONFIG_DIR,
    PROP_TARGET_FILE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_aliases_finalize (GObject *gobject)
{
    FontManagerAliases *self = FONT_MANAGER_ALIASES(gobject);
    g_return_if_fail(self != NULL);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    g_free(priv->config_dir);
    g_free(priv->target_file);
    if (priv->hash_table)
        g_hash_table_destroy(priv->hash_table);
    G_OBJECT_CLASS(font_manager_aliases_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_aliases_get_property (GObject *gobject,
                                  guint property_id,
                                  GValue *value,
                                  GParamSpec *pspec)
{
    FontManagerAliases *self = FONT_MANAGER_ALIASES(gobject);
    g_return_if_fail(self != NULL);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    switch (property_id) {
        case PROP_CONFIG_DIR:
            g_value_set_string(value, priv->config_dir);
            break;
        case PROP_TARGET_FILE:
            g_value_set_string(value, priv->target_file);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_aliases_set_property (GObject *gobject,
                                  guint property_id,
                                  const GValue *value,
                                  GParamSpec *pspec)
{
    FontManagerAliases *self = FONT_MANAGER_ALIASES(gobject);
    g_return_if_fail(self != NULL);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    switch (property_id) {
        case PROP_CONFIG_DIR:
            g_free(priv->config_dir);
            priv->config_dir = g_value_dup_string(value);
            break;
        case PROP_TARGET_FILE:
            g_free(priv->target_file);
            priv->target_file = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_aliases_class_init (FontManagerAliasesClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = font_manager_aliases_finalize;
    object_class->get_property = font_manager_aliases_get_property;
    object_class->set_property = font_manager_aliases_set_property;

    /**
     * FontManagerAliases:config-dir:
     *
     * Should be set to one of the directories monitored by Fontconfig
     * for configuration files and writeable by the user.
     */
    obj_properties[PROP_CONFIG_DIR] = g_param_spec_string("config-dir", NULL,
                                                          NULL, NULL,
                                                          G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerAliases:target-file:
     *
     * Should be set to a filename in the form [3][0-9]*.conf
     */
    obj_properties[PROP_TARGET_FILE] = g_param_spec_string("target-file", NULL,
                                                            NULL, NULL,
                                                            G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);

    return;
}

static void
font_manager_aliases_init (FontManagerAliases *self)
{
    g_return_if_fail(self != NULL);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    priv->hash_table = g_hash_table_new_full(g_str_hash,
                                             g_str_equal,
                                             (GDestroyNotify) g_free,
                                             (GDestroyNotify) g_object_unref);
    return;
}

static void
_xml_writer_add_alias_element(FontManagerXmlWriter *writer,
                              FontManagerStringHashset *hashset,
                              const gchar *type)
{
    GList *families = font_manager_string_hashset_list(hashset);
    font_manager_xml_writer_start_element(writer, type);
    font_manager_xml_writer_add_elements(writer, "family", families);
    font_manager_xml_writer_end_element(writer);
    g_list_free(families);
    return;
}

static void
xml_writer_add_alias_element (FontManagerXmlWriter *writer,
                              FontManagerAliasElement *alias)
{
    gchar *family;
    FontManagerStringHashset *p;
    FontManagerStringHashset *a;
    FontManagerStringHashset *d;
    g_object_get(alias, "family", &family, "prefer", &p, "accept", &a, "default", &d, NULL);
    g_return_if_fail(family != NULL);
    font_manager_xml_writer_start_element(writer, "alias");
    font_manager_xml_writer_write_attribute(writer, "binding", "strong");
    font_manager_xml_writer_write_element(writer, "family", family);
    g_free(family);
    if (p) {
        _xml_writer_add_alias_element(writer, p, "prefer");
        g_object_unref(p);
    }
    if (a) {
        _xml_writer_add_alias_element(writer, a, "accept");
        g_object_unref(a);
    }
    if (d) {
        _xml_writer_add_alias_element(writer, d, "default");
        g_object_unref(d);
    }
    font_manager_xml_writer_end_element(writer);
    return;
}

static void
parse_alias_node (FontManagerAliases *self, xmlNodePtr alias_node)
{
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    FontManagerAliasElement *ae = font_manager_alias_element_new(NULL);
    xmlChar *family = NULL;
    for (xmlNodePtr iter = alias_node->children; iter != NULL; iter = iter->next) {
        if (iter->type != XML_ELEMENT_NODE)
            continue;
        if (g_strcmp0((const char *) iter->name, "family") == 0) {
            family = xmlNodeGetContent(iter);
            g_object_set(ae, "family", family, NULL);
        } else {
            GObjectClass *object_class = G_OBJECT_GET_CLASS(ae);
            GParamSpec *pspec = g_object_class_find_property(object_class, (const gchar *) iter->name);
            if (pspec == NULL)
                continue;
            FontManagerStringHashset *hashset = font_manager_string_hashset_new();
            for (xmlNodePtr _iter = iter->children; _iter != NULL; _iter = _iter->next) {
                if (g_strcmp0((const char *) _iter->name, "family") == 0) {
                    xmlChar *content = xmlNodeGetContent(_iter);
                    font_manager_string_hashset_add(hashset, (const gchar *) content);
                    xmlFree(content);
                }
            }
            g_object_set(ae, g_param_spec_get_name(pspec), hashset, NULL);
            g_object_unref(hashset);
        }
    }
    gchar *tmp = g_strdup((const gchar *) family);
    g_hash_table_insert(priv->hash_table, tmp, ae);
    if (family)
        xmlFree(family);
    return;
}

/**
 * font_manager_aliases_get:
 * @self:   #FontManagerAliases
 *
 * Returns: (transfer none): #FontManagerAliasElement
 */
FontManagerAliasElement *
font_manager_aliases_get (FontManagerAliases *self, const gchar *family)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    return g_hash_table_lookup(priv->hash_table, family);
}

/**
 * font_manager_aliases_contains:
 * @self:   #FontManagerAliases
 * @family: family to check for
 *
 * Returns: %TRUE if @family exists
 */
gboolean
font_manager_aliases_contains (FontManagerAliases *self, const gchar *family)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    return (g_hash_table_lookup(priv->hash_table, family) != NULL);
}

/**
 * font_manager_aliases_add:
 * @self:   #FontManagerAliases
 * @family: family name
 *
 * Returns:    %TRUE if alias element for @family was added successfully
 */
gboolean
font_manager_aliases_add (FontManagerAliases *self, const gchar *family)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    FontManagerAliasElement *element = font_manager_alias_element_new(family);
    gchar *tmp = g_strdup(family);
    g_hash_table_insert(priv->hash_table, tmp, element);
    return g_hash_table_contains(priv->hash_table, family);
}

/**
 * font_manager_aliases_add_element:
 * @self:   #FontManagerAliases
 * @element: (transfer full): #FontManagerAliasElement
 *
 * Returns:    %TRUE if alias element was added successfully
 */
gboolean
font_manager_aliases_add_element (FontManagerAliases *self, FontManagerAliasElement *element)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    gchar *tmp;
    g_object_get(element, "family", &tmp, NULL);
    g_hash_table_insert(priv->hash_table, tmp, element);
    return g_hash_table_contains(priv->hash_table, tmp);
}

/**
 * font_manager_aliases_remove:
 * @self:   #FontManagerAliases
 * @family: family name
 *
 * Returns:    %TRUE if alias element for @family was removed successfully
 */
gboolean
font_manager_aliases_remove (FontManagerAliases *self, const gchar *family)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    return g_hash_table_remove(priv->hash_table, family);
}

/**
 * font_manager_aliases_load:
 * @self:   #FontManagerAliases
 *
 * Returns:    %TRUE if current configuration was successfully loaded
 */
gboolean
font_manager_aliases_load (FontManagerAliases *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    g_hash_table_remove_all(priv->hash_table);

    gchar *filepath = font_manager_aliases_get_filepath(self);
    if (filepath == NULL)
        return FALSE;

    GFile *file = g_file_new_for_path(filepath);
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

    xmlXPathContextPtr ctx = xmlXPathNewContext(doc);
    xmlXPathObjectPtr res = xmlXPathEvalExpression((const xmlChar *) "//alias", ctx);
    for (int i = 0; i < xmlXPathNodeSetGetLength(res->nodesetval); i++)
        parse_alias_node(self, xmlXPathNodeSetItem(res->nodesetval, i));

    xmlFreeDoc(doc);
    xmlXPathFreeContext(ctx);
    xmlXPathFreeObject(res);
    xmlCleanupParser();
    g_object_unref(file);
    g_free(filepath);
    return TRUE;
}

/**
 * font_manager_aliases_save:
 * @self:   #FontManagerAliases
 *
 * Returns:    %TRUE if current configuration was successfully saved to file
 */
gboolean
font_manager_aliases_save (FontManagerAliases *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    gchar *filepath = font_manager_aliases_get_filepath(self);
    g_return_val_if_fail(filepath != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    FontManagerXmlWriter *writer = font_manager_xml_writer_new();
    font_manager_xml_writer_open(writer, filepath);
    GList *aliases = g_hash_table_get_values(priv->hash_table);
    for (GList *iter = aliases; iter != NULL; iter = iter->next)
        xml_writer_add_alias_element(writer, iter->data);
    g_list_free(aliases);
    gboolean result = font_manager_xml_writer_close(writer);
    g_object_unref(writer);
    g_free(filepath);
    return result;
}

/**
 * font_manager_aliases_list:
 * @self:   #FontManagerAliases
 *
 * Returns: (nullable) (transfer container) (element-type FontManager.AliasElement):
 * #GList of #FontManagerAliasElement or %NULL
 */
GList *
font_manager_aliases_list (FontManagerAliases *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    return g_hash_table_get_values(priv->hash_table);
}

/**
 * font_manager_aliases_get_filepath:
 * @self:   #FontManagerAliases
 *
 * Returns: (transfer full) (nullable): a newly allocated string containing the full
 * filepath to current configuration file or %NULL. Free the result using #g_free().
 */
gchar *
font_manager_aliases_get_filepath (FontManagerAliases *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    FontManagerAliasesPrivate *priv = font_manager_aliases_get_instance_private(self);
    if (priv->config_dir == NULL || priv->target_file == NULL)
        return NULL;
    return g_build_filename(priv->config_dir, priv->target_file, NULL);
}

/**
 * font_manager_aliases_new:
 *
 * Returns: (transfer full): #FontManagerAliases
 * Use #g_object_unref() to free result.
 */
FontManagerAliases *
font_manager_aliases_new (void)
{
    return FONT_MANAGER_ALIASES(g_object_new(FONT_MANAGER_TYPE_ALIASES, NULL));
}
