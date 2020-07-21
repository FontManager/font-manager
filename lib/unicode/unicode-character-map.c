/* unicode-character-map.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017 - 2020 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
 * Copyright © 2007, 2008, 2010 Christian Persch
 *
 * Some code copied from gtk+/gtk/gtkiconview:
 * Copyright © 2002, 2004  Anders Carlsson <andersca@gnu.org>
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

#include <math.h>
#include <glib/gi18n-lib.h>
#include <gtk/gtk.h>

#include "unicode-info.h"
#include "unicode-codepoint-list.h"
#include "unicode-character-map.h"
#include "unicode-character-map-zoom-window.h"

/**
 * SECTION: unicode-character-map
 * @short_description: Browse available characters
 * @title: UnicodeCharacterMap
 * @include: unicode-character-map.h
 *
 * Widget which displays all the available characters in the selected font.
 */

#define VALID_FONT_SIZE(X) (X < 6.0 ? 6.0 : X > 96.0 ? 96.0 : X)

/* Notes
 *
 * 1. Table geometry
 * The allocated rectangle is divided into ::rows rows and ::col columns,
 * numbered 0..rows-1 and 0..cols-1.
 * The available width (height) is divided evenly between all columns (rows).
 * The remaining space is distributed among the columns (rows) so that
 * columns cols-n_padded_columns .. cols-1 (rows rows-n_padded_rows .. rows)
 * are 1px wider (taller) than the others.
 */


typedef struct
{
    /* GtkScrollable implementation */
    gulong vadjustment_changed_handler_id;
    GtkAdjustment *vadjustment;
    GtkAdjustment *hadjustment; /* unused */
    guint hscroll_policy : 1;    /* unused */
    guint vscroll_policy : 1;

    /* Font */
    PangoFontDescription *font_desc;

    /* Geometry */
    int rows;
    int cols;
    int minimal_column_width;     /* depends on font_desc and size allocation */
    int minimal_row_height;       /* depends on font_desc and size allocation */
    int n_padded_columns;         /* columns 0..n-1 will be 1px wider than minimal_column_width */
    int n_padded_rows;            /* rows 0..n-1 will be 1px taller than minimal_row_height */
    int page_size;                /* rows * cols */
    int page_first_cell;          /* the cell index of the top left corner */
    int active_cell;              /* the active cell index */
    int last_cell;                /* from unicode_codepoint_list_get_last_index */

    /* Drawing */
    PangoLayout *pango_layout;

    /* Drag and Drop */
    GtkTargetList *target_list;
    gdouble click_x, click_y;

    /* Touch events */
    GtkGesture *long_press;
    GtkGesture *pinch_zoom;

    UnicodeCodepointList *codepoint_list;
    UnicodeCharacterMapZoomWindow *popover;
    double preview_size;
}
UnicodeCharacterMapPrivate;

/* Type definition */
G_DEFINE_TYPE_WITH_CODE (UnicodeCharacterMap, unicode_character_map,
                         GTK_TYPE_DRAWING_AREA,
                         G_IMPLEMENT_INTERFACE(GTK_TYPE_SCROLLABLE, NULL)
                         G_ADD_PRIVATE(UnicodeCharacterMap))

/* XXX: FIXME! Set during initial construction - this IS a bad idea */
UnicodeCharacterMapPrivate *priv = NULL;

/* These are chosen for compatibility with the older code that didn't
 * scale the font size by resolution and used 3 and 2.5 here, resp.
 * Where exactly these factors came from, I don't know.
 */
#define FACTOR_WIDTH (2.25) /* 3 / (96 / 72) */
#define FACTOR_HEIGHT (1.875) /* 2.5 / (96 / 72) */
#define DEFAULT_FONT_SIZE (20.0 * (double) PANGO_SCALE)

enum
{
    ACTIVATE,
    STATUS_MESSAGE,
    MOVE_CURSOR,
    COPY_CLIPBOARD,
    PASTE_CLIPBOARD,
    NUM_SIGNALS
};

static guint signals[NUM_SIGNALS];

enum
{
    PROP_0,
    PROP_HADJUSTMENT,
    PROP_VADJUSTMENT,
    PROP_HSCROLL_POLICY,
    PROP_VSCROLL_POLICY,
    PROP_ACTIVE_CHAR,
    PROP_CODEPOINT_LIST,
    PROP_FONT_DESC,
    PROP_PREVIEW_SIZE
};

/* Utility functions */

static void
update_scrollbar_adjustment (UnicodeCharacterMap *charmap)
{
    g_return_if_fail(charmap != NULL);
    GtkAdjustment *vadjustment = priv->vadjustment;
    if (vadjustment != NULL) {
        gtk_adjustment_configure(vadjustment,
                                 priv->page_first_cell / priv->rows,
                                 0 /* lower */,
                                 priv->last_cell / priv->cols + 1 /* upper */,
                                 1 /* step increment */,
                                 priv->rows /* page increment */,
                                 priv->rows);
    }
    return;
}

static void
unicode_character_map_clear_pango_layout (UnicodeCharacterMap *charmap)
{
    g_return_if_fail(charmap != NULL);
    if (priv->pango_layout) {
        g_object_unref(priv->pango_layout);
        priv->pango_layout = NULL;
    }
    return;
}

static void
unicode_character_map_ensure_pango_layout (UnicodeCharacterMap *charmap)
{
    g_return_if_fail(charmap != NULL);
    if (priv->pango_layout == NULL) {
        priv->pango_layout = gtk_widget_create_pango_layout(GTK_WIDGET(charmap), NULL);
        pango_layout_set_font_description(priv->pango_layout, priv->font_desc);
        PangoAttrList *attrs = pango_attr_list_new();
        pango_attr_list_insert(attrs, pango_attr_fallback_new (FALSE));
        pango_layout_set_attributes(priv->pango_layout, attrs);
        pango_attr_list_unref(attrs);
    }
    return;
}

static void
unicode_character_map_emit_status_message (UnicodeCharacterMap *charmap, const char *message)
{
    g_signal_emit(charmap, signals[STATUS_MESSAGE], 0, message);
    return;
}

static gint
get_cell_at_rowcol (UnicodeCharacterMap *charmap, gint row, gint col)
{
    /* Depends on directionality */
    if (gtk_widget_get_direction(GTK_WIDGET(charmap)) == GTK_TEXT_DIR_RTL)
        return priv->page_first_cell + row * priv->cols + (priv->cols - col - 1);
    else
        return priv->page_first_cell + row * priv->cols + col;
}

static gint
unicode_character_map_cell_column (UnicodeCharacterMap *charmap, guint cell)
{
    /* Depends on directionality. Column 0 is the furthest left. */
    if (gtk_widget_get_direction(GTK_WIDGET(charmap)) == GTK_TEXT_DIR_RTL)
        return priv->cols - (cell - priv->page_first_cell) % priv->cols - 1;
    else
        return (cell - priv->page_first_cell) % priv->cols;
}

static gint
unicode_character_map_column_width (UnicodeCharacterMap *charmap, gint col)
{
    g_return_val_if_fail(charmap != NULL, priv->minimal_column_width);
    /* Not all columns are necessarily the same width because of padding */
    if (priv->cols - col <= priv->n_padded_columns)
        return priv->minimal_column_width + 1;
    else
        return priv->minimal_column_width;
}

/* Calculate the position of the left end of the column (just to the right
 * of the left border)
 * XXX: calling this repeatedly is not the most efficient, but it probably
 * is the most readable
 */
static gint
unicode_character_map_x_offset (UnicodeCharacterMap *charmap, gint col)
{
    gint c, x;
    for (c = 0, x = 1; c < col; c++)
        x += unicode_character_map_column_width(charmap, c);
    return x;
}


static gint
unicode_character_map_row_height (UnicodeCharacterMap *charmap, gint row)
{
    g_return_val_if_fail(charmap != NULL, priv->minimal_row_height);
    /* Not all rows are necessarily the same height because of padding */
    if (priv->rows - row <= priv->n_padded_rows)
        return priv->minimal_row_height + 1;
    else
        return priv->minimal_row_height;
}

/* Calculate the position of the top end of the row (just below the top
 * border)
 * XXX: calling this repeatedly is not the most efficient, but it probably
 * is the most readable
 */
static gint
unicode_character_map_y_offset (UnicodeCharacterMap *charmap, gint row)
{
    gint r, y;
    for (r = 0, y = 1; r < row; r++)
        y += unicode_character_map_row_height(charmap, r);
    return y;
}

static PangoLayout *
layout_scaled_glyph (UnicodeCharacterMap *charmap, gunichar uc, double font_factor)
{
    PangoFontDescription *font_desc;
    PangoLayout *layout;
    gchar buf[11];

    font_desc = pango_font_description_copy(priv->font_desc);
    double font_size = font_factor * pango_font_description_get_size(priv->font_desc);

    if (pango_font_description_get_size_is_absolute(priv->font_desc))
        pango_font_description_set_absolute_size(font_desc, font_size);
    else
        pango_font_description_set_size(font_desc, (int) font_size);

    unicode_character_map_ensure_pango_layout(charmap);
    layout = pango_layout_new(pango_layout_get_context (priv->pango_layout));
    pango_layout_set_font_description(layout, font_desc);
    buf[unicode_unichar_to_printable_utf8(uc, buf)] = '\0';
    pango_layout_set_text(layout, buf, -1);
    pango_font_description_free(font_desc);
    return layout;
}

static cairo_surface_t *
create_glyph_surface (UnicodeCharacterMap *charmap, gunichar wc, double font_factor)
{
    GtkWidget *widget = GTK_WIDGET(charmap);
    enum { PADDING = 16 };
    gint width, height;
    PangoRectangle char_rect;

    PangoLayout *pango_layout = layout_scaled_glyph(charmap, wc, font_factor);
    pango_layout_get_pixel_extents(pango_layout, &char_rect, NULL);
    width  = char_rect.width + 2 * PADDING;
    height = char_rect.height + 2 * PADDING;

    GdkWindow *window = gtk_widget_get_window(widget);
    cairo_surface_t *surface = gdk_window_create_similar_surface(window,
                                                                   CAIRO_CONTENT_COLOR,
                                                                   width,
                                                                   height);
    cairo_t *cr = cairo_create(surface);
    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    gtk_render_background(ctx, cr, 0, 0, width, height);
    /* Draw a subtle border effect */
    gtk_style_context_save(ctx);
    gtk_style_context_set_state(ctx, GTK_STATE_FLAG_INSENSITIVE | GTK_STATE_FLAG_BACKDROP);
    gtk_render_focus(ctx, cr, 0, 0, width, height);
    gtk_render_focus(ctx, cr, 0, 0, width + 1, height + 1);
    gtk_style_context_restore(ctx);
    /* The coordinates are adapted in order to compensate negative char_rect offsets. */
    gtk_render_layout(ctx, cr, -char_rect.x + PADDING, -char_rect.y + PADDING, pango_layout);
    g_object_unref(pango_layout);
    cairo_destroy(cr);
    return surface;
}

static int
get_font_size_px (UnicodeCharacterMap *charmap)
{
    g_assert(priv->font_desc != NULL);

    int font_size;
    GtkWidget *widget = GTK_WIDGET(charmap);
    GdkScreen *screen = gtk_widget_get_screen(widget);
    double resolution = gdk_screen_get_resolution(screen);

    /* -1 if not set */
    if (resolution < 0.0)
        resolution = 96.0;

    font_size = pango_font_description_get_size(priv->font_desc);

    if (PANGO_PIXELS(font_size) <= 0)
        font_size = DEFAULT_FONT_SIZE * resolution / 72.0;

    return PANGO_PIXELS(font_size);
}

static gint
get_cell_at_xy (UnicodeCharacterMap *charmap, gint x, gint y)
{
    gint c, r, x0, y0, cell;

    for (c = 0, x0 = 0;  x0 <= x && c < priv->cols;  c++)
        x0 += unicode_character_map_column_width (charmap, c);

    for (r = 0, y0 = 0;  y0 <= y && r < priv->rows;  r++)
        y0 += unicode_character_map_row_height (charmap, r);

    cell = get_cell_at_rowcol (charmap, r-1, c-1);

    if (cell > priv->last_cell)
        return priv->last_cell;

    return cell;
}


static void
draw_character (UnicodeCharacterMap *charmap,
                cairo_t *cr,
                cairo_rectangle_int_t *rect,
                gint row,
                gint col)
{
    GtkWidget *widget = GTK_WIDGET(charmap);
    int n, char_width, char_height;
    guint cell;
    gchar buf[10];

    cell = get_cell_at_rowcol(charmap, row, col);
    gunichar wc = unicode_codepoint_list_get_char(priv->codepoint_list, cell);

    if (wc > UNICODE_UNICHAR_MAX ||
        !unicode_unichar_validate(wc) ||
        !unicode_unichar_isdefined(wc))
        return;

    n = unicode_unichar_to_printable_utf8(wc, buf);
    pango_layout_set_text(priv->pango_layout, buf, n);

    /* Keep the square empty if the font has no glyph for this cell. */
    if (pango_layout_get_unknown_glyphs_count(priv->pango_layout) > 0)
        return;

    GtkStyleContext *ctx;
    ctx = gtk_widget_get_style_context(widget);
    gtk_style_context_save(ctx);
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_CELL);
    GtkStateFlags _state = GTK_STATE_FLAG_NORMAL;
    if (gtk_widget_has_focus(widget) && (gint) cell == priv->active_cell)
        _state = GTK_STATE_FLAG_SELECTED | GTK_STATE_FLAG_FOCUSED;
    else if ((gint) cell == priv->active_cell)
        _state = GTK_STATE_FLAG_INSENSITIVE | GTK_STATE_FLAG_SELECTED;
    gtk_style_context_set_state(ctx, _state);
    pango_layout_get_pixel_size(priv->pango_layout, &char_width, &char_height);
    gtk_render_layout(ctx, cr,
                      rect->x + (rect->width - char_width - 2 + 1) / 2,
                      rect->y + (rect->height - char_height - 2 + 1) / 2,
                      priv->pango_layout);
    gtk_style_context_restore(ctx);
    return;
}

static void
expose_cell (UnicodeCharacterMap *charmap, guint cell)
{
    gint row = (cell - priv->page_first_cell) / priv->cols;
    gint col = unicode_character_map_cell_column(charmap, cell);

    if ((row >= 0 && row < priv->rows) && (col >= 0 && col < priv->cols)) {
        gtk_widget_queue_draw_area(GTK_WIDGET(charmap),
                                    unicode_character_map_x_offset(charmap, col),
                                    unicode_character_map_y_offset(charmap, row),
                                    unicode_character_map_column_width(charmap, col),
                                    unicode_character_map_row_height(charmap, row));
    }

    return;
}

static void
draw_square_bg (UnicodeCharacterMap *charmap,
                cairo_t *cr,
                cairo_rectangle_int_t  *rect,
                gint row,
                gint col)
{
    GtkWidget *widget = GTK_WIDGET(charmap);
    gint cell = (gint) get_cell_at_rowcol(charmap, row, col);
    gunichar wc = unicode_codepoint_list_get_char(priv->codepoint_list, cell);

    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    gtk_style_context_save(ctx);

    GtkStateFlags _state = GTK_STATE_FLAG_NORMAL;
    if (gtk_widget_has_focus(widget) && cell == priv->active_cell)
        _state = GTK_STATE_FLAG_SELECTED;
    else if (cell == priv->active_cell)
        _state = GTK_STATE_FLAG_INSENSITIVE | GTK_STATE_FLAG_SELECTED;
    else if (!wc || !unicode_unichar_validate(wc) || !unicode_unichar_isdefined(wc))
        _state = GTK_STATE_FLAG_INSENSITIVE;
    else
        _state = GTK_STATE_FLAG_NORMAL;

    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_CELL);
    gtk_style_context_set_state(ctx, _state);
    gtk_render_background(ctx, cr, rect->x, rect->y, rect->width, rect->height);
    gtk_style_context_restore(ctx);
    return;
}

static void
draw_separators (UnicodeCharacterMap *charmap, cairo_t *cr)
{
    GtkWidget *widget = GTK_WIDGET(charmap);
    gint x, y, col, row;
    GtkAllocation allocation;

    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    gtk_style_context_save(ctx);
    /* Set insensitive flag so our lines have less contrast */
    gtk_style_context_set_state(ctx, GTK_STATE_FLAG_INSENSITIVE | GTK_STATE_FLAG_BACKDROP);
    gtk_widget_get_allocation(widget, &allocation);
    /* Vertical */
    gtk_render_line(ctx, cr, 0, 0, 0, allocation.height);
    for (col = 0, x = 0;  col < priv->cols;  col++) {
        x += unicode_character_map_column_width(charmap, col);
        gtk_render_line(ctx, cr, x, 0, x, allocation.height);
    }
    /* Horizontal */
    gtk_render_line(ctx, cr, 0, 0, allocation.width, 0);
    for (row = 0, y = 0;  row < priv->rows;  row++) {
        y += unicode_character_map_row_height(charmap, row);
        gtk_render_line(ctx, cr, 0, y, allocation.width, y);
    }
    gtk_style_context_restore(ctx);
    return;
}

static void
unicode_character_map_set_active_cell (UnicodeCharacterMap *charmap, gint cell)
{
    GtkWidget *widget = GTK_WIDGET(charmap);

    if (cell == priv->active_cell)
        return;

    if (cell < 0)
        cell = 0;
    else if (cell > priv->last_cell)
        cell = priv->last_cell;

    int old_active_cell = priv->active_cell;
    int old_page_first_cell = priv->page_first_cell;

    priv->active_cell = cell;

    if (cell < priv->page_first_cell || cell >= priv->page_first_cell + priv->page_size) {
        int old_row = old_active_cell / priv->cols;
        int new_row = cell / priv->cols;
        int new_page_first_cell = old_page_first_cell + ((new_row - old_row) * priv->cols);
        int last_row = (priv->last_cell / priv->cols) + 1;
        int last_page_first_row = last_row - priv->rows;
        int last_page_first_cell = (last_page_first_row * priv->cols) + 1;
        priv->page_first_cell = CLAMP(new_page_first_cell, 0, last_page_first_cell);
        if (priv->vadjustment)
            gtk_adjustment_set_value(priv->vadjustment, priv->page_first_cell / priv->cols);
    } else if (gtk_widget_get_realized(widget)) {
        /* Clear previous selection */
        expose_cell(charmap, old_active_cell);
        /* Update selected cell */
        expose_cell(charmap, cell);
    }

    g_object_notify(G_OBJECT(charmap), "active-character");
    return;
}

static void
vadjustment_value_changed_cb (GtkAdjustment *vadjustment, UnicodeCharacterMap *charmap)
{
    int row = (int) gtk_adjustment_get_value (vadjustment);

    if (row < 0 )
        row = 0;

    int first_cell = row * priv->cols;
    if (first_cell == priv->page_first_cell)
        return;

    gtk_widget_queue_draw(GTK_WIDGET(charmap));

    priv->page_first_cell = first_cell;
    return;
}

static void
unicode_character_map_set_font_desc_internal (UnicodeCharacterMap *charmap,
                                              PangoFontDescription *font_desc /* adopting */)
{
    if (!font_desc)
        return;
    if (priv->font_desc)
        pango_font_description_free(priv->font_desc);
    priv->font_desc = font_desc;
    pango_font_description_set_size(priv->font_desc, priv->preview_size * PANGO_SCALE);
    unicode_character_map_clear_pango_layout(charmap);
    gtk_widget_queue_resize(GTK_WIDGET(charmap));
    unicode_character_map_set_active_cell(charmap, 1);
    update_scrollbar_adjustment(charmap);
    g_object_notify(G_OBJECT(charmap), "font-desc");
    g_object_notify(G_OBJECT(charmap), "active-character");
    return;
}

static void
unicode_character_map_show_info(UnicodeCharacterMap *self, gdouble x, gdouble y)
{
    g_return_if_fail(self != NULL);

    if (priv->active_cell >= unicode_codepoint_list_get_last_index(priv->codepoint_list))
        return;

    if (!priv->popover) {
        priv->popover = unicode_character_map_zoom_window_new();
        gtk_popover_set_relative_to((GtkPopover *) priv->popover, (GtkWidget *) self);
        GBindingFlags flags = G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE;
        g_object_bind_property(self, "font-desc", priv->popover, "font-desc", flags);
        g_object_bind_property(self, "active-character", priv->popover, "active-character", flags);
    }

    gint row = (priv->active_cell - priv->page_first_cell) / priv->cols;
    gint col = unicode_character_map_cell_column(self, priv->active_cell);

    if ((row >= 0 && row < priv->rows) && (col >= 0 && col < priv->cols)) {
        gint x_offset = unicode_character_map_x_offset(self, col);
        gint column_width = unicode_character_map_column_width(self, col);
        gint y_offset = unicode_character_map_y_offset(self, row);
        GdkRectangle rect = { x_offset + (column_width / 2), y_offset, 1, 1 };
        gtk_popover_set_pointing_to((GtkPopover *) priv->popover, &rect);
    } else {
        GdkRectangle rect = { x, y, 1, 1 };
        gtk_popover_set_pointing_to((GtkPopover *) priv->popover, &rect);
    }

    gtk_popover_popup((GtkPopover *) priv->popover);
    return;
}

/* GtkWidget class methods */

/* - single click: select character
 * - double-click: emit activate signal
 */
static gboolean
unicode_character_map_button_press (GtkWidget *widget, GdkEventButton *event)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);
    GtkWidgetClass *cls = GTK_WIDGET_CLASS(unicode_character_map_parent_class);

    /* In case we lost keyboard focus and are clicking to get it back */
    gtk_widget_grab_focus(widget);

    gdouble x, y;

    if (!gdk_event_get_coords((GdkEvent *) event, &x, &y))
        return cls->button_press_event(widget, event);

    guint button;

    if (!gdk_event_get_button((GdkEvent *) event, &button))
        return cls->button_press_event(widget, event);

    /* Drag and Drop */
    if (button == GDK_BUTTON_PRIMARY) {
        priv->click_x = x;
        priv->click_y = y;
    }

    GdkEventType event_type = gdk_event_get_event_type((GdkEvent *) event);

    /* single-click */
    if ((button == GDK_BUTTON_PRIMARY && event_type == GDK_BUTTON_PRESS)) {
        unicode_character_map_set_active_cell(charmap, get_cell_at_xy(charmap, x, y));
    /* double-click */
    } else if (button == GDK_BUTTON_PRIMARY && event_type == GDK_2BUTTON_PRESS) {
        g_signal_emit(charmap, signals[ACTIVATE], 0);
    /* right-click */
    } else if (gdk_event_triggers_context_menu((GdkEvent *) event)) {
        unicode_character_map_set_active_cell(charmap, get_cell_at_xy(charmap, x, y));
        unicode_character_map_show_info(charmap, x, y);
    }

    return cls->button_press_event(widget, event);
}

static void
unicode_character_map_drag_begin (GtkWidget *widget, GdkDragContext *context)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);
    double scale;
    int font_size_px;
    cairo_surface_t *drag_surface;
    GdkRectangle geometry;

    font_size_px = get_font_size_px(charmap);
    GdkDisplay *display = gtk_widget_get_display(widget);
    GdkWindow *window = gtk_widget_get_window(widget);
    GdkMonitor *monitor = gdk_display_get_monitor_at_window(display, window);
    gdk_monitor_get_geometry(monitor, &geometry);
    scale = CLAMP(((0.3 * geometry.height) / (FACTOR_WIDTH * font_size_px)), 1.0, 5.0);
    drag_surface = create_glyph_surface(charmap,
                                        unicode_character_map_get_active_character(charmap),
                                        scale);
    gtk_drag_set_icon_surface(context, drag_surface);
    cairo_surface_destroy(drag_surface);
    /* no need to chain up */
    return;
}

static void
unicode_character_map_drag_data_get (G_GNUC_UNUSED GtkWidget *widget,
                                     G_GNUC_UNUSED GdkDragContext *context,
                                     GtkSelectionData *selection_data,
                                     G_GNUC_UNUSED guint info,
                                     G_GNUC_UNUSED guint time)
{
    gchar buf[7];
    gunichar wc = unicode_codepoint_list_get_char(priv->codepoint_list, priv->active_cell);
    gint n = g_unichar_to_utf8(wc, buf);
    gtk_selection_data_set_text(selection_data, buf, n);
    /* no need to chain up */
    return;
}

static void
unicode_character_map_drag_data_received (GtkWidget *widget,
                                          G_GNUC_UNUSED GdkDragContext *context,
                                          G_GNUC_UNUSED gint x, G_GNUC_UNUSED gint y,
                                          GtkSelectionData *selection_data,
                                          G_GNUC_UNUSED guint info,
                                          G_GNUC_UNUSED guint time)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);
    g_autofree gchar *text = NULL;
    gunichar wc;

    if (gtk_selection_data_get_length(selection_data) <= 0 ||
        gtk_selection_data_get_data(selection_data) == NULL)
        return;

    text = (gchar *) gtk_selection_data_get_text(selection_data);

    if (text == NULL) /* XXX: say something in the statusbar? */
        return;

    wc = g_utf8_get_char_validated(text, -1);

    if (wc == (gunichar)(-2) || wc == (gunichar)(-1) || wc > UNICODE_UNICHAR_MAX)
        unicode_character_map_emit_status_message(charmap, _("Unknown character, unable to identify."));
    else if (unicode_codepoint_list_get_index(priv->codepoint_list, wc) == -1)
        unicode_character_map_emit_status_message(charmap, _("Not found."));
    else {
        unicode_character_map_emit_status_message(charmap, _("Character found."));
        unicode_character_map_set_active_character(charmap, wc);
    }
    /* no need to chain up */
    return;
}

static gboolean
unicode_character_map_draw (GtkWidget *widget, cairo_t *cr)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);
    cairo_rectangle_int_t clip_rect;
    cairo_region_t *region;

    if (!gdk_cairo_get_clip_rectangle(cr, &clip_rect))
        return FALSE;

    region = cairo_region_create_rectangle(&clip_rect);

    if (cairo_region_is_empty(region))
        goto expose_done;

    GtkAllocation allocation;

    gtk_widget_get_allocation(widget, &allocation);

    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    gtk_render_background(ctx, cr, allocation.x, allocation.y, allocation.width, allocation.height);

    if (priv->codepoint_list == NULL)
        goto expose_done;

    unicode_character_map_ensure_pango_layout(charmap);

    for (int row = priv->rows - 1; row >= 0; --row) {

        for (int col = priv->cols - 1; col >= 0; --col)  {

            cairo_rectangle_int_t rect;

            rect.x = unicode_character_map_x_offset(charmap, col);
            rect.y = unicode_character_map_y_offset(charmap, row);
            rect.width = unicode_character_map_column_width(charmap, col);
            rect.height = unicode_character_map_row_height(charmap, row);

            if (cairo_region_contains_rectangle(region, &rect) == CAIRO_REGION_OVERLAP_OUT)
                continue;

            draw_square_bg(charmap, cr, &rect, row, col);
            draw_character(charmap, cr, &rect, row, col);

        }

    }

    draw_separators(charmap, cr);

expose_done:

    cairo_region_destroy(region);
    /* no need to chain up */
    return FALSE;
}


static gboolean
unicode_character_map_motion_notify (GtkWidget *widget, GdkEventMotion *event)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);
    gboolean (* motion_notify_event) (GtkWidget *, GdkEventMotion *) =
    GTK_WIDGET_CLASS (unicode_character_map_parent_class)->motion_notify_event;

    if ((event->state & GDK_BUTTON1_MASK) &&
        gtk_drag_check_threshold(widget, priv->click_x, priv->click_y, event->x, event->y) &&
        unicode_unichar_validate(unicode_character_map_get_active_character(charmap)))
    {
        gtk_drag_begin_with_coordinates(widget,
                                        priv->target_list,
                                        GDK_ACTION_COPY,
                                        1,
                                        (GdkEvent *) event,
                                        -1, -1);
    }

    if (motion_notify_event)
        motion_notify_event(widget, event);
    return FALSE;
}

#define FIRST_CELL_IN_SAME_ROW(x) ((x) - ((x) % priv->cols))

static void
unicode_character_map_size_allocate (GtkWidget *widget, GtkAllocation *allocation)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);
    int old_rows, old_cols;
    int total_extra_pixels;
    int new_first_cell;
    int bare_minimal_column_width, bare_minimal_row_height;
    int font_size_px;
    GtkAllocation widget_allocation;

    GTK_WIDGET_CLASS(unicode_character_map_parent_class)->size_allocate(widget, allocation);

    gtk_widget_get_allocation(widget, &widget_allocation);
    allocation = &widget_allocation;

    old_rows = priv->rows;
    old_cols = priv->cols;

    font_size_px = get_font_size_px(charmap);

    /* FIXMEchpe bug 329481 */
    bare_minimal_column_width = FACTOR_WIDTH * font_size_px;
    bare_minimal_row_height = FACTOR_HEIGHT * font_size_px;

    priv->cols = (allocation->width - 1) / bare_minimal_column_width;
    priv->rows = (allocation->height - 1) / bare_minimal_row_height;

    /* Avoid a horrible floating point exception crash */
    if (priv->rows < 1)
        priv->rows = 1;
    if (priv->cols < 1)
        priv->cols = 1;

    priv->page_size = priv->rows * priv->cols;

    total_extra_pixels = allocation->width - (priv->cols * bare_minimal_column_width + 1);
    priv->minimal_column_width = bare_minimal_column_width + total_extra_pixels / priv->cols;
    priv->n_padded_columns = allocation->width - (priv->minimal_column_width * priv->cols + 1);

    total_extra_pixels = allocation->height - (priv->rows * bare_minimal_row_height + 1);
    priv->minimal_row_height = bare_minimal_row_height + total_extra_pixels / priv->rows;
    priv->n_padded_rows = allocation->height - (priv->minimal_row_height * priv->rows + 1);

    if (priv->rows == old_rows && priv->cols == old_cols)
        return;

    /* Need to recalculate the first cell, see bug #517188 */
    new_first_cell = FIRST_CELL_IN_SAME_ROW(priv->active_cell);
    if ((new_first_cell + priv->rows*priv->cols) > (priv->last_cell)) {
        /* Last cell is visible, so make sure it is in the last row */
        new_first_cell = FIRST_CELL_IN_SAME_ROW(priv->last_cell) - priv->page_size + priv->cols;
        if (new_first_cell < 0)
            new_first_cell = 0;
    }
    priv->page_first_cell = new_first_cell;
    update_scrollbar_adjustment(charmap);
    return;
}

static void
unicode_character_map_get_preferred_width (GtkWidget *widget, gint *minimum, gint *natural)
{
    int font_size_px = get_font_size_px(UNICODE_CHARACTER_MAP(widget));
    *minimum = *natural = FACTOR_WIDTH * font_size_px;
    return;
}

static void
unicode_character_map_get_preferred_height (GtkWidget *widget, gint *minimum, gint *natural)
{
    int font_size_px = get_font_size_px(UNICODE_CHARACTER_MAP(widget));
    *minimum = *natural = FACTOR_HEIGHT * font_size_px;
    return;
}

static void
unicode_character_map_style_updated (GtkWidget *widget)
{
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(widget);

    GTK_WIDGET_CLASS(unicode_character_map_parent_class)->style_updated(widget);

    unicode_character_map_clear_pango_layout(charmap);

    if (priv->font_desc == NULL) {
        GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
        PangoFontDescription *_font_desc;
        gtk_style_context_get(ctx, GTK_STATE_FLAG_NORMAL, "font", &_font_desc, NULL);
        PangoFontDescription *font_desc = pango_font_description_copy(_font_desc);
        pango_font_description_free(_font_desc);
        /* Use twice the size of the default font */
        gint new_size =  2 * pango_font_description_get_size(font_desc);
        if (pango_font_description_get_size_is_absolute(font_desc))
            pango_font_description_set_absolute_size(font_desc, (double) new_size);
        else
            pango_font_description_set_size(font_desc, new_size);
        unicode_character_map_set_font_desc_internal(charmap, font_desc /* adopts */);
        g_assert(priv->font_desc != NULL);
    }

    gtk_widget_queue_resize(widget);
    return;
}


/* UnicodeCharacterMap class methods */

static void
unicode_character_map_set_hadjustment (UnicodeCharacterMap *charmap, GtkAdjustment *hadjustment)
{
    g_return_if_fail(charmap != NULL);

    if (hadjustment == priv->hadjustment)
        return;

    if (priv->hadjustment)
        g_object_unref(priv->hadjustment);

    priv->hadjustment = hadjustment ? g_object_ref_sink(hadjustment) : NULL;
    return;
}

static void
unicode_character_map_set_vadjustment (UnicodeCharacterMap *charmap, GtkAdjustment *vadjustment)
{
    if (vadjustment)
        g_return_if_fail(GTK_IS_ADJUSTMENT(vadjustment));
    else
        vadjustment = GTK_ADJUSTMENT(gtk_adjustment_new (0.0, 0.0, 0.0, 0.0, 0.0, 0.0));

    if (priv->vadjustment) {
        g_signal_handler_disconnect(priv->vadjustment, priv->vadjustment_changed_handler_id);
        priv->vadjustment_changed_handler_id = 0;
        g_object_unref(priv->vadjustment);
        priv->vadjustment = NULL;
    }

    if (vadjustment) {
        priv->vadjustment = g_object_ref_sink(vadjustment);
        priv->vadjustment_changed_handler_id = g_signal_connect(vadjustment,
                                                                "value-changed",
                                                                G_CALLBACK(vadjustment_value_changed_cb),
                                                                charmap);
    }

    update_scrollbar_adjustment(charmap);
    return;
}

static void
unicode_character_map_add_move_binding (GtkBindingSet  *binding_set,
                                        guint           keyval,
                                        guint           modmask,
                                        GtkMovementStep step,
                                        gint            count)
{
    gtk_binding_entry_add_signal(binding_set, keyval,
                                modmask,
                                "move-cursor", 2,
                                G_TYPE_ENUM, step,
                                G_TYPE_INT, count);

    gtk_binding_entry_add_signal(binding_set, keyval,
                                GDK_SHIFT_MASK,
                                "move-cursor", 2,
                                G_TYPE_ENUM, step,
                                G_TYPE_INT, count);

    if ((modmask & GDK_CONTROL_MASK) == GDK_CONTROL_MASK)
        return;

    gtk_binding_entry_add_signal(binding_set, keyval,
                                GDK_CONTROL_MASK | GDK_SHIFT_MASK,
                                "move-cursor", 2,
                                G_TYPE_ENUM, step,
                                G_TYPE_INT, count);

    gtk_binding_entry_add_signal(binding_set, keyval,
                                GDK_CONTROL_MASK,
                                "move-cursor", 2,
                                G_TYPE_ENUM, step,
                                G_TYPE_INT, count);

    return;
}

static void
unicode_character_map_move_cursor_left_right (UnicodeCharacterMap *charmap, int count)
{
    gboolean is_rtl = (gtk_widget_get_direction(GTK_WIDGET(charmap)) == GTK_TEXT_DIR_RTL);
    int offset = is_rtl ? -count : count;
    unicode_character_map_set_active_cell(charmap, priv->active_cell + offset);
    return;
}

static void
unicode_character_map_move_cursor_up_down (UnicodeCharacterMap *charmap, int count)
{
    unicode_character_map_set_active_cell(charmap, priv->active_cell + priv->cols * count);
    return;
}

static void
unicode_character_map_move_cursor_page_up_down (UnicodeCharacterMap *charmap, int count)
{
  unicode_character_map_set_active_cell(charmap, priv->active_cell + priv->page_size * count);
  return;
}

static void
unicode_character_map_move_cursor_start_end (UnicodeCharacterMap *charmap, int count)
{
    int new_cell = count > 0 ? priv->last_cell : 0;
    unicode_character_map_set_active_cell(charmap, new_cell);
    return;
}

static gboolean
unicode_character_map_move_cursor (UnicodeCharacterMap *charmap,
                                    GtkMovementStep step,
                                    int count)
{
    switch (step) {
        case GTK_MOVEMENT_LOGICAL_POSITIONS:
        case GTK_MOVEMENT_VISUAL_POSITIONS:
            unicode_character_map_move_cursor_left_right(charmap, count);
            break;
        case GTK_MOVEMENT_DISPLAY_LINES:
            unicode_character_map_move_cursor_up_down(charmap, count);
            break;
        case GTK_MOVEMENT_PAGES:
            unicode_character_map_move_cursor_page_up_down(charmap, count);
            break;
        case GTK_MOVEMENT_BUFFER_ENDS:
            unicode_character_map_move_cursor_start_end(charmap, count);
            break;
        default:
            return FALSE;
    }
    return TRUE;
}

static void
unicode_character_map_copy_clipboard (UnicodeCharacterMap *charmap)
{
    gunichar wc = unicode_character_map_get_active_character(charmap);
    if (unicode_unichar_validate(wc)) {
        gchar utf8[7];
        gsize len = g_unichar_to_utf8(wc, utf8);
        GtkClipboard *clipboard = gtk_widget_get_clipboard(GTK_WIDGET(charmap),
                                                            GDK_SELECTION_CLIPBOARD);
        gtk_clipboard_set_text(clipboard, utf8, len);
    }
    return;
}

static void
unicode_character_map_paste_received_cb (G_GNUC_UNUSED GtkClipboard *clipboard,
                                         const char *text,
                                         gpointer user_data)
{
    gpointer *data = (gpointer *) user_data;
    UnicodeCharacterMap *charmap = *data;

    g_slice_free(gpointer, data);
    g_return_if_fail(charmap != NULL);
    g_object_remove_weak_pointer(G_OBJECT(charmap), data);
    g_return_if_fail(text != NULL);

    gunichar wc = g_utf8_get_char_validated(text, -1);
    if (wc == 0 || !unicode_unichar_validate(wc)) {
        gtk_widget_error_bell(GTK_WIDGET(charmap));
        return;
    }
    unicode_character_map_set_active_character(charmap, wc);
    return;
}

static void
unicode_character_map_paste_clipboard (UnicodeCharacterMap *charmap)
{
    g_return_if_fail(gtk_widget_get_realized(GTK_WIDGET(charmap)));

    gpointer *data = g_slice_new(gpointer);
    GtkClipboard *clipboard = gtk_widget_get_clipboard(GTK_WIDGET(charmap), GDK_SELECTION_CLIPBOARD);
    *data = charmap;
    g_object_add_weak_pointer(G_OBJECT(charmap), data);
    gtk_clipboard_request_text(clipboard, unicode_character_map_paste_received_cb, data);
    return;
}

void
unicode_character_map_on_long_press (G_GNUC_UNUSED GtkGestureLongPress *gesture,
                                     gdouble x,
                                     gdouble y,
                                     gpointer charmap)
{
    unicode_character_map_set_active_cell(charmap, get_cell_at_xy(charmap, x, y));
    unicode_character_map_show_info(charmap, x, y);
    return;
}

void
unicode_character_map_on_pinch_zoom (G_GNUC_UNUSED GtkGestureZoom *gesture,
                                     gdouble scale_factor,
                                     gpointer charmap)
{
    gdouble size = nearbyint(priv->preview_size * scale_factor);
    unicode_character_map_set_preview_size(charmap, VALID_FONT_SIZE(size));
    return;
}

/* Does all the initial construction */
static void
unicode_character_map_init (UnicodeCharacterMap *charmap)
{
    priv = unicode_character_map_get_instance_private(charmap);
    priv->page_first_cell = 0;
    priv->active_cell = 0;
    priv->rows = 1;
    priv->cols = 1;
    priv->vadjustment = NULL;
    priv->hadjustment = NULL;
    priv->hscroll_policy = GTK_SCROLL_NATURAL;
    priv->vscroll_policy = GTK_SCROLL_NATURAL;
    priv->target_list = gtk_target_list_new(NULL, 0);
    priv->preview_size = 14;
    priv->codepoint_list = NULL;
    priv->popover = NULL;

    GtkWidget *widget = GTK_WIDGET(charmap);
    gtk_widget_set_events(widget, GDK_ALL_EVENTS_MASK);
    /* This is required to get key press events */
    gtk_widget_set_can_focus(widget, TRUE);
    /* Touch events */
    priv->long_press = gtk_gesture_long_press_new(widget);
    g_signal_connect(priv->long_press, "pressed",
                     G_CALLBACK(unicode_character_map_on_long_press),
                     widget);
    priv->pinch_zoom = gtk_gesture_zoom_new(widget);
    g_signal_connect(priv->pinch_zoom, "scale-changed",
                     G_CALLBACK(unicode_character_map_on_pinch_zoom),
                     widget);
    /* Set up drag and drop */
    gtk_target_list_add_text_targets(priv->target_list, 0);
    gtk_drag_dest_set(widget, GTK_DEST_DEFAULT_ALL, NULL, 0, GDK_ACTION_COPY);
    gtk_drag_dest_add_text_targets(widget);
    /* Make sure we look like what we are */
    gtk_style_context_add_class(gtk_widget_get_style_context(widget), GTK_STYLE_CLASS_VIEW);
    gtk_widget_show(widget);
    return;
}

static void
unicode_character_map_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(gobject);
    g_clear_pointer(&priv->font_desc, pango_font_description_free);
    unicode_character_map_clear_pango_layout(charmap);
    g_clear_pointer(&priv->target_list, gtk_target_list_unref);
    g_clear_object(&priv->codepoint_list);
    g_clear_object(&priv->long_press);
    g_clear_object(&priv->pinch_zoom);
    G_OBJECT_CLASS(unicode_character_map_parent_class)->dispose(gobject);
    return;
}

static void
unicode_character_map_set_property (GObject *gobject,
                                    guint prop_id,
                                    const GValue *value,
                                    GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(gobject);

    switch (prop_id) {
        case PROP_HADJUSTMENT:
            unicode_character_map_set_hadjustment(charmap, g_value_get_object(value));
            break;
        case PROP_VADJUSTMENT:
            unicode_character_map_set_vadjustment(charmap, g_value_get_object(value));
            break;
        case PROP_HSCROLL_POLICY:
            priv->hscroll_policy = g_value_get_enum(value);
            gtk_widget_queue_resize(GTK_WIDGET(charmap));
            break;
        case PROP_VSCROLL_POLICY:
            priv->vscroll_policy = g_value_get_enum(value);
            gtk_widget_queue_resize(GTK_WIDGET(charmap));
            break;
        case PROP_ACTIVE_CHAR:
            unicode_character_map_set_active_character(charmap, g_value_get_uint(value));
            break;
        case PROP_FONT_DESC:
            unicode_character_map_set_font_desc(charmap, g_value_get_boxed(value));
            break;
        case PROP_CODEPOINT_LIST:
            unicode_character_map_set_codepoint_list(charmap, g_value_get_object(value));
            break;
        case PROP_PREVIEW_SIZE:
            unicode_character_map_set_preview_size(charmap, g_value_get_double(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
unicode_character_map_get_property (GObject *gobject,
                                    guint prop_id,
                                    GValue *value,
                                    GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    UnicodeCharacterMap *charmap = UNICODE_CHARACTER_MAP(gobject);

    switch (prop_id) {
        case PROP_HADJUSTMENT:
            g_value_set_object(value, NULL);
            break;
        case PROP_VADJUSTMENT:
            g_value_set_object(value, priv->vadjustment);
            break;
        case PROP_HSCROLL_POLICY:
            g_value_set_enum(value, priv->hscroll_policy);
            break;
        case PROP_VSCROLL_POLICY:
            g_value_set_enum(value, priv->vscroll_policy);
            break;
        case PROP_ACTIVE_CHAR:
            g_value_set_uint(value, unicode_character_map_get_active_character (charmap));
            break;
        case PROP_FONT_DESC:
            g_value_set_boxed(value, unicode_character_map_get_font_desc (charmap));
            break;
        case PROP_CODEPOINT_LIST:
            g_value_set_object(value, unicode_character_map_get_codepoint_list (charmap));
            break;
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, unicode_character_map_get_preview_size(charmap));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

#define I_(string) g_intern_static_string (string)

static void
unicode_character_map_class_init (UnicodeCharacterMapClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = unicode_character_map_dispose;
    object_class->get_property = unicode_character_map_get_property;
    object_class->set_property = unicode_character_map_set_property;

    widget_class->drag_begin = unicode_character_map_drag_begin;
    widget_class->drag_data_get = unicode_character_map_drag_data_get;
    widget_class->drag_data_received = unicode_character_map_drag_data_received;
    widget_class->button_press_event = unicode_character_map_button_press;
    widget_class->get_preferred_width = unicode_character_map_get_preferred_width;
    widget_class->get_preferred_height = unicode_character_map_get_preferred_height;
    widget_class->draw = unicode_character_map_draw;
    widget_class->motion_notify_event = unicode_character_map_motion_notify;
    widget_class->size_allocate = unicode_character_map_size_allocate;
    widget_class->style_updated = unicode_character_map_style_updated;

    klass->activate = NULL;
    klass->set_active_char = NULL;
    klass->move_cursor = unicode_character_map_move_cursor;
    klass->copy_clipboard = unicode_character_map_copy_clipboard;
    klass->paste_clipboard = unicode_character_map_paste_clipboard;

    /* GtkScrollable interface properties */
    g_object_class_override_property(object_class, PROP_HADJUSTMENT, "hadjustment");
    g_object_class_override_property(object_class, PROP_VADJUSTMENT, "vadjustment");
    g_object_class_override_property(object_class, PROP_HSCROLL_POLICY, "hscroll-policy");
    g_object_class_override_property(object_class, PROP_VSCROLL_POLICY, "vscroll-policy");

    signals[ACTIVATE] = g_signal_new(I_("activate"),
                                    G_TYPE_FROM_CLASS (object_class),
                                    G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
                                    G_STRUCT_OFFSET(UnicodeCharacterMapClass, activate),
                                    NULL, NULL,
                                    NULL,//g_cclosure_marshal_VOID__VOID,
                                    G_TYPE_NONE,
                                    0);

    widget_class->activate_signal = signals[ACTIVATE];

    signals[STATUS_MESSAGE] = g_signal_new(I_("status-message"),
                                            UNICODE_TYPE_CHARACTER_MAP,
                                            G_SIGNAL_RUN_FIRST,
                                            G_STRUCT_OFFSET(UnicodeCharacterMapClass, status_message),
                                            NULL, NULL,
                                            NULL,//g_cclosure_marshal_VOID__STRING,
                                            G_TYPE_NONE,
                                            1,
                                            G_TYPE_STRING);

    signals[MOVE_CURSOR] = g_signal_new(I_("move-cursor"),
                                        G_TYPE_FROM_CLASS(object_class),
                                        G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
                                        G_STRUCT_OFFSET(UnicodeCharacterMapClass, move_cursor),
                                        NULL, NULL,
                                        NULL,//_g_cclosure_marshal_BOOLEAN__ENUM_INT,
                                        G_TYPE_BOOLEAN,
                                        2,
                                        GTK_TYPE_MOVEMENT_STEP,
                                        G_TYPE_INT);

    signals[COPY_CLIPBOARD] = g_signal_new(I_("copy-clipboard"),
                                            G_OBJECT_CLASS_TYPE(object_class),
                                            G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
                                            G_STRUCT_OFFSET(UnicodeCharacterMapClass, copy_clipboard),
                                            NULL, NULL,
                                            NULL,//g_cclosure_marshal_VOID__VOID,
                                            G_TYPE_NONE,
                                            0);

    signals[PASTE_CLIPBOARD] = g_signal_new(I_("paste-clipboard"),
                                            G_OBJECT_CLASS_TYPE(object_class),
                                            G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
                                            G_STRUCT_OFFSET(UnicodeCharacterMapClass, paste_clipboard),
                                            NULL, NULL,
                                            NULL,//g_cclosure_marshal_VOID__VOID,
                                            G_TYPE_NONE,
                                            0);

    /* Not using g_param_spec_unichar on purpose, since it disallows certain
     * values we want (it's performing a g_unichar_validate).
     */
    g_object_class_install_property(object_class,
                                    PROP_ACTIVE_CHAR,
                                    g_param_spec_uint("active-character",
                                                        NULL,
                                                        "Active character",
                                                        0,
                                                        UNICODE_UNICHAR_MAX,
                                                        0,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS));

    g_object_class_install_property(object_class,
                                    PROP_FONT_DESC,
                                    g_param_spec_boxed("font-desc",
                                                        NULL,
                                                        "PangoFontDescription",
                                                        PANGO_TYPE_FONT_DESCRIPTION,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS));

    g_object_class_install_property(object_class,
                                    PROP_PREVIEW_SIZE,
                                    g_param_spec_double("preview-size",
                                                        NULL,
                                                        "Preview size",
                                                        6, 96, 14,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS));

    g_object_class_install_property(object_class,
                                    PROP_CODEPOINT_LIST,
                                    g_param_spec_object("codepoint-list",
                                                        NULL,
                                                        "UnicodeCodepointList",
                                                        UNICODE_TYPE_CODEPOINT_LIST,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS));

    /* Keybindings */
    GtkBindingSet *binding_set = gtk_binding_set_by_class(klass);

    /* Cursor movement */
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Up, 0, GTK_MOVEMENT_DISPLAY_LINES, -1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Up, 0, GTK_MOVEMENT_DISPLAY_LINES, -1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Down, 0, GTK_MOVEMENT_DISPLAY_LINES, 1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Down, 0, GTK_MOVEMENT_DISPLAY_LINES, 1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_p, GDK_CONTROL_MASK, GTK_MOVEMENT_DISPLAY_LINES, -1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_n, GDK_CONTROL_MASK, GTK_MOVEMENT_DISPLAY_LINES, 1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Home, 0, GTK_MOVEMENT_BUFFER_ENDS, -1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Home, 0, GTK_MOVEMENT_BUFFER_ENDS, -1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_End, 0, GTK_MOVEMENT_BUFFER_ENDS, 1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_End, 0, GTK_MOVEMENT_BUFFER_ENDS, 1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Page_Up, 0, GTK_MOVEMENT_PAGES, -1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Page_Up, 0, GTK_MOVEMENT_PAGES, -1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Page_Down, 0, GTK_MOVEMENT_PAGES, 1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Page_Down, 0, GTK_MOVEMENT_PAGES, 1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Left, 0, GTK_MOVEMENT_VISUAL_POSITIONS, -1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Left, 0, GTK_MOVEMENT_VISUAL_POSITIONS, -1);

    unicode_character_map_add_move_binding(binding_set, GDK_KEY_Right, 0, GTK_MOVEMENT_VISUAL_POSITIONS, 1);
    unicode_character_map_add_move_binding(binding_set, GDK_KEY_KP_Right, 0, GTK_MOVEMENT_VISUAL_POSITIONS, 1);

    /* Activate */
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_Return, 0, "activate", 0);
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_ISO_Enter, 0, "activate", 0);
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_KP_Enter, 0, "activate", 0);
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_space, 0, "activate", 0);

    /* Clipboard actions */
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_c, GDK_CONTROL_MASK, "copy-clipboard", 0);
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_Insert, GDK_CONTROL_MASK, "copy-clipboard", 0);
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_v, GDK_CONTROL_MASK, "paste-clipboard", 0);
    gtk_binding_entry_add_signal(binding_set, GDK_KEY_Insert, GDK_SHIFT_MASK, "paste-clipboard", 0);

    return;
}

/* Public API */

/**
 * unicode_character_map_new:
 *
 * Returns: (transfer full): A newly created #UnicodeCharacterMap.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
unicode_character_map_new (void)
{
    return GTK_WIDGET(g_object_new(UNICODE_TYPE_CHARACTER_MAP, NULL));
}

/**
 * unicode_character_map_set_font_desc:
 * @charmap: a #UnicodeCharacterMap
 * @font_desc: a #PangoFontDescription
 *
 * Sets @font_desc as the font to use to display the character table.
 */
void
unicode_character_map_set_font_desc (UnicodeCharacterMap *charmap, PangoFontDescription *font_desc)
{

    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(charmap));
    g_return_if_fail(font_desc != NULL);

    if (priv->font_desc && pango_font_description_equal(font_desc, priv->font_desc))
        return;

    unicode_character_map_set_font_desc_internal(charmap, pango_font_description_copy(font_desc));
    return;
}

/**
 * unicode_character_map_get_font_desc:
 * @charmap: a #UnicodeCharacterMap
 *
 * Returns: (transfer none) (nullable):
 * The #PangoFontDescription used to display the character table.
 * The returned object is owned by @charmap and must not be modified or freed.
 */
PangoFontDescription *
unicode_character_map_get_font_desc (UnicodeCharacterMap *charmap)
{
      g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(charmap), NULL);
      return priv->font_desc;
}

/**
 * unicode_character_map_get_codepoint_list:
 * @charmap: a #UnicodeCharacterMap
 *
 * Returns: (transfer none) (nullable): The current #UnicodeCodepointList
 */
UnicodeCodepointList *
unicode_character_map_get_codepoint_list (UnicodeCharacterMap *charmap)
{
    g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(charmap), NULL);
    return priv->codepoint_list;
}

/**
 * unicode_character_map_set_codepoint_list:
 * @charmap: a #UnicodeCharacterMap
 * @codepoint_list: (nullable): a #UnicodeCodepointList
 *
 * Sets the codepoint list to show in the character table.
 */
void
unicode_character_map_set_codepoint_list (UnicodeCharacterMap *charmap,
                                          UnicodeCodepointList *codepoint_list)
{
    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(charmap));
    GObject *obj = G_OBJECT(charmap);
    g_object_freeze_notify(obj);
    g_set_object(&priv->codepoint_list, codepoint_list);
    priv->active_cell = 0;
    priv->page_first_cell = 0;
    if (priv->codepoint_list)
        priv->last_cell = unicode_codepoint_list_get_last_index(priv->codepoint_list);
    else
        priv->last_cell = 0;
    g_object_notify(obj, "codepoint-list");
    g_object_notify(obj, "active-character");
    gtk_widget_queue_draw(GTK_WIDGET(charmap));
    update_scrollbar_adjustment(charmap);
    g_object_thaw_notify(obj);
    return;
}

/**
 * unicode_character_map_set_preview_size:
 * @charmap: a #UnicodeCharacterMap
 * @size: new preview size
 *
 * Sets the preview size to @size.
 */
void
unicode_character_map_set_preview_size (UnicodeCharacterMap *charmap, gdouble size)
{
    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(charmap));
    priv->preview_size = size;
    PangoFontDescription *font_desc = pango_font_description_copy(priv->font_desc);
    unicode_character_map_set_font_desc_internal(charmap, font_desc);
    g_object_notify(G_OBJECT(charmap), "preview-size");
    return;
}

/**
 * unicode_character_map_get_preview_size:
 * @charmap: a #UnicodeCharacterMap
 *
 * Returns: The current preview size
 */
double
unicode_character_map_get_preview_size (UnicodeCharacterMap *charmap)
{
    g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(charmap), 0.0);
    return priv->preview_size;
}

/**
 * unicode_character_map_get_active_character:
 * @charmap: a #UnicodeCharacterMap
 *
 * Returns: The currently selected #gunichar
 */
gunichar
unicode_character_map_get_active_character (UnicodeCharacterMap *charmap)
{
    g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(charmap), 0);
    if (!priv->codepoint_list)
        return 0;
    return unicode_codepoint_list_get_char(priv->codepoint_list, priv->active_cell);
}

/**
 * unicode_character_map_set_active_character:
 * @charmap: a #UnicodeCharacterMap
 * @wc: a unicode character (UTF-32)
 *
 * Sets @wc as the selected character.
 */
void
unicode_character_map_set_active_character (UnicodeCharacterMap *charmap, gunichar wc)
{
    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(charmap));
    gint cell = unicode_codepoint_list_get_index(priv->codepoint_list, wc);
    if (cell < 0 || cell > priv->last_cell) {
        gtk_widget_error_bell(GTK_WIDGET(charmap));
        return;
    }
    unicode_character_map_set_active_cell(charmap, cell);
    return;
}
