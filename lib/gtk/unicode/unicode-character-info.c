/* unicode-character-info.c
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

#include "unicode-character-info.h"

/**
 * SECTION: unicode-character-info
 * @short_description: Character info widget
 * @title: Unicode Character Info
 * @include: unicode-character-info.h
 *
 * Widget which displays information such as the codepoint and name of the
 * currently selected character as well as how many codepoints are currently
 * being displayed in the attached #UnicodeCharacterMap.
 */

struct _FontManagerUnicodeCharacterInfoClass
{
    GtkWidgetClass  parent_instance;

    GtkWidget   *codepoint;
    GtkWidget   *name;
    GtkWidget   *n_codepoints;

    FontManagerUnicodeCharacterMap *cmap;
};

G_DEFINE_TYPE(FontManagerUnicodeCharacterInfo, font_manager_unicode_character_info, GTK_TYPE_WIDGET)

enum
{
    PROP_RESERVED,
    PROP_CMAP,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = {0};

static void
font_manager_unicode_character_info_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeCharacterInfo *self = FONT_MANAGER_UNICODE_CHARACTER_INFO(gobject);
    g_clear_object(&self->cmap);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_unicode_character_info_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_unicode_character_info_get_property (GObject *gobject,
                                                  guint prop_id,
                                                  GValue *value,
                                                  GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeCharacterInfo *self = FONT_MANAGER_UNICODE_CHARACTER_INFO(gobject);
    switch (prop_id) {
        case PROP_CMAP:
            g_value_set_object(value, self->cmap);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
font_manager_unicode_character_info_set_property (GObject *gobject,
                                                  guint prop_id,
                                                  const GValue *value,
                                                  GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeCharacterInfo *self = FONT_MANAGER_UNICODE_CHARACTER_INFO(gobject);
    switch (prop_id) {
        case PROP_CMAP:
            font_manager_unicode_character_info_set_character_map(self, g_value_get_object(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
font_manager_unicode_character_info_class_init (FontManagerUnicodeCharacterInfoClass *klass)
{
    g_return_if_fail(klass != NULL);

    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_unicode_character_info_dispose;
    object_class->get_property = font_manager_unicode_character_info_get_property;
    object_class->set_property = font_manager_unicode_character_info_set_property;

    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);

    /**
     * FontManagerUnicodeCharacterInfo:character-map:
     *
     * #FontManagerUnicodeCharacterMap
     */
    obj_properties[PROP_CMAP] = g_param_spec_object("character-map",
                                                    NULL,
                                                    "FontManagerUnicodeCharacterMap",
                                                    G_TYPE_OBJECT,
                                                    G_PARAM_STATIC_STRINGS |
                                                    G_PARAM_READWRITE |
                                                    G_PARAM_EXPLICIT_NOTIFY);

    g_object_class_install_property(object_class, PROP_CMAP, obj_properties[PROP_CMAP]);

    return;
}

static void
font_manager_unicode_character_info_init (FontManagerUnicodeCharacterInfo *self)
{
    g_return_if_fail(self != NULL);
    self->cmap = NULL;
    self->codepoint = gtk_label_new(NULL);
    gtk_widget_set_can_focus(self->codepoint, FALSE);
    gtk_label_set_selectable(GTK_LABEL(self->codepoint), TRUE);
    self->name = gtk_label_new(NULL);
    self->n_codepoints = gtk_label_new(NULL);
    GtkWidget *center_box = gtk_center_box_new();
    gtk_center_box_set_start_widget(GTK_CENTER_BOX(center_box), self->codepoint);
    gtk_center_box_set_center_widget(GTK_CENTER_BOX(center_box), self->name);
    gtk_widget_set_opacity(self->codepoint, 0.9);
    gtk_widget_set_opacity(self->name, 0.9);
    gtk_widget_set_hexpand(self->name, TRUE);
    gtk_widget_set_vexpand(self->name, FALSE);
    gtk_center_box_set_end_widget(GTK_CENTER_BOX(center_box), self->n_codepoints);
    gtk_widget_set_hexpand(center_box, TRUE);
    gtk_widget_set_vexpand(center_box, FALSE);
    gtk_widget_set_parent(center_box, GTK_WIDGET(self));
    gtk_widget_add_css_class(self->n_codepoints, "CharacterMapCount");
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerUnicodeCharacterInfo");
    gtk_widget_set_hexpand(GTK_WIDGET(self), TRUE);
    gtk_widget_set_vexpand(GTK_WIDGET(self), FALSE);
    font_manager_widget_set_margin(center_box, 6);
    gtk_widget_set_margin_start(center_box, 12);
    gtk_widget_set_margin_end(center_box, 12);
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
    return;
}

static void
on_selection_changed (FontManagerUnicodeCharacterInfo *self,
                      const gchar *codepoint,
                      const gchar *name,
                      const gchar *n_codepoints)
{
    g_return_if_fail(self != NULL);
    gtk_label_set_label(GTK_LABEL(self->codepoint), codepoint);
    gtk_label_set_label(GTK_LABEL(self->name), name);
    gtk_label_set_label(GTK_LABEL(self->n_codepoints), n_codepoints);
    return;
}

/**
 * font_manager_unicode_character_info_set_character_map:
 * @self:                                       #FontManagerUnicodeCharacterInfo
 * @character_map: (transfer none) (nullable):  #FontManagerUnicodeCharacterMap
 */
void
font_manager_unicode_character_info_set_character_map (FontManagerUnicodeCharacterInfo *self,
                                                       FontManagerUnicodeCharacterMap *character_map)
{
    g_return_if_fail(self != NULL);
    if (self->cmap)
        g_signal_handlers_disconnect_by_func(self->cmap, G_CALLBACK(on_selection_changed), self);
    if (g_set_object(&self->cmap, character_map))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_CMAP]);
    if (self->cmap)
        g_signal_connect_swapped(self->cmap, "selection-changed", G_CALLBACK(on_selection_changed), self);
    /* Trigger first update */
    gint active_cell = font_manager_unicode_character_map_get_active_cell(character_map);
    font_manager_unicode_character_map_set_active_cell(character_map, active_cell != 0 ? 0 : 1);
    font_manager_unicode_character_map_set_active_cell(character_map, active_cell);
    return;
}

/**
 * font_manager_unicode_character_info_new:
 *
 * Returns: (transfer full): A newly created #FontManagerUnicodeCharacterInfo.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_unicode_character_info_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_UNICODE_CHARACTER_INFO, NULL);
}
