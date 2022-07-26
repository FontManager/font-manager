/* font-manager-license-page.c
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

#include "font-manager-license-page.h"

/**
 * SECTION: font-manager-license-page
 * @short_description: Font licensing details
 * @title: License Pane
 * @include: font-manager-license-page.h
 *
 * Widget which displays embedded or detected font licensing data.
 */

struct _FontManagerLicensePage
{
    GtkWidget   parent_instance;

    gint        _fsType;
    GtkWidget   *fsType;
    GtkWidget   *license_data;
    GtkWidget   *license_url;
    GtkWidget   *placeholder;

};

G_DEFINE_TYPE(FontManagerLicensePage, font_manager_license_page, GTK_TYPE_WIDGET)

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
font_manager_license_page_dispose (GObject *gobject)
{
    FontManagerLicensePage *self = FONT_MANAGER_LICENSE_PAGE(gobject);
    g_return_if_fail(self != NULL);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_license_page_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_license_page_get_property (GObject    *gobject,
                                        guint       property_id,
                                        GValue     *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerLicensePage *self = FONT_MANAGER_LICENSE_PAGE(gobject);
    g_autofree gchar *data = NULL;
    switch (property_id) {
        case PROP_FSTYPE:
            g_value_set_enum(value, self->_fsType);
            break;
        case PROP_LICENSE_DATA:
            data = font_manager_license_page_get_license_data(self);
            g_value_set_string(value, data);
            break;
        case PROP_LICENSE_URL:
            data = font_manager_license_page_get_license_url(self);
            g_value_set_string(value, data);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_license_page_set_property (GObject      *gobject,
                                        guint         property_id,
                                        const GValue *value,
                                        GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerLicensePage *self = FONT_MANAGER_LICENSE_PAGE(gobject);
    switch (property_id) {
        case PROP_FSTYPE:
            font_manager_license_page_set_fsType(self, g_value_get_int(value));
            break;
        case PROP_LICENSE_DATA:
            font_manager_license_page_set_license_data(self, g_value_get_string(value));
            break;
        case PROP_LICENSE_URL:
            font_manager_license_page_set_license_url(self, g_value_get_string(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_license_page_class_init (FontManagerLicensePageClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_license_page_dispose;
    object_class->get_property = font_manager_license_page_get_property;
    object_class->set_property = font_manager_license_page_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);
    gtk_widget_class_set_css_name(widget_class, "FontManagerLicensePage");

    /**
     * FontManagerLicensePage:fstype:
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
     * FontManagerLicensePage:license-data:
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
     * FontManagerLicensePage:license-url:
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

static void
font_manager_license_page_init (FontManagerLicensePage *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerLicensePage");
    self->fsType = gtk_label_new(NULL);
    const gchar *msg = _("File does not contain license information.");
    self->placeholder = font_manager_place_holder_new(NULL, NULL, msg, "dialog-question-symbolic");
    self->license_data = gtk_text_view_new();
    self->license_url = gtk_link_button_new("");
    GtkWidget *overlay = gtk_overlay_new();
    GtkWidget *scroll = gtk_scrolled_window_new();
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    g_autoptr(PangoAttrList) attrs = pango_attr_list_new();
    PangoAttribute *attr = pango_attr_weight_new(PANGO_WEIGHT_BOLD);
    pango_attr_list_insert(attrs, attr);
    gtk_label_set_attributes(GTK_LABEL(self->fsType), attrs);
    gtk_text_view_set_editable(GTK_TEXT_VIEW(self->license_data), FALSE);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(self->license_data), FALSE);
    gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(self->license_data), GTK_WRAP_WORD_CHAR);
    GtkWidget *separator_top = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    GtkWidget *separator_bottom = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_widget_add_css_class(separator_top, "thin-separator");
    gtk_widget_add_css_class(separator_bottom, "thin-separator");
    gtk_widget_set_opacity(separator_top, 0.25);
    gtk_widget_set_opacity(separator_bottom, 0.25);
    gtk_box_prepend(GTK_BOX(box), self->fsType);
    gtk_box_append(GTK_BOX(box), separator_top);
    gtk_box_append(GTK_BOX(box), overlay);
    gtk_box_append(GTK_BOX(box), separator_bottom);
    gtk_box_append(GTK_BOX(box), self->license_url);
    gtk_overlay_set_child(GTK_OVERLAY(overlay), scroll);
    gtk_overlay_add_overlay(GTK_OVERLAY(overlay), self->placeholder);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), self->license_data);
    gtk_widget_set_parent(box, GTK_WIDGET(self));
    gtk_widget_set_opacity(self->fsType, 0.55);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    font_manager_widget_set_expand(scroll, TRUE);
    font_manager_widget_set_margin(separator_top, 0);
    font_manager_widget_set_margin(separator_bottom, 0);
    gtk_widget_set_margin_start(separator_top, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    gtk_widget_set_margin_end(separator_top, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    gtk_widget_set_margin_start(separator_bottom, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    gtk_widget_set_margin_end(separator_bottom, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    font_manager_widget_set_margin(self->fsType, FONT_MANAGER_DEFAULT_MARGIN * 1.25);
    gtk_widget_set_margin_start(self->license_data, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_end(self->license_data, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_hide(self->fsType);
    gtk_widget_hide(self->license_data);
    gtk_widget_hide(self->license_url);
    return;
}

/**
 * font_manager_license_page_get_fsType:
 * @self:       #FontManagerLicensePage
 *
 * Returns: #FontManagerfsType
 */
gint
font_manager_license_page_get_fsType (FontManagerLicensePage *self)
{
    g_return_val_if_fail(self != NULL, 0);
    return self->_fsType;
}

/**
 * font_manager_license_page_get_license_data:
 * @self:       #FontManagerLicensePage
 *
 * Returns: (transfer none) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_license_page_get_license_data (FontManagerLicensePage *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->license_data));
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    return gtk_text_buffer_get_text(buffer, &start, &end, FALSE);
}

/**
 * font_manager_license_page_get_license_url:
 * @self:       #FontManagerLicensePage
 *
 * Returns: (transfer none) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_license_page_get_license_url (FontManagerLicensePage *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return g_strdup(gtk_link_button_get_uri(GTK_LINK_BUTTON(self->license_url)));
}

/**
 * font_manager_license_page_set_fsType:
 * @self:           #FontManagerLicensePage
 * @fstype:         #FontManagerfsType
 */
void
font_manager_license_page_set_fsType (FontManagerLicensePage *self, gint fstype)
{
    g_return_if_fail(self != NULL);
    self->_fsType = fstype;
    gtk_label_set_label(GTK_LABEL(self->fsType), font_manager_fsType_to_string(fstype));
    gtk_widget_set_visible(self->fsType, gtk_widget_get_visible(self->license_data));
    return;
}

/**
 * font_manager_license_page_set_license_data:
 * @self:                       #FontManagerLicensePage
 * @license_data: (nullable):   License data embedded in font file or %NULL
 */
void
font_manager_license_page_set_license_data (FontManagerLicensePage *self,
                                            const gchar            *license_data)
{
    g_return_if_fail(self != NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->license_data));
    g_autofree gchar *license_text = license_data ?
                                     g_strdup_printf("\n%s\n", license_data) :
                                     g_strdup("");
    gtk_text_buffer_set_text(buffer, license_text, -1);
    gtk_widget_set_visible(self->placeholder, license_data == NULL);
    gtk_widget_set_visible(self->license_data, license_data != NULL);
    gtk_widget_set_visible(self->fsType, license_data != NULL);
    const gchar *uri = gtk_link_button_get_uri(GTK_LINK_BUTTON(self->license_url));
    gtk_widget_set_visible(self->license_url, uri != NULL);
    return;
}

/**
 * font_manager_license_page_set_license_url:
 * @self:               #FontManagerLicensePage
 * @url: (nullable):    URL to latest version of license or %NULL
 */
void
font_manager_license_page_set_license_url (FontManagerLicensePage *self,
                                           const gchar            *url)
{
    g_return_if_fail(self != NULL);
    gtk_button_set_label(GTK_BUTTON(self->license_url), url);
    gtk_link_button_set_uri(GTK_LINK_BUTTON(self->license_url), url ? url : "");
    gboolean visible = url != NULL && gtk_widget_get_visible(self->license_data);
    gtk_widget_set_visible(self->license_url, visible);
    return;
}

/**
 * font_manager_license_page_new:
 *
 * Returns: (transfer full): A newly created #FontManagerLicensePage.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_license_page_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_LICENSE_PAGE, NULL);
}

