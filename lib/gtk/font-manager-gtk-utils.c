/* font-manager-gtk-utils.c
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

#include "font-manager-gtk-utils.h"

/**
 * SECTION: font-manager-gtk-utils
 * @short_description: Gtk related utility functions
 * @title: Gtk utility functions
 * @include: font-manager-gtk-utils.h
 */

/**
 * font_manager_text_tag_table_new:
 *
 * Returns: (transfer full): A newly created #GtkTextTagTable.
 * Free the returned object using #g_object_unref().
 */
GtkTextTagTable *
font_manager_text_tag_table_new (void)
{
    GtkTextTagTable *tags = gtk_text_tag_table_new();
    g_autoptr(GtkTextTag) font = gtk_text_tag_new("FontDescription");
    g_object_set(font, "fallback", FALSE, NULL);
    if (!gtk_text_tag_table_add(tags, font))
        g_warning(G_STRLOC" : Failed to add tag to table: FontDescription");
    g_autoptr(GtkTextTag) point_size = gtk_text_tag_new("SizePoint");
    g_object_set(point_size, "family", "Monospace", "rise", 1250, "size-points", 6.5, NULL);
    if (!gtk_text_tag_table_add(tags, point_size))
        g_warning(G_STRLOC" : Failed to add tag to table: size-points");
    return tags;
}

/**
 * font_manager_widget_set_align:
 *
 * Set both halign and valign to the same value.
 */
void
font_manager_widget_set_align (GtkWidget *widget, GtkAlign align)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_halign(GTK_WIDGET(widget), align);
    gtk_widget_set_valign(GTK_WIDGET(widget), align);
    return;
}

/**
 * font_manager_widget_set_expand:
 *
 * Set both hexpand and vexpand to the same value.
 */
void
font_manager_widget_set_expand (GtkWidget *widget, gboolean expand)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_hexpand(GTK_WIDGET(widget), expand);
    gtk_widget_set_vexpand(GTK_WIDGET(widget), expand);
    return;
}

/**
 * font_manager_widget_set_margin:
 *
 * Set all margin properties to the same value.
 */
void
font_manager_widget_set_margin (GtkWidget *widget, gint margin)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_margin_start(widget, margin);
    gtk_widget_set_margin_end(widget, margin);
    gtk_widget_set_margin_top(widget, margin);
    gtk_widget_set_margin_bottom(widget, margin);
    return;
}

/**
 * font_manager_widget_dispose:
 *
 * Convenience function which iterates through the children of a #GtkWidget,
 * calls #gtk_widget_unparent() on each and sets the pointer to #NULL.
 */
void
font_manager_widget_dispose (GtkWidget *widget)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    GtkWidget *child = gtk_widget_get_first_child(GTK_WIDGET(widget));
    while (child) {
        GtkWidget *next = gtk_widget_get_next_sibling(child);
        g_clear_pointer(&child, gtk_widget_unparent);
        child = next;
    }
    return;
}

/**
 * font_manager_get_localized_pangram:
 *
 * Retrieve a sample string from Pango for the default language.
 * If Pango does not have a sample string for language,
 * the classic "The quick brown fox..." is returned.
 *
 * Returns: (transfer full): A newly allocated string. Free the result using #g_free.
 */
gchar *
font_manager_get_localized_pangram (void)
{
    PangoLanguage * lang = pango_language_get_default();
    const gchar *pangram = pango_language_get_sample_string(lang);
    return g_strdup(pangram);
}

/**
 * font_manager_get_shortcut_for_stateful_action:
 * @prefix: (nullable): Action prefix i.e. "app", "window", etc.
 * @name:               Action name
 * @target:             Action target
 * @accel: (nullable):  A valid accelerator string as understood by #gtk_accelerator_parse
 *
 * Returns: (transfer full) (nullable): A newly created #GtkShortcut.
 * Free the returned object using #g_object_unref.
 */
GtkShortcut *
font_manager_get_shortcut_for_stateful_action (const gchar *prefix, const gchar *name,
                                                const gchar *target, const gchar *accel)
{
    g_return_val_if_fail(name != NULL && target != NULL, NULL);
    g_autofree gchar *action_name = prefix ? g_strdup_printf("%s.%s", prefix, name) : g_strdup(name);
    GtkShortcutAction *shortcut_action = gtk_named_action_new(action_name);
    GtkShortcutTrigger *shortcut_trigger = gtk_shortcut_trigger_parse_string(accel);
    GtkShortcut *shortcut = gtk_shortcut_new(shortcut_trigger, shortcut_action);
    GVariant *arg = g_variant_new_string(target);
    gtk_shortcut_set_arguments(shortcut, arg);
    return shortcut;
}


/* Begin - GtkTreeView multiple selection drag support */

static gint pending_event = 0;
static GdkModifierType modifiers = (GDK_CONTROL_MASK | GDK_SHIFT_MASK);

gboolean tree_view_select_func (GtkTreeSelection *selection,
                                GtkTreeModel *model,
                                GtkTreePath *path,
                                gboolean path_currently_selected,
                                gpointer user_data)
{
    return (pending_event < 1);
}

void on_tree_view_pressed_event (GtkGestureClick *gesture,
                                 gint n_press,
                                 gdouble x,
                                 gdouble y,
                                 gpointer treeview)
{
    g_autoptr(GtkTreePath) path;
    gtk_tree_view_get_path_at_pos(treeview, x, y, &path, NULL, NULL, NULL);
    if (!path)
        return;
    GtkTreeSelection *selection = gtk_tree_view_get_selection(treeview);
    gint selected_rows = gtk_tree_selection_count_selected_rows(selection);
    gboolean selected = gtk_tree_selection_path_is_selected(selection, path);
    GdkEventSequence *sequence = gtk_gesture_get_last_updated_sequence(GTK_GESTURE(gesture));
    GdkEvent *event = gtk_gesture_get_last_event(GTK_GESTURE(gesture), sequence);
    gboolean modified = (gdk_event_get_modifier_state(event) & modifiers) != 0;
    gboolean pending = (selected && !modified && selected_rows > 1 && pending_event != -1);
    pending_event = pending ? pending_event + 1 : 0;
    return;
}

void on_tree_view_released_event (GtkGestureClick *gesture,
                                 gint n_press,
                                 gdouble x,
                                 gdouble y,
                                 gpointer treeview)
{
    g_autoptr(GtkTreePath) path;
    gtk_tree_view_get_path_at_pos(treeview, x, y, &path, NULL, NULL, NULL);
    if (!path)
        return;
    GtkTreeSelection *selection = gtk_tree_view_get_selection(treeview);
    if (gtk_tree_selection_path_is_selected(selection, path) && pending_event > 0) {
        pending_event = -1;
        gtk_tree_selection_unselect_all(selection);
        /* XXX : Why is path off by one here? */
        gtk_tree_path_prev(path);
        gtk_tree_selection_select_path(selection, path);
    } else {
        pending_event = 0;
    }
    return;
}

/**
 * font_manager_tree_view_setup_drag_selection:
 * @treeview:       #GtkTreeView
 *
 * Add support for multiple selection drags to @treeview.
 *
 * Returns: (transfer none): The #GtkGesture added to @treeview.
 */
GtkGesture * font_manager_tree_view_setup_drag_selection (GtkTreeView *treeview) {
    GtkGesture *gesture = gtk_gesture_click_new();
    gtk_gesture_single_set_touch_only(GTK_GESTURE_SINGLE(gesture), FALSE);
    gtk_gesture_single_set_exclusive(GTK_GESTURE_SINGLE(gesture), TRUE);
    g_signal_connect(gesture, "pressed", G_CALLBACK(on_tree_view_pressed_event), treeview);
    g_signal_connect(gesture, "released", G_CALLBACK(on_tree_view_released_event), treeview);
    gtk_event_controller_set_propagation_phase(GTK_EVENT_CONTROLLER(gesture), GTK_PHASE_CAPTURE);
    gtk_widget_add_controller(GTK_WIDGET(treeview), GTK_EVENT_CONTROLLER(gesture));
    GtkTreeSelection *selection = gtk_tree_view_get_selection(treeview);
    gtk_tree_selection_set_select_function(selection, tree_view_select_func, NULL, NULL);
    return gesture;
}

/* End - GtkTreeView multiple selection drag support */

