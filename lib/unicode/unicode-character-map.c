/* unicode-character-map.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017-2022 Jerry Casiano
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

#include "unicode-character-map.h"

/**
 * SECTION: unicode-character-map
 * @short_description: Character map widget
 * @title: Character Map
 * @include: unicode-character-map.h
 *
 * Widget which displays all the available characters in the selected font.
 */

#define CELL_PADDING 2.5
#define VALID_FONT_SIZE(X) (X < 6.0 ? 6.0 : X > 96.0 ? 96.0 : X)
#define FIRST_CELL_IN_SAME_ROW(x) ((x) - ((x) % self->columns))

enum
{
    SELECTION_CHANGED,
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
    PROP_ACTIVE_CELL,
    PROP_CODEPOINT_LIST,
    PROP_FONT_DESC,
    PROP_PREVIEW_SIZE
};

struct _UnicodeCharacterMap
{
    GtkDrawingArea parent_instance;

    gint    rows;
    gint    columns;
    gint    active_cell;        /* the active cell index */
    gint    last_cell;          /* from unicode_codepoint_list_get_last_index */
    gint    min_cell_height;    /* depends on font_desc and size allocation */
    gint    min_cell_width;     /* depends on font_desc and size allocation */
    gint    n_padded_columns;   /* columns 0..n-1 will be 1px wider than min_cell_width */
    gint    n_padded_rows;      /* rows 0..n-1 will be 1px taller than min_cell_height */
    gint    page_first_cell;    /* the cell index of the top left corner */
    gint    page_size;          /* rows * cols */

    GtkWidget *context_widget;
    UnicodeCodepointList *codepoint_list;

    /* Drawing */
    gdouble  preview_size;
    PangoLayout *pango_layout;
    PangoLayout *zoom_layout;
    GtkWidget *zoom_center_box;
    PangoFontDescription *font_desc;
    /* GtkScrollable implementation */
    guint hscroll_policy : 1;   /* unused */
    guint vscroll_policy : 1;
    GtkAdjustment *hadjustment; /* unused */
    GtkAdjustment *vadjustment;
    gulong vadjustment_changed_handler_id;
};

G_DEFINE_TYPE_WITH_CODE (UnicodeCharacterMap, unicode_character_map,
                         GTK_TYPE_DRAWING_AREA,
                         G_IMPLEMENT_INTERFACE(GTK_TYPE_SCROLLABLE, NULL))


static GtkWidget * unicode_character_map_get_context_widget (UnicodeCharacterMap *self);

static void
unicode_character_map_update_scrollbar_adjustment (UnicodeCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    if (self->vadjustment != NULL) {
        gtk_adjustment_configure(self->vadjustment,
                                 self->page_first_cell / self->rows, /* current value */
                                 0 /* lower */,
                                 self->last_cell / self->columns + 1 /* upper */,
                                 1 /* step increment */,
                                 self->rows /* page increment */,
                                 self->rows); /* page size */
    }
    return;
}

static void
unicode_character_map_clear_pango_layout (UnicodeCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    g_clear_object(&self->pango_layout);
    g_clear_object(&self->zoom_layout);
    return;
}

static void
unicode_character_map_ensure_pango_layout (UnicodeCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    if (self->pango_layout == NULL || self->zoom_layout == NULL) {
        g_autoptr(PangoAttrList) attrs = pango_attr_list_new();
        pango_attr_list_insert(attrs, pango_attr_fallback_new (FALSE));
        if (self->pango_layout == NULL) {
            self->pango_layout = gtk_widget_create_pango_layout(GTK_WIDGET(self), NULL);
            pango_layout_set_font_description(self->pango_layout, self->font_desc);
            pango_layout_set_attributes(self->pango_layout, attrs);
        }
        if (self->zoom_layout == NULL) {
            GtkWidget *popover = unicode_character_map_get_context_widget(self);
            GtkWidget *box = gtk_popover_get_child(GTK_POPOVER(popover));
            GtkWidget *widget = gtk_widget_get_first_child(box);
            self->zoom_layout = gtk_widget_create_pango_layout(widget, NULL);
            g_autoptr(PangoFontDescription) font_desc = pango_font_description_copy(self->font_desc);
            pango_font_description_set_size(font_desc, 96 * PANGO_SCALE);
            pango_layout_set_font_description(self->zoom_layout, font_desc);
            pango_layout_set_alignment(self->zoom_layout, PANGO_ALIGN_CENTER);
            pango_layout_set_attributes(self->zoom_layout, attrs);
        }
    }
    return;
}

static gchar *
unicode_character_map_get_text_for_cell (UnicodeCharacterMap *self, gint cell)
{
    if (self->codepoint_list == NULL)
        return NULL;
    GSList *codepoints = unicode_codepoint_list_get_codepoints(self->codepoint_list, cell);
    for (GSList *iter = codepoints; iter != NULL; iter = iter->next) {
        gunichar wc = GPOINTER_TO_INT(iter->data);
        if (wc > UNICODE_UNICHAR_MAX || !unicode_unichar_validate(wc))
            return NULL;
    }
    gchar text [24];
    gchar *p = text;
    for (GSList *iter = codepoints; iter != NULL; iter = iter->next)
        p += unicode_unichar_to_printable_utf8((gunichar) GPOINTER_TO_INT(iter->data), p);
    p[0] = 0;
    g_slist_free(codepoints);
    return g_strdup(text);
}

static void
unicode_character_map_resize_context_widget (UnicodeCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    unicode_character_map_ensure_pango_layout(self);
    g_autofree gchar *cell_text = unicode_character_map_get_text_for_cell(self, self->active_cell);
    pango_layout_set_text(self->zoom_layout, cell_text, -1);
    PangoRectangle char_rect;
    gint glyph_pad = 48, width = -1, height = -1;
    pango_layout_get_pixel_size(self->zoom_layout, &width, &height);
    pango_layout_get_pixel_extents(self->zoom_layout, NULL, &char_rect);
    if (width < 0) width = char_rect.width;
    if (height < 0) height = char_rect.height;
    GtkWidget *parent = gtk_widget_get_parent(self->zoom_center_box);
    int parent_size = MAX(width + glyph_pad, height + glyph_pad);
    gtk_widget_set_size_request(parent, parent_size, parent_size);
    gtk_widget_set_size_request(self->zoom_center_box, width + glyph_pad, height + glyph_pad);
    return;
}

static void
unicode_character_map_resize (GtkDrawingArea *widget, int width, int height)
{
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(widget);
    gint old_rows = self->rows;
    gint old_cols = self->columns;
    GtkAllocation allocation;
    gtk_widget_get_allocation(GTK_WIDGET(widget), &allocation);
    gint min_width = CELL_PADDING * self->preview_size;
    gint min_height = CELL_PADDING * self->preview_size;
    self->rows = allocation.height / min_height;
    self->columns = allocation.width / min_width;
    /* Avoid a horrible floating point exception crash */
    if (self->rows < 1) self->rows = 1;
    if (self->columns < 1) self->columns = 1;
    self->page_size = self->rows * self->columns;
    gint extra = allocation.width - (self->columns * min_width + 1);
    self->min_cell_width = min_width + extra / self->columns;
    self->n_padded_columns = allocation.width - (self->min_cell_width * self->columns + 1);
    extra = allocation.height - (self->rows * min_height + 1);
    self->min_cell_height = min_height + extra / self->rows;
    self->n_padded_rows = allocation.height - (self->min_cell_height * self->rows + 1);
    if (self->rows == old_rows && self->columns == old_cols)
        return;
    /* Need to recalculate the first cell, see bug #517188 */
    gint new_first_cell = FIRST_CELL_IN_SAME_ROW(self->active_cell);
    if ((new_first_cell + self->page_size) > (self->last_cell)) {
        /* Last cell is visible, so make sure it is in the last row */
        new_first_cell = FIRST_CELL_IN_SAME_ROW(self->last_cell) - self->page_size + self->columns;
        if (new_first_cell < 0)
            new_first_cell = 0;
    }
    self->page_first_cell = new_first_cell;
    unicode_character_map_update_scrollbar_adjustment(self);
    unicode_character_map_resize_context_widget(self);
    return;
}

static gint
unicode_character_map_get_cell_at_rowcol (UnicodeCharacterMap *self, gint row, gint col)
{
    /* Depends on directionality */
    if (gtk_widget_get_direction(GTK_WIDGET(self)) == GTK_TEXT_DIR_RTL)
        return self->page_first_cell + row * self->columns + (self->columns - col - 1);
    else
        return self->page_first_cell + row * self->columns + col;
}

static gint
unicode_character_map_cell_column (UnicodeCharacterMap *self, guint cell)
{
    /* Depends on directionality. Column 0 is the furthest left. */
    if (gtk_widget_get_direction(GTK_WIDGET(self)) == GTK_TEXT_DIR_RTL)
        return self->columns - (cell - self->page_first_cell) % self->columns - 1;
    else
        return (cell - self->page_first_cell) % self->columns;
}

static gint
unicode_character_map_column_width (UnicodeCharacterMap *self, gint col)
{
    g_return_val_if_fail(self != NULL, self->min_cell_width);
    /* Not all columns are necessarily the same width because of padding */
    if (self->columns - col <= self->n_padded_columns)
        return self->min_cell_width + 1;
    else
        return self->min_cell_width;
}

static gint
unicode_character_map_row_height (UnicodeCharacterMap *self, gint row)
{
    g_return_val_if_fail(self != NULL, self->min_cell_height);
    /* Not all rows are necessarily the same height because of padding */
    if (self->rows - row <= self->n_padded_rows)
        return self->min_cell_height + 1;
    else
        return self->min_cell_height;
}

static gint
unicode_character_map_get_cell_at_xy (UnicodeCharacterMap *self, gint x, gint y)
{
    gint c, r, x0, y0, cell;

    for (c = 0, x0 = 0;  x0 <= x && c < self->columns;  c++)
        x0 += unicode_character_map_column_width(self, c);

    for (r = 0, y0 = 0;  y0 <= y && r < self->rows;  r++)
        y0 += unicode_character_map_row_height(self, r);

    cell = unicode_character_map_get_cell_at_rowcol(self, r-1, c-1);

    if (cell > self->last_cell)
        return self->last_cell;

    return cell;
}

/* Calculate the position of the left end of the column (just to the right
 * of the left border)
 * XXX: calling this repeatedly is not the most efficient, but it probably
 * is the most readable
 */
static gint
unicode_character_map_x_offset (UnicodeCharacterMap *self, gint col)
{
    gint c, x;
    for (c = 0, x = 1; c < col; c++)
        x += unicode_character_map_column_width(self, c);
    return x;
}

/* Calculate the position of the top end of the row (just below the top
 * border)
 * XXX: calling this repeatedly is not the most efficient, but it probably
 * is the most readable
 */
static gint
unicode_character_map_y_offset (UnicodeCharacterMap *self, gint row)
{
    gint r, y;
    for (r = 0, y = 1; r < row; r++)
        y += unicode_character_map_row_height(self, r);
    return y;
}

static void
unicode_character_map_draw_character_with_metrics (GtkDrawingArea *widget,
                                                   cairo_t *cr,
                                                   gint unused_width,
                                                   gint unused_height,
                                                   gpointer user_data)
{
    g_return_if_fail(user_data != NULL);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(user_data);
    unicode_character_map_ensure_pango_layout(self);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(widget));
    g_autofree gchar *cell_text = unicode_character_map_get_text_for_cell(self, self->active_cell);
    pango_layout_set_text(self->zoom_layout, cell_text, -1);
    PangoRectangle char_rect;
    GtkAllocation alloc;
    gint glyph_pad = 48, width = -1, height = -1;
    pango_layout_get_pixel_size(self->zoom_layout, &width, &height);
    pango_layout_get_pixel_extents(self->zoom_layout, NULL, &char_rect);
    if (width < 0) width = char_rect.width;
    if (height < 0) height = char_rect.height;
    GtkWidget *parent = gtk_widget_get_parent(GTK_WIDGET(widget));
    int parent_size = MAX(width + glyph_pad, height + glyph_pad);
    gtk_widget_set_size_request(parent, parent_size, parent_size);
    gtk_widget_set_size_request(GTK_WIDGET(widget), width + glyph_pad, height + glyph_pad);
    gtk_widget_get_allocation(GTK_WIDGET(widget), &alloc);
    gint xpad = ((alloc.width - char_rect.width) / 2);
    gint ypad = ((alloc.height - char_rect.height) / 2);
    gint baseline = pango_layout_get_baseline(self->zoom_layout) / PANGO_SCALE;
    gtk_render_layout(ctx, cr, char_rect.x + xpad, char_rect.y + ypad, self->zoom_layout);
    gtk_style_context_save(ctx);
    gtk_style_context_set_state(ctx, GTK_STATE_FLAG_INSENSITIVE);
    gtk_style_context_add_class(ctx, "PangoGlyphMetrics");
    gtk_render_line(ctx, cr, 1, baseline + xpad, alloc.width - 1, baseline + xpad);
    gtk_render_line(ctx, cr, 1, PANGO_ASCENT(char_rect) + xpad, alloc.width - 1, PANGO_ASCENT(char_rect) + xpad);
    gtk_render_line(ctx, cr, 1, PANGO_DESCENT(char_rect) + xpad, alloc.width - 1, PANGO_DESCENT(char_rect) + xpad);
    gtk_render_line(ctx, cr, PANGO_LBEARING(char_rect) + ypad, 1, PANGO_LBEARING(char_rect) + ypad, alloc.height - 1);
    gtk_render_line(ctx, cr, PANGO_RBEARING(char_rect) + ypad, 1, PANGO_RBEARING(char_rect) + ypad, alloc.height - 1);
    gtk_style_context_restore(ctx);
    return;
}

static void
unicode_character_map_draw_character (GtkWidget *widget,
                                      GtkSnapshot *snapshot,
                                      GtkStyleContext *ctx,
                                      graphene_rect_t *rect,
                                      gint row,
                                      gint col)
{
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(widget);
    guint cell = unicode_character_map_get_cell_at_rowcol(self, row, col);
    g_autofree gchar *text = unicode_character_map_get_text_for_cell(self, cell);
    pango_layout_set_text(self->pango_layout, text, -1);
    /* Keep the square empty if the font has no glyph for this cell. */
    if (pango_layout_get_unknown_glyphs_count(self->pango_layout) > 0)
        return;
    gtk_style_context_save(ctx);
    GtkStateFlags _state = GTK_STATE_FLAG_NORMAL;
    if (gtk_widget_has_focus(widget) && (gint) cell == self->active_cell)
        _state = GTK_STATE_FLAG_SELECTED | GTK_STATE_FLAG_FOCUSED;
    else if ((gint) cell == self->active_cell)
        _state = GTK_STATE_FLAG_INSENSITIVE | GTK_STATE_FLAG_SELECTED;
    gtk_style_context_set_state(ctx, _state);
    gtk_style_context_add_class(ctx, "CharacterMapGlyph");
    gint char_width, char_height;
    pango_layout_get_pixel_size(self->pango_layout, &char_width, &char_height);
    gtk_snapshot_render_layout(snapshot, ctx,
                               rect->origin.x + (rect->size.width - char_width - 2 + 1) / 2,
                               rect->origin.y + (rect->size.height - char_height - 2 + 1) / 2,
                               self->pango_layout);
    gtk_style_context_restore(ctx);
    return;
}

static void
unicode_character_map_draw_square_bg (GtkWidget *widget,
                                      GtkSnapshot *snapshot,
                                      GtkStyleContext *ctx,
                                      graphene_rect_t *rect,
                                      gint row,
                                      gint col)
{
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(widget);
    gint cell = (gint) unicode_character_map_get_cell_at_rowcol(self, row, col);
    gtk_style_context_save(ctx);
    GtkStateFlags _state = GTK_STATE_FLAG_NORMAL;
    if (gtk_widget_has_focus(widget) && cell == self->active_cell)
        _state = GTK_STATE_FLAG_FOCUSED | GTK_STATE_FLAG_SELECTED;
    else if (cell == self->active_cell)
        _state = GTK_STATE_FLAG_SELECTED;
    else if (cell > self->last_cell)
        _state = GTK_STATE_FLAG_INSENSITIVE;
    else
        _state = GTK_STATE_FLAG_NORMAL;
    gtk_style_context_set_state(ctx, _state);
    gtk_style_context_add_class(ctx, "CharacterMapCell");
    gtk_snapshot_render_background(snapshot, ctx,
                                   rect->origin.x + 2, rect->origin.y + 2,
                                   rect->size.width - 5, rect->size.height - 5);
    gtk_style_context_restore(ctx);
    return;
}

static void
unicode_character_map_draw_separators (GtkWidget *widget, GtkStyleContext *ctx, cairo_t *cr)
{
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(widget);
    gint x, y, col, row;
    GtkAllocation allocation;
    gtk_style_context_save(ctx);
    /* Set insensitive flag so our lines have less contrast */
    gtk_style_context_set_state(ctx, GTK_STATE_FLAG_INSENSITIVE);
    gtk_style_context_add_class(ctx, "CharacterMapSeparator");
    gtk_widget_get_allocation(widget, &allocation);
    /* Vertical */
    gtk_render_line(ctx, cr, 0, 0, 0, allocation.height);
    for (col = 0, x = 0;  col < self->columns;  col++) {
        x += unicode_character_map_column_width(self, col);
        gtk_render_line(ctx, cr, x, 0, x, allocation.height);
    }
    /* Horizontal */
    gtk_render_line(ctx, cr, 0, 0, allocation.width, 0);
    for (row = 0, y = 0;  row < self->rows;  row++) {
        y += unicode_character_map_row_height(self, row);
        gtk_render_line(ctx, cr, 0, y, allocation.width, y);
    }
    gtk_style_context_restore(ctx);
    return;
}

static void
unicode_character_map_snapshot (GtkWidget *widget, GtkSnapshot *snapshot)
{
    GtkAllocation allocation;
    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(widget);
    unicode_character_map_ensure_pango_layout(self);
    gtk_widget_get_allocation(widget, &allocation);
    for (int row = self->rows - 1; row >= 0; --row) {
        for (int col = self->columns - 1; col >= 0; --col)  {
            graphene_rect_t *cell_rect = graphene_rect_alloc();
            cell_rect = graphene_rect_init(cell_rect,
                                           unicode_character_map_x_offset(self, col),
                                           unicode_character_map_y_offset(self, row),
                                           unicode_character_map_column_width(self, col),
                                           unicode_character_map_row_height(self, row));
            unicode_character_map_draw_square_bg(widget, snapshot, ctx, cell_rect, row, col);
            unicode_character_map_draw_character(widget, snapshot, ctx, cell_rect, row, col);
            graphene_rect_free(cell_rect);
        }
    }
    graphene_rect_t *allocated_rect = graphene_rect_alloc();
    allocated_rect = graphene_rect_init(allocated_rect, allocation.x, allocation.y, allocation.width, allocation.height);
    cairo_t *cr = gtk_snapshot_append_cairo(snapshot, allocated_rect);
    unicode_character_map_draw_separators(widget, ctx, cr);
    graphene_rect_free(allocated_rect);
    cairo_destroy(cr);
    return;
}

static void
unicode_character_map_set_hadjustment (UnicodeCharacterMap *self, GtkAdjustment *hadjustment)
{
    g_return_if_fail(self != NULL);
    g_set_object(&self->hadjustment, hadjustment);
    return;
}

static void
vadjustment_value_changed_cb (GtkAdjustment *vadjustment, UnicodeCharacterMap *self)
{
    int row = (int) gtk_adjustment_get_value(vadjustment);

    if (row < 0 ) row = 0;

    int first_cell = row * self->columns;
    if (first_cell == self->page_first_cell)
        return;

    gtk_widget_queue_resize(GTK_WIDGET(self));

    self->page_first_cell = first_cell;
    return;
}

static void
unicode_character_map_set_vadjustment (UnicodeCharacterMap *self, GtkAdjustment *vadjustment)
{
    if (vadjustment)
        g_return_if_fail(GTK_IS_ADJUSTMENT(vadjustment));
    else
        vadjustment = GTK_ADJUSTMENT(gtk_adjustment_new (0.0, 0.0, 0.0, 0.0, 0.0, 0.0));

    if (self->vadjustment) {
        g_signal_handler_disconnect(self->vadjustment, self->vadjustment_changed_handler_id);
        self->vadjustment_changed_handler_id = 0;
        g_clear_object(&self->vadjustment);
    }

    g_set_object(&self->vadjustment, vadjustment);
    self->vadjustment_changed_handler_id = g_signal_connect(vadjustment,
                                                            "value-changed",
                                                            G_CALLBACK(vadjustment_value_changed_cb),
                                                            self);

    unicode_character_map_update_scrollbar_adjustment(self);
    return;
}

static void
unicode_character_map_set_font_desc_internal (UnicodeCharacterMap *self,
                                              PangoFontDescription *font_desc /* adopting */)
{
    if (!font_desc)
        return;
    if (self->font_desc)
        pango_font_description_free(self->font_desc);
    self->font_desc = font_desc;
    pango_font_description_set_size(self->font_desc, self->preview_size * PANGO_SCALE);
    unicode_character_map_clear_pango_layout(self);
    gtk_widget_queue_resize(GTK_WIDGET(self));
    g_object_notify(G_OBJECT(self), "font-desc");
    g_object_notify(G_OBJECT(self), "active-cell");
    return;
}

static void
unicode_character_map_on_selection_changed (UnicodeCharacterMap *self)
{
    if (self->codepoint_list == NULL)
        return;
    const gchar *name = NULL;
    g_autofree gchar *codepoint = NULL;
    gint last_index = unicode_codepoint_list_get_last_index(UNICODE_CODEPOINT_LIST(self->codepoint_list));
    g_autofree gchar *n_codepoints = g_strdup_printf("%i", last_index);
    GSList *codepoints = unicode_codepoint_list_get_codepoints(UNICODE_CODEPOINT_LIST(self->codepoint_list), self->active_cell);
    guint points = g_slist_length(codepoints);
    if (points == 1) {
        gunichar ac = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
        codepoint = g_markup_printf_escaped("U+%4.4X", ac);
        name = unicode_get_codepoint_name(ac);
    } else if (points == 2) {
        gunichar code1 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
        gunichar code2 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 1));
        int index;
        for (index = 0; index < G_N_ELEMENTS(RegionalIndicatorSymbols); index++)
            if (RegionalIndicatorSymbols[index].code1 == code1 && RegionalIndicatorSymbols[index].code2 == code2)
                break;
        codepoint = g_markup_printf_escaped("U+%4.4X + U+%4.4X", code1, code2);
        name = RegionalIndicatorSymbols[index].region;
    }
    g_slist_free(codepoints);
    g_signal_emit(self, signals[SELECTION_CHANGED], 0, codepoint, name, n_codepoints);
    return;
}

static void
unicode_character_map_copy_clipboard (GtkWidget *widget, gpointer user_data)
{
    g_return_if_fail(user_data != NULL);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(user_data);
    g_autofree gchar *text = unicode_character_map_get_text_for_cell(self, self->active_cell);
    GdkClipboard *clipboard = gtk_widget_get_clipboard(GTK_WIDGET(self));
    gdk_clipboard_set_text(clipboard, text);
    if (self->context_widget && gtk_widget_get_mapped(self->context_widget))
        gtk_popover_popdown(GTK_POPOVER(self->context_widget));
    return;
}

static void
unicode_character_map_copy_shortcut_func (GtkWidget *widget, GVariant *args, gpointer user_data)
{
    unicode_character_map_copy_clipboard(widget, widget);
    return;
}

static void
unicode_character_map_move_cursor_left_right (UnicodeCharacterMap *self, int count)
{
    gboolean is_rtl = (gtk_widget_get_direction(GTK_WIDGET(self)) == GTK_TEXT_DIR_RTL);
    int offset = is_rtl ? -count : count;
    unicode_character_map_set_active_cell(self, self->active_cell + offset);
    return;
}

static void
unicode_character_map_move_cursor_up_down (UnicodeCharacterMap *self, int count)
{
    unicode_character_map_set_active_cell(self, self->active_cell + self->columns * count);
    return;
}

static void
unicode_character_map_move_cursor_page_up_down (UnicodeCharacterMap *self, int count)
{
  unicode_character_map_set_active_cell(self, self->active_cell + self->page_size * count);
  return;
}

static void
unicode_character_map_move_cursor_start_end (UnicodeCharacterMap *self, int count)
{
    int new_cell = count > 0 ? self->last_cell : 0;
    unicode_character_map_set_active_cell(self, new_cell);
    return;
}

static void
unicode_character_map_move_cursor (GtkWidget *widget, GVariant *variant, gpointer user_data)
{
    g_return_if_fail(widget != NULL);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(widget);
    gint step, count;
    g_variant_get(variant, "(ii)", &step, &count);
    switch ((GtkMovementStep) step) {
        case GTK_MOVEMENT_LOGICAL_POSITIONS:
        case GTK_MOVEMENT_VISUAL_POSITIONS:
            unicode_character_map_move_cursor_left_right(self, count);
            break;
        case GTK_MOVEMENT_DISPLAY_LINES:
            unicode_character_map_move_cursor_up_down(self, count);
            break;
        case GTK_MOVEMENT_PAGES:
            unicode_character_map_move_cursor_page_up_down(self, count);
            break;
        case GTK_MOVEMENT_BUFFER_ENDS:
            unicode_character_map_move_cursor_start_end(self, count);
            break;
        default:
            return;
    }
    return;
}

static GtkWidget *
unicode_character_map_get_context_widget (UnicodeCharacterMap *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    if (self->context_widget != NULL)
        return self->context_widget;
    self->context_widget = gtk_popover_new();
    gtk_popover_set_autohide(GTK_POPOVER(self->context_widget), TRUE);
    GtkWidget *center_box = gtk_center_box_new();
    self->zoom_center_box = center_box;
    GtkWidget *glyph = gtk_drawing_area_new();
    GtkWidget *separator = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_widget_set_opacity(separator, 0.5);
    font_manager_widget_set_margin(separator, 6);
    GtkWidget *copy_button = gtk_button_new_with_label(_("Copy"));
    gtk_widget_set_opacity(copy_button, 0.75);
    gtk_widget_add_css_class(copy_button, "rounded-button");
    font_manager_widget_set_align(copy_button, GTK_ALIGN_CENTER);
    font_manager_widget_set_margin(copy_button, 0);
    gtk_widget_set_focusable(copy_button, FALSE);
    gtk_center_box_set_center_widget(GTK_CENTER_BOX(center_box), glyph);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_box_append(GTK_BOX(box), center_box);
    gtk_box_append(GTK_BOX(box), separator);
    gtk_box_append(GTK_BOX(box), copy_button);
    font_manager_widget_set_expand(glyph, FALSE);
    font_manager_widget_set_expand(separator, FALSE);
    font_manager_widget_set_expand(copy_button, FALSE);
    font_manager_widget_set_expand(box, FALSE);
    font_manager_widget_set_margin(box, 0);
    g_signal_connect(copy_button, "clicked", G_CALLBACK(unicode_character_map_copy_clipboard), self);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(glyph), unicode_character_map_draw_character_with_metrics, self, NULL);
    gtk_popover_set_child(GTK_POPOVER(self->context_widget), box);
    gtk_popover_set_position(GTK_POPOVER(self->context_widget), GTK_POS_TOP);
    gtk_widget_set_parent(self->context_widget, GTK_WIDGET(self));
    gtk_popover_set_default_widget(GTK_POPOVER(self->context_widget), copy_button);
    return self->context_widget;
}

static void
unicode_character_map_show_info(UnicodeCharacterMap *self, gdouble x, gdouble y)
{
    g_return_if_fail(self != NULL);
    GtkWidget *popover = unicode_character_map_get_context_widget(self);
    gint row = (self->active_cell - self->page_first_cell) / self->columns;
    gint col = unicode_character_map_cell_column(self, self->active_cell);
    if ((row >= 0 && row < self->rows) && (col >= 0 && col < self->columns)) {
        gint x_offset = unicode_character_map_x_offset(self, col);
        gint y_offset = unicode_character_map_y_offset(self, row);
        GdkRectangle rect = { x_offset, y_offset, self->min_cell_width, self->min_cell_height };
        gtk_popover_set_pointing_to(GTK_POPOVER(popover), &rect);
    } else {
        GdkRectangle rect = { x, y, 1, 1 };
        gtk_popover_set_pointing_to(GTK_POPOVER(popover), &rect);
    }
    gtk_popover_popup(GTK_POPOVER(popover));
    return;
}

void
unicode_character_map_on_long_press (G_GNUC_UNUSED GtkGestureLongPress *gesture,
                                     gdouble x,
                                     gdouble y,
                                     gpointer user_data)
{
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(user_data);
    unicode_character_map_set_active_cell(self, unicode_character_map_get_cell_at_xy(self, x, y));
    unicode_character_map_show_info(self, x, y);
    return;
}

void
unicode_character_map_on_pinch_zoom (G_GNUC_UNUSED GtkGestureZoom *gesture,
                                     gdouble scale_factor,
                                     gpointer user_data)
{
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(user_data);
    gdouble size = nearbyint(self->preview_size * scale_factor);
    unicode_character_map_set_preview_size(self, VALID_FONT_SIZE(size));
    return;
}

static void
unicode_character_map_on_click (GtkGestureClick* click,
                                gint n_press,
                                gdouble x,
                                gdouble y,
                                gpointer user_data)
{
    if (n_press > 1)
        return;
    g_return_if_fail(user_data != NULL);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(user_data);
    gtk_widget_grab_focus(GTK_WIDGET(user_data));
    unicode_character_map_set_active_cell(self, unicode_character_map_get_cell_at_xy(self, x, y));
    if (gtk_gesture_single_get_current_button(GTK_GESTURE_SINGLE(click)) == GDK_BUTTON_SECONDARY)
        unicode_character_map_show_info(self, x, y);
    return;
}

static GdkContentProvider *
unicode_character_map_on_prepare_drag (GtkDragSource *source,
                                       double x,
                                       double y,
                                       gpointer user_data)
{
    g_return_val_if_fail(user_data != NULL, NULL);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(user_data);
    gint cell = unicode_character_map_get_cell_at_xy(self, x, y);
    g_autofree gchar *text = unicode_character_map_get_text_for_cell(self, cell);
    return gdk_content_provider_new_typed(G_TYPE_STRING, text);
}

static void
unicode_character_map_on_drag_begin (GtkDragSource *source,
                                     GdkDrag *drag,
                                     gpointer user_data)
{
    /* TODO : Set a drag icon that actually represents what is being dragged */
    gint size = 36;
    GdkDisplay *display = gtk_widget_get_display(GTK_WIDGET(user_data));
    GtkIconTheme *icon_theme = gtk_icon_theme_get_for_display(display);
    GtkIconPaintable *icon = gtk_icon_theme_lookup_icon (icon_theme,
                                                         "font-x-generic-symbolic",
                                                         NULL,
                                                         size, 1,
                                                         gtk_widget_get_direction(GTK_WIDGET(user_data)),
                                                         0);
    gtk_drag_source_set_icon(source, GDK_PAINTABLE(icon), 0, 0);
    g_object_unref(icon);
    return;
}

static void
unicode_character_map_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(gobject);
    g_clear_pointer(&self->font_desc, pango_font_description_free);
    unicode_character_map_clear_pango_layout(self);
    g_clear_object(&self->codepoint_list);
    font_manager_widget_dispose(GTK_WIDGET(self));
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
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(gobject);

    switch (prop_id) {
        case PROP_HADJUSTMENT:
            unicode_character_map_set_hadjustment(self, g_value_get_object(value));
            break;
        case PROP_VADJUSTMENT:
            unicode_character_map_set_vadjustment(self, g_value_get_object(value));
            break;
        case PROP_HSCROLL_POLICY:
            self->hscroll_policy = g_value_get_enum(value);
            gtk_widget_queue_resize(GTK_WIDGET(self));
            break;
        case PROP_VSCROLL_POLICY:
            self->vscroll_policy = g_value_get_enum(value);
            gtk_widget_queue_resize(GTK_WIDGET(self));
            break;
        case PROP_ACTIVE_CELL:
            self->active_cell = g_value_get_int(value);
            break;
        case PROP_FONT_DESC:
            unicode_character_map_set_font_desc(self, g_value_get_boxed(value));
            break;
        case PROP_CODEPOINT_LIST:
            unicode_character_map_set_codepoint_list(self, g_value_get_object(value));
            break;
        case PROP_PREVIEW_SIZE:
            unicode_character_map_set_preview_size(self, g_value_get_double(value));
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
    UnicodeCharacterMap *self = UNICODE_CHARACTER_MAP(gobject);

    switch (prop_id) {
        case PROP_HADJUSTMENT:
            g_value_set_object(value, NULL);
            break;
        case PROP_VADJUSTMENT:
            g_value_set_object(value, self->vadjustment);
            break;
        case PROP_HSCROLL_POLICY:
            g_value_set_enum(value, self->hscroll_policy);
            break;
        case PROP_VSCROLL_POLICY:
            g_value_set_enum(value, self->vscroll_policy);
            break;
        case PROP_ACTIVE_CELL:
            g_value_set_int(value, self->active_cell);
            break;
        case PROP_FONT_DESC:
            g_value_set_boxed(value, unicode_character_map_get_font_desc(self));
            break;
        case PROP_CODEPOINT_LIST:
            g_value_set_object(value, unicode_character_map_get_codepoint_list(self));
            break;
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, unicode_character_map_get_preview_size(self));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
unicode_character_map_class_init (UnicodeCharacterMapClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    gtk_widget_class_set_css_name(widget_class, "UnicodeCharacterMap");

    GTK_DRAWING_AREA_CLASS(widget_class)->resize = unicode_character_map_resize;
    widget_class->snapshot = unicode_character_map_snapshot;
    object_class->dispose = unicode_character_map_dispose;
    object_class->get_property = unicode_character_map_get_property;
    object_class->set_property = unicode_character_map_set_property;

    /* GtkScrollable interface properties */
    g_object_class_override_property(object_class, PROP_HADJUSTMENT, "hadjustment");
    g_object_class_override_property(object_class, PROP_VADJUSTMENT, "vadjustment");
    g_object_class_override_property(object_class, PROP_HSCROLL_POLICY, "hscroll-policy");
    g_object_class_override_property(object_class, PROP_VSCROLL_POLICY, "vscroll-policy");

    signals[SELECTION_CHANGED] = g_signal_new("selection-changed",
                                              UNICODE_TYPE_CHARACTER_MAP,
                                              G_SIGNAL_RUN_FIRST,
                                              0,
                                              NULL, NULL, NULL,
                                              G_TYPE_NONE,
                                              3,
                                              G_TYPE_STRING,
                                              G_TYPE_STRING,
                                              G_TYPE_STRING);

    g_object_class_install_property(object_class,
                                    PROP_ACTIVE_CELL,
                                    g_param_spec_int("active-cell",
                                                     NULL,
                                                     "Active cell in character map",
                                                     G_MININT,
                                                     G_MAXINT,
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
    /* Clipboard */
    GtkShortcutFunc copy_callback = (GtkShortcutFunc) unicode_character_map_copy_shortcut_func;
    gtk_widget_class_add_binding(widget_class, GDK_KEY_c, GDK_CONTROL_MASK, copy_callback, NULL);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Insert, GDK_CONTROL_MASK, copy_callback, NULL);
    /* Cursor movement */
    GtkShortcutFunc callback = (GtkShortcutFunc) unicode_character_map_move_cursor;
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Up, 0, callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Up, 0, callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Down, 0, callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Down, 0, callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_p, GDK_CONTROL_MASK, callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_n, GDK_CONTROL_MASK, callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Home, 0, callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Home, 0, callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_End, 0, callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_End, 0, callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Page_Up, 0, callback, "(ii)", GTK_MOVEMENT_PAGES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Page_Up, 0, callback, "(ii)", GTK_MOVEMENT_PAGES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Page_Down, 0, callback, "(ii)", GTK_MOVEMENT_PAGES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Page_Down, 0, callback, "(ii)", GTK_MOVEMENT_PAGES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Left, 0, callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Left, 0, callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Right, 0, callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Right, 0, callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, 1);
    return;
}

static void
unicode_character_map_init (UnicodeCharacterMap *self)
{
    self->page_first_cell = 0;
    self->active_cell = 0;
    self->rows = 1;
    self->columns = 1;
    self->vadjustment = NULL;
    self->hadjustment = NULL;
    self->hscroll_policy = GTK_SCROLL_NATURAL;
    self->vscroll_policy = GTK_SCROLL_NATURAL;
    self->preview_size = 16;
    self->codepoint_list = NULL;
    GtkWidget *widget = GTK_WIDGET(self);
    gtk_widget_set_focusable(widget, TRUE);
    gtk_widget_add_css_class(widget, FONT_MANAGER_STYLE_CLASS_VIEW);
    font_manager_widget_set_expand(widget, TRUE);
    gtk_widget_set_name(widget, "UnicodeCharacterMap");
    g_autoptr(PangoFontDescription) font_desc = pango_font_description_from_string(FONT_MANAGER_DEFAULT_FONT);
    unicode_character_map_set_font_desc(self, font_desc);
    g_signal_connect(self, "notify::active-cell", G_CALLBACK(unicode_character_map_on_selection_changed), self);
    /* Mouse events */
    GtkGesture *click_gesture = gtk_gesture_click_new();
    gtk_gesture_single_set_button(GTK_GESTURE_SINGLE(click_gesture), 0);
    g_signal_connect(click_gesture, "released", G_CALLBACK(unicode_character_map_on_click), self);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(click_gesture));
    /* Touch events */
    GtkGesture *long_press = gtk_gesture_long_press_new();
    g_signal_connect(long_press, "pressed", G_CALLBACK(unicode_character_map_on_long_press), widget);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(long_press));
    GtkGesture *pinch_zoom = gtk_gesture_zoom_new();
    g_signal_connect(pinch_zoom, "scale-changed", G_CALLBACK(unicode_character_map_on_pinch_zoom), widget);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(pinch_zoom));
    /* Drag and drop */
    GtkDragSource *drag_source = gtk_drag_source_new();
    g_signal_connect(drag_source, "prepare", G_CALLBACK(unicode_character_map_on_prepare_drag), self);
    g_signal_connect(drag_source, "drag-begin", G_CALLBACK(unicode_character_map_on_drag_begin), self);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(drag_source));
    return;
}

/**
 * unicode_character_map_get_active_cell:
 * @self: a #UnicodeCharacterMap
 *
 * Returns: The currently selected cell
 */
gint
unicode_character_map_get_active_cell (UnicodeCharacterMap *self)
{
    g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(self), 0);
    return self->active_cell;
}

/**
 * unicode_character_map_get_codepoint_list:
 * @self: a #UnicodeCharacterMap
 *
 * Returns: (transfer none) (nullable): The current #UnicodeCodepointList
 */
UnicodeCodepointList *
unicode_character_map_get_codepoint_list (UnicodeCharacterMap *self)
{
    g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(self), NULL);
    return self->codepoint_list;
}

/**
 * unicode_character_map_get_font_desc:
 * @self: a #UnicodeCharacterMap
 *
 * Returns: (transfer none) (nullable):
 * The #PangoFontDescription used to display the character table.
 * The returned object is owned by @self and must not be modified or freed.
 */
PangoFontDescription *
unicode_character_map_get_font_desc (UnicodeCharacterMap *self)
{
      g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(self), NULL);
      return self->font_desc;
}

/**
 * unicode_character_map_get_preview_size:
 * @self: a #UnicodeCharacterMap
 *
 * Returns: The current preview size
 */
double
unicode_character_map_get_preview_size (UnicodeCharacterMap *self)
{
    g_return_val_if_fail(UNICODE_IS_CHARACTER_MAP(self), 0.0);
    return self->preview_size;
}

/**
 * unicode_character_map_set_active_cell:
 * @self: a #UnicodeCharacterMap
 * @cell: cell to select
 */
void
unicode_character_map_set_active_cell (UnicodeCharacterMap *self, gint cell)
{
    if (cell == self->active_cell)
        return;
    GtkWidget *widget = GTK_WIDGET(self);
    cell = CLAMP(cell, 0, self->last_cell);
    int old_active_cell = self->active_cell;
    int old_page_first_cell = self->page_first_cell;
    self->active_cell = cell;
    if (cell < self->page_first_cell || cell >= self->page_first_cell + self->page_size) {
        int old_row = old_active_cell / self->columns;
        int new_row = cell / self->columns;
        int new_page_first_cell = old_page_first_cell + ((new_row - old_row) * self->columns);
        int last_row = (self->last_cell / self->columns) + 1;
        int last_page_first_row = last_row - self->rows;
        int last_page_first_cell = (last_page_first_row * self->columns) + 1;
        self->page_first_cell = CLAMP(new_page_first_cell, 0, last_page_first_cell);
        if (self->vadjustment)
            gtk_adjustment_set_value(self->vadjustment, self->page_first_cell / self->columns);
    }
    gtk_widget_queue_draw(widget);
    g_object_notify(G_OBJECT(self), "active-cell");
    return;
}

/**
 * unicode_character_map_set_codepoint_list:
 * @self: a #UnicodeCharacterMap
 * @codepoint_list: (nullable): a #UnicodeCodepointList
 *
 * Sets the codepoint list to show in the character table.
 */
void
unicode_character_map_set_codepoint_list (UnicodeCharacterMap *self,
                                          UnicodeCodepointList *codepoint_list)
{
    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(self));
    GObject *obj = G_OBJECT(self);
    g_object_freeze_notify(obj);
    g_set_object(&self->codepoint_list, codepoint_list);
    self->active_cell = 0;
    self->page_first_cell = 0;
    self->last_cell = self->codepoint_list ? unicode_codepoint_list_get_last_index(self->codepoint_list) : 0;
    g_object_notify(obj, "codepoint-list");
    g_object_notify(obj, "active-cell");
    gtk_widget_queue_resize(GTK_WIDGET(self));
    g_object_thaw_notify(obj);
    return;
}

/**
 * unicode_character_map_set_font_desc:
 * @self: a #UnicodeCharacterMap
 * @font_desc: (transfer none): a #PangoFontDescription
 *
 * Sets @font_desc as the font to use to display the character table.
 */
void
unicode_character_map_set_font_desc (UnicodeCharacterMap *self, PangoFontDescription *font_desc)
{
    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(self));
    g_return_if_fail(font_desc != NULL);
    if (self->font_desc && pango_font_description_equal(font_desc, self->font_desc))
        return;
    unicode_character_map_set_font_desc_internal(self, pango_font_description_copy(font_desc));
    return;
}

/**
 * unicode_character_map_set_preview_size:
 * @self: a #UnicodeCharacterMap
 * @size: new preview size
 *
 * Sets the preview size to @size.
 */
void
unicode_character_map_set_preview_size (UnicodeCharacterMap *self, gdouble size)
{
    g_return_if_fail(UNICODE_IS_CHARACTER_MAP(self));
    self->preview_size = VALID_FONT_SIZE(size);
    PangoFontDescription *font_desc = pango_font_description_copy(self->font_desc);
    unicode_character_map_set_font_desc_internal(self, font_desc);
    g_object_notify(G_OBJECT(self), "preview-size");
    return;
}

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
