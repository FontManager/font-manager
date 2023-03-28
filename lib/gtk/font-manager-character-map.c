/* font-manager-character-map.c
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

#include "font-manager-character-map.h"

/**
 * SECTION: font-manager-character-map
 * @short_description: Browse available characters
 * @title: Character Map
 * @include: font-manager-character-map.h
 *
 * Widget which displays available characters in the selected font.
 * It also provides basic information about the selected character and the
 * ability to search for a specific character based on codepoint, name or
 * other details.
 */

struct _FontManagerCharacterMapClass
{
    GtkBoxClass   parent_instance;

    gint        active_cell;
    gdouble     preview_size;

    GtkWidget   *action_area;
    GtkWidget   *character_map;
    GtkWidget   *character_info;
    GtkWidget   *fontscale;
    GtkWidget   *search;

    FontManagerFont    *font;
};

G_DEFINE_TYPE(FontManagerCharacterMap, font_manager_character_map, GTK_TYPE_WIDGET)

enum
{
    PROP_RESERVED,
    PROP_FONT,
    PROP_ACTIVE_CELL,
    PROP_PREVIEW_SIZE,
    PROP_SEARCH_MODE,
    N_PROPERTIES
};


static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

void
font_manager_character_map_set_active_cell (FontManagerCharacterMap *self,
                                            gint                     cell)
{
    g_return_if_fail(self != NULL);
    self->active_cell = cell;
    return;
}

static void
font_manager_character_map_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerCharacterMap *self = FONT_MANAGER_CHARACTER_MAP(gobject);
    g_clear_pointer(&self->font, g_object_unref);
    font_manager_widget_dispose(GTK_WIDGET(self));
    G_OBJECT_CLASS(font_manager_character_map_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_character_map_get_property (GObject    *gobject,
                                         guint       property_id,
                                         GValue     *value,
                                         GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerCharacterMap *self = FONT_MANAGER_CHARACTER_MAP(gobject);
    GtkWidget *child = NULL;
    switch (property_id) {
        case PROP_FONT:
            g_value_set_object(value, self->font);
            break;
        case PROP_ACTIVE_CELL:
            g_value_set_int(value, self->active_cell);
            break;
        case PROP_SEARCH_MODE:
            child = gtk_stack_get_visible_child(GTK_STACK(self->action_area));
            g_value_set_boolean(value, child == self->search);
            break;
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, self->preview_size);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_character_map_set_property (GObject      *gobject,
                                         guint         property_id,
                                         const GValue *value,
                                         GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerCharacterMap *self = FONT_MANAGER_CHARACTER_MAP(gobject);
    GtkWidget *child = NULL;
    switch (property_id) {
        case PROP_FONT:
            font_manager_character_map_set_font(self, g_value_get_object(value));
            break;
        case PROP_ACTIVE_CELL:
            font_manager_character_map_set_active_cell(self, g_value_get_int(value));
            break;
        case PROP_SEARCH_MODE:
            child = g_value_get_boolean(value) ? self->search : self->fontscale;
            gtk_stack_set_visible_child(GTK_STACK(self->action_area), child);
            break;
        case PROP_PREVIEW_SIZE:
            self->preview_size = g_value_get_double(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}


static void
font_manager_character_map_class_init (FontManagerCharacterMapClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_character_map_dispose;
    object_class->get_property = font_manager_character_map_get_property;
    object_class->set_property = font_manager_character_map_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BIN_LAYOUT);

    /**
     * FontManagerCharacterMap:font:
     *
     * #FontManagerFont
     */
    obj_properties[PROP_FONT] = g_param_spec_object("font",
                                                    NULL,
                                                    "FontManagerFont",
                                                    FONT_MANAGER_TYPE_FONT,
                                                    G_PARAM_READWRITE |
                                                    G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerCharacterMap:active-cell:
     *
     * Currently selected cell in character map
     */
    obj_properties[PROP_ACTIVE_CELL] = g_param_spec_int("active-cell",
                                                        NULL,
                                                        "Active cell in character map",
                                                        G_MININT,
                                                        G_MAXINT,
                                                        0,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerCharacterMap:preview-size:
     *
     * Font preview size
     */
    obj_properties[PROP_PREVIEW_SIZE] = g_param_spec_double("preview-size",
                                                            NULL,
                                                            "Preview size",
                                                            FONT_MANAGER_MIN_FONT_SIZE,
                                                            FONT_MANAGER_MAX_FONT_SIZE,
                                                            FONT_MANAGER_LARGE_PREVIEW_SIZE,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE);

    /**
     * FontManagerCharacterMap:search-mode:
     *
     * Whether search mode is active or not
     */
    obj_properties[PROP_SEARCH_MODE] = g_param_spec_boolean("search-mode",
                                                            NULL,
                                                            "Whether search mode is active or not",
                                                            FALSE,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

GtkWidget *
create_action_area (FontManagerCharacterMap *self)
{
    self->action_area = gtk_stack_new();
    self->fontscale = font_manager_font_scale_new();
    self->search = font_manager_unicode_search_bar_new();
    gtk_stack_add_named(GTK_STACK(self->action_area), self->fontscale, gtk_widget_get_name(self->fontscale));
    gtk_stack_add_named(GTK_STACK(self->action_area), self->search, gtk_widget_get_name(self->search));
    gtk_stack_set_visible_child(GTK_STACK(self->action_area), self->fontscale);
    gtk_stack_set_transition_type(GTK_STACK(self->action_area), GTK_STACK_TRANSITION_TYPE_CROSSFADE);
    gtk_stack_set_vhomogeneous(GTK_STACK(self->action_area), FALSE);
    return self->action_area;
}

static void
font_manager_character_map_init (FontManagerCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerCharacterMap");
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    self->character_map = font_manager_unicode_character_map_new();
    GtkWidget *info_widget = font_manager_unicode_character_info_new();
    FontManagerUnicodeCharacterMap *charmap = FONT_MANAGER_UNICODE_CHARACTER_MAP(self->character_map);
    FontManagerUnicodeCharacterInfo *charinfo = FONT_MANAGER_UNICODE_CHARACTER_INFO(info_widget);
    font_manager_unicode_character_info_set_character_map(charinfo, charmap);
    gtk_box_append(GTK_BOX(box), info_widget);
    GtkWidget *scroll = gtk_scrolled_window_new();
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), self->character_map);
    gtk_box_append(GTK_BOX(box), scroll);
    GtkWidget *action_area = create_action_area(self);
    gtk_box_append(GTK_BOX(box), action_area);
    FontManagerUnicodeSearchBar *search_bar = FONT_MANAGER_UNICODE_SEARCH_BAR(self->search);
    font_manager_unicode_search_bar_set_character_map(search_bar, charmap);
    font_manager_font_scale_set_default_size(FONT_MANAGER_FONT_SCALE(self->fontscale),
                                             FONT_MANAGER_LARGE_PREVIEW_SIZE);
    self->preview_size = FONT_MANAGER_LARGE_PREVIEW_SIZE;
    gtk_widget_set_parent(box, GTK_WIDGET(self));
    font_manager_widget_set_expand(GTK_WIDGET(box), TRUE);
    font_manager_widget_set_expand(GTK_WIDGET(charmap), TRUE);
    font_manager_widget_set_expand(GTK_WIDGET(scroll), TRUE);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    gtk_widget_set_valign(info_widget, GTK_ALIGN_START);
    gtk_widget_set_valign(action_area, GTK_ALIGN_END);
    GBindingFlags flags = G_BINDING_SYNC_CREATE | G_BINDING_BIDIRECTIONAL;
    g_object_bind_property(self, "preview-size", self->fontscale, "value", flags);
    g_object_bind_property(self, "preview-size", self->character_map, "preview-size", flags);
    g_object_bind_property(self, "active-cell", self->character_map, "active-cell", flags);
    return;
}

/**
 * font_manager_character_map_set_font:
 * @self:                       #FontManagerCharacterMap
 * @font: (transfer none):      #FontManagerFont
 */
void
font_manager_character_map_set_font (FontManagerCharacterMap *self,
                                     FontManagerFont         *font)
{
    g_return_if_fail(self != NULL);
    g_set_object(&self->font, font);
    FontManagerUnicodeCharacterMap *charmap = FONT_MANAGER_UNICODE_CHARACTER_MAP(self->character_map);
    g_autofree gchar *description = NULL;
    g_object_get(font, "description", &description, NULL);
    g_autoptr(PangoFontDescription) font_desc = pango_font_description_from_string(description);
    font_manager_unicode_character_map_set_font_desc(charmap, font_desc);
    return;
}

/**
 * font_manager_character_map_set_filter:
 * @self:   #FontManagerCharacterMap
 * @filter:(element-type uint) (transfer full) (nullable): #GList of codepoints
 */
void
font_manager_character_map_set_filter (FontManagerCharacterMap *self, GList *filter)
{
    g_return_if_fail(self != NULL);
    FontManagerUnicodeCharacterMap *charmap = FONT_MANAGER_UNICODE_CHARACTER_MAP(self->character_map);
    font_manager_unicode_character_map_set_filter(charmap, filter);
    return;
}

/**
 * font_manager_character_map_restore_state:
 * @self:       #FontManagerCharacterMap
 * @settings:   #GSettings
 *
 * Applies the values in @settings to @self and also binds those settings to their
 * respective properties so that they are updated when any changes take place.
 *
 * The following keys MUST be present in @settings:
 *
 *  - charmap-font-size
 */
void
font_manager_character_map_restore_state (FontManagerCharacterMap *self, GSettings *settings)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(settings != NULL);
    g_settings_bind(settings, "charmap-font-size", self, "preview-size", G_SETTINGS_BIND_DEFAULT);
    return;
}

/**
 * font_manager_character_map_new:
 *
 * Returns: (transfer full): A newly created #FontManagerCharacterMap.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_character_map_new ()
{
    return g_object_new(FONT_MANAGER_TYPE_CHARACTER_MAP, NULL);
}

