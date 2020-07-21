/* font-manager-preview-controls.c
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

#include "font-manager-preview-controls.h"

/**
 * SECTION: font-manager-preview-controls
 * @short_description: Font preview controls
 * @title: FontManagerPreviewControls
 * @include: font-manager-preview-controls.h
 *
 * Widget which provides controls for setting preview text justification,
 * resetting the preview back to its default state and displays a description
 * of the current font.
 */

struct _FontManagerPreviewControls
{
    GtkBox parent_instance;

    GtkWidget *description;
    GtkWidget *undo_button;

    GtkJustification justification;
};

G_DEFINE_TYPE(FontManagerPreviewControls, font_manager_preview_controls, GTK_TYPE_BOX)

enum
{
    EDIT_TOGGLED,
    UNDO_CLICKED,
    N_SIGNALS
};

enum
{
    PROP_RESERVED,
    PROP_DESCRIPTION,
    PROP_JUSTIFICATION,
    PROP_UNDO_AVAILABLE,
    N_PROPERTIES
};

static guint signals[N_SIGNALS];
static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static const struct
{
    const gchar *name;
    const gchar *tooltip_text;
    const gchar *icon_name;
    const GtkJustification justification;
}
JustificationControls [] =
{
    {
        "left",
        N_("Left Aligned"),
        "format-justify-left-symbolic",
        GTK_JUSTIFY_LEFT
    },
    {
        "center",
        N_("Centered"),
        "format-justify-center-symbolic",
        GTK_JUSTIFY_CENTER
    },
    {
        "fill",
        N_("Fill"),
        "format-justify-fill-symbolic",
        GTK_JUSTIFY_FILL
    },
    {
        "right",
        N_("Right Aligned"),
        "format-justify-right-symbolic",
        GTK_JUSTIFY_RIGHT
    }
};

static void
font_manager_preview_controls_get_property (GObject *gobject,
                                            guint property_id,
                                            GValue *value,
                                            GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewControls *self = FONT_MANAGER_PREVIEW_CONTROLS(gobject);
    switch (property_id) {
        case PROP_DESCRIPTION:
            g_value_set_string(value, gtk_label_get_text(GTK_LABEL(self->description)));
            break;
        case PROP_UNDO_AVAILABLE:
            g_value_set_boolean(value, gtk_widget_get_sensitive(self->undo_button));
            break;
        case PROP_JUSTIFICATION:
            g_value_set_enum(value, (gint) self->justification);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preview_controls_set_property (GObject *gobject,
                                            guint property_id,
                                            const GValue *value,
                                            GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewControls *self = FONT_MANAGER_PREVIEW_CONTROLS(gobject);
    switch (property_id) {
        case PROP_DESCRIPTION:
            gtk_label_set_text(GTK_LABEL(self->description), g_value_get_string(value));
            break;
        case PROP_UNDO_AVAILABLE:
            gtk_widget_set_sensitive(self->undo_button, g_value_get_boolean(value));
            break;
        case PROP_JUSTIFICATION:
            self->justification = (GtkJustification) g_value_get_enum(value);
            static const gchar *justify [4] = { "left", "right", "center", "fill" };
            gpointer toggle = g_object_get_data(gobject, justify[(gint) self->justification]);
            gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(toggle), TRUE);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preview_controls_class_init (FontManagerPreviewControlsClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->get_property = font_manager_preview_controls_get_property;
    object_class->set_property = font_manager_preview_controls_set_property;

    /**
     * FontManagerPreviewControls:description:
     *
     * #PangoFontDescription for currently displayed font.
     */
    obj_properties[PROP_DESCRIPTION] = g_param_spec_string("description",
                                                           NULL,
                                                           "Description of font being displayed",
                                                           NULL,
                                                           G_PARAM_STATIC_STRINGS |
                                                           G_PARAM_READWRITE);

    /**
     * FontManagerPreviewControls:undo-available:
     *
     * Whether the undo button should be available or not.
     */
    obj_properties[PROP_UNDO_AVAILABLE] = g_param_spec_boolean("undo-available",
                                                               NULL,
                                                               "Whether the undo button should be available",
                                                               FALSE,
                                                               G_PARAM_STATIC_STRINGS |
                                                               G_PARAM_READWRITE);

    /**
     * FontManagerPreviewControls:justification:
     *
     * Preview text justification.
     */
     obj_properties[PROP_JUSTIFICATION] = g_param_spec_enum("justification",
                                                            NULL,
                                                            "Preview text justification.",
                                                            GTK_TYPE_JUSTIFICATION,
                                                            GTK_JUSTIFY_CENTER,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE |
                                                            G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewControls:edit-toggled:
     *
     * Emitted whenever the edit button has been toggled.
     */
    signals[EDIT_TOGGLED] = g_signal_new("edit-toggled",
                                         FONT_MANAGER_TYPE_PREVIEW_CONTROLS,
                                         G_SIGNAL_RUN_FIRST,
                                         0,
                                         NULL,
                                         NULL,
                                         NULL,
                                         G_TYPE_NONE,
                                         1,
                                         G_TYPE_BOOLEAN);

    /**
     * FontManagerPreviewControls:undo-clicked:
     *
     * Emitted whenever the undo button has been clicked.
     */
    signals[UNDO_CLICKED] = g_signal_new("undo-clicked",
                                         FONT_MANAGER_TYPE_PREVIEW_CONTROLS,
                                         G_SIGNAL_RUN_FIRST,
                                         0,
                                         NULL,
                                         NULL,
                                         NULL,
                                         G_TYPE_NONE,
                                         0);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
on_justification_set (FontManagerPreviewControls *self, GtkRadioButton *button)
{
    if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(button))) {
        int index = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(button), "index"));
        GtkJustification justification = JustificationControls[index].justification;
        self->justification = justification;
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_JUSTIFICATION]);
    }
    return;
}

static void
on_edit_toggled (FontManagerPreviewControls *self, GtkToggleButton *button)
{
    gboolean active = gtk_toggle_button_get_active(button);
    g_signal_emit(self, signals[EDIT_TOGGLED], 0, active);
    return;
}

static void
on_undo_clicked (FontManagerPreviewControls *self, GtkButton *button)
{
    g_signal_emit(self, signals[UNDO_CLICKED], 0);
    return;
}

static void
set_start_widget (FontManagerPreviewControls *self)
{
    g_return_if_fail(self != NULL);
    GtkWidget *start = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 2);
    GtkWidget *last = NULL;
    for (gint i = 0; i < G_N_ELEMENTS(JustificationControls); i++) {
        GtkWidget *widget = gtk_radio_button_new_from_widget(GTK_RADIO_BUTTON(last));
        GtkWidget *icon = gtk_image_new_from_icon_name(JustificationControls[i].icon_name, GTK_ICON_SIZE_SMALL_TOOLBAR);
        gtk_button_set_image(GTK_BUTTON(widget), icon);
        g_object_set(G_OBJECT(widget), "draw-indicator", FALSE, NULL);
        gtk_button_set_relief(GTK_BUTTON(widget), GTK_RELIEF_NONE);
        gtk_widget_set_tooltip_text(widget, gettext(JustificationControls[i].tooltip_text));
        gboolean active = (JustificationControls[i].justification == GTK_JUSTIFY_CENTER);
        gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(widget), active);
        g_object_set_data(G_OBJECT(widget), "index", GINT_TO_POINTER(i));
        g_signal_connect_swapped(widget, "toggled", G_CALLBACK(on_justification_set), self);
        g_object_set_data(G_OBJECT(self), JustificationControls[i].name, widget);
        gtk_box_pack_start(GTK_BOX(start), widget, FALSE, FALSE, 0);
        last = widget;
    }
    font_manager_widget_set_margin(start, FONT_MANAGER_MIN_MARGIN);
    gtk_box_pack_start(GTK_BOX(self), start, FALSE, FALSE, 0);
    gtk_widget_show_all(start);
    return;
}

static void
set_center_widget (FontManagerPreviewControls *self)
{
    g_return_if_fail(self != NULL);
    self->description = gtk_label_new("<PangoFontDescription>");
    GtkStyleContext *ctx = gtk_widget_get_style_context(self->description);
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_DIM_LABEL);
    gtk_box_set_center_widget(GTK_BOX(self), self->description);
    gtk_widget_show(self->description);
    return;
}

static void
set_end_widget (FontManagerPreviewControls *self)
{
    GtkWidget *end = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 2);
    GtkWidget *edit = gtk_toggle_button_new();
    GtkWidget *edit_icon = gtk_image_new_from_icon_name("document-edit-symbolic", GTK_ICON_SIZE_SMALL_TOOLBAR);
    self->undo_button = gtk_button_new();
    GtkWidget *undo_icon = gtk_image_new_from_icon_name("edit-undo-symbolic", GTK_ICON_SIZE_SMALL_TOOLBAR);
    gtk_button_set_image(GTK_BUTTON(edit), edit_icon);
    gtk_button_set_image(GTK_BUTTON(self->undo_button), undo_icon);
    gtk_widget_set_sensitive(self->undo_button, FALSE);
    gtk_button_set_relief(GTK_BUTTON(edit), GTK_RELIEF_NONE);
    gtk_button_set_relief(GTK_BUTTON(self->undo_button), GTK_RELIEF_NONE);
    gtk_widget_set_tooltip_text(edit, _("Edit preview text"));
    gtk_widget_set_tooltip_text(self->undo_button, _("Undo changes"));
    font_manager_widget_set_margin(end, FONT_MANAGER_MIN_MARGIN);
    g_signal_connect_swapped(edit, "toggled", G_CALLBACK(on_edit_toggled), self);
    g_signal_connect_swapped(self->undo_button, "clicked", G_CALLBACK(on_undo_clicked), self);
    gtk_box_pack_end(GTK_BOX(end), edit, FALSE, FALSE, 0);
    gtk_box_pack_end(GTK_BOX(end), self->undo_button, FALSE, FALSE, 0);
    gtk_widget_show_all(end);
    gtk_box_pack_end(GTK_BOX(self), end, FALSE, FALSE, 0);
    return;
}

static void
font_manager_preview_controls_init (FontManagerPreviewControls *self)
{
    g_return_if_fail(self != NULL);
    set_start_widget(self);
    set_center_widget(self);
    set_end_widget(self);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(self));
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_VIEW);
    gtk_widget_set_valign(GTK_WIDGET(self), GTK_ALIGN_START);
    gtk_widget_set_hexpand(GTK_WIDGET(self), TRUE);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerPreviewControls");
    return;
}

/**
 * font_manager_preview_controls_new:
 *
 * Returns: (transfer full): A newly created #FontManagerPreviewControls.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_preview_controls_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_PREVIEW_CONTROLS, NULL);
}
