/* font-manager-preview-controls.c
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

#include "font-manager-preview-controls.h"

/**
 * SECTION: font-manager-preview-controls
 * @short_description: Font preview controls
 * @title: FontManagerPreviewControls
 * @include: font-manager-preview-controls.h
 *
 * Widget which provides controls for setting preview text justification,
 * enabling editing, resetting the preview back to its default state and
 * also displays a description of the current font.
 */

struct _FontManagerPreviewControls
{
    GtkWidget parent_instance;

    GtkWidget *description;
    GtkWidget *undo_button;

    GtkJustification justification;
};

G_DEFINE_TYPE(FontManagerPreviewControls, font_manager_preview_controls, GTK_TYPE_WIDGET)

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
font_manager_preview_controls_dispose (GObject *gobject)
{
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_preview_controls_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_preview_controls_get_property (GObject *gobject,
                                            guint property_id,
                                            GValue *value,
                                            GParamSpec *pspec)
{
    FontManagerPreviewControls *self = FONT_MANAGER_PREVIEW_CONTROLS(gobject);
    g_return_if_fail(self != NULL);
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
    FontManagerPreviewControls *self = FONT_MANAGER_PREVIEW_CONTROLS(gobject);
    g_return_if_fail(self != NULL);
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
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_preview_controls_dispose;
    object_class->get_property = font_manager_preview_controls_get_property;
    object_class->set_property = font_manager_preview_controls_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_CENTER_LAYOUT);
    gtk_widget_class_set_css_name(widget_class, "FontManagerPreviewControls");

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
on_justification_set (FontManagerPreviewControls *self, GtkToggleButton *button)
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
set_start_widget (FontManagerPreviewControls *self, GtkCenterLayout *layout)
{
    g_return_if_fail(self != NULL);
    GtkWidget *start = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 2);
    GtkWidget *last = NULL;
    for (gint i = 0; i < G_N_ELEMENTS(JustificationControls); i++) {
        GtkWidget *widget = gtk_toggle_button_new();
        gtk_toggle_button_set_group(GTK_TOGGLE_BUTTON(widget), GTK_TOGGLE_BUTTON(last));
        GtkWidget *icon = gtk_image_new_from_icon_name(JustificationControls[i].icon_name);
        gtk_button_set_child(GTK_BUTTON(widget), icon);
        gtk_button_set_has_frame(GTK_BUTTON(widget), FALSE);
        gtk_widget_set_tooltip_text(widget, gettext(JustificationControls[i].tooltip_text));
        gtk_box_append(GTK_BOX(start), widget);
        gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(widget), (i == 1));
        g_object_set_data(G_OBJECT(widget), "index", GINT_TO_POINTER(i));
        g_signal_connect_swapped(widget, "toggled", G_CALLBACK(on_justification_set), self);
        g_object_set_data(G_OBJECT(self), JustificationControls[i].name, widget);
        last = widget;
    }
    font_manager_widget_set_margin(start, FONT_MANAGER_MIN_MARGIN);
    gtk_widget_set_parent(start, GTK_WIDGET(self));
    gtk_center_layout_set_start_widget(layout, start);
    return;
}

static void
set_center_widget (FontManagerPreviewControls *self, GtkCenterLayout *layout)
{
    g_return_if_fail(self != NULL);
    self->description = gtk_label_new("<PangoFontDescription>");
    gtk_widget_add_css_class(self->description, FONT_MANAGER_STYLE_CLASS_DIM_LABEL);
    gtk_widget_set_parent(self->description, GTK_WIDGET(self));
    gtk_center_layout_set_center_widget(layout, self->description);
    return;
}

static void
set_end_widget (FontManagerPreviewControls *self, GtkCenterLayout *layout)
{
    GtkWidget *end = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 2);
    GtkWidget *edit = gtk_toggle_button_new();
    GtkWidget *edit_icon = gtk_image_new_from_icon_name("document-edit-symbolic");
    self->undo_button = gtk_button_new();
    GtkWidget *undo_icon = gtk_image_new_from_icon_name("edit-undo-symbolic");
    gtk_button_set_child(GTK_BUTTON(edit), edit_icon);
    gtk_button_set_child(GTK_BUTTON(self->undo_button), undo_icon);
    gtk_widget_set_sensitive(self->undo_button, FALSE);
    gtk_button_set_has_frame(GTK_BUTTON(edit), FALSE);
    gtk_button_set_has_frame(GTK_BUTTON(self->undo_button), FALSE);
    gtk_widget_set_tooltip_text(edit, _("Edit preview text"));
    gtk_widget_set_tooltip_text(self->undo_button, _("Undo changes"));
    gtk_box_append(GTK_BOX(end), edit);
    gtk_box_append(GTK_BOX(end), self->undo_button);
    gtk_widget_set_parent(end, GTK_WIDGET(self));
    gtk_center_layout_set_end_widget(layout, end);
    font_manager_widget_set_margin(end, FONT_MANAGER_MIN_MARGIN);
    g_signal_connect_swapped(edit, "toggled", G_CALLBACK(on_edit_toggled), self);
    g_signal_connect_swapped(self->undo_button, "clicked", G_CALLBACK(on_undo_clicked), self);
    return;
}

static void
font_manager_preview_controls_init (FontManagerPreviewControls *self)
{
    GtkLayoutManager *layout = gtk_widget_get_layout_manager(GTK_WIDGET(self));
    set_start_widget(self, GTK_CENTER_LAYOUT(layout));
    set_center_widget(self, GTK_CENTER_LAYOUT(layout));
    set_end_widget(self, GTK_CENTER_LAYOUT(layout));
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
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
