/* unicode-character-map-zoom-window.c
 *
 * Copyright (C) 2019-2022 Jerry Casiano
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

#include "unicode-character-map-zoom-window.h"

#include "unicode-info.h"

#define UI_RESOURCE_PATH "/ui/unicode-character-map-zoom-window.ui"

/**
 * SECTION: unicode-character-map-zoom-window
 * @short_description: Close up view of the selected glyph
 * @title: Zoom Window
 * @include: unicode-character-map-zoom-window.h
 *
 * This widget provides a close up of the selected glyph along with Pango
 * font metrics and an option to copy the glyph to the clipboard.
 */

struct _UnicodeCharacterMapZoomWindow
{
    GtkPopover  parent_instance;

    int active_cell;
    gchar *cell_text;
    GtkDrawingArea *drawing_area;
    PangoFontDescription *font_desc;
    PangoLayout *layout;

    GtkStyleContext *ctx;
};

G_DEFINE_TYPE(UnicodeCharacterMapZoomWindow, unicode_character_map_zoom_window, GTK_TYPE_POPOVER)

enum
{
    PROP_RESERVED,
    PROP_FONT_DESC,
    PROP_ACTIVE_CELL,
    PROP_CELL_TEXT,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = {0};

#define DEFAULT_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

static void
unicode_character_map_zoom_window_clear_layout (GtkWidget *widget)
{
    UnicodeCharacterMapZoomWindow *self = UNICODE_CHARACTER_MAP_ZOOM_WINDOW(widget);
    g_return_if_fail(self != NULL);
    g_clear_object(&self->layout);
    return;
}

static void
on_copy_clicked (G_GNUC_UNUSED GtkButton *button, UnicodeCharacterMapZoomWindow *self)
{
    g_return_if_fail(self != NULL);
    GtkClipboard *clipboard = gtk_widget_get_clipboard(GTK_WIDGET(self), GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_set_text(clipboard, self->cell_text, -1);
    return;
}

static gboolean
on_draw (GtkWidget *widget, cairo_t *cr, UnicodeCharacterMapZoomWindow *self)
{
    if (!self->layout) {
        self->layout = gtk_widget_create_pango_layout(widget, NULL);
        PangoAttrList *attrs = pango_attr_list_new();
        pango_attr_list_insert(attrs, pango_attr_fallback_new (FALSE));
        pango_layout_set_attributes(self->layout, attrs);
        pango_attr_list_unref(attrs);
    }

    if (!self->ctx)
        self->ctx = gtk_widget_get_style_context(widget);

    pango_layout_set_text(self->layout, self->cell_text, -1);

    PangoRectangle char_rect;
    GtkAllocation alloc;
    gint glyph_pad = 48, width = -1, height = -1;

    pango_layout_set_font_description(self->layout, self->font_desc);
    pango_layout_set_alignment(self->layout, PANGO_ALIGN_CENTER);
    pango_layout_get_pixel_size(self->layout, &width, &height);
    pango_layout_get_pixel_extents(self->layout, NULL, &char_rect);

    if (width < 0)
        width = char_rect.width;

    if (height < 0)
        height = char_rect.height;

    GtkWidget *parent = gtk_widget_get_parent(widget);
    int parent_size = MAX(width + glyph_pad, height + glyph_pad);
    gtk_widget_set_size_request(parent, parent_size, parent_size);
    gtk_widget_set_size_request(widget, width + glyph_pad, height + glyph_pad);
    gtk_widget_get_allocation(widget, &alloc);

    gint xpad = ((alloc.width - char_rect.width) / 2);
    gint ypad = ((alloc.height - char_rect.height) / 2);
    gint baseline = pango_layout_get_baseline(self->layout) / PANGO_SCALE;

    gtk_render_layout(self->ctx, cr, char_rect.x + xpad, char_rect.y + ypad, self->layout);
    gtk_style_context_save(self->ctx);
    gtk_style_context_add_class(self->ctx, "PangoGlyphMetrics");
    gtk_render_line(self->ctx, cr, 1, baseline + xpad, alloc.width - 1, baseline + xpad);
    gtk_render_line(self->ctx, cr, 1, PANGO_ASCENT(char_rect) + xpad, alloc.width - 1, PANGO_ASCENT(char_rect) + xpad);
    gtk_render_line(self->ctx, cr, 1, PANGO_DESCENT(char_rect) + xpad, alloc.width - 1, PANGO_DESCENT(char_rect) + xpad);
    gtk_render_line(self->ctx, cr, PANGO_LBEARING(char_rect) + ypad, 1, PANGO_LBEARING(char_rect) + ypad, alloc.height - 1);
    gtk_render_line(self->ctx, cr, PANGO_RBEARING(char_rect) + ypad, 1, PANGO_RBEARING(char_rect) + ypad, alloc.height - 1);
    gtk_style_context_restore(self->ctx);

    return FALSE;
}

static void
unicode_character_map_zoom_window_set_property (GObject *gobject,
                                                guint prop_id,
                                                const GValue *value,
                                                GParamSpec *pspec)
{
    UnicodeCharacterMapZoomWindow *self = UNICODE_CHARACTER_MAP_ZOOM_WINDOW(gobject);
    switch (prop_id) {
        case PROP_ACTIVE_CELL:
            self->active_cell = g_value_get_int(value);
            break;
        case PROP_FONT_DESC:
            if (self->font_desc)
                pango_font_description_free(self->font_desc);
            self->font_desc = pango_font_description_copy(g_value_get_boxed(value));
            pango_font_description_set_size(self->font_desc, 96 * PANGO_SCALE);
            break;
        case PROP_CELL_TEXT:
            g_clear_pointer(&self->cell_text, g_free);
            self->cell_text = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
unicode_character_map_zoom_window_get_property (GObject *gobject,
                                                guint prop_id,
                                                GValue *value,
                                                GParamSpec *pspec)
{
    UnicodeCharacterMapZoomWindow *self = UNICODE_CHARACTER_MAP_ZOOM_WINDOW(gobject);
    switch (prop_id) {
        case PROP_ACTIVE_CELL:
            g_value_set_int(value, self->active_cell);
            break;
        case PROP_FONT_DESC:
            g_value_set_boxed(value, self->font_desc);
            break;
        case PROP_CELL_TEXT:
            g_value_set_string(value, self->cell_text);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
unicode_character_map_zoom_window_constructed (GObject *gobject)
{
    UnicodeCharacterMapZoomWindow *self = UNICODE_CHARACTER_MAP_ZOOM_WINDOW(gobject);
    self->font_desc = pango_font_description_from_string("Sans 96");
    g_signal_connect_after(self->drawing_area, "draw", G_CALLBACK(on_draw), self);
    G_OBJECT_CLASS(unicode_character_map_zoom_window_parent_class)->constructed(gobject);
    return;
}

static void
unicode_character_map_zoom_window_init (UnicodeCharacterMapZoomWindow *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_init_template(GTK_WIDGET(self));
    return;
}

static void
unicode_character_map_zoom_window_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    UnicodeCharacterMapZoomWindow *self = UNICODE_CHARACTER_MAP_ZOOM_WINDOW(gobject);
    g_clear_pointer(&self->font_desc, pango_font_description_free);
    unicode_character_map_zoom_window_clear_layout(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(unicode_character_map_zoom_window_parent_class)->dispose(gobject);
    return;
}

static void
unicode_character_map_zoom_window_class_init (UnicodeCharacterMapZoomWindowClass *klass)
{
    g_return_if_fail(klass != NULL);
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = unicode_character_map_zoom_window_dispose;
    object_class->constructed = unicode_character_map_zoom_window_constructed;
    object_class->get_property = unicode_character_map_zoom_window_get_property;
    object_class->set_property = unicode_character_map_zoom_window_set_property;

    widget_class->style_updated = unicode_character_map_zoom_window_clear_layout;

    gtk_widget_class_set_template_from_resource(widget_class, UI_RESOURCE_PATH);
    gtk_widget_class_bind_template_child(widget_class, UnicodeCharacterMapZoomWindow, drawing_area);
    gtk_widget_class_bind_template_callback(widget_class, on_copy_clicked);

    obj_properties[PROP_FONT_DESC] = g_param_spec_boxed("font-desc",
                                                        NULL,
                                                        "PangoFontDescription",
                                                        PANGO_TYPE_FONT_DESCRIPTION,
                                                        DEFAULT_PARAM_FLAGS);

    obj_properties[PROP_ACTIVE_CELL] = g_param_spec_int("active-cell",
                                                        NULL,
                                                        "Active cell in character map",
                                                        G_MININT,
                                                        G_MAXINT,
                                                        0,
                                                        DEFAULT_PARAM_FLAGS);

    obj_properties[PROP_CELL_TEXT] = g_param_spec_string("cell-text",
                                                         NULL,
                                                         "Text to display",
                                                         NULL,
                                                         DEFAULT_PARAM_FLAGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);

    return;
}

/**
 * unicode_character_map_zoom_window_new:
 *
 * Returns: (transfer full): A newly created #UnicodeCharacterMapZoomWindow.
 * Free the returned object using #g_object_unref().
 */
UnicodeCharacterMapZoomWindow *
unicode_character_map_zoom_window_new (void)
{
    return g_object_new(UNICODE_TYPE_CHARACTER_MAP_ZOOM_WINDOW, NULL);
}
