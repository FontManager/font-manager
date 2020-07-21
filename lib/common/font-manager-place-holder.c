/* font-manager-place-holder.c
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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
 * @title: FontManagerPlaceHolder
 * @include: font-manager-place-holder.h
 *
 * Widget intended to display a message in an empty area.
 */

struct _FontManagerPlaceHolder
{
    GtkEventBox   parent_instance;

    GtkWidget   *icon;
    GtkWidget   *message;
};

G_DEFINE_TYPE(FontManagerPlaceHolder, font_manager_place_holder, GTK_TYPE_EVENT_BOX)

enum
{
    PROP_RESERVED,
    PROP_ICON_NAME,
    PROP_MARKUP,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

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
        case PROP_MARKUP:
            g_value_set_string(value, gtk_label_get_label(GTK_LABEL(self->message)));
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
    switch (property_id) {
        case PROP_ICON_NAME:
            gtk_image_set_from_icon_name(GTK_IMAGE(self->icon), g_value_get_string(value), GTK_ICON_SIZE_DIALOG);
            break;
        case PROP_MARKUP:
            gtk_label_set_markup(GTK_LABEL(self->message), g_value_get_string(value));
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

    object_class->get_property = font_manager_place_holder_get_property;
    object_class->set_property = font_manager_place_holder_set_property;

    /**
     * FontManagerPlaceHolder:icon-name:
     *
     * Named icon to display in center of place holder.
     */
    obj_properties[PROP_ICON_NAME] = g_param_spec_string("icon-name",
                                                         NULL,
                                                         "Named icon to display",
                                                         NULL,
                                                         G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE);

    /**
     * FontManagerPlaceHolder:markup:
     *
     * Markup or plain text to display beneath icon.
     */
    obj_properties[PROP_MARKUP] = g_param_spec_string("message",
                                                      NULL,
                                                      "Text to display under icon",
                                                      NULL,
                                                      G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_place_holder_init (FontManagerPlaceHolder *self)
{
    g_return_if_fail(self != NULL);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(self));
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerPlaceHoler");
    gtk_widget_set_opacity(GTK_WIDGET(self), 0.75);
    self->icon = gtk_image_new();
    self->message = gtk_label_new(NULL);
    gtk_widget_set_halign(GTK_WIDGET(self->icon), GTK_ALIGN_CENTER);
    gtk_widget_set_valign(GTK_WIDGET(self->icon), GTK_ALIGN_END);
    gtk_widget_set_halign(GTK_WIDGET(self->message), GTK_ALIGN_CENTER);
    gtk_widget_set_valign(GTK_WIDGET(self->message), GTK_ALIGN_START);
    gtk_widget_set_opacity(self->icon, 0.25);
    gtk_widget_set_sensitive(self->icon, FALSE);
    gtk_widget_set_sensitive(self->message, FALSE);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, FONT_MANAGER_DEFAULT_MARGIN * 3);
    gtk_box_pack_start(GTK_BOX(box), self->icon, TRUE, TRUE, 0);
    gtk_box_pack_end(GTK_BOX(box), self->message, TRUE, TRUE, 0);
    gtk_image_set_pixel_size(GTK_IMAGE(self->icon), 64);
    gtk_label_set_justify(GTK_LABEL(self->message), GTK_JUSTIFY_CENTER);
    gtk_label_set_line_wrap(GTK_LABEL(self->message), TRUE);
    font_manager_widget_set_margin(box, FONT_MANAGER_DEFAULT_MARGIN * 4);
    font_manager_widget_set_expand(self->icon, TRUE);
    font_manager_widget_set_expand(self->message, TRUE);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    gtk_widget_show_all(box);
    gtk_container_add(GTK_CONTAINER(self), box);
    return;
}

/**
 * font_manager_place_holder_new:
 * @message: (nullable):    Message to display in placeholder
 * @icon_name: (nullable):  Named icon to use in placeholder
 *
 * Returns: (transfer full): A newly created #FontManagerPlaceHolder.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_place_holder_new (const gchar *message, const gchar *icon_name)
{
    return g_object_new(FONT_MANAGER_TYPE_PLACE_HOLDER, "icon-name", icon_name, "message", message, NULL);
}
