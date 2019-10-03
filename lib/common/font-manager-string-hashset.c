/* font-manager-string-hashset.c
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

#include "font-manager-string-hashset.h"

struct _FontManagerStringHashsetClass
{
    GObjectClass parent_class;
};

typedef struct
{
    GHashTable *hashset;
}
FontManagerStringHashsetPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerStringHashset, font_manager_string_hashset, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_SIZE,
    N_PROPERTIES
};

static void
font_manager_string_hashset_finalize (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerStringHashset *self = FONT_MANAGER_STRING_HASHSET(gobject);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    if (priv->hashset)
        g_hash_table_destroy(priv->hashset);
    G_OBJECT_CLASS(font_manager_string_hashset_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_string_hashset_get_property (GObject *gobject,
                                          guint property_id,
                                          GValue *value,
                                          GParamSpec *pspec)
{
    FontManagerStringHashset *self = FONT_MANAGER_STRING_HASHSET(gobject);
    g_return_if_fail(self != NULL);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);

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
font_manager_string_hashset_class_init (FontManagerStringHashsetClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = font_manager_string_hashset_finalize;
    object_class->get_property = font_manager_string_hashset_get_property;

    g_object_class_install_property(object_class,
                                    PROP_SIZE,
                                    g_param_spec_uint("size", NULL, NULL,
                                                      0, G_MAXUINT, 0,
                                                      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));
    return;
}

static void
font_manager_string_hashset_init (FontManagerStringHashset *self)
{
    g_return_if_fail(self != NULL);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    /* NULL value_destroy_function, keys and values are same */
    priv->hashset = g_hash_table_new_full((GHashFunc) g_str_hash,
                                          (GEqualFunc) g_str_equal,
                                          (GDestroyNotify) g_free,
                                          NULL);
    return;
}

/**
 * font_manager_string_hashset_add:
 * @self:           a #FontManagerStringHashset
 * @str:            string to add to #FontManagerStringHashset
 *
 * Returns:         %TRUE on success
 */
gboolean
font_manager_string_hashset_add (FontManagerStringHashset *self, const gchar *str)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(str != NULL, FALSE);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    /* g_hash_table_add returns FALSE if the key previously existed */
    gchar *tmp = g_strdup(str);
    g_hash_table_add(priv->hashset, tmp);
    return g_hash_table_contains(priv->hashset, str);
}

/**
 * font_manager_string_hashset_add_all:
 * @self:           a #FontManagerStringHashset
 * @add: (element-type utf8) (transfer none): #Glist of strings to add to #FontManagerStringHashset
 *
 * Returns:         %TRUE if successful
 */
gboolean
font_manager_string_hashset_add_all (FontManagerStringHashset *self, GList *add)
{
    g_return_val_if_fail(self != NULL, FALSE);
    GList *iter;
    gboolean result = TRUE;
    for (iter = add; iter != NULL; iter = iter->next) {
        if (!font_manager_string_hashset_add(self, iter->data)) {
            result = FALSE;
            g_warning(G_STRLOC ": Failed to add %s", (char *) iter->data);
        }
    }
    return result;
}

/**
 * font_manager_string_hashset_contains:
 * @self:           a #FontManagerStringHashset
 * @str:            string to look for in #FontManagerStringHashset
 *
 * Returns:         %TRUE if #FontManagerStringHashset contains str
 */
gboolean
font_manager_string_hashset_contains (FontManagerStringHashset *self, const gchar *str)
{
    g_return_val_if_fail(self != NULL && str != NULL, FALSE);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    return g_hash_table_contains(priv->hashset, str);
}

/**
 * font_manager_string_hashset_contains_all:
 * @self:           a #FontManagerStringHashset
 * @contents: (element-type utf8) (transfer none): #GList containing strings to check
 *
 * Returns:         %TRUE if all strings in @contents are contained in #FontManagerStringHashset
 */
gboolean
font_manager_string_hashset_contains_all (FontManagerStringHashset *self, GList *contents)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    GList *iter;
    for (iter = contents; iter != NULL; iter = iter->next)
        if (!g_hash_table_contains(priv->hashset, iter->data))
            return FALSE;
    return TRUE;
}

/**
 * font_manager_string_hashset_remove:
 * @self:           a #FontManagerStringHashset
 * @str:            string to remove from #FontManagerStringHashset
 *
 * Returns:         %TRUE if successful
 */
gboolean
font_manager_string_hashset_remove (FontManagerStringHashset *self, const gchar *str)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    return g_hash_table_remove(priv->hashset, str);
}

/**
 * font_manager_string_hashset_remove_all:
 * @self:           a #FontManagerStringHashset
 * @remove: (element-type utf8) (transfer none): #GList containing strings to remove
 *
 * Returns:         %TRUE if successful
 */
gboolean
font_manager_string_hashset_remove_all (FontManagerStringHashset *self, GList *remove)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    gboolean result = TRUE;
    GList *iter = NULL;
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
 * font_manager_string_hashset_retain_all:
 * @self:           a #FontManagerStringHashset
 * @retain: (element-type utf8) (transfer none): #GList of strings to check against
 *
 * Remove any elements not contained in @retain
 */
gboolean
font_manager_string_hashset_retain_all (FontManagerStringHashset *self, GList *retain)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);

    gboolean result = TRUE;
    GHashTableIter iter;
    gpointer key, value;

    g_hash_table_iter_init(&iter, priv->hashset);
    while (g_hash_table_iter_next (&iter, &key, &value)) {
        if (g_list_find_custom(retain, key, (GCompareFunc) g_strcmp0) == NULL) {
            g_hash_table_iter_remove(&iter);
            if (g_hash_table_contains(priv->hashset, key)) {
                result = FALSE;
                g_warning(G_STRLOC ": Failed to remove %s", (char *) key);
            }
        }
    }

    return result;
}

/**
 * font_manager_string_hashset_size:
 * @self:           a #FontManagerStringHashset
 *
 * Returns:         Returns the number of elements contained in #FontManagerStringHashset
 */
guint
font_manager_string_hashset_size (FontManagerStringHashset *self)
{
    g_return_val_if_fail(self != NULL, 0);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    return g_hash_table_size(priv->hashset);
}

/**
 * font_manager_string_hashset_list:
 * @self:           a #FontManagerStringHashset
 *
 * Returns: (element-type utf8) (transfer full): a #GList containing
 * the contents of #FontManagerStringHashset.
 * Use g_list_free_full() when done using the list.
 */
GList *
font_manager_string_hashset_list (FontManagerStringHashset *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);

    GList *result = NULL;
    GHashTableIter iter;
    gpointer key, value;

    g_hash_table_iter_init(&iter, priv->hashset);
    while (g_hash_table_iter_next (&iter, &key, &value)) {
        result = g_list_prepend(result, g_strdup(key));
    }

    return result;
}

/**
 * font_manager_string_hashset_clear:
 * @self:           a #FontManagerStringHashset
 *
 * Clear the #FontManagerStringHashset
 */
void
font_manager_string_hashset_clear (FontManagerStringHashset *self)
{
    g_return_if_fail(self != NULL);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    g_hash_table_remove_all(priv->hashset);
    return;
}

/**
 * font_manager_string_hashset_get:
 * @self:           a #FontManagerStringHashset
 * @index:          index of entry to retrieve
 *
 * Returns: (transfer none): a string which is owned by #FontManagerStringHashset
 * and should not be modified or freed.
 */
const gchar *
font_manager_string_hashset_get (FontManagerStringHashset *self, guint index)
{
    g_return_val_if_fail(self != NULL, 0);
    FontManagerStringHashsetPrivate *priv = font_manager_string_hashset_get_instance_private(self);
    GList *tmp = g_hash_table_get_keys(priv->hashset);
    const gchar *result = g_list_nth_data(tmp, index);
    g_list_free(tmp);
    return result;
}

/**
 * font_manager_string_hashset_new:
 *
 * Returns: (transfer full): the newly-created #FontManagerStringHashset.
 * Use g_object_unref() to free the result.
 **/
FontManagerStringHashset *
font_manager_string_hashset_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_STRING_HASHSET, NULL);
}
