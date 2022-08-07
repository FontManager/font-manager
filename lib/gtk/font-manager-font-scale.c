/* font-manager-font-scale.c
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
#define MIN_LABEL "<span font=\"Serif Italic Bold\" size=\"small\"> A </span>"
#define MAX_LABEL "<span font=\"Serif Italic Bold\" size=\"large\"> A </span>"

#define N_ZOOM_SHORTCUTS 3

static const struct {
    gint16 direction;
    const gchar *accel;
} ZoomShortcuts [N_ZOOM_SHORTCUTS] = {
    { -1, "<Ctrl>minus" },
    { 0, "<Ctrl>0" },
    { 1, "<Ctrl>plus|<Ctrl>equal" }
};

static void on_zoom (GtkWidget *widget, const gchar *action_name, GVariant *parameter);

struct _FontManagerFontScale
{
    GtkWidget parent_instance;

    gdouble         default_size;
    GtkWidget       *min;
    GtkWidget       *max;
    GtkWidget       *scale;
    GtkWidget       *spin;
    GtkAdjustment   *adjustment;
};

G_DEFINE_TYPE(FontManagerFontScale, font_manager_font_scale, GTK_TYPE_WIDGET)

enum
{
    PROP_RESERVED,
    PROP_ADJUSTMENT,
    PROP_DEFAULT_SIZE,
    PROP_VALUE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_font_scale_dispose (GObject *gobject)
{
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    g_return_if_fail(self != NULL);
    g_clear_object(&self->adjustment);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_font_scale_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_font_scale_get_property (GObject    *gobject,
                                      guint       property_id,
                                      GValue     *value,
                                      GParamSpec *pspec)
{
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    g_return_if_fail(self != NULL);
    switch (property_id) {
        case PROP_ADJUSTMENT:
            g_value_set_object(value, font_manager_font_scale_get_adjustment(self));
            break;
        case PROP_DEFAULT_SIZE:
            g_value_set_double(value, self->default_size);
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
font_manager_font_scale_set_property (GObject      *gobject,
                                      guint         property_id,
                                      const GValue *value,
                                      GParamSpec   *pspec)
{
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(gobject);
    g_return_if_fail(self != NULL);
    switch (property_id) {
        case PROP_ADJUSTMENT:
            font_manager_font_scale_set_adjustment(self, g_value_get_object(value));
            break;
        case PROP_DEFAULT_SIZE:
            font_manager_font_scale_set_default_size(self, g_value_get_double(value));
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
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_font_scale_dispose;
    object_class->get_property = font_manager_font_scale_get_property;
    object_class->set_property = font_manager_font_scale_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);
    gtk_widget_class_set_css_name(widget_class, "FontManagerFontScale");
    gtk_widget_class_install_action(widget_class, "zoom", "n",  on_zoom);

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

    /**
     * FontManagerFontScale:default-size:
     *
     * The default preview size of #FontManagerFontScale.
     */
    obj_properties[PROP_DEFAULT_SIZE] = g_param_spec_double("default-size",
                                                            NULL,
                                                            "Default preview size",
                                                            MIN_FONT_SIZE,
                                                            MAX_FONT_SIZE,
                                                            FONT_MANAGER_DEFAULT_PREVIEW_SIZE,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE |
                                                            G_PARAM_EXPLICIT_NOTIFY);

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
                                                     FONT_MANAGER_DEFAULT_PREVIEW_SIZE,
                                                     G_PARAM_STATIC_STRINGS |
                                                     G_PARAM_READWRITE |
                                                     G_PARAM_EXPLICIT_NOTIFY);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;

}

static void
on_zoom (GtkWidget   *widget,
         const gchar *action_name,
         GVariant    *parameter)
{
    FontManagerFontScale *self = FONT_MANAGER_FONT_SCALE(widget);
    gint16 direction = g_variant_get_int16(parameter);
    gdouble step = 0.5;
    gdouble current = gtk_adjustment_get_value(self->adjustment);
    gdouble value = self->default_size;
    if (direction != 0)
        value = direction > 0 ? current + step : current - step;
    value = CLAMP(value, MIN_FONT_SIZE, MAX_FONT_SIZE);
    gtk_adjustment_set_value(self->adjustment, value);
    return;
}

static void
on_click (GtkGestureClick      *gesture,
          gint                  n_press,
          gdouble               x,
          gdouble               y,
          FontManagerFontScale *self)
{
    g_return_if_fail(self != NULL);
    GtkWidget *widget = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(gesture));
    gdouble new_value = (widget == self->min) ? MIN_FONT_SIZE : MAX_FONT_SIZE;
    gtk_adjustment_set_value(self->adjustment, new_value);
    return;
}

static void
on_state_change (GtkWidget            *widget,
                 GtkStateFlags         flags,
                 FontManagerFontScale *self)
{
    gboolean active = gtk_window_is_active(GTK_WINDOW(gtk_widget_get_root(widget)));
    gboolean prelight = ((flags & GTK_STATE_FLAG_PRELIGHT) == 0);
    gdouble opacity = active && prelight ? FOCUSED_OPACITY : DEFAULT_OPACITY;
    gtk_widget_set_opacity(widget, opacity);
    return;
}

static void
on_value_changed (FontManagerFontScale *self, GtkAdjustment *adjustment)
{
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_VALUE]);
    return;
}

static void
add_child_widget (FontManagerFontScale *self,
                  const gchar          *name,
                  GtkWidget            *widget)
{
    gtk_widget_set_parent(widget, GTK_WIDGET(self));
    gtk_widget_set_name(widget, name);
    font_manager_widget_set_expand(widget, FALSE);
    font_manager_widget_set_align(widget, GTK_ALIGN_CENTER);
    font_manager_widget_set_margin(widget, FONT_MANAGER_DEFAULT_MARGIN);
    return;
}

static void
add_click_target (FontManagerFontScale *self, GtkWidget *widget)
{
    gtk_widget_set_can_focus(widget, TRUE);
    gtk_widget_set_opacity(widget, DEFAULT_OPACITY);
    g_signal_connect(widget, "state-flags-changed", G_CALLBACK(on_state_change), self);
    GtkGesture *gesture = gtk_gesture_click_new();
    gtk_gesture_single_set_touch_only(GTK_GESTURE_SINGLE(gesture), FALSE);
    gtk_gesture_single_set_exclusive(GTK_GESTURE_SINGLE(gesture), TRUE);
    gtk_gesture_single_set_button(GTK_GESTURE_SINGLE(gesture), GDK_BUTTON_PRIMARY);
    g_signal_connect(gesture, "pressed", G_CALLBACK(on_click), self);
    gtk_event_controller_set_propagation_phase(GTK_EVENT_CONTROLLER(gesture),
                                               GTK_PHASE_BUBBLE);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(gesture));
    return;
}

static void
font_manager_font_scale_init (FontManagerFontScale *self)
{
    g_return_if_fail(self != NULL);
    self->default_size = FONT_MANAGER_DEFAULT_PREVIEW_SIZE;
    self->min = gtk_label_new(NULL);
    self->max = gtk_label_new(NULL);
    self->scale = gtk_scale_new(GTK_ORIENTATION_HORIZONTAL, NULL);
    self->spin = gtk_spin_button_new(NULL, 0.5, 1);
    self->adjustment = gtk_adjustment_new(self->default_size,
                                          MIN_FONT_SIZE,
                                          MAX_FONT_SIZE,
                                          0.5, 1.0, 0);
    self->adjustment = g_object_ref_sink(self->adjustment);
    font_manager_font_scale_set_adjustment(self, self->adjustment);
    add_child_widget(self, "min", self->min);
    add_child_widget(self, "scale", self->scale);
    add_child_widget(self, "max", self->max);
    add_child_widget(self, "spin", self->spin);
    add_click_target(self, self->min);
    add_click_target(self, self->max);
    gtk_widget_set_focusable(self->scale, FALSE);
    gtk_widget_set_focusable(self->spin, FALSE);
    gtk_widget_set_hexpand(self->scale, TRUE);
    gtk_widget_set_halign(self->scale, GTK_ALIGN_FILL);
    gtk_scale_set_draw_value(GTK_SCALE(self->scale), FALSE);
    gtk_spin_button_set_numeric(GTK_SPIN_BUTTON(self->spin), TRUE);
    gtk_label_set_markup(GTK_LABEL(self->min), MIN_LABEL);
    gtk_label_set_markup(GTK_LABEL(self->max), MAX_LABEL);
    gtk_widget_set_hexpand(GTK_WIDGET(self), TRUE);
    gtk_widget_set_valign(GTK_WIDGET(self), GTK_ALIGN_END);
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerFontScale");
    GtkEventController *shortcuts = gtk_shortcut_controller_new();
    gtk_event_controller_set_propagation_phase(shortcuts, GTK_PHASE_BUBBLE);
    gtk_widget_add_controller(GTK_WIDGET(self), GTK_EVENT_CONTROLLER(shortcuts));
    gtk_shortcut_controller_set_scope(GTK_SHORTCUT_CONTROLLER(shortcuts), GTK_SHORTCUT_SCOPE_GLOBAL);
    for (gint i = 0; i < N_ZOOM_SHORTCUTS; i++) {
        GtkShortcutAction *action = gtk_named_action_new("zoom");
        GtkShortcutTrigger *trigger = gtk_shortcut_trigger_parse_string(ZoomShortcuts[i].accel);
        GtkShortcut *shortcut = gtk_shortcut_new(trigger, action);
        GVariant *args = g_variant_new_int16(ZoomShortcuts[i].direction);
        gtk_shortcut_set_arguments(shortcut, args);
        gtk_shortcut_controller_add_shortcut(GTK_SHORTCUT_CONTROLLER(shortcuts), shortcut);
    }
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
 * font_manager_font_scale_set_adjustment:
 * @self:           #FontManagerFontScale
 * @adjustment:     #GtkAdjustment to use
 */
void
font_manager_font_scale_set_adjustment (FontManagerFontScale *self,
                                        GtkAdjustment        *adjustment)
{
    g_return_if_fail(self != NULL && adjustment != NULL);
    if (g_set_object(&self->adjustment, adjustment))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_ADJUSTMENT]);
    gtk_range_set_adjustment(GTK_RANGE(self->scale), self->adjustment);
    gtk_spin_button_set_adjustment(GTK_SPIN_BUTTON(self->spin), self->adjustment);
    g_signal_connect_swapped(self->adjustment, "value-changed",
                             (GCallback) on_value_changed, self);
    return;
}

/**
 * font_manager_font_scale_set_default_size:
 * @self:   #FontManagerFontScale
 * @value:  #gdouble to use as default size for @self
 *
 * Sets the size used as default when a reset is requested using a keyboard
 * shortcut i.e. &lt;Ctrl&gt;+0
 */
void
font_manager_font_scale_set_default_size (FontManagerFontScale *self,
                                          gdouble               value)
{
    self->default_size = value;
    gdouble current_value = gtk_adjustment_get_value(self->adjustment);
    gtk_adjustment_configure(self->adjustment,
                             current_value,
                             MIN_FONT_SIZE, MAX_FONT_SIZE,
                             0.5, 1.0, 0);
    return;
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
    gtk_adjustment_set_value(self->adjustment,
                             CLAMP(value, MIN_FONT_SIZE, MAX_FONT_SIZE));
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

