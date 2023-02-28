/* font-manager-place-holder.c
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

#include "font-manager-place-holder.h"

/**
 * SECTION: font-manager-place-holder
 * @short_description: Place holder widget
 * @title: Place Holder
 * @include: font-manager-place-holder.h
 *
 * Widget intended to display a message in an empty area.
 */

struct _FontManagerPlaceHolder
{
    GtkWidget   parent_instance;

    GtkWidget   *icon;
    GtkWidget   *title;
    GtkWidget   *subtitle;
    GtkWidget   *message;
};

G_DEFINE_TYPE(FontManagerPlaceHolder, font_manager_place_holder, GTK_TYPE_WIDGET)

enum
{
    PROP_RESERVED,
    PROP_ICON_NAME,
    PROP_TITLE,
    PROP_SUBTITLE,
    PROP_MESSAGE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_place_holder_dispose (GObject *gobject)
{
    FontManagerPlaceHolder *self = FONT_MANAGER_PLACE_HOLDER(gobject);
    g_return_if_fail(self != NULL);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_place_holder_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_place_holder_set_label (GtkLabel *_label, const gchar *msg)
{
    gtk_label_set_text(_label, msg);
    gtk_widget_set_visible(GTK_WIDGET(_label), strlen(gtk_label_get_text(_label)) > 0);
    return;
}

static void
font_manager_place_holder_get_property (GObject *gobject,
                                        guint property_id,
                                        GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPlaceHolder *self = FONT_MANAGER_PLACE_HOLDER(gobject);
    g_autofree gchar *icon_name = NULL;
    switch (property_id) {
        case PROP_ICON_NAME:
            g_object_get(gobject, "icon-name", &icon_name, NULL);
            g_value_set_string(value, icon_name);
            break;
        case PROP_TITLE:
            g_value_set_string(value, gtk_label_get_text(GTK_LABEL(self->title)));
            break;
        case PROP_SUBTITLE:
            g_value_set_string(value, gtk_label_get_text(GTK_LABEL(self->subtitle)));
            break;
        case PROP_MESSAGE:
            g_value_set_string(value, gtk_label_get_text(GTK_LABEL(self->message)));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_place_holder_set_property (GObject *gobject,
                                        guint property_id,
                                        const GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPlaceHolder *self = FONT_MANAGER_PLACE_HOLDER(gobject);
    const gchar *val = g_value_get_string(value);
    switch (property_id) {
        case PROP_ICON_NAME:
            gtk_image_set_from_icon_name(GTK_IMAGE(self->icon), val);
            break;
        case PROP_TITLE:
            font_manager_place_holder_set_label(GTK_LABEL(self->title), val);
            break;
        case PROP_SUBTITLE:
            font_manager_place_holder_set_label(GTK_LABEL(self->subtitle), val);
            break;
        case PROP_MESSAGE:
            font_manager_place_holder_set_label(GTK_LABEL(self->message), val);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_place_holder_class_init (FontManagerPlaceHolderClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_place_holder_dispose;
    object_class->get_property = font_manager_place_holder_get_property;
    object_class->set_property = font_manager_place_holder_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);

    /**
     * FontManagerPlaceHolder:icon-name:
     *
     * Named icon to display in center of place holder.
     */
    obj_properties[PROP_ICON_NAME] = g_param_spec_string("icon-name",
                                                         NULL,
                                                         "Named icon to display",
                                                         NULL,
                                                         G_PARAM_STATIC_STRINGS |
                                                         G_PARAM_READWRITE);

    /**
     * FontManagerPlaceHolder:title:
     *
     * Text to display as the title beneath icon.
     */
    obj_properties[PROP_TITLE] = g_param_spec_string("title",
                                                      NULL,
                                                      "Title to display under icon",
                                                      NULL,
                                                      G_PARAM_STATIC_STRINGS |
                                                      G_PARAM_READWRITE);

    /**
     * FontManagerPlaceHolder:subtitle:
     *
     * Text to display as a subtitle beneath icon.
     */
    obj_properties[PROP_SUBTITLE] = g_param_spec_string("subtitle",
                                                        NULL,
                                                        "Subtitle to display under icon",
                                                        NULL,
                                                        G_PARAM_STATIC_STRINGS |
                                                        G_PARAM_READWRITE);

    /**
     * FontManagerPlaceHolder:message:
     *
     * Message to display beneath icon.
     */
    obj_properties[PROP_MESSAGE] = g_param_spec_string("message",
                                                      NULL,
                                                      "Text to display under icon",
                                                      NULL,
                                                      G_PARAM_STATIC_STRINGS |
                                                      G_PARAM_READWRITE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
set_title_attributes (GtkWidget *widget)
{
    PangoAttrList *attrs = pango_attr_list_new();
    pango_attr_list_insert(attrs, pango_attr_weight_new(PANGO_WEIGHT_BOLD));
    pango_attr_list_insert(attrs, pango_attr_scale_new(PANGO_SCALE_XX_LARGE));
    gtk_label_set_attributes(GTK_LABEL(widget), attrs);
    pango_attr_list_unref(attrs);
    return;
}

static void
set_subtitle_attributes (GtkWidget *widget)
{
    PangoAttrList *attrs = pango_attr_list_new();
    pango_attr_list_insert(attrs, pango_attr_scale_new(PANGO_SCALE_LARGE));
    gtk_label_set_attributes(GTK_LABEL(widget), attrs);
    pango_attr_list_unref(attrs);
    return;
}

static void
set_message_attributes (GtkWidget *widget)
{
    PangoAttrList *attrs = pango_attr_list_new();
    pango_attr_list_insert(attrs, pango_attr_scale_new(PANGO_SCALE_X_LARGE));
    gtk_label_set_attributes(GTK_LABEL(widget), attrs);
    pango_attr_list_unref(attrs);
    return;
}

static void
insert_label (GtkBox *box, GtkWidget *widget)
{
    gtk_widget_set_opacity(widget, 0.90);
    gtk_widget_set_sensitive(widget, FALSE);
    gtk_widget_set_halign(widget, GTK_ALIGN_CENTER);
    gtk_widget_set_valign(widget, GTK_ALIGN_START);
    gtk_widget_set_margin_bottom(widget, FONT_MANAGER_DEFAULT_MARGIN * 3);
    gtk_label_set_justify(GTK_LABEL(widget), GTK_JUSTIFY_CENTER);
    gtk_label_set_wrap(GTK_LABEL(widget), TRUE);
    gtk_box_append(GTK_BOX(box), widget);
    return;
}

static void
font_manager_place_holder_init (FontManagerPlaceHolder *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_set_opacity(GTK_WIDGET(self), 0.75);
    self->icon = gtk_image_new();
    gtk_image_set_pixel_size(GTK_IMAGE(self->icon), 96);
    self->title = gtk_label_new(NULL);
    set_title_attributes(self->title);
    self->subtitle = gtk_label_new(NULL);
    set_subtitle_attributes(self->subtitle);
    self->message = gtk_label_new(NULL);
    set_message_attributes(self->message);
    gtk_widget_set_halign(GTK_WIDGET(self->icon), GTK_ALIGN_CENTER);
    gtk_widget_set_valign(GTK_WIDGET(self->icon), GTK_ALIGN_END);
    gtk_widget_set_opacity(self->icon, 0.25);
    gtk_widget_set_sensitive(self->icon, FALSE);
    GtkWidget *scrolled_window = gtk_scrolled_window_new();
    GtkWidget *bbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, FONT_MANAGER_DEFAULT_MARGIN * 3);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, FONT_MANAGER_DEFAULT_MARGIN);
    gtk_box_prepend(GTK_BOX(bbox), self->icon);
    gtk_box_append(GTK_BOX(bbox), box);
    insert_label(GTK_BOX(box), self->title);
    insert_label(GTK_BOX(box), self->subtitle);
    insert_label(GTK_BOX(box), self->message);
    gtk_widget_set_margin_bottom(box, FONT_MANAGER_DEFAULT_MARGIN * 4);
    gtk_widget_set_margin_top(box, FONT_MANAGER_DEFAULT_MARGIN * 4);
    font_manager_widget_set_margin(bbox, FONT_MANAGER_DEFAULT_MARGIN * 4);
    font_manager_widget_set_expand(self->icon, TRUE);
    font_manager_widget_set_expand(box, TRUE);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scrolled_window), bbox);
    gtk_widget_set_parent(scrolled_window, GTK_WIDGET(self));
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerPlaceHoler");
    return;
}

/**
 * font_manager_place_holder_new:
 * @title: (nullable):      Title to display in placeholder
 * @subtitle: (nullable):   Subtitle to display in placeholder
 * @message: (nullable):    Message to display in placeholder
 * @icon_name: (nullable):  Named icon to use in placeholder
 *
 * Returns: (transfer full): A newly created #FontManagerPlaceHolder.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_place_holder_new (const gchar *title,
                               const gchar *subtitle,
                               const gchar *message,
                               const gchar *icon_name)
{
    return g_object_new(FONT_MANAGER_TYPE_PLACE_HOLDER,
                        "icon-name", icon_name,
                        "title", title,
                        "subtitle", subtitle,
                        "message", message,
                        NULL);
}
