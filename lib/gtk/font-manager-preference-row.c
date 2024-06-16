/* font-manager-preference-row.c
 *
 * Copyright (C) 2020-2023 Jerry Casiano
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

#include "font-manager-preference-row.h"

/**
 * SECTION: font-manager-preference-row
 * @short_description: Preference row widget
 * @title: Preference Row
 * @include: font-manager-preference-row.h
 *
 * Convenience class to allow quickly creating consistent application preference rows.
 */

struct _FontManagerPreferenceRow
{
    GtkWidget parent;

    GtkWidget       *icon;
    GtkWidget       *title;
    GtkWidget       *subtitle;
    GtkWidget       *control;
    GtkWidget       *revealer;
    GtkWidget       *children;
};

G_DEFINE_TYPE(FontManagerPreferenceRow, font_manager_preference_row, GTK_TYPE_WIDGET)

enum
{
    PROP_RESERVED,
    PROP_ICON_NAME,
    PROP_TITLE,
    PROP_SUBTITLE,
    PROP_CONTROL,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_preference_row_dispose (GObject *gobject)
{
    FontManagerPreferenceRow *self = FONT_MANAGER_PREFERENCE_ROW(gobject);
    g_return_if_fail(self != NULL);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_preference_row_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_preference_row_set_label (GtkLabel *_label, const gchar *msg)
{
    gtk_label_set_text(_label, msg);
    gtk_widget_set_visible(GTK_WIDGET(_label), strlen(gtk_label_get_text(_label)) > 0);
    return;
}

static void
font_manager_preference_row_set_icon_name (FontManagerPreferenceRow *self,
                                           const gchar              *icon_name)
{
    gtk_image_set_from_icon_name(GTK_IMAGE(self->icon), icon_name);
    gtk_widget_set_visible(GTK_WIDGET(self->icon), icon_name != NULL);
    return;
}

static void
font_manager_preference_row_update_title_alignment (FontManagerPreferenceRow *self)
{
    gboolean icon_visible = gtk_widget_get_visible(self->icon);
    gboolean subtitle_visible = gtk_widget_get_visible(self->subtitle);
    if (!icon_visible || !subtitle_visible) {
        gtk_widget_set_halign(self->title, GTK_ALIGN_START);
        gtk_widget_set_valign(self->title, GTK_ALIGN_CENTER);
    } else {
        gtk_widget_set_halign(self->title, GTK_ALIGN_START);
        gtk_widget_set_valign(self->title, GTK_ALIGN_END);
    }
    return;
}

static void
font_manager_preference_row_get_property (GObject    *gobject,
                                          guint       property_id,
                                          GValue     *value,
                                          GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreferenceRow *self = FONT_MANAGER_PREFERENCE_ROW(gobject);
    g_autofree gchar *icon_name = NULL;
    switch (property_id) {
        case PROP_ICON_NAME:
            g_value_set_string(value, gtk_image_get_icon_name(GTK_IMAGE(self->icon)));
            break;
        case PROP_TITLE:
            g_value_set_string(value, gtk_label_get_text(GTK_LABEL(self->title)));
            break;
        case PROP_SUBTITLE:
            g_value_set_string(value, gtk_label_get_text(GTK_LABEL(self->subtitle)));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preference_row_set_property (GObject      *gobject,
                                          guint         property_id,
                                          const GValue *value,
                                          GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreferenceRow *self = FONT_MANAGER_PREFERENCE_ROW(gobject);
    gboolean string_type = pspec->value_type == G_TYPE_STRING;
    const gchar *val = string_type ?  g_value_get_string(value) : NULL;
    switch (property_id) {
        case PROP_ICON_NAME:
            font_manager_preference_row_set_icon_name(self, val);
            font_manager_preference_row_update_title_alignment(self);
            break;
        case PROP_TITLE:
            font_manager_preference_row_set_label(GTK_LABEL(self->title), val);
            font_manager_preference_row_update_title_alignment(self);
            break;
        case PROP_SUBTITLE:
            font_manager_preference_row_set_label(GTK_LABEL(self->subtitle), val);
            font_manager_preference_row_update_title_alignment(self);
            break;
        case PROP_CONTROL:
            font_manager_preference_row_set_action_widget(self, g_value_get_object(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preference_row_class_init (FontManagerPreferenceRowClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_preference_row_dispose;
    object_class->get_property = font_manager_preference_row_get_property;
    object_class->set_property = font_manager_preference_row_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);

    /**
     * FontManagerPreferenceRow:icon-name:
     *
     * Named icon to display.
     */

    obj_properties[PROP_ICON_NAME] = g_param_spec_string("icon-name",
                                                         NULL,
                                                         "Named icon to display",
                                                         NULL,
                                                         G_PARAM_STATIC_STRINGS |
                                                         G_PARAM_READWRITE);

    /**
     * FontManagerPreferenceRow:title:
     *
     * Name of preference.
     */

    obj_properties[PROP_TITLE] = g_param_spec_string("title",
                                                      NULL,
                                                      "Preference name",
                                                      NULL,
                                                      G_PARAM_STATIC_STRINGS |
                                                      G_PARAM_READWRITE);

    /**
     * FontManagerPreferenceRow:subtitle:
     *
     * Short description of preference.
     */

    obj_properties[PROP_SUBTITLE] = g_param_spec_string("subtitle",
                                                        NULL,
                                                        "Subtitle to display under title",
                                                        NULL,
                                                        G_PARAM_STATIC_STRINGS |
                                                        G_PARAM_READWRITE);

    /**
     * FontManagerPreferenceRow:action-widget:
     *
     * Widget to control preference state.
     */
    obj_properties[PROP_CONTROL] = g_param_spec_object("action-widget",
                                                       NULL,
                                                       "Widget to control preference state",
                                                       GTK_TYPE_WIDGET,
                                                       G_PARAM_STATIC_STRINGS |
                                                       G_PARAM_WRITABLE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
set_title_attributes (GtkWidget *widget)
{
    PangoAttrList *attrs = pango_attr_list_new();
    pango_attr_list_insert(attrs, pango_attr_scale_new(PANGO_SCALE_MEDIUM));
    gtk_label_set_attributes(GTK_LABEL(widget), attrs);
    pango_attr_list_unref(attrs);
    return;
}

static void
set_subtitle_attributes (GtkWidget *widget)
{
    PangoAttrList *attrs = pango_attr_list_new();
    pango_attr_list_insert(attrs, pango_attr_scale_new(PANGO_SCALE_SMALL));
    gtk_label_set_attributes(GTK_LABEL(widget), attrs);
    gtk_widget_add_css_class(widget, "dim-label");
    pango_attr_list_unref(attrs);
    return;
}

static void
insert_widget (GtkGrid   *grid,
               GtkWidget *widget,
               GtkAlign   halign,
               GtkAlign   valign,
               int        column,
               int        row,
               int        width,
               int        height,
               gboolean   expand)
{
    gtk_widget_set_halign(widget, halign);
    gtk_widget_set_valign(widget, valign);
    font_manager_widget_set_margin(widget, FONT_MANAGER_DEFAULT_MARGIN);
    font_manager_widget_set_expand(widget, expand);
    gtk_grid_attach(grid, widget, column, row, width, height);
    return;
}

static void
font_manager_preference_row_init (FontManagerPreferenceRow *self)
{
    g_return_if_fail(self != NULL);
    GtkWidget *container = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    self->revealer = gtk_revealer_new();
    gtk_revealer_set_transition_duration(GTK_REVEALER(self->revealer), 500);
    GtkWidget *inner_container = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    self->control = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    self->children = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_margin_start(self->children, FONT_MANAGER_DEFAULT_MARGIN * 3);
    gtk_widget_set_margin_end(self->children, FONT_MANAGER_DEFAULT_MARGIN * 3);
    gtk_widget_set_margin_top(self->children, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_bottom(self->children, 0);
    gtk_revealer_set_child(GTK_REVEALER(self->revealer), self->children);
    self->icon = gtk_image_new();
    gtk_image_set_icon_size(GTK_IMAGE(self->icon),  GTK_ICON_SIZE_LARGE);
    self->title = gtk_label_new(NULL);
    set_title_attributes(self->title);
    self->subtitle = gtk_label_new(NULL);
    set_subtitle_attributes(self->subtitle);
    GtkWidget *grid = gtk_grid_new();
    insert_widget(GTK_GRID(grid), self->icon,
                  GTK_ALIGN_CENTER, GTK_ALIGN_CENTER,
                  0, 0, 2, 2, FALSE);
    insert_widget(GTK_GRID(grid), self->title,
                  GTK_ALIGN_START, GTK_ALIGN_END,
                  3, 0, 3, 1, TRUE);
    insert_widget(GTK_GRID(grid), self->subtitle,
                  GTK_ALIGN_START, GTK_ALIGN_START,
                  3, 1, 3, 1, TRUE);
    font_manager_widget_set_margin(self->icon, FONT_MANAGER_DEFAULT_MARGIN * 2);
    font_manager_widget_set_margin(GTK_WIDGET(self), FONT_MANAGER_DEFAULT_MARGIN * 2);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    gtk_box_append(GTK_BOX(inner_container), grid);
    gtk_box_append(GTK_BOX(inner_container), self->control);
    gtk_box_append(GTK_BOX(container), inner_container);
    gtk_box_append(GTK_BOX(container), self->revealer);
    gtk_widget_set_parent(container, GTK_WIDGET(self));
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerPreferenceRow");
    return;
}

/**
 * font_manager_preference_row_get_action_widget:
 * @self:       #FontManagerPreferenceRow
 *
 * Returns: (transfer none) (nullable): The #GtkWidget set using
 * #font_manager_preference_row_get_action_widget or %NULL
 */
GtkWidget *
font_manager_preference_row_get_action_widget (FontManagerPreferenceRow *self)
{
    return gtk_widget_get_first_child(self->control);
}

/**
 * font_manager_preference_row_set_action_widget:
 * @self:                   #FontManagerPreferenceRow
 * @control: (nullable):    #GtkWidget
 *
 * Sets the action widget for @self.
 */
void
font_manager_preference_row_set_action_widget (FontManagerPreferenceRow *self,
                                               GtkWidget *control)
{
    g_return_if_fail(self != NULL);
    GtkWidget *child = gtk_widget_get_first_child(self->control);
    if (child)
        gtk_box_remove(GTK_BOX(self->control), child);
    if (control) {
        font_manager_widget_set_align(control, GTK_ALIGN_CENTER);
        font_manager_widget_set_margin(control, FONT_MANAGER_DEFAULT_MARGIN);
        gtk_box_append(GTK_BOX(self->control), control);
    }
    return;
}

static void
on_state_set (GtkSwitch                *control,
              gboolean                  state,
              FontManagerPreferenceRow *self)
{
    gboolean visible = gtk_switch_get_active(control);
    font_manager_preference_row_set_reveal_child(self, visible);
    return;
}

/**
 * font_manager_preference_row_append_child:
 * @parent:     #FontManagerPreferenceRow
 * @child:      #FontManagerPreferenceRow
 *
 * Appends @child to @parent. Children are typically preferences which are
 * dependent on the parents state and are therefore hidden by default.
 *
 * If the action widget set for @parent is a #GtkSwitch then children will
 * be revealed and concealed automatically when the widget is activated.
 *
 * Otherwise use #font_manager_preference_row_set_reveal_child to control
 * their visibility.
 */
void
font_manager_preference_row_append_child (FontManagerPreferenceRow *parent,
                                          FontManagerPreferenceRow *child)
{
    g_return_if_fail(parent != NULL);
    g_return_if_fail(child != NULL);
    gtk_box_append(GTK_BOX(parent->children), GTK_WIDGET(child));
    font_manager_widget_set_margin(GTK_WIDGET(child), FONT_MANAGER_DEFAULT_MARGIN);
    GtkWidget *control = font_manager_preference_row_get_action_widget(parent);
    if (control && GTK_IS_SWITCH(control))
        g_signal_connect_after(control, "notify::state", G_CALLBACK(on_state_set), parent);
    return;
}

/**
 * font_manager_preference_row_set_reveal_child:
 * @self:       #FontManagerPreferenceRow
 * @visible:    %TRUE to reveal child preferences
 */
void
font_manager_preference_row_set_reveal_child (FontManagerPreferenceRow *self,
                                               gboolean                  visible)
{
    g_return_if_fail(self != NULL);
    gtk_revealer_set_reveal_child(GTK_REVEALER(self->revealer), visible);
    if (visible)
        gtk_widget_set_margin_bottom(GTK_WIDGET(self), 0);
    else
        gtk_widget_set_margin_bottom(GTK_WIDGET(self), FONT_MANAGER_DEFAULT_MARGIN * 2);
    return;
}

/**
 * font_manager_preference_row_new:
 * @title:                          Preference name
 * @subtitle:       (nullable):     Description of preference or %NULL
 * @icon_name:      (nullable):     Icon to display or %NULL
 * @action_widget:  (nullable):     #GtkWidget to control preference state or %NULL
 *
 * Returns: (transfer full): A newly created #FontManagerPreferenceRow.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_preference_row_new (const gchar *title,
                                 const gchar *subtitle,
                                 const gchar *icon_name,
                                 GtkWidget   *action_widget)
{
    return g_object_new(FONT_MANAGER_TYPE_PREFERENCE_ROW,
                        "title", title,
                        "subtitle", subtitle,
                        "icon-name", icon_name,
                        "action-widget", action_widget,
                        NULL);
}

