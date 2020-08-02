/* font-manager-font-scale.c
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

#include "font-manager-font-scale.h"

/**
 * SECTION: font-manager-font-scale
 * @short_description: Font size selection widget
 * @title: Font Scale
 * @include: font-manager-font-scale.h
 *
 * Widget allowing for font size selection through use of a #GtkScale,
 * #GtkSpinButton and two clickable #GtkLabel widgets for quick selection
 * of minimum and maximum sizes.
 */

#define DEFAULT_OPACITY 0.60
#define FOCUSED_OPACITY 0.95
#define MIN_FONT_SIZE FONT_MANAGER_MIN_FONT_SIZE
#define MAX_FONT_SIZE FONT_MANAGER_MAX_FONT_SIZE
#define DEFAULT_PREVIEW_SIZE FONT_MANAGER_DEFAULT_PREVIEW_SIZE
#define MIN_LABEL "<span font=\"Serif Italic Bold\" size=\"small\"> A </span>"
#define MAX_LABEL "<span font=\"Serif Italic Bold\" size=\"large\"> A </span>"

struct _FontManagerFontScale
{
    GtkEventBox parent_instance;

    GtkWidget *min;
    GtkWidget *max;
    GtkWidget *scale;
    GtkWidget *spin;
    GtkAdjustment *adjustment;
};

G_DEFINE_TYPE(FontManagerFontScale, font_manager_font_scale, GTK_TYPE_EVENT_BOX)

enum
{
    PROP_RESERVED,
    PROP_VALUE,
    PROP_ADJUSTMENT,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_font_scale_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    g_clear_object(&self->adjustment);
    G_OBJECT_CLASS(font_manager_font_scale_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_font_scale_finalize (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    g_clear_object(&self->adjustment);
    G_OBJECT_CLASS(font_manager_font_scale_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_font_scale_get_property (GObject *gobject,
                                      guint property_id,
                                      GValue *value,
                                      GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    switch (property_id) {
        case PROP_ADJUSTMENT:
            g_value_set_object(value, font_manager_font_scale_get_adjustment(self));
            break;
        case PROP_VALUE:
            g_value_set_double(value, font_manager_font_scale_get_value(self));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_font_scale_set_property (GObject *gobject,
                                      guint property_id,
                                      const GValue *value,
                                      GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    switch (property_id) {
        case PROP_ADJUSTMENT:
            font_manager_font_scale_set_adjustment(self, g_value_get_object(value));
            break;
        case PROP_VALUE:
            font_manager_font_scale_set_value(self, g_value_get_double(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_font_scale_class_init (FontManagerFontScaleClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->dispose = font_manager_font_scale_dispose;
    object_class->finalize = font_manager_font_scale_finalize;
    object_class->get_property = font_manager_font_scale_get_property;
    object_class->set_property = font_manager_font_scale_set_property;

    /**
     * FontManagerFontScale:value:
     *
     * The current value of #FontManagerFontScale.
     */
    obj_properties[PROP_VALUE] = g_param_spec_double("value",
                                                     NULL,
                                                     "Current value",
                                                     MIN_FONT_SIZE,
                                                     MAX_FONT_SIZE,
                                                     DEFAULT_PREVIEW_SIZE,
                                                     G_PARAM_STATIC_STRINGS |
                                                     G_PARAM_READWRITE |
                                                     G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerFontScale:adjustment:
     *
     * The #GtkAdjustment in use.
     */
    obj_properties[PROP_ADJUSTMENT] = g_param_spec_object("adjustment",
                                                          NULL,
                                                          "#GtkAdjustment in use",
                                                          GTK_TYPE_ADJUSTMENT,
                                                          G_PARAM_STATIC_STRINGS |
                                                          G_PARAM_READWRITE |
                                                          G_PARAM_EXPLICIT_NOTIFY);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static gboolean
on_button_press_event (GtkWidget *wrapper, GdkEvent *event, FontManagerFontScale *self)
{
    GtkWidget *widget = gtk_bin_get_child(GTK_BIN(wrapper));
    gdouble new_value = (widget == self->min) ? MIN_FONT_SIZE : MAX_FONT_SIZE;
    gtk_adjustment_set_value(self->adjustment, new_value);
    return FALSE;
}

static gboolean
on_enter_event (GtkWidget *wrapper, GdkEvent *event, GtkWidget *widget)
{
    gtk_widget_set_opacity(widget, FOCUSED_OPACITY);
    return FALSE;
}

static gboolean
on_leave_event (GtkWidget *wrapper, GdkEvent *event, GtkWidget *widget)
{
    gtk_widget_set_opacity(widget, DEFAULT_OPACITY);
    return FALSE;
}

GtkWidget *
get_reactive_widget (FontManagerFontScale *self, GtkWidget *widget)
{
    GtkWidget *reactive = gtk_event_box_new();
    gtk_widget_add_events(reactive, GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK |
                                    GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK |
                                    GDK_STRUCTURE_MASK);
    gtk_container_add(GTK_CONTAINER(reactive), widget);
    g_signal_connect(reactive, "enter-notify-event", G_CALLBACK(on_enter_event), widget);
    g_signal_connect(reactive, "leave-notify-event", G_CALLBACK(on_leave_event), widget);
    g_signal_connect(reactive, "button-press-event", G_CALLBACK(on_button_press_event), self);
    gtk_widget_set_opacity(widget, DEFAULT_OPACITY);
    return reactive;
}

static void
font_manager_font_scale_init (FontManagerFontScale *self)
{
    g_return_if_fail(self != NULL);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(self));
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerFontScale");
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    self->min = gtk_label_new(NULL);
    self->max = gtk_label_new(NULL);
    self->scale = gtk_scale_new(GTK_ORIENTATION_HORIZONTAL, NULL);
    self->spin = gtk_spin_button_new(NULL, 0.5, 1);
    self->adjustment = gtk_adjustment_new(DEFAULT_PREVIEW_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5, 1.0, 0);
    self->adjustment = g_object_ref_sink(self->adjustment);
    font_manager_font_scale_set_adjustment(self, self->adjustment);
    GtkWidget *min = get_reactive_widget(self, self->min);
    GtkWidget *max = get_reactive_widget(self, self->max);
    gtk_box_pack_start(GTK_BOX(box), min, FALSE, FALSE, 1);
    gtk_box_pack_start(GTK_BOX(box), self->scale, TRUE, TRUE, 1);
    gtk_box_pack_start(GTK_BOX(box), max, FALSE, FALSE, FONT_MANAGER_DEFAULT_MARGIN);
    gtk_box_pack_start(GTK_BOX(box), self->spin, FALSE, FALSE, 1);
    gtk_widget_set_hexpand(self->scale, TRUE);
    gtk_widget_set_halign(self->scale, GTK_ALIGN_FILL);
    gtk_scale_set_draw_value(GTK_SCALE(self->scale), FALSE);
    gtk_label_set_markup(GTK_LABEL(self->min), MIN_LABEL);
    gtk_label_set_markup(GTK_LABEL(self->max), MAX_LABEL);
    gtk_widget_set_hexpand(GTK_WIDGET(self), TRUE);
    gtk_widget_set_valign(GTK_WIDGET(self), GTK_ALIGN_END);
    gtk_widget_set_can_focus(self->spin, FALSE);
    gtk_container_add(GTK_CONTAINER(self), box);
    font_manager_widget_set_margin(box, FONT_MANAGER_DEFAULT_MARGIN);
    gtk_widget_show_all(box);
    GBindingFlags flags = G_BINDING_SYNC_CREATE | G_BINDING_BIDIRECTIONAL;
    g_object_bind_property(self, "value", self->adjustment, "value", flags);
    return;
}

/**
 * font_manager_font_scale_get_adjustment:
 * @self:   #FontManagerFontScale
 *
 * Returns: (transfer none) (nullable): The #GtkAdjustment currently in use or %NULL.
 */
GtkAdjustment *
font_manager_font_scale_get_adjustment (FontManagerFontScale *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return self->adjustment;
}

/**
 * font_manager_font_scale_set_adjustment:
 * @self:           #FontManagerFontScale
 * @adjustment:     #GtkAdjustment to use
 */
void
font_manager_font_scale_set_adjustment (FontManagerFontScale *self, GtkAdjustment *adjustment)
{
    g_return_if_fail(self != NULL);
    if (g_set_object(&self->adjustment, adjustment))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_ADJUSTMENT]);
    gtk_range_set_adjustment(GTK_RANGE(self->scale), self->adjustment);
    gtk_spin_button_set_adjustment(GTK_SPIN_BUTTON(self->spin), self->adjustment);
    return;
}

/**
 * font_manager_font_scale_get_value:
 * @self:   #FontManagerFontScale
 *
 * Returns: The current value.
 */
gdouble
font_manager_font_scale_get_value (FontManagerFontScale *self)
{
    g_return_val_if_fail(self != NULL && self->adjustment != NULL, -1);
    return gtk_adjustment_get_value(self->adjustment);
}

/**
 * font_manager_font_scale_set_value:
 * @self:   #FontManagerFontScale
 * @value:  New value
 */
void
font_manager_font_scale_set_value (FontManagerFontScale *self, gdouble value)
{
    g_return_if_fail(self != NULL && self->adjustment != NULL);
    gtk_adjustment_set_value(self->adjustment, CLAMP(value, MIN_FONT_SIZE, MAX_FONT_SIZE));
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_VALUE]);
    return;
}

/**
 * font_manager_font_scale_new:
 *
 * Returns: (transfer full): A newly created #FontManagerFontScale.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_font_scale_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_FONT_SCALE, NULL);
}
