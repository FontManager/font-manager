/* font-manager-font-model.c
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

#include "font-manager-font-model.h"

/**
 * SECTION: font-manager-font-model
 * @short_description: Font data model
 * @title: Font Model
 * @include: font-manager-font-model.h
 * @see_also: #FontManagerFamily #FontManagerFont
 *
 * Minimal implementation which wraps the #JsonArray returned by #font_manager_sort_json_font_listing().
 *
 * This model provides read-only access to available #FontManagerFamily objects.
 */

struct _FontManagerFontModel
{
    GObject parent_instance;

    gint stamp;
    JsonArray *available_fonts;
};

static void g_list_model_interface_init (GListModelInterface *iface);
static void gtk_tree_model_interface_init (GtkTreeModelIface *iface);
static void gtk_tree_drag_source_interface_init (GtkTreeDragSourceIface *iface);
static void gtk_tree_drag_dest_interface_init (GtkTreeDragDestIface *iface);

G_DEFINE_TYPE_WITH_CODE(FontManagerFontModel, font_manager_font_model, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(G_TYPE_LIST_MODEL, g_list_model_interface_init)
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

GType
font_manager_font_model_column_get_type (void)
{
  static gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_FONT_MODEL_OBJECT, "FONT_MANAGER_FONT_MODEL_OBJECT", "object" },
        { FONT_MANAGER_FONT_MODEL_NAME, "FONT_MANAGER_FONT_MODEL_NAME", "name" },
        { FONT_MANAGER_FONT_MODEL_DESCRIPTION, "FONT_MANAGER_FONT_MODEL_DESCRIPTION", "description" },
        { FONT_MANAGER_FONT_MODEL_COUNT, "FONT_MANAGER_FONT_MODEL_COUNT", "count" },
        { FONT_MANAGER_FONT_MODEL_N_COLUMNS, "FONT_MANAGER_FONT_MODEL_N_COLUMNS", "n-columns" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerFontModelColumn"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}

#define SOURCE "source-array"

gint
get_n_variations (FontManagerFontModel *self, gint index)
{
    JsonObject *family = json_array_get_object_element(self->available_fonts, index);
    return (gint) json_object_get_int_member(family, "n_variations");
}

gboolean
invalid_iter (GtkTreeIter *iter) {
    iter->stamp = 0;
    return FALSE;
}

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
    if (!self->available_fonts || indices[0] >= ((int) json_array_get_length(self->available_fonts)))
        return invalid_iter(iter);
    iter->stamp = self->stamp;
    iter->user_data = GINT_TO_POINTER(indices[0]);
    iter->user_data2 = GINT_TO_POINTER(-1);
    if (depth > 1) {
        gint n_variations = get_n_variations(self, indices[0]);
        if (indices[1] >= n_variations)
            return invalid_iter(iter);
        iter->user_data2 = GINT_TO_POINTER(indices[1]);
    }
    return TRUE;
}

static GtkTreePath *
font_manager_font_model_get_path (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, NULL);
    g_return_val_if_fail(iter->stamp == self->stamp, NULL);
    GtkTreePath *path = gtk_tree_path_new();
    gtk_tree_path_append_index(path, GPOINTER_TO_INT(iter->user_data));
    if (GPOINTER_TO_INT(iter->user_data2) != -1)
        gtk_tree_path_append_index(path, GPOINTER_TO_INT(iter->user_data2));
    return path;
}

static void
font_manager_font_model_get_value (GtkTreeModel *tree_model,
                                   GtkTreeIter *iter,
                                   gint column,
                                   GValue *value)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_if_fail(self != NULL);
    g_return_if_fail(self->available_fonts != NULL);
    g_return_if_fail(json_array_get_length(self->available_fonts) > 0);
    g_return_if_fail(iter != NULL);
    g_return_if_fail(iter->stamp == self->stamp);
    g_value_init(value, COLUMN_TYPES[column]);
    JsonObject *root = NULL, *child = NULL;
    root = json_array_get_object_element(self->available_fonts, GPOINTER_TO_INT(iter->user_data));
    gboolean root_node = (GPOINTER_TO_INT(iter->user_data2) == -1);
    if (!root_node) {
        JsonArray *children = json_object_get_array_member(root, "variations");
        child = json_array_get_object_element(children, GPOINTER_TO_INT(iter->user_data2));
    }
    JsonObject *obj = root_node ? root : child;
    const gchar *member = root_node ? "family" : "style";
    switch (column) {
        case FONT_MANAGER_FONT_MODEL_NAME:
            g_value_set_string(value, json_object_get_string_member(obj, member));
            break;
        case FONT_MANAGER_FONT_MODEL_DESCRIPTION:
            g_value_set_string(value, json_object_get_string_member(obj, "description"));
            break;
        case FONT_MANAGER_FONT_MODEL_COUNT:
            if (root_node)
                g_value_set_int(value, get_n_variations(self, GPOINTER_TO_INT(iter->user_data)));
            else
                g_value_set_int(value, -1);
            break;
        case FONT_MANAGER_FONT_MODEL_OBJECT:
            if (root_node) {
                g_autoptr(FontManagerFamily) family = font_manager_family_new();
                g_object_set(family, "source-object", obj, NULL);
                g_value_set_object(value, family);
            } else {
                g_autoptr(FontManagerFont) font = font_manager_font_new();
                g_object_set(font, "source-object", obj, NULL);
                g_value_set_object(value, font);
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
    if (!self->available_fonts || json_array_get_length(self->available_fonts) < 1)
        return invalid_iter(iter);
    gint index = GPOINTER_TO_INT(iter->user_data);
    if (GPOINTER_TO_INT(iter->user_data2) == -1) {
        gint n_root_nodes = (gint) json_array_get_length(self->available_fonts);
        if (!(index < n_root_nodes - 1))
            return invalid_iter(iter);
        iter->user_data = GINT_TO_POINTER(index + 1);
    } else {
        gint n_children = get_n_variations(self, index);
        index = GPOINTER_TO_INT(iter->user_data2);
        if (!(index < n_children - 1))
            return invalid_iter(iter);
        iter->user_data2 = GINT_TO_POINTER(index + 1);
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
    if (!self->available_fonts || json_array_get_length(self->available_fonts) < 1)
        return invalid_iter(iter);
    gint index = GPOINTER_TO_INT(iter->user_data);
    if (GPOINTER_TO_INT(iter->user_data2) == -1) {
        if (index < 1)
            return invalid_iter(iter);
        iter->user_data = GINT_TO_POINTER(index - 1);
    } else {
        index = GPOINTER_TO_INT(iter->user_data2);
        if (index < 1)
            return invalid_iter(iter);
        iter->user_data2 = GINT_TO_POINTER(index - 1);
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
    if (!self->available_fonts || json_array_get_length(self->available_fonts) < 1)
        return invalid_iter(iter);
    /* Special case - if parent equals %NULL this function should return the first node */
    if (parent == NULL) {
        iter->user_data = GINT_TO_POINTER(0);
        iter->user_data2 = GINT_TO_POINTER(-1);
    } else if (GPOINTER_TO_INT(parent->user_data2) != -1) {
        /* Maximum depth of this model is 2 */
        return invalid_iter(iter);
    } else {
        iter->user_data = parent->user_data;
        iter->user_data2 = GINT_TO_POINTER(0);
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
    if (!self->available_fonts || json_array_get_length(self->available_fonts) < 1)
        return FALSE;
    return (GPOINTER_TO_INT(iter->user_data2) == -1);
}

static gint
font_manager_font_model_iter_n_children (GtkTreeModel *tree_model, GtkTreeIter *iter)
{
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(tree_model);
    g_return_val_if_fail(self != NULL, 0);
    g_return_val_if_fail(self->available_fonts != NULL, 0);
    /* Special case - if iter is %NULL this function should return the number of toplevel nodes */
    if (iter == NULL)
        return ((gint) json_array_get_length(self->available_fonts));
    return get_n_variations(self, GPOINTER_TO_INT(iter->user_data));
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
    if (!self->available_fonts || json_array_get_length(self->available_fonts) < 1)
        return FALSE;
    iter->stamp = self->stamp;
    /* Special case - if parent is %NULL this function should set iter to toplevel node n */
    if (parent == NULL) {
        gint n_root_nodes = (gint) json_array_get_length(self->available_fonts);
        if (n < n_root_nodes) {
            iter->user_data = GINT_TO_POINTER(n);
            iter->user_data2 = GINT_TO_POINTER(-1);
            return TRUE;
        } else {
            return invalid_iter(iter);
        }
    }

    g_return_val_if_fail(parent->stamp == self->stamp, FALSE);
    gint n_children = get_n_variations(self, GPOINTER_TO_INT(parent->user_data));

    if (n > n_children -1) {
        return invalid_iter(iter);
    } else {
        iter->user_data = parent->user_data;
        iter->user_data2 = GINT_TO_POINTER(n);
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
    iter->user_data2 = GINT_TO_POINTER(-1);
    return TRUE;
}

/* GListModelInterface */

static GType
font_manager_font_model_get_item_type (G_GNUC_UNUSED GListModel *self)
{
    return FONT_MANAGER_TYPE_FAMILY;
}

static guint
font_manager_font_model_get_n_items (GListModel *self)
{
    g_return_val_if_fail(self != NULL, 0);
    FontManagerFontModel *model = FONT_MANAGER_FONT_MODEL(self);
    return json_array_get_length(model->available_fonts);
}

static gpointer
font_manager_font_model_get_item (GListModel *self, guint position)
{
    g_return_val_if_fail(self != NULL, NULL);
    if (position >= font_manager_font_model_get_n_items(self))
        return NULL;
    FontManagerFontModel *model = FONT_MANAGER_FONT_MODEL(self);
    JsonObject *obj = json_array_get_object_element(model->available_fonts, position);
    FontManagerFamily *family = font_manager_family_new();
    g_object_set(G_OBJECT(family), "source-object", obj, NULL);
    return family;
}

static void
g_list_model_interface_init (GListModelInterface *iface)
{
    iface->get_item_type = font_manager_font_model_get_item_type;
    iface->get_n_items = font_manager_font_model_get_n_items;
    iface->get_item = font_manager_font_model_get_item;
    return;
}

/* GtkTreeModelIface */

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
    self->available_fonts = json_array_new();
    return;
}

static void
font_manager_font_model_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(gobject);
    g_clear_pointer(&self->available_fonts, json_array_unref);
    G_OBJECT_CLASS(font_manager_font_model_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_font_model_get_property (GObject *gobject,
                                      guint property_id,
                                      GValue *value,
                                      GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(gobject);
    g_return_if_fail(self->available_fonts != NULL);

    switch (property_id) {
        case PROP_SOURCE:
            g_value_set_boxed(value, self->available_fonts);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
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
font_manager_font_model_set_property (GObject *gobject,
                                      guint property_id,
                                      const GValue *value,
                                      GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontModel *self = FONT_MANAGER_FONT_MODEL(gobject);

    switch (property_id) {
        case PROP_SOURCE:
            set_source(self, g_value_get_boxed(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
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
    object_class->dispose = font_manager_font_model_dispose;

    /**
     * FontManagerFontModel:source-array:
     *
     * #JsonArray source.
     */
    g_object_class_install_property(object_class,
                                    PROP_SOURCE,
                                    g_param_spec_boxed(SOURCE,
                                                       NULL,
                                                       "#JsonArray backing this model",
                                                       JSON_TYPE_ARRAY,
                                                       G_PARAM_STATIC_STRINGS |
                                                       G_PARAM_READWRITE));
    return;
}

/**
 * font_manager_font_model_new:
 *
 * Returns : (transfer full) : A newly created #FontManagerFontModel.
 * Free the returned object using #g_object_unref().
 */
FontManagerFontModel *
font_manager_font_model_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_FONT_MODEL, NULL);
}
