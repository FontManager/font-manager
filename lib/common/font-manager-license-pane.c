/* font-manager-license-pane.c
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

#include "font-manager-license-pane.h"

/**
 * SECTION: font-manager-license-pane
 * @short_description: Font licensing details
 * @title: License Pane
 * @include: font-manager-license-pane.h
 *
 * Widget which displays embedded or detected font licensing data.
 */

struct _FontManagerLicensePane
{
    GtkEventBox   parent_instance;

    gint        _fsType;
    GtkWidget   *fsType;
    GtkWidget   *license_data;
    GtkWidget   *license_url;
    GtkWidget   *placeholder;

};

G_DEFINE_TYPE(FontManagerLicensePane, font_manager_license_pane, GTK_TYPE_EVENT_BOX)

enum
{
    PROP_RESERVED,
    PROP_FSTYPE,
    PROP_LICENSE_DATA,
    PROP_LICENSE_URL,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_license_pane_get_property (GObject *gobject,
                                        guint property_id,
                                        GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerLicensePane *self = FONT_MANAGER_LICENSE_PANE(gobject);
    g_autofree gchar *data = NULL;
    switch (property_id) {
        case PROP_FSTYPE:
            g_value_set_enum(value, self->_fsType);
            break;
        case PROP_LICENSE_DATA:
            data = font_manager_license_pane_get_license_data(self);
            g_value_set_string(value, data);
            break;
        case PROP_LICENSE_URL:
            data = font_manager_license_pane_get_license_url(self);
            g_value_set_string(value, data);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_license_pane_set_property (GObject *gobject,
                                        guint property_id,
                                        const GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerLicensePane *self = FONT_MANAGER_LICENSE_PANE(gobject);
    switch (property_id) {
        case PROP_FSTYPE:
            font_manager_license_pane_set_fsType(self, g_value_get_int(value));
            break;
        case PROP_LICENSE_DATA:
            font_manager_license_pane_set_license_data(self, g_value_get_string(value));
            break;
        case PROP_LICENSE_URL:
            font_manager_license_pane_set_license_url(self, g_value_get_string(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_license_pane_class_init (FontManagerLicensePaneClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->get_property = font_manager_license_pane_get_property;
    object_class->set_property = font_manager_license_pane_set_property;

    /**
     * FontManagerLicensePane:fstype:
     *
     * Font embedding information
     */
    obj_properties[PROP_FSTYPE] = g_param_spec_int("fstype",
                                                    NULL,
                                                    "Font embedding information",
                                                    G_MININT, G_MAXINT, 0,
                                                    G_PARAM_STATIC_STRINGS |
                                                    G_PARAM_READWRITE |
                                                    G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerLicensePane:license-data:
     *
     * Embedded or detected license text
     */
    obj_properties[PROP_LICENSE_DATA] = g_param_spec_string("license-data",
                                                            NULL,
                                                            "Embedded or detected license text",
                                                            NULL,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE |
                                                            G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerLicensePane:license-url:
     *
     * Embedded or detected license url
     */
    obj_properties[PROP_LICENSE_URL] = g_param_spec_string("license-url",
                                                            NULL,
                                                            "Embedded or detected license url",
                                                            NULL,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE |
                                                            G_PARAM_EXPLICIT_NOTIFY);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static gboolean
on_event (GtkWidget *widget, GdkEvent *event, G_GNUC_UNUSED gpointer user_data)
{
    g_return_val_if_fail(widget != NULL, GDK_EVENT_PROPAGATE);
    g_return_val_if_fail(event != NULL, GDK_EVENT_PROPAGATE);
    if (event->type == GDK_SCROLL)
        return GDK_EVENT_PROPAGATE;
    GdkWindow *text_window = gtk_text_view_get_window(GTK_TEXT_VIEW(widget), GTK_TEXT_WINDOW_TEXT);
    gdk_window_set_cursor(text_window, NULL);
    return GDK_EVENT_STOP;
}

static void
font_manager_license_pane_init (FontManagerLicensePane *self)
{
    g_return_if_fail(self != NULL);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(self));
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerLicensePane");
    self->fsType = gtk_label_new(NULL);
    PangoAttrList *attrs = pango_attr_list_new();
    PangoAttribute *attr = pango_attr_weight_new(PANGO_WEIGHT_BOLD);
    pango_attr_list_insert(attrs, attr);
    gtk_label_set_attributes(GTK_LABEL(self->fsType), attrs);
    g_clear_pointer(&attrs, pango_attr_list_unref);
    gtk_widget_set_opacity(self->fsType, 0.55);
    const gchar *msg = _("File does not contain license information.");
    self->placeholder = font_manager_place_holder_new(NULL, NULL, msg, "dialog-question-symbolic");
    font_manager_widget_set_expand(self->placeholder, TRUE);
    font_manager_widget_set_margin(self->placeholder, FONT_MANAGER_DEFAULT_MARGIN * 4);
    gtk_widget_set_halign(self->placeholder, GTK_ALIGN_CENTER);
    gtk_widget_set_valign(self->placeholder, GTK_ALIGN_START);
    self->license_data = gtk_text_view_new();
    g_signal_connect(self->license_data, "event", G_CALLBACK(on_event), NULL);
    self->license_url = gtk_link_button_new("");
    GtkWidget *overlay = gtk_overlay_new();
    gtk_overlay_add_overlay(GTK_OVERLAY(overlay), self->placeholder);
    gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(self->license_data), GTK_WRAP_WORD_CHAR);
    gtk_text_view_set_editable(GTK_TEXT_VIEW(self->license_data), FALSE);
    font_manager_widget_set_margin(self->fsType, FONT_MANAGER_DEFAULT_MARGIN * 2);
    font_manager_widget_set_margin(self->license_url, FONT_MANAGER_DEFAULT_MARGIN * 1.25);
    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scroll), self->license_data);
    font_manager_widget_set_expand(scroll, TRUE);
    font_manager_widget_set_margin(self->license_data, FONT_MANAGER_DEFAULT_MARGIN * 2);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    gtk_box_pack_start(GTK_BOX(box), self->fsType, FALSE, FALSE, 0);
    gtk_container_add(GTK_CONTAINER(overlay), scroll);
    gtk_box_pack_start(GTK_BOX(box), overlay, TRUE, TRUE, 0);
    gtk_box_pack_end(GTK_BOX(box), self->license_url, FALSE, FALSE, 0);
    gtk_container_add(GTK_CONTAINER(self), box);
    gtk_widget_show(scroll);
    gtk_widget_show(self->fsType);
    gtk_widget_show(self->license_data);
    gtk_widget_show(self->license_url);
    gtk_widget_show(self->placeholder);
    gtk_widget_show(overlay);
    gtk_widget_show(box);
    return;
}

/**
 * font_manager_license_pane_get_fsType:
 * @self:       #FontManagerLicensePane
 *
 * Returns: #FontManagerfsType
 */
gint
font_manager_license_pane_get_fsType (FontManagerLicensePane *self)
{
    g_return_val_if_fail(self != NULL, 0);
    return self->_fsType;
}

/**
 * font_manager_license_pane_get_license_data:
 * @self:       #FontManagerLicensePane
 *
 * Returns: (transfer none) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_license_pane_get_license_data (FontManagerLicensePane *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->license_data));
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    return gtk_text_buffer_get_text(buffer, &start, &end, FALSE);
}

/**
 * font_manager_license_pane_get_license_url:
 * @self:       #FontManagerLicensePane
 *
 * Returns: (transfer none) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_license_pane_get_license_url (FontManagerLicensePane *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return g_strdup(gtk_link_button_get_uri(GTK_LINK_BUTTON(self->license_url)));
}

/**
 * font_manager_license_pane_set_fsType:
 * @self:           #FontManagerLicensePane
 * @fstype:         #FontManagerfsType
 */
void
font_manager_license_pane_set_fsType (FontManagerLicensePane *self, gint fstype)
{
    g_return_if_fail(self != NULL);
    self->_fsType = fstype;
    gtk_label_set_label(GTK_LABEL(self->fsType), font_manager_fsType_to_string(fstype));
    return;
}

/**
 * font_manager_license_pane_set_license_data:
 * @self:                       #FontManagerLicensePane
 * @license_data: (nullable):   License data embedded in font file or %NULL
 */
void
font_manager_license_pane_set_license_data (FontManagerLicensePane *self, const gchar *license_data)
{
    g_return_if_fail(self != NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->license_data));
    gtk_text_buffer_set_text(buffer, license_data ? license_data : "", -1);
    gtk_widget_set_visible(self->placeholder, license_data == NULL);
    return;
}

/**
 * font_manager_license_pane_set_license_url:
 * @self:               #FontManagerLicensePane
 * @url: (nullable):    URL to latest version of license or %NULL
 */
void
font_manager_license_pane_set_license_url (FontManagerLicensePane *self, const gchar *url)
{
    g_return_if_fail(self != NULL);
    gtk_button_set_label(GTK_BUTTON(self->license_url), url);
    gtk_link_button_set_uri(GTK_LINK_BUTTON(self->license_url), url ? url : "");
    gtk_widget_set_visible(self->license_url, url != NULL);
    return;
}

/**
 * font_manager_license_pane_new:
 *
 * Returns: (transfer full): A newly created #FontManagerLicensePane.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_license_pane_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_LICENSE_PANE, NULL);
}

