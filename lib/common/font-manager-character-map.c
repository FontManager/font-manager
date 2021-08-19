/* font-manager-character-map.c
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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
 */

struct _FontManagerCharacterMap
{
    GtkBox   parent_instance;

    GtkWidget   *name;
    GtkWidget   *count;
    GtkWidget   *codepoint;
    GtkWidget   *character_map;
    GtkWidget   *action_area;
    GtkWidget   *fontscale;
    GtkWidget   *search;

    gint                        active_cell;
    gdouble                     preview_size;
    FontManagerFont             *font;
    FontManagerCodepointList    *codepoint_list;
};

G_DEFINE_TYPE(FontManagerCharacterMap, font_manager_character_map, GTK_TYPE_BOX)

enum
{
    PROP_RESERVED,
    PROP_FONT,
    PROP_ACTIVE_CHAR,
    PROP_ACTIVE_CELL,
    PROP_PREVIEW_SIZE,
    PROP_SEARCH_MODE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

void font_manager_character_map_set_active_cell(FontManagerCharacterMap *self, gint cell);

static void
font_manager_character_map_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerCharacterMap *self = FONT_MANAGER_CHARACTER_MAP(gobject);
    g_clear_object(&self->font);
    g_clear_object(&self->codepoint_list);
    G_OBJECT_CLASS(font_manager_character_map_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_character_map_get_property (GObject *gobject,
                                         guint property_id,
                                         GValue *value,
                                         GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerCharacterMap *self = FONT_MANAGER_CHARACTER_MAP(gobject);
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(self->character_map);
    gunichar ac = -1;
    GtkWidget *child = NULL;
    switch (property_id) {
        case PROP_FONT:
            g_value_set_object(value, self->font);
            break;
        case PROP_ACTIVE_CHAR:
            ac = unicode_character_map_get_active_character(charmap);
            g_value_set_uint(value, (guint) ac);
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
font_manager_character_map_set_property (GObject *gobject,
                                        guint property_id,
                                        const GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerCharacterMap *self = FONT_MANAGER_CHARACTER_MAP(gobject);
    GtkWidget *child = NULL;
    switch (property_id) {
        case PROP_FONT:
            font_manager_character_map_set_font(self, g_value_get_object(value));
            break;
        case PROP_ACTIVE_CHAR:
            unicode_character_map_set_active_character(UNICODE_CHARACTER_MAP(self->character_map),
                                                       g_value_get_uint(value));
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

    object_class->dispose = font_manager_character_map_dispose;
    object_class->get_property = font_manager_character_map_get_property;
    object_class->set_property = font_manager_character_map_set_property;

    /**
     * FontManagerCharacterMap:font:
     *
     * #FontManagerFont to display
     */
    obj_properties[PROP_FONT] = g_param_spec_object("font",
                                                    NULL,
                                                    "Currently selected font",
                                                    FONT_MANAGER_TYPE_FONT,
                                                    G_PARAM_STATIC_STRINGS |
                                                    G_PARAM_READWRITE);

    /**
     * FontManagerCharacterMap:active-character:
     *
     * Currently selected character
     */
    obj_properties[PROP_ACTIVE_CHAR] = g_param_spec_uint("active-character",
                                                        NULL,
                                                        "Active character",
                                                        0,
                                                        UNICODE_UNICHAR_MAX,
                                                        0,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS);

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
                                                            FONT_MANAGER_CHARACTER_MAP_PREVIEW_SIZE,
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

static GtkWidget *
create_info_widget (FontManagerCharacterMap *self)
{
    GtkWidget *info = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    self->name = gtk_label_new(NULL);
    self->count = gtk_label_new(NULL);
    self->codepoint = gtk_label_new(NULL);
    GtkStyleContext *ctx = gtk_widget_get_style_context(self->count);
    gtk_style_context_add_class(ctx, "CellRendererPill");
    gtk_widget_set_opacity(self->name, 0.75);
    gtk_widget_set_opacity(self->codepoint, 0.75);
    gtk_widget_set_margin_start(self->codepoint, FONT_MANAGER_DEFAULT_MARGIN);
    gtk_label_set_selectable(GTK_LABEL(self->name), TRUE);
    gtk_label_set_selectable(GTK_LABEL(self->codepoint), TRUE);
    gtk_widget_set_can_default(self->name, FALSE);
    gtk_widget_set_can_default(self->codepoint, FALSE);
    gtk_widget_set_can_focus(self->name, FALSE);
    gtk_widget_set_can_focus(self->codepoint, FALSE);
    gtk_box_pack_start(GTK_BOX(info), self->codepoint, FALSE, FALSE, 0);
    gtk_box_set_center_widget(GTK_BOX(info), self->name);
    gtk_box_pack_end(GTK_BOX(info), self->count, FALSE, FALSE, 0);
    font_manager_widget_set_margin(info, FONT_MANAGER_DEFAULT_MARGIN);
    gtk_widget_show_all(info);
    return info;
}

GtkWidget *
create_action_area (FontManagerCharacterMap *self)
{
    self->action_area = gtk_stack_new();
    self->fontscale = font_manager_font_scale_new();
    self->search = unicode_search_bar_new();
    gtk_stack_add_named(GTK_STACK(self->action_area), self->fontscale, gtk_widget_get_name(self->fontscale));
    gtk_stack_add_named(GTK_STACK(self->action_area), self->search, gtk_widget_get_name(self->search));
    gtk_widget_show(self->search);
    gtk_widget_show(self->fontscale);
    gtk_widget_show(self->action_area);
    gtk_stack_set_visible_child(GTK_STACK(self->action_area), self->fontscale);
    gtk_stack_set_transition_type(GTK_STACK(self->action_area), GTK_STACK_TRANSITION_TYPE_CROSSFADE);
    return self->action_area;
}

static void
font_manager_character_map_init (FontManagerCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerCharacterMap");
    gtk_orientable_set_orientation(GTK_ORIENTABLE(self), GTK_ORIENTATION_VERTICAL);
    self->codepoint_list = font_manager_codepoint_list_new();
    self->character_map = unicode_character_map_new();
    font_manager_widget_set_expand(self->character_map, TRUE);
    gtk_box_pack_start(GTK_BOX(self), create_info_widget(self), FALSE, FALSE, 0);
    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scroll), self->character_map);
    gtk_box_pack_start(GTK_BOX(self), scroll, TRUE, TRUE, 0);
    gtk_box_pack_end(GTK_BOX(self), create_action_area(self), FALSE, FALSE, 0);
    gtk_widget_show(self->character_map);
    gtk_widget_show(scroll);
    unicode_search_bar_set_character_map(UNICODE_SEARCH_BAR(self->search),
                                         UNICODE_CHARACTER_MAP(self->character_map));
    GBindingFlags flags = G_BINDING_SYNC_CREATE | G_BINDING_BIDIRECTIONAL;
    g_object_bind_property(self, "preview-size", self->fontscale, "value", flags);
    g_object_bind_property(self->character_map, "preview-size", self->fontscale, "value", flags);
    g_object_bind_property(self->character_map, "active-character", self, "active-character", flags);
    g_object_bind_property(self->character_map, "active-cell", self, "active-cell", flags);
    return;
}

void
font_manager_character_map_set_active_cell(FontManagerCharacterMap *self, gint cell)
{
    g_return_if_fail(self != NULL);
    self->active_cell = cell;
    GSList *codepoints = unicode_codepoint_list_get_codepoints(UNICODE_CODEPOINT_LIST(self->codepoint_list), cell);
    if (g_slist_length(codepoints) == 1) {
        gunichar ac = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
        g_autofree gchar *codepoint_str = g_markup_printf_escaped("<b>U+%4.4X</b>", ac);
        const gchar *name = unicode_get_codepoint_name(ac);
        g_autofree gchar *name_str = g_markup_printf_escaped("<b>%s</b>", name);
        gtk_label_set_markup(GTK_LABEL(self->codepoint), codepoint_str);
        gtk_label_set_markup(GTK_LABEL(self->name), name_str);
    } else if (cell != 0) {
        gunichar code1 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
        gunichar code2 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 1));
        int index;
        for (index = 0; index < G_N_ELEMENTS(FontManagerRIS); index++)
            if (FontManagerRIS[index].code1 == code1 && FontManagerRIS[index].code2 == code2)
                break;
        g_autofree gchar *points = g_markup_printf_escaped("<b>U+%4.4X</b> + <b>U+%4.4X</b>", code1, code2);
        g_autofree gchar *name = g_markup_printf_escaped("<b>%s</b>", FontManagerRIS[index].region);
        gtk_label_set_markup(GTK_LABEL(self->codepoint), points);
        gtk_label_set_markup(GTK_LABEL(self->name), name);
    } else {
        gtk_label_set_markup(GTK_LABEL(self->codepoint), "");
        gtk_label_set_markup(GTK_LABEL(self->name), "");
    }
    g_slist_free(codepoints);
    return;
}

void
font_manager_character_map_set_count (FontManagerCharacterMap *self)
{
    gint count = unicode_codepoint_list_get_last_index(UNICODE_CODEPOINT_LIST(self->codepoint_list));
    g_autofree gchar *count_str = count >= 0 ? g_strdup_printf("   %i   ", count) : g_strdup("   0   ");
    gtk_label_set_label(GTK_LABEL(self->count), count_str);
    return;
}

static void
font_manager_character_map_update (FontManagerCharacterMap *self)
{
    unicode_character_map_set_codepoint_list(UNICODE_CHARACTER_MAP(self->character_map), NULL);
    g_autofree gchar *description = NULL;
    g_autoptr(JsonObject) font = NULL;
    if (self->font && font_manager_json_proxy_is_valid(FONT_MANAGER_JSON_PROXY(self->font)))
        g_object_get(G_OBJECT(self->font), "description", &description, "source-object", &font, NULL);
    else
        description = g_strdup(FONT_MANAGER_DEFAULT_FONT);
    PangoFontDescription *font_desc = pango_font_description_from_string(description);
    font_manager_codepoint_list_set_font(self->codepoint_list, font);
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(self->character_map);
    unicode_character_map_set_font_desc(charmap, font_desc);
    unicode_character_map_set_codepoint_list(charmap, UNICODE_CODEPOINT_LIST(self->codepoint_list));
    pango_font_description_free(font_desc);
    font_manager_character_map_set_count(self);
    return;
}

/**
 * font_manager_character_map_set_font:
 * @self:               #FontManagerCharacterMap
 * @font: (nullable):   #FontManagerFont
 */
void
font_manager_character_map_set_font (FontManagerCharacterMap *self, FontManagerFont *font)
{
    g_return_if_fail(self != NULL);
    if (g_set_object(&self->font, font))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_FONT]);
    font_manager_character_map_update(self);
    return;
}

/**
 * font_manager_character_map_set_filter:
 * @self:                                       #FontManagerCharacterMap
 * @orthography: (nullable) (transfer none):    #FontManagerOrthography
 */
void
font_manager_character_map_set_filter (FontManagerCharacterMap *self, FontManagerOrthography *orthography)
{
    unicode_character_map_set_codepoint_list(UNICODE_CHARACTER_MAP(self->character_map), NULL);
    GList *filter = NULL;
    if (orthography)
        filter = font_manager_orthography_get_filter(orthography);
    font_manager_codepoint_list_set_filter(self->codepoint_list, filter);
    font_manager_character_map_set_count(self);
    unicode_character_map_set_codepoint_list(UNICODE_CHARACTER_MAP(self->character_map),
                                             UNICODE_CODEPOINT_LIST(self->codepoint_list));
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

