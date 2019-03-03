/* font-manager-font-model.c
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

#include <gtk/gtk.h>
#include <json-glib/json-glib.h>

#include "font-manager-font.h"
#include "font-manager-family.h"
#include "font-manager-font-model.h"

struct _FontManagerFontModel
{
    GObject parent_instance;

    gint stamp;
    JsonArray *available_fonts;
};

static void gtk_tree_model_interface_init (GtkTreeModelIface *iface);
static void gtk_tree_drag_source_interface_init (GtkTreeDragSourceIface *iface);
static void gtk_tree_drag_dest_interface_init (GtkTreeDragDestIface *iface);

G_DEFINE_TYPE_WITH_CODE(FontManagerFontModel, font_manager_font_model, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(GTK_TYPE_TREE_MODEL, gtk_tree_model_interface_init)
    G_IMPLEMENT_INTERFACE(GTK_TYPE_TREE_DRAG_SOURCE, gtk_tree_drag_source_interface_init)
    G_IMPLEMENT_INTERFACE(GTK_TYPE_TREE_DRAG_DEST, gtk_tree_drag_dest_interface_init))

enum
{
    PROP_RESERVED,
    PROP_SOURCE,
    N_PROPERTIES
};

GType COLUMN_TYPES [FONT_MANAGER_FONT_MODEL_N_COLUMNS] = {
    G_TYPE_OBJECT,
    G_TYPE_STRING,
    G_TYPE_STRING,
    G_TYPE_INT
};

#define SOURCE "source-array"
#define JSON_OBJECT(o) (JsonObject *) o
#define GET_INDEX(o) ((gint) json_object_get_int_member(JSON_OBJECT(o), "_index"))
#define GET_VARIATIONS(o) json_object_get_array_member(JSON_OBJECT(o), "variations")
#define N_VARIATIONS(o) ((gint) json_object_get_int_member(JSON_OBJECT(o), "n_variations"))

/* GtkTreeModelIface */

static GtkTreeModelFlags
font_manager_font_model_get_flags (G_GNUC_UNUSED GtkTreeModel *tree_model)
{
    return GTK_TREE_MODEL_ITERS_PERSIST;
}

static gint
font_manager_font_model_get_n_columns (G_GNUC_UNUSED GtkTreeModel *tree_model)
{
    return FONT_MANAGER_FONT_MODEL_N_COLUMNS;
}

static GType
font_manager_font_model_get_column_type (G_GNUC_UNUSED GtkTreeModel *tree_model, gint index)
{
    g_return_val_if_fail(index < FONT_MANAGER_FONT_MODEL_N_COLUMNS, G_TYPE_INVALID);
    return COLUMN_TYPES[index];
}

static gboolean
font_manager_font_model_get_iter (GtkTreeModel *tree_model,
                                 GtkTreeIter *iter,
                                 GtkTreePath *path)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(path != NULL, FALSE);
    gint depth = gtk_tree_path_get_depth(path);
    gint *indices = gtk_tree_path_get_indices(path);
    iter->stamp = self->stamp;
    iter->user_data = json_array_get_object_element(self->available_fonts, indices[0]);
    g_return_val_if_fail(iter->user_data != NULL, FALSE);
    if (depth > 1) {
        JsonArray *variations = GET_VARIATIONS(iter->user_data);
        iter->user_data2 = json_array_get_object_element(variations, indices[1]);
    } else
        iter->user_data2 = NULL;
    return TRUE;
}

static GtkTreePath *
font_manager_font_model_get_path (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, NULL);
    g_return_val_if_fail(iter->stamp == self->stamp, NULL);
    g_return_val_if_fail(iter->user_data != NULL, NULL);
    gint index = GET_INDEX(iter->user_data);
    if (iter->user_data2 == NULL)
        return gtk_tree_path_new_from_indices(index, -1);
    else
        return gtk_tree_path_new_from_indices(index, GET_INDEX(iter->user_data2), -1);
}

static void
font_manager_font_model_get_value (GtkTreeModel *tree_model,
                                  GtkTreeIter *iter,
                                  gint column,
                                  GValue *value)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_if_fail(self != NULL);
    g_return_if_fail(iter != NULL);
    g_return_if_fail(iter->stamp == self->stamp);
    g_return_if_fail(iter->user_data != NULL);
    g_value_init(value, COLUMN_TYPES[column]);
    gboolean root_node = (iter->user_data2 == NULL);
    const gchar *member = root_node ? "family" : "style";
    JsonObject *obj = root_node ? JSON_OBJECT(iter->user_data) : JSON_OBJECT(iter->user_data2);
    switch (column) {
        case FONT_MANAGER_FONT_MODEL_NAME:
            g_value_set_string(value, json_object_get_string_member(obj, member));
            break;
        case FONT_MANAGER_FONT_MODEL_DESCRIPTION:
            g_value_set_string(value, json_object_get_string_member(obj, "description"));
            break;
        case FONT_MANAGER_FONT_MODEL_COUNT:
            if (root_node)
                g_value_set_int(value, N_VARIATIONS(obj));
            else
                g_value_set_int(value, -1);
            break;
        case FONT_MANAGER_FONT_MODEL_OBJECT:
            if (root_node) {
                FontManagerFamily *family = font_manager_family_new();
                g_object_set(family, "source-object", obj, NULL);
                g_value_take_object(value, family);
            } else {
                FontManagerFont *font = font_manager_font_new();
                g_object_set(font, "source-object", obj, NULL);
                g_value_take_object(value, font);
            }
            break;
        default:
            g_critical(G_STRLOC ": Invalid column index : %i", column);
    }
    return;
}

static gboolean
font_manager_font_model_iter_next (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(iter != NULL, FALSE);
    g_return_val_if_fail(iter->stamp == self->stamp, FALSE);
    g_return_val_if_fail(iter->user_data != NULL, FALSE);
    gint index;
    if (iter->user_data2 == NULL) {
        gint n_root_nodes = (gint) json_array_get_length(self->available_fonts);
        index = GET_INDEX(iter->user_data);
        if (!(index < n_root_nodes - 1))
            return FALSE;
        iter->user_data = json_array_get_object_element(self->available_fonts, index + 1);
    } else {
        gint n_children = N_VARIATIONS(iter->user_data);
        index = GET_INDEX(iter->user_data2);
        if (!(index < n_children - 1))
            return FALSE;
        JsonArray *variations = GET_VARIATIONS(iter->user_data);
        iter->user_data2 = json_array_get_object_element(variations, index + 1);
    }
    return TRUE;
}

static gboolean
font_manager_font_model_iter_previous (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(iter != NULL, FALSE);
    g_return_val_if_fail(iter->stamp == self->stamp, FALSE);
    g_return_val_if_fail(iter->user_data != NULL, FALSE);
    gint index;
    if (iter->user_data2 == NULL) {
        index = GET_INDEX(iter->user_data);
        if (index < 1)
            return FALSE;
        iter->user_data = json_array_get_object_element(self->available_fonts, index - 1);
    } else {
        index = GET_INDEX(iter->user_data2);
        if (index < 1)
            return FALSE;
        JsonArray *variations = GET_VARIATIONS(iter->user_data);
        iter->user_data2 = json_array_get_object_element(variations, index - 1);
    }
    return TRUE;
}

static gboolean
font_manager_font_model_iter_children (GtkTreeModel *tree_model,
                                      GtkTreeIter *iter,
                                      GtkTreeIter *parent)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    iter->stamp = self->stamp;
    /* Special case - if parent equals %NULL this function should return the first node */
    if (parent == NULL) {
        iter->user_data = json_array_get_object_element(self->available_fonts, 0);
        iter->user_data2 = NULL;
    } else if (parent->user_data2 != NULL) {
        /* Maximum depth of this model is 2 */
        iter->stamp = 0;
        return FALSE;
    } else {
        iter->user_data = parent->user_data;
        JsonArray *variations = GET_VARIATIONS(iter->user_data);
        iter->user_data2 = json_array_get_object_element(variations, 0);
    }
    return TRUE;
}

static gboolean
font_manager_font_model_iter_has_child (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(iter != NULL, FALSE);
    g_return_val_if_fail(iter->stamp == self->stamp, FALSE);
    return (iter->user_data != NULL && iter->user_data2 == NULL) ? TRUE : FALSE;
}

static gint
font_manager_font_model_iter_n_children (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, 0);
    /* Special case - if iter is %NULL this function should return the number of toplevel nodes */
    if (iter == NULL)
        return ((gint) json_array_get_length(self->available_fonts));
    g_return_val_if_fail(iter->user_data != NULL, 0);
    return N_VARIATIONS(iter->user_data);
}

static gboolean
font_manager_font_model_iter_nth_child (GtkTreeModel *tree_model,
                                       GtkTreeIter *iter,
                                       GtkTreeIter *parent,
                                       gint n)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(n >= 0, FALSE);

    iter->stamp = self->stamp;
    /* Special case - if parent is %NULL this function should set iter to toplevel node n */
    if (parent == NULL) {
        gint n_root_nodes = (gint) json_array_get_length(self->available_fonts);
        if (n < n_root_nodes) {
            iter->user_data = json_array_get_object_element(self->available_fonts, n);
            iter->user_data2 = NULL;
            return TRUE;
        } else {
            return FALSE;
        }
    }

    g_return_val_if_fail(parent->user_data != NULL, FALSE);
    gint n_children = N_VARIATIONS(parent->user_data);

    if (n > n_children -1) {
        return FALSE;
    } else {
        iter->user_data = parent->user_data;
        JsonArray *variations = GET_VARIATIONS(iter->user_data);
        iter->user_data2 = json_array_get_object_element(variations, n);
        g_return_val_if_fail(iter->user_data2 != NULL, FALSE);
        return TRUE;
    }

}

static gboolean
font_manager_font_model_iter_parent (GtkTreeModel *tree_model,
                                    GtkTreeIter *iter,
                                    GtkTreeIter *child)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, FALSE);
    g_return_val_if_fail(child->stamp == self->stamp, FALSE);
    g_return_val_if_fail(child->user_data != NULL, FALSE);
    g_return_val_if_fail(child->user_data2 != NULL, FALSE);
    iter->stamp = self->stamp;
    iter->user_data = child->user_data;
    iter->user_data2 = NULL;
    return TRUE;
}

static void
gtk_tree_model_interface_init (GtkTreeModelIface *iface)
{
    iface->get_flags = font_manager_font_model_get_flags;
    iface->get_n_columns = font_manager_font_model_get_n_columns;
    iface->get_column_type = font_manager_font_model_get_column_type;
    iface->get_iter = font_manager_font_model_get_iter;
    iface->get_path = font_manager_font_model_get_path;
    iface->get_value = font_manager_font_model_get_value;
    iface->iter_next = font_manager_font_model_iter_next;
    iface->iter_previous = font_manager_font_model_iter_previous;
    iface->iter_children = font_manager_font_model_iter_children;
    iface->iter_has_child = font_manager_font_model_iter_has_child;
    iface->iter_n_children = font_manager_font_model_iter_n_children;
    iface->iter_nth_child = font_manager_font_model_iter_nth_child;
    iface->iter_parent = font_manager_font_model_iter_parent;
    return;
}

/* GtkTreeDragSourceIface */

static gboolean
font_manager_font_model_row_draggable (G_GNUC_UNUSED GtkTreeDragSource *source,
                                       G_GNUC_UNUSED GtkTreePath *path)
{
    return TRUE;
}

static gboolean
font_manager_font_model_drag_data_get (GtkTreeDragSource *source,
                                      GtkTreePath *path,
                                      GtkSelectionData *selection_data)
{
    if (gtk_tree_set_row_drag_data(selection_data, GTK_TREE_MODEL(source), path))
        return TRUE;
    return FALSE;
}

static gboolean
font_manager_font_model_drag_data_delete (G_GNUC_UNUSED GtkTreeDragSource *drag_source,
                                          G_GNUC_UNUSED GtkTreePath *path)
{
    /* This model is read-only */
    return FALSE;
}

static void
gtk_tree_drag_source_interface_init (GtkTreeDragSourceIface *iface)
{
    iface->row_draggable = font_manager_font_model_row_draggable;
    iface->drag_data_get = font_manager_font_model_drag_data_get;
    iface->drag_data_delete = font_manager_font_model_drag_data_delete;
    return;
}

/* GtkTreeDragDestIface */

static gboolean
font_manager_font_model_drag_data_received (G_GNUC_UNUSED GtkTreeDragDest *drag_dest,
                                            G_GNUC_UNUSED GtkTreePath *dest,
                                            G_GNUC_UNUSED GtkSelectionData *selection_data)
{
    return FALSE;
}

static gboolean
font_manager_font_model_row_drop_possible (G_GNUC_UNUSED GtkTreeDragDest *drag_dest,
                                           G_GNUC_UNUSED GtkTreePath *dest,
                                           G_GNUC_UNUSED GtkSelectionData *selection_data)
{
    /* This model is read-only */
    return FALSE;
}

static void
gtk_tree_drag_dest_interface_init (GtkTreeDragDestIface *iface)
{
    iface->drag_data_received = font_manager_font_model_drag_data_received;
    iface->row_drop_possible = font_manager_font_model_row_drop_possible;
    return;
}

/* FontManagerFontModel */

static void
font_manager_font_model_init (FontManagerFontModel *self)
{
    do { self->stamp = g_random_int(); } while (self->stamp == 0);
    return;
}

static void
font_manager_font_model_finalize (GObject *object)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(object);
    if (self && self->available_fonts != NULL)
        json_array_unref(self->available_fonts);
    G_OBJECT_CLASS(font_manager_font_model_parent_class)->finalize(object);
    return;
}

static void
font_manager_font_model_get_property (GObject *object,
                                     guint property_id,
                                     GValue *value,
                                     GParamSpec *pspec)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(object);
    g_return_if_fail(self != NULL && self->available_fonts != NULL);

    switch (property_id) {
        case PROP_SOURCE:
            g_value_set_boxed(value, self->available_fonts);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
            break;
    }

    return;
}

static void
set_source (FontManagerFontModel *self, JsonArray *value)
{
    g_return_if_fail(self != NULL);
    if (self->available_fonts == value)
        return;
    if (self->available_fonts != NULL)
        json_array_unref(self->available_fonts);
    self->available_fonts = value ? json_array_ref(value) : NULL;
    g_object_notify(G_OBJECT(self), SOURCE);
    return;
}

static void
font_manager_font_model_set_property (GObject *object,
                                     guint property_id,
                                     const GValue *value,
                                     GParamSpec *pspec)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(object);
    g_return_if_fail(self != NULL);

    switch (property_id) {
        case PROP_SOURCE:
            set_source(self, g_value_get_boxed(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
            break;
    }

    return;
}

static void
font_manager_font_model_class_init (FontManagerFontModelClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->get_property = font_manager_font_model_get_property;
    object_class->set_property = font_manager_font_model_set_property;
    object_class->finalize = font_manager_font_model_finalize;
    g_object_class_install_property(object_class,
                                    PROP_SOURCE,
                                    g_param_spec_boxed(SOURCE, NULL, NULL,
                                                       JSON_TYPE_ARRAY,
                                                       G_PARAM_STATIC_STRINGS |
                                                       G_PARAM_READWRITE));
    return;
}

/**
 * font_manager_font_model_new:
 *
 * Minimal #GtkTreeModel implementation which wraps the #JsonArray
 * returned by #sort_json_font_listing
 *
 * Returns : (transfer full) : a new #FontManagerFontModel
 */
FontManagerFontModel *
font_manager_font_model_new (void)
{
    return FONT_MANAGER_FONT_MODEL(g_object_new(font_manager_font_model_get_type(), NULL));
}
