/* string-hashset.c
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

#include "string-hashset.h"

struct _StringHashsetClass
{
    GObjectClass parent_class;
};

typedef struct
{
    GHashTable *hashset;
}
StringHashsetPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(StringHashset, string_hashset, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_SIZE,
    N_PROPERTIES
};

static void
string_hashset_finalize (GObject *self)
{
    g_return_if_fail(self != NULL);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(STRING_HASHSET(self));
    if (priv->hashset)
        g_hash_table_destroy(priv->hashset);
    G_OBJECT_CLASS(string_hashset_parent_class)->finalize(self);
    return;
}

static void
string_hashset_get_property (GObject *gobject,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
    StringHashset *self = STRING_HASHSET(gobject);
    g_return_if_fail(self != NULL);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);

    switch (property_id) {
        case PROP_SIZE:
            g_value_set_uint(value, g_hash_table_size(priv->hashset));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }

    return;
}

static void
string_hashset_class_init (StringHashsetClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = string_hashset_finalize;
    object_class->get_property = string_hashset_get_property;

    g_object_class_install_property(object_class,
                                    PROP_SIZE,
                                    g_param_spec_uint("size", NULL, NULL,
                                                      0, G_MAXUINT, 0,
                                                      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));
    return;
}

static void
string_hashset_init (StringHashset *self)
{
    g_return_if_fail(self != NULL);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    /* NULL value_destroy_function, keys and values are same */
    priv->hashset = g_hash_table_new_full((GHashFunc) g_str_hash,
                                          (GEqualFunc) g_str_equal,
                                          (GDestroyNotify) g_free,
                                          NULL);
    return;
}

/**
 * string_hashset_add:
 * @self:           a #StringHashset
 * @str:            string to add to #StringHashset
 *
 * Returns:         %TRUE on success
 */
gboolean
string_hashset_add (StringHashset *self, const gchar *str)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(str != NULL, FALSE);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    /* g_hash_table_add returns FALSE if the key previously existed */
    gchar *tmp = g_strdup(str);
    g_hash_table_add(priv->hashset, tmp);
    return g_hash_table_contains(priv->hashset, str);
}

/**
 * string_hashset_add_all:
 * @self:           a #StringHashset
 * @add: (element-type utf8) (transfer none): #Glist of strings to add to #StringHashset
 *
 * Returns:         %TRUE if successful
 */
gboolean
string_hashset_add_all (StringHashset *self, GList *add)
{
    g_return_val_if_fail(self != NULL, FALSE);
    GList *iter;
    gboolean result = TRUE;
    for (iter = add; iter != NULL; iter = iter->next) {
        if (!string_hashset_add(self, iter->data)) {
            result = FALSE;
            g_warning(G_STRLOC ": Failed to add %s", (char *) iter->data);
        }
    }
    return result;
}

/**
 * string_hashset_contains:
 * @self:           a #StringHashset
 * @str:            string to look for in #StringHashset
 *
 * Returns:         %TRUE if #StringHashset contains str
 */
gboolean
string_hashset_contains (StringHashset *self, const gchar *str)
{
    g_return_val_if_fail(self != NULL && str != NULL, FALSE);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    return g_hash_table_contains(priv->hashset, str);
}

/**
 * string_hashset_contains_all:
 * @self:           a #StringHashset
 * @contents: (element-type utf8) (transfer none): #GList containing strings to check
 *
 * Returns:         %TRUE if all strings in @contents are contained in #StringHashset
 */
gboolean
string_hashset_contains_all (StringHashset *self, GList *contents)
{
    g_return_val_if_fail(self != NULL, FALSE);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    GList *iter;
    for (iter = contents; iter != NULL; iter = iter->next)
        if (!g_hash_table_contains(priv->hashset, iter->data))
            return FALSE;
    return TRUE;
}

/**
 * string_hashset_remove:
 * @self:           a #StringHashset
 * @str:            string to remove from #StringHashset
 *
 * Returns:         %TRUE if successful
 */
gboolean
string_hashset_remove (StringHashset *self, const gchar *str)
{
    g_return_val_if_fail(self != NULL, FALSE);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    return g_hash_table_remove(priv->hashset, str);
}

/**
 * string_hashset_remove_all:
 * @self:           a #StringHashset
 * @remove: (element-type utf8) (transfer none): #GList containing strings to remove
 *
 * Returns:         %TRUE if successful
 */
gboolean
string_hashset_remove_all (StringHashset *self, GList *remove)
{
    g_return_val_if_fail(self != NULL, FALSE);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    GList *iter;
    gboolean result = TRUE;
    for (iter = remove; iter != NULL; iter = iter->next) {
        g_hash_table_remove(priv->hashset, iter->data);
        if (g_hash_table_contains(priv->hashset, iter->data)) {
            result = FALSE;
            g_warning(G_STRLOC ": Failed to remove %s", (char *) iter->data);
        }
    }
    return result;
}

/**
 * string_hashset_retain_all:
 * @self:           a #StringHashset
 * @retain: (element-type utf8) (transfer none): #GList of strings to check against
 *
 * Remove any elements not contained in @retain
 */
gboolean
string_hashset_retain_all (StringHashset *self, GList *retain)
{
    g_return_val_if_fail(self != NULL, FALSE);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    gboolean result = TRUE;
    GList *iter, *current = g_hash_table_get_keys(priv->hashset);
    for (iter = current; iter != NULL; iter = iter->next) {
        if (g_list_find_custom(retain, iter->data, (GCompareFunc) g_strcmp0) == NULL) {
            g_hash_table_remove(priv->hashset, iter->data);
            if (g_hash_table_contains(priv->hashset, iter->data)) {
                result = FALSE;
                g_warning(G_STRLOC ": Failed to remove %s", (char *) iter->data);
            }
        }
    }
    g_list_free(current);
    return result;
}

/**
 * string_hashset_size:
 * @self:           a #StringHashset
 *
 * Returns:         Returns the number of elements contained in #StringHashset
 */
guint
string_hashset_size (StringHashset *self)
{
    g_return_val_if_fail(self != NULL, 0);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    return g_hash_table_size(priv->hashset);
}

/**
 * string_hashset_list:
 * @self:           a #StringHashset
 *
 * Returns: (element-type utf8) (transfer full): a #GList containing
 * the contents of #StringHashset. The content of the list is owned by the
 * #StringHashset and should not be modified or freed.
 * Use g_list_free_full() when done using the list.
 */
GList *
string_hashset_list (StringHashset *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    GList *result = NULL;
    for (GList *iter = g_hash_table_get_values(priv->hashset); iter != NULL; iter = iter->next)
        result = g_list_prepend(result, g_strdup(iter->data));
    result = g_list_reverse(result);
    return result;
}

/**
 * string_hashset_clear:
 * @self:           a #StringHashset
 *
 * Clear the #StringHashset
 */
void
string_hashset_clear (StringHashset *self)
{
    g_return_if_fail(self != NULL);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    g_hash_table_remove_all(priv->hashset);
    return;
}

/**
 * string_hashset_get:
 * @self:           a #StringHashset
 * @index:          index of entry to retrieve
 *
 * Returns: (transfer none): a string which is owned by #StringHashset
 * and should not be modified or freed.
 */
const gchar *
string_hashset_get (StringHashset *self, guint index)
{
    g_return_val_if_fail(self != NULL, 0);
    StringHashsetPrivate *priv = string_hashset_get_instance_private(self);
    GList *tmp = g_hash_table_get_keys(priv->hashset);
    const gchar *result = g_list_nth_data(tmp, index);
    g_list_free(tmp);
    return result;
}

/**
 * string_hashset_new:
 *
 * Returns: (transfer full): the newly-created #StringHashset.
 * Use g_object_unref() to free the result.
 **/
StringHashset *
string_hashset_new (void)
{
    return STRING_HASHSET(g_object_new(string_hashset_get_type(), NULL));
}
