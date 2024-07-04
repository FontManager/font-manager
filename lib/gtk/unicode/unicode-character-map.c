/* unicode-character-map.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017-2024 Jerry Casiano
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
 * @title: Unicode Character Map
 * @include: unicode-character-map.h
 *
 * Widget which displays all the available characters in the selected font.
 */

#define CELL_PADDING 2.5
#define VALID_FONT_SIZE(X) (X < 6.0 ? 6.0 : X > 96.0 ? 96.0 : X)
#define FIRST_CELL_IN_SAME_ROW(x) ((x) - ((x) % self->columns))
#define N_REGIONAL_INDICATORS G_N_ELEMENTS(FontManagerRegionalIndicatorSymbols)

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
    PROP_FONT_DESC,
    PROP_PREVIEW_SIZE
};

struct _FontManagerUnicodeCharacterMap
{
    GtkDrawingArea parent;

    gint    rows;
    gint    columns;
    gint    active_cell;        /* the active cell index */
    gint    drag_cell;          /* the cell currently being dragged */
    gint    last_cell;          /* charset length */
    gint    min_cell_height;    /* depends on font_desc and size allocation */
    gint    min_cell_width;     /* depends on font_desc and size allocation */
    gint    n_padded_columns;   /* columns 0..n-1 will be 1px wider than min_cell_width */
    gint    n_padded_rows;      /* rows 0..n-1 will be 1px taller than min_cell_height */
    gint    page_first_cell;    /* the cell index of the top left corner */
    gint    page_size;          /* rows * cols */

    GtkWidget *context_widget;

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
    /* Character set information */
    gboolean has_regional_indicator_symbols;
    gboolean is_regional_indicator_filter;
    GList *charset;
    GList *filter;
};

G_DEFINE_TYPE_WITH_CODE (FontManagerUnicodeCharacterMap, font_manager_unicode_character_map,
                         GTK_TYPE_DRAWING_AREA,
                         G_IMPLEMENT_INTERFACE(GTK_TYPE_SCROLLABLE, NULL))

static GtkWidget * get_context_widget (FontManagerUnicodeCharacterMap *self);

static void
update_scrollbar_adjustment (FontManagerUnicodeCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    if (self->vadjustment != NULL) {
        gtk_adjustment_configure(self->vadjustment,
                                 self->page_first_cell / self->columns, /* current value */
                                 0 /* lower */,
                                 self->last_cell / self->columns + 1 /* upper */,
                                 1 /* step increment */,
                                 self->rows /* page increment */,
                                 self->rows); /* page size */
    }
    return;
}

static void
clear_pango_layout (FontManagerUnicodeCharacterMap *self)
{
    g_return_if_fail(self != NULL);
    g_clear_object(&self->pango_layout);
    g_clear_object(&self->zoom_layout);
    return;
}

static void
ensure_pango_layout (FontManagerUnicodeCharacterMap *self)
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
            GtkWidget *popover = get_context_widget(self);
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

static gint
get_index (FontManagerUnicodeCharacterMap *self, GSList *codepoints)
{
    g_return_val_if_fail(self != NULL, -1);
    if (!codepoints || g_slist_length(codepoints) < 1)
        return -1;
    gunichar code1 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
    if (self->filter && self->is_regional_indicator_filter) {
        if (g_slist_length(codepoints) == 2) {
            gunichar code2 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 1));
            for (int i = 0; i < N_REGIONAL_INDICATORS; i++)
                if (FontManagerRegionalIndicatorSymbols[i].code1 == code1
                    && FontManagerRegionalIndicatorSymbols[i].code2 == code2)
                    return i;
        }
        return -1;
    } else if (self->filter)
        return g_list_index(self->filter, GINT_TO_POINTER(code1));
    else
        return self->charset != NULL ? (gint) g_list_index(self->charset, GINT_TO_POINTER(code1)) : -1;
}

static gint
get_last_index (FontManagerUnicodeCharacterMap *self)
{
    g_return_val_if_fail(self != NULL, -1);
    if (self->filter && self->is_regional_indicator_filter)
        return N_REGIONAL_INDICATORS - 1;
    else if (self->filter)
        return g_list_length(self->filter) - 1;
    if (!self->charset)
        return 0;
    if (!self->has_regional_indicator_symbols)
        return (gint) g_list_length(self->charset) - 1;
    return (((gint) g_list_length(self->charset)) + N_REGIONAL_INDICATORS) - 1;
}

static GSList *
get_codepoints (FontManagerUnicodeCharacterMap *self, gint index)
{
    g_return_val_if_fail(self != NULL, NULL);
    gint base_codepoints = (gint) g_list_length(self->charset);
    GSList *results = NULL;
    if (index < base_codepoints) {
        if (self->filter && self->is_regional_indicator_filter) {
            if (index < N_REGIONAL_INDICATORS) {
                results = g_slist_append(results, GINT_TO_POINTER(FontManagerRegionalIndicatorSymbols[index].code1));
                results = g_slist_append(results, GINT_TO_POINTER(FontManagerRegionalIndicatorSymbols[index].code2));
            }
        } else if (self->filter)
            results = g_slist_append(results, g_list_nth_data(self->filter, index));
        else
            results = g_slist_append(results, self->charset != NULL ?
                                              g_list_nth_data(self->charset, index) :
                                              GINT_TO_POINTER(-1));
    } else if (base_codepoints > 0) {
        gint _index = index - base_codepoints;
        if (_index < N_REGIONAL_INDICATORS) {
            results = g_slist_append(results, GINT_TO_POINTER(FontManagerRegionalIndicatorSymbols[_index].code1));
            results = g_slist_append(results, GINT_TO_POINTER(FontManagerRegionalIndicatorSymbols[_index].code2));
        }
    }
    return results;
}

static gchar *
get_text_for_cell (FontManagerUnicodeCharacterMap *self, gint index)
{
    g_return_val_if_fail(self != NULL, NULL);
    GSList *codepoints = get_codepoints(self, index);
    for (GSList *iter = codepoints; iter != NULL; iter = iter->next) {
        gunichar wc = GPOINTER_TO_INT(iter->data);
        if (wc > FONT_MANAGER_UNICHAR_MAX || !font_manager_unicode_unichar_validate(wc))
            return NULL;
    }
    gchar text [24];
    gchar *p = text;
    for (GSList *iter = codepoints; iter != NULL; iter = iter->next)
        p += font_manager_unicode_unichar_to_printable_utf8((gunichar) GPOINTER_TO_INT(iter->data), p);
    p[0] = 0;
    g_slist_free(codepoints);
    return g_strdup(text);
}

static void
font_manager_unicode_character_map_resize (GtkDrawingArea *widget, int width, int height)
{
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(widget);
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
    if (self->rows != old_rows || self->columns != old_cols) {
        /* Need to recalculate the first cell, see bug #517188 */
        gint new_first_cell = FIRST_CELL_IN_SAME_ROW(self->active_cell);
        if ((new_first_cell + self->page_size) > (self->last_cell)) {
            /* Last cell is visible, so make sure it is in the last row */
            new_first_cell = FIRST_CELL_IN_SAME_ROW(self->last_cell) - self->page_size + self->columns;
            if (new_first_cell < 0)
                new_first_cell = 0;
        }
        self->page_first_cell = new_first_cell;
    }
    update_scrollbar_adjustment(self);
    return;
}

static gint
get_cell_at_rowcol (FontManagerUnicodeCharacterMap *self, gint row, gint col)
{
    /* Depends on directionality */
    if (gtk_widget_get_direction(GTK_WIDGET(self)) == GTK_TEXT_DIR_RTL)
        return self->page_first_cell + row * self->columns + (self->columns - col - 1);
    else
        return self->page_first_cell + row * self->columns + col;
}

static gint
cell_column (FontManagerUnicodeCharacterMap *self, guint cell)
{
    /* Depends on directionality. Column 0 is the furthest left. */
    if (gtk_widget_get_direction(GTK_WIDGET(self)) == GTK_TEXT_DIR_RTL)
        return self->columns - (cell - self->page_first_cell) % self->columns - 1;
    else
        return (cell - self->page_first_cell) % self->columns;
}

static gint
column_width (FontManagerUnicodeCharacterMap *self, gint col)
{
    g_return_val_if_fail(self != NULL, self->min_cell_width);
    /* Not all columns are necessarily the same width because of padding */
    if (self->columns - col <= self->n_padded_columns)
        return self->min_cell_width + 1;
    else
        return self->min_cell_width;
}

static gint
row_height (FontManagerUnicodeCharacterMap *self, gint row)
{
    g_return_val_if_fail(self != NULL, self->min_cell_height);
    /* Not all rows are necessarily the same height because of padding */
    if (self->rows - row <= self->n_padded_rows)
        return self->min_cell_height + 1;
    else
        return self->min_cell_height;
}

static gint
get_cell_at_xy (FontManagerUnicodeCharacterMap *self, gint x, gint y)
{
    gint c, r, x0, y0, cell;

    for (c = 0, x0 = 0;  x0 <= x && c < self->columns;  c++)
        x0 += column_width(self, c);

    for (r = 0, y0 = 0;  y0 <= y && r < self->rows;  r++)
        y0 += row_height(self, r);

    cell = get_cell_at_rowcol(self, r-1, c-1);

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
get_x_offset (FontManagerUnicodeCharacterMap *self, gint col)
{
    gint c, x;
    for (c = 0, x = 1; c < col; c++)
        x += column_width(self, c);
    return x;
}

/* Calculate the position of the top end of the row (just below the top
 * border)
 * XXX: calling this repeatedly is not the most efficient, but it probably
 * is the most readable
 */
static gint
get_y_offset (FontManagerUnicodeCharacterMap *self, gint row)
{
    gint r, y;
    for (r = 0, y = 1; r < row; r++)
        y += row_height(self, r);
    return y;
}

/* FIXME ! */
G_GNUC_BEGIN_IGNORE_DEPRECATIONS

static void
draw_character_with_metrics (GtkDrawingArea *widget,
                             cairo_t *cr,
                             gint unused_width,
                             gint unused_height,
                             gpointer user_data)
{
    g_return_if_fail(user_data != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    ensure_pango_layout(self);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(widget));
    g_autofree gchar *cell_text = get_text_for_cell(self, self->active_cell);
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
    gtk_style_context_save(ctx);
    gtk_style_context_set_state(ctx, GTK_STATE_FLAG_INSENSITIVE);
    gtk_style_context_add_class(ctx, "PangoGlyphMetrics");
    gtk_render_line(ctx, cr, 1, baseline + xpad, alloc.width - 1, baseline + xpad);
    gtk_render_line(ctx, cr, 1, PANGO_ASCENT(char_rect) + xpad, alloc.width - 1, PANGO_ASCENT(char_rect) + xpad);
    gtk_render_line(ctx, cr, 1, PANGO_DESCENT(char_rect) + xpad, alloc.width - 1, PANGO_DESCENT(char_rect) + xpad);
    gtk_render_line(ctx, cr, PANGO_LBEARING(char_rect) + ypad, 1, PANGO_LBEARING(char_rect) + ypad, alloc.height - 1);
    gtk_render_line(ctx, cr, PANGO_RBEARING(char_rect) + ypad, 1, PANGO_RBEARING(char_rect) + ypad, alloc.height - 1);
    gtk_style_context_restore(ctx);
    gtk_render_layout(ctx, cr, char_rect.x + xpad, char_rect.y + ypad, self->zoom_layout);
    gtk_popover_present(GTK_POPOVER(get_context_widget(self)));
    return;
}

static void
draw_character (GtkWidget *widget,
                GtkSnapshot *snapshot,
                GtkStyleContext *ctx,
                graphene_rect_t *rect,
                gint cell)
{
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(widget);
    g_autofree gchar *text = get_text_for_cell(self, cell);
    pango_layout_set_text(self->pango_layout, text, -1);
    /* Keep the square empty if the font has no glyph for this cell. */
    if (pango_layout_get_unknown_glyphs_count(self->pango_layout) > 0)
        return;
    gtk_style_context_save(ctx);
    GtkStateFlags _state = GTK_STATE_FLAG_NORMAL;
    if (gtk_widget_has_focus(widget) && cell == self->active_cell)
        _state = GTK_STATE_FLAG_SELECTED | GTK_STATE_FLAG_FOCUSED;
    else if ((gint) cell == self->active_cell)
        _state = GTK_STATE_FLAG_INSENSITIVE | GTK_STATE_FLAG_SELECTED;
    gtk_style_context_set_state(ctx, _state);
    gtk_style_context_add_class(ctx, "CharacterMapGlyph");
    gint char_width, char_height;
    pango_layout_get_pixel_size(self->pango_layout, &char_width, &char_height);
    gtk_snapshot_render_layout(snapshot, ctx,
                               rect->origin.x + (rect->size.width - char_width) / 2,
                               rect->origin.y + (rect->size.height - char_height) / 2,
                               self->pango_layout);
    gtk_style_context_restore(ctx);
    return;
}

static void
draw_square_bg (GtkWidget *widget,
                GtkSnapshot *snapshot,
                GtkStyleContext *ctx,
                graphene_rect_t *rect,
                gint cell)
{
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(widget);
    gtk_style_context_save(ctx);
    GtkStateFlags _state = GTK_STATE_FLAG_NORMAL;
    if (gtk_widget_has_focus(widget) && cell == self->active_cell)
        _state = GTK_STATE_FLAG_FOCUSED | GTK_STATE_FLAG_SELECTED;
    else if (cell == self->active_cell)
        _state = GTK_STATE_FLAG_SELECTED;
    else if (cell > self->last_cell)
        _state = GTK_STATE_FLAG_INSENSITIVE;
    gtk_style_context_set_state(ctx, _state);
    gtk_style_context_add_class(ctx, "CharacterMapCell");
    gtk_snapshot_render_background(snapshot, ctx,
                                   rect->origin.x + 2, rect->origin.y + 2,
                                   rect->size.width - 5, rect->size.height - 5);
    gtk_style_context_restore(ctx);
    return;
}

static void
draw_separators (GtkWidget *widget, GtkStyleContext *ctx, cairo_t *cr)
{
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(widget);
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
        x += column_width(self, col);
        gtk_render_line(ctx, cr, x, 0, x, allocation.height);
    }
    /* Horizontal */
    gtk_render_line(ctx, cr, 0, 0, allocation.width, 0);
    for (row = 0, y = 0;  row < self->rows;  row++) {
        y += row_height(self, row);
        gtk_render_line(ctx, cr, 0, y, allocation.width, y);
    }
    gtk_style_context_restore(ctx);
    return;
}

static void
font_manager_unicode_character_map_snapshot (GtkWidget *widget, GtkSnapshot *snapshot)
{
    GtkAllocation allocation;
    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(widget);
    ensure_pango_layout(self);
    gtk_widget_get_allocation(widget, &allocation);
    for (int row = self->rows - 1; row >= 0; --row) {
        for (int col = self->columns - 1; col >= 0; --col)  {
            graphene_rect_t *cell_rect = graphene_rect_alloc();
            cell_rect = graphene_rect_init(cell_rect,
                                           get_x_offset(self, col),
                                           get_y_offset(self, row),
                                           column_width(self, col),
                                           row_height(self, row));
            gint cell = get_cell_at_rowcol(self, row, col);
            draw_square_bg(widget, snapshot, ctx, cell_rect, cell);
            draw_character(widget, snapshot, ctx, cell_rect, cell);
            graphene_rect_free(cell_rect);
        }
    }
    graphene_rect_t *allocated_rect = graphene_rect_alloc();
    allocated_rect = graphene_rect_init(allocated_rect,
                                        allocation.x, allocation.y,
                                        allocation.width, allocation.height);
    cairo_t *cr = gtk_snapshot_append_cairo(snapshot, allocated_rect);
    draw_separators(widget, ctx, cr);
    graphene_rect_free(allocated_rect);
    cairo_destroy(cr);
    return;
}

static void
set_hadjustment (FontManagerUnicodeCharacterMap *self, GtkAdjustment *hadjustment)
{
    g_return_if_fail(self != NULL);
    g_set_object(&self->hadjustment, hadjustment);
    return;
}

static void
vadjustment_value_changed_cb (GtkAdjustment *vadjustment, FontManagerUnicodeCharacterMap *self)
{
    int row = (int) gtk_adjustment_get_value(vadjustment);
    if (row < 0 )
        row = 0;
    int first_cell = row * self->columns;
    if (first_cell == self->page_first_cell)
        return;
    gtk_widget_queue_resize(GTK_WIDGET(self));
    self->page_first_cell = first_cell;
    return;
}

static void
set_vadjustment (FontManagerUnicodeCharacterMap *self, GtkAdjustment *vadjustment)
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

    update_scrollbar_adjustment(self);
    return;
}

gboolean
is_regional_indicator_filter (GList *filter)
{
    if (!filter || g_list_length(filter) != 26)
        return FALSE;
    return (GPOINTER_TO_INT(g_list_nth_data(filter, 0)) == FONT_MANAGER_RIS_START_POINT
            && GPOINTER_TO_INT(g_list_nth_data(filter, 25)) == FONT_MANAGER_RIS_END_POINT);
}

static void
check_for_regional_indicator_symbols (FontManagerUnicodeCharacterMap *self, hb_set_t *charset)
{
    self->has_regional_indicator_symbols = FALSE;
    for (guint32 i = FONT_MANAGER_RIS_START_POINT; i < FONT_MANAGER_RIS_END_POINT; i++)
        if (!hb_set_has(charset, i))
            return;
    self->has_regional_indicator_symbols = TRUE;
    return;
}

static void
populate_charset (FontManagerUnicodeCharacterMap *self, const PangoFontDescription *font_desc)
{
    g_clear_pointer(&self->charset, g_list_free);
    g_clear_pointer(&self->filter, g_list_free);
    ensure_pango_layout(self);
    PangoContext *context = pango_layout_get_context(self->pango_layout);
    PangoFontMap *font_map = pango_context_get_font_map(context);
    g_autoptr(PangoFont) font = pango_font_map_load_font(font_map, context, font_desc);
    hb_font_t *hb_font = pango_font_get_hb_font(font);
    hb_face_t *face = hb_font_get_face(hb_font);
    hb_set_t *charset = hb_set_create();
    hb_face_collect_unicodes(face, charset);
    hb_codepoint_t codepoint = HB_SET_VALUE_INVALID;
    while (hb_set_next(charset, &codepoint))
        if (font_manager_unicode_unichar_isgraph(codepoint))
            self->charset = g_list_prepend(self->charset, GINT_TO_POINTER(codepoint));
    self->charset = g_list_reverse(self->charset);
    check_for_regional_indicator_symbols(self, charset);
    hb_set_destroy(charset);
    return;
}

static void
set_font_desc_internal (FontManagerUnicodeCharacterMap *self,
                        PangoFontDescription           *font_desc)
{
    g_return_if_fail(font_desc != NULL);
    if (!self->font_desc || !pango_font_description_equal(font_desc, self->font_desc)){
        g_clear_pointer(&self->font_desc, pango_font_description_free);
        pango_font_description_set_size(font_desc, self->preview_size * PANGO_SCALE);
        self->font_desc = pango_font_description_copy(font_desc);
        populate_charset(self, font_desc);
        g_object_notify(G_OBJECT(self), "font-desc");
    }
    self->active_cell = 0;
    self->page_first_cell = 0;
    self->last_cell = get_last_index(self);
    clear_pango_layout(self);
    gtk_widget_queue_resize(GTK_WIDGET(self));
    g_object_notify(G_OBJECT(self), "active-cell");
    return;
}

static void
on_selection_changed (FontManagerUnicodeCharacterMap *self)
{
    if (self->charset == NULL)
        return;
    const gchar *name = NULL;
    g_autofree gchar *codepoint = NULL;
    gint last_index = get_last_index(self);
    g_autofree gchar *n_codepoints = g_strdup_printf("%i", (last_index + 1));
    GSList *codepoints = get_codepoints(self, self->active_cell);
    guint points = g_slist_length(codepoints);
    if (points == 1) {
        gunichar ac = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
        codepoint = g_markup_printf_escaped("U+%4.4X", ac);
        name = font_manager_unicode_get_codepoint_name(ac);
    } else if (points == 2) {
        gunichar code1 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
        gunichar code2 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 1));
        int index;
        for (index = 0; index < G_N_ELEMENTS(FontManagerRegionalIndicatorSymbols); index++)
            if (FontManagerRegionalIndicatorSymbols[index].code1 == code1 && FontManagerRegionalIndicatorSymbols[index].code2 == code2)
                break;
        codepoint = g_markup_printf_escaped("U+%4.4X + U+%4.4X", code1, code2);
        name = FontManagerRegionalIndicatorSymbols[index].region;
    }
    g_slist_free(codepoints);
    g_signal_emit(self, signals[SELECTION_CHANGED], 0, codepoint, name, n_codepoints);
    return;
}

static void
copy_clipboard (GtkWidget *widget, gpointer user_data)
{
    g_return_if_fail(user_data != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    g_autofree gchar *text = get_text_for_cell(self, self->active_cell);
    GdkClipboard *clipboard = gtk_widget_get_clipboard(GTK_WIDGET(self));
    gdk_clipboard_set_text(clipboard, text);
    if (self->context_widget && gtk_widget_get_mapped(self->context_widget))
        gtk_popover_popdown(GTK_POPOVER(self->context_widget));
    return;
}

static void
copy_shortcut_func (GtkWidget *widget, GVariant *args, gpointer user_data)
{
    copy_clipboard(widget, widget);
    return;
}

static void
move_cursor_left_right (FontManagerUnicodeCharacterMap *self, int count)
{
    gboolean is_rtl = (gtk_widget_get_direction(GTK_WIDGET(self)) == GTK_TEXT_DIR_RTL);
    int offset = is_rtl ? -count : count;
    font_manager_unicode_character_map_set_active_cell(self, self->active_cell + offset);
    return;
}

static void
move_cursor_up_down (FontManagerUnicodeCharacterMap *self, int count)
{
    font_manager_unicode_character_map_set_active_cell(self, self->active_cell + self->columns * count);
    return;
}

static void
move_cursor_page_up_down (FontManagerUnicodeCharacterMap *self, int count)
{
  font_manager_unicode_character_map_set_active_cell(self, self->active_cell + self->page_size * count);
  return;
}

static void
move_cursor_start_end (FontManagerUnicodeCharacterMap *self, int count)
{
    int new_cell = count > 0 ? self->last_cell : 0;
    font_manager_unicode_character_map_set_active_cell(self, new_cell);
    return;
}

static void
move_cursor (GtkWidget *widget, GVariant *variant, gpointer user_data)
{
    g_return_if_fail(widget != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(widget);
    gint step, count;
    g_variant_get(variant, "(ii)", &step, &count);
    switch ((GtkMovementStep) step) {
        case GTK_MOVEMENT_LOGICAL_POSITIONS:
        case GTK_MOVEMENT_VISUAL_POSITIONS:
            move_cursor_left_right(self, count);
            break;
        case GTK_MOVEMENT_DISPLAY_LINES:
            move_cursor_up_down(self, count);
            break;
        case GTK_MOVEMENT_PAGES:
            move_cursor_page_up_down(self, count);
            break;
        case GTK_MOVEMENT_BUFFER_ENDS:
            move_cursor_start_end(self, count);
            break;
        default:
            return;
    }
    return;
}

static GtkWidget *
get_context_widget (FontManagerUnicodeCharacterMap *self)
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
    gtk_widget_set_margin_top(separator, FONT_MANAGER_DEFAULT_MARGIN);
    gtk_widget_set_margin_bottom(separator, FONT_MANAGER_DEFAULT_MARGIN);
    GtkWidget *copy_button = gtk_button_new_with_label(_("Copy"));
    gtk_widget_set_opacity(copy_button, 0.75);
    gtk_widget_add_css_class(copy_button, "pill-button");
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
    g_signal_connect(copy_button, "clicked", G_CALLBACK(copy_clipboard), self);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(glyph), draw_character_with_metrics, self, NULL);
    gtk_popover_set_child(GTK_POPOVER(self->context_widget), box);
    gtk_popover_set_position(GTK_POPOVER(self->context_widget), GTK_POS_TOP);
    gtk_widget_set_parent(self->context_widget, GTK_WIDGET(self));
    gtk_popover_set_default_widget(GTK_POPOVER(self->context_widget), copy_button);
    return self->context_widget;
}

static void
show_context_widget (FontManagerUnicodeCharacterMap *self, gdouble x, gdouble y)
{
    g_return_if_fail(self != NULL);
    GtkWidget *popover = get_context_widget(self);
    gint row = (self->active_cell - self->page_first_cell) / self->columns;
    gint col = cell_column(self, self->active_cell);
    if ((row >= 0 && row < self->rows) && (col >= 0 && col < self->columns)) {
        gint x_offset = get_x_offset(self, col);
        gint y_offset = get_y_offset(self, row);
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
on_long_press (G_GNUC_UNUSED GtkGestureLongPress *gesture, gdouble x, gdouble y, gpointer user_data)
{
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    font_manager_unicode_character_map_set_active_cell(self, get_cell_at_xy(self, x, y));
    show_context_widget(self, x, y);
    return;
}

void
on_pinch_zoom (G_GNUC_UNUSED GtkGestureZoom *gesture, gdouble scale_factor, gpointer user_data)
{
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    gdouble size = nearbyint(self->preview_size * scale_factor);
    font_manager_unicode_character_map_set_preview_size(self, VALID_FONT_SIZE(size));
    return;
}

static void
on_click (GtkGestureClick* click, gint n_press, gdouble x, gdouble y, gpointer user_data)
{
    if (n_press > 1)
        return;
    g_return_if_fail(user_data != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    gtk_widget_grab_focus(GTK_WIDGET(user_data));
    font_manager_unicode_character_map_set_active_cell(self, get_cell_at_xy(self, x, y));
    if (gtk_gesture_single_get_current_button(GTK_GESTURE_SINGLE(click)) == GDK_BUTTON_SECONDARY)
        show_context_widget(self, x, y);
    return;
}

static GdkContentProvider *
on_prepare_drag (GtkDragSource *source, double x, double y, gpointer user_data)
{
    g_return_val_if_fail(user_data != NULL, NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    self->drag_cell = get_cell_at_xy(self, x, y);
    g_autofree gchar *text = get_text_for_cell(self, self->drag_cell);
    return gdk_content_provider_new_typed(G_TYPE_STRING, text);
}

static void
on_drag_begin (GtkDragSource *source, GdkDrag *drag, gpointer user_data)
{
    gint font_size = FONT_MANAGER_LARGE_PREVIEW_SIZE * 1.5;
    GtkWidget *widget = GTK_WIDGET(user_data);
    g_autoptr(GtkSnapshot) snapshot = gtk_snapshot_new();
    GtkStyleContext *ctx = gtk_widget_get_style_context(widget);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data);
    graphene_rect_t *rect = graphene_rect_alloc();
    rect = graphene_rect_init(rect, 0, 0, font_size * 3, font_size * 3);
    gtk_style_context_save(ctx);
    gtk_style_context_set_state(ctx, GTK_STATE_FLAG_FOCUSED | GTK_STATE_FLAG_SELECTED);
    gtk_style_context_add_class(ctx, "CharacterMapCell");
    gtk_style_context_add_class(ctx, "CharacterMapGlyph");
    gtk_snapshot_render_background(snapshot, ctx,
                                   rect->origin.x, rect->origin.y,
                                   rect->size.width, rect->size.height);
    g_autofree gchar *text = get_text_for_cell(self, self->drag_cell);
    g_autoptr(PangoLayout) layout = gtk_widget_create_pango_layout(widget, text);
    PangoAttrList *attrs = pango_attr_list_new();
    PangoAttribute *size = pango_attr_size_new(font_size * PANGO_SCALE);
    PangoAttribute *font = pango_attr_font_desc_new(self->font_desc);
    pango_attr_list_insert(attrs, font);
    pango_attr_list_insert(attrs, size);
    pango_layout_set_attributes(layout, attrs);
    gint char_width, char_height;
    pango_layout_get_pixel_size(layout, &char_width, &char_height);
    gtk_snapshot_render_layout(snapshot, ctx,
                               rect->origin.x + (rect->size.width - char_width) / 2,
                               rect->origin.y + (rect->size.height - char_height) / 2,
                               layout);
    gtk_style_context_restore(ctx);
    graphene_rect_free(rect);
    pango_attr_list_unref(attrs);
    gtk_drag_source_set_icon(source, gtk_snapshot_to_paintable(snapshot, NULL), 0, 0);
    gdk_drag_set_hotspot(drag,
                         rect->origin.x - ((rect->size.width / 2)),
                         rect->origin.y - ((rect->size.height / 2)) - 12);
    return;
}

G_GNUC_END_IGNORE_DEPRECATIONS

static void
font_manager_unicode_character_map_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(gobject);
    g_clear_pointer(&self->font_desc, pango_font_description_free);
    clear_pango_layout(self);
    font_manager_widget_dispose(GTK_WIDGET(self));
    G_OBJECT_CLASS(font_manager_unicode_character_map_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_unicode_character_map_set_property (GObject *gobject,
                                                 guint prop_id,
                                                 const GValue *value,
                                                 GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(gobject);

    switch (prop_id) {
        case PROP_HADJUSTMENT:
            set_hadjustment(self, g_value_get_object(value));
            break;
        case PROP_VADJUSTMENT:
            set_vadjustment(self, g_value_get_object(value));
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
            font_manager_unicode_character_map_set_font_desc(self, g_value_get_boxed(value));
            break;
        case PROP_PREVIEW_SIZE:
            font_manager_unicode_character_map_set_preview_size(self, g_value_get_double(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
font_manager_unicode_character_map_get_property (GObject *gobject,
                                                 guint prop_id,
                                                 GValue *value,
                                                 GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeCharacterMap *self = FONT_MANAGER_UNICODE_CHARACTER_MAP(gobject);

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
            g_value_set_boxed(value, font_manager_unicode_character_map_get_font_desc(self));
            break;
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, font_manager_unicode_character_map_get_preview_size(self));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
font_manager_unicode_character_map_class_init (FontManagerUnicodeCharacterMapClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    GTK_DRAWING_AREA_CLASS(widget_class)->resize = font_manager_unicode_character_map_resize;
    widget_class->snapshot = font_manager_unicode_character_map_snapshot;
    object_class->dispose = font_manager_unicode_character_map_dispose;
    object_class->get_property = font_manager_unicode_character_map_get_property;
    object_class->set_property = font_manager_unicode_character_map_set_property;

    /* GtkScrollable interface properties */
    g_object_class_override_property(object_class, PROP_HADJUSTMENT, "hadjustment");
    g_object_class_override_property(object_class, PROP_VADJUSTMENT, "vadjustment");
    g_object_class_override_property(object_class, PROP_HSCROLL_POLICY, "hscroll-policy");
    g_object_class_override_property(object_class, PROP_VSCROLL_POLICY, "vscroll-policy");

    /**
     * FontManagerUnicodeCharacterMap::selection-changed:
     * @self:               #FontManagerUnicodeCharacterMap
     * @codepoint:          Unicode codepoint as a string
     * @codepoint_name:     Codepoint name
     * @n_codepoints:       Total # of codepoints in current list as a string
     *
     * The :selection-changed signal is emitted whenever a new cell is selected.
     */
    signals[SELECTION_CHANGED] = g_signal_new("selection-changed",
                                              FONT_MANAGER_TYPE_UNICODE_CHARACTER_MAP,
                                              G_SIGNAL_RUN_FIRST,
                                              0,
                                              NULL, NULL, NULL,
                                              G_TYPE_NONE,
                                              3,
                                              G_TYPE_STRING,
                                              G_TYPE_STRING,
                                              G_TYPE_STRING);

    /**
     * FontManagerUnicodeCharacterMap:active-cell:
     *
     * Active cell in character map
     */
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

    /**
     * FontManagerUnicodeCharacterMap:font-desc:
     *
     * #PangoFontDescription
     */
    g_object_class_install_property(object_class,
                                    PROP_FONT_DESC,
                                    g_param_spec_boxed("font-desc",
                                                        NULL,
                                                        "PangoFontDescription",
                                                        PANGO_TYPE_FONT_DESCRIPTION,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS));

    /**
     * FontManagerUnicodeCharacterMap:preview-size:
     *
     * Character map preview size
     */
    g_object_class_install_property(object_class,
                                    PROP_PREVIEW_SIZE,
                                    g_param_spec_double("preview-size",
                                                        NULL,
                                                        "Preview size",
                                                        6, 96, 14,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_STATIC_STRINGS));


    /* Clipboard */
    GtkShortcutFunc copy_callback = (GtkShortcutFunc) copy_shortcut_func;
    gtk_widget_class_add_binding(widget_class, GDK_KEY_c, GDK_CONTROL_MASK, copy_callback, NULL);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Insert, GDK_CONTROL_MASK, copy_callback, NULL);
    /* Cursor movement */
    GtkShortcutFunc move_callback = (GtkShortcutFunc) move_cursor;
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Up, 0, move_callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Up, 0, move_callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Down, 0, move_callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Down, 0, move_callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_p, GDK_CONTROL_MASK, move_callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_n, GDK_CONTROL_MASK, move_callback, "(ii)", GTK_MOVEMENT_DISPLAY_LINES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Home, 0, move_callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Home, 0, move_callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_End, 0, move_callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_End, 0, move_callback, "(ii)", GTK_MOVEMENT_BUFFER_ENDS, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Page_Up, 0, move_callback, "(ii)", GTK_MOVEMENT_PAGES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Page_Up, 0, move_callback, "(ii)", GTK_MOVEMENT_PAGES, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Page_Down, 0, move_callback, "(ii)", GTK_MOVEMENT_PAGES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Page_Down, 0, move_callback, "(ii)", GTK_MOVEMENT_PAGES, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Left, 0, move_callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Left, 0, move_callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, -1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_Right, 0, move_callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, 1);
    gtk_widget_class_add_binding(widget_class, GDK_KEY_KP_Right, 0, move_callback, "(ii)", GTK_MOVEMENT_VISUAL_POSITIONS, 1);
    return;
}

static void
font_manager_unicode_character_map_init (FontManagerUnicodeCharacterMap *self)
{
    self->page_first_cell = 0;
    self->active_cell = 0;
    self->rows = 1;
    self->columns = 1;
    self->vadjustment = NULL;
    self->hadjustment = NULL;
    self->hscroll_policy = GTK_SCROLL_NATURAL;
    self->vscroll_policy = GTK_SCROLL_NATURAL;
    self->preview_size = FONT_MANAGER_LARGE_PREVIEW_SIZE;
    GtkWidget *widget = GTK_WIDGET(self);
    gtk_widget_set_focusable(widget, TRUE);
    gtk_widget_add_css_class(widget, FONT_MANAGER_STYLE_CLASS_VIEW);
    font_manager_widget_set_expand(widget, TRUE);
    font_manager_widget_set_name(widget, "FontManagerUnicodeCharacterMap");
    g_autoptr(PangoFontDescription) font_desc = pango_font_description_from_string(FONT_MANAGER_DEFAULT_FONT);
    font_manager_unicode_character_map_set_font_desc(self, font_desc);
    g_signal_connect(self, "notify::active-cell", G_CALLBACK(on_selection_changed), self);
    /* Mouse events */
    GtkGesture *click_gesture = gtk_gesture_click_new();
    gtk_gesture_single_set_button(GTK_GESTURE_SINGLE(click_gesture), 0);
    g_signal_connect(click_gesture, "released", G_CALLBACK(on_click), self);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(click_gesture));
    /* Touch events */
    GtkGesture *long_press = gtk_gesture_long_press_new();
    g_signal_connect(long_press, "pressed", G_CALLBACK(on_long_press), widget);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(long_press));
    GtkGesture *pinch_zoom = gtk_gesture_zoom_new();
    g_signal_connect(pinch_zoom, "scale-changed", G_CALLBACK(on_pinch_zoom), widget);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(pinch_zoom));
    /* Drag and drop */
    GtkDragSource *drag_source = gtk_drag_source_new();
    g_signal_connect(drag_source, "prepare", G_CALLBACK(on_prepare_drag), self);
    g_signal_connect(drag_source, "drag-begin", G_CALLBACK(on_drag_begin), self);
    gtk_widget_add_controller(widget, GTK_EVENT_CONTROLLER(drag_source));
    return;
}

/**
 * font_manager_unicode_character_map_get_active_cell:
 * @self: a #FontManagerUnicodeCharacterMap
 *
 * Returns: The currently selected cell
 */
gint
font_manager_unicode_character_map_get_active_cell (FontManagerUnicodeCharacterMap *self)
{
    g_return_val_if_fail(FONT_MANAGER_IS_UNICODE_CHARACTER_MAP(self), 0);
    return self->active_cell;
}

/**
 * font_manager_unicode_character_map_get_font_desc:
 * @self: a #FontManagerUnicodeCharacterMap
 *
 * Returns: (transfer none) (nullable):
 * The #PangoFontDescription used to display the character table.
 * The returned object is owned by the instance and must not be modified or freed.
 */
PangoFontDescription *
font_manager_unicode_character_map_get_font_desc (FontManagerUnicodeCharacterMap *self)
{
      g_return_val_if_fail(FONT_MANAGER_IS_UNICODE_CHARACTER_MAP(self), NULL);
      return self->font_desc;
}

/**
 * font_manager_unicode_character_map_get_preview_size:
 * @self: a #FontManagerUnicodeCharacterMap
 *
 * Returns: The current preview size
 */
double
font_manager_unicode_character_map_get_preview_size (FontManagerUnicodeCharacterMap *self)
{
    g_return_val_if_fail(FONT_MANAGER_IS_UNICODE_CHARACTER_MAP(self), 0.0);
    return self->preview_size;
}

/**
 * font_manager_unicode_character_map_get_index:
 * @self:           a #FontManagerUnicodeCharacterMap
 * @codepoints: (element-type uint) (transfer none): #GList of codepoints to get index of
 *
 * Returns: index of @codepoints
 */
gint
font_manager_unicode_character_map_get_index (FontManagerUnicodeCharacterMap *self,
                                              GSList *codepoints)
{
    return get_index(self, codepoints);
}

/**
 * font_manager_unicode_character_map_get_last_index:
 * @self:           a #FontManagerUnicodeCharacterMap
 *
 * Returns: # of codepoints in character map
 */
gint
font_manager_unicode_character_map_get_last_index (FontManagerUnicodeCharacterMap *self)
{
    return get_last_index(self);
}

/**
 * font_manager_unicode_character_map_get_codepoints:
 * @self:           a #FontManagerUnicodeCharacterMap
 * @index:          #gint
 *
 * Returns: (element-type uint) (transfer full) (nullable): #GList of codepoints for @index
 */
GSList *
font_manager_unicode_character_map_get_codepoints (FontManagerUnicodeCharacterMap *self,
                                                   gint index)
{
    return get_codepoints(self, index);
}

/**
 * font_manager_unicode_character_map_set_active_cell:
 * @self: a #FontManagerUnicodeCharacterMap
 * @cell: cell to select
 *
 * Sets the currently selected cell for @self
 */
void
font_manager_unicode_character_map_set_active_cell (FontManagerUnicodeCharacterMap *self,
                                                    gint cell)
{
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
 * font_manager_unicode_character_map_set_filter:
 * @self: #FontManagerCodepointList
 * @filter: (element-type uint) (transfer full) (nullable): #GList containing codepoints
 *
 * When a filter is set only codepoints which are in the filter and actually present
 * in the selected font will be displayed.
 */
void
font_manager_unicode_character_map_set_filter (FontManagerUnicodeCharacterMap *self, GList *filter)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->filter, g_list_free);
    self->filter = filter;
    self->is_regional_indicator_filter = is_regional_indicator_filter(filter);
    self->last_cell = get_last_index(self);
    gtk_widget_queue_resize(GTK_WIDGET(self));
    gtk_widget_queue_draw(GTK_WIDGET(self));
    font_manager_unicode_character_map_set_active_cell(self, 0);
    return;
}

/**
 * font_manager_unicode_character_map_set_font_desc:
 * @self:                       #FontManagerUnicodeCharacterMap
 * @font_desc: (transfer none): #PangoFontDescription
 *
 * Sets @font_desc as the font to use to display the character table.
 */
void
font_manager_unicode_character_map_set_font_desc (FontManagerUnicodeCharacterMap *self,
                                                  PangoFontDescription *font_desc)
{
    g_return_if_fail(FONT_MANAGER_IS_UNICODE_CHARACTER_MAP(self));
    g_return_if_fail(font_desc != NULL);
    set_font_desc_internal(self, font_desc);
    return;
}

/**
 * font_manager_unicode_character_map_set_preview_size:
 * @self: a #FontManagerUnicodeCharacterMap
 * @size: new preview size
 *
 * Sets the preview size to @size.
 */
void
font_manager_unicode_character_map_set_preview_size (FontManagerUnicodeCharacterMap *self,
                                                     gdouble size)
{
    g_return_if_fail(FONT_MANAGER_IS_UNICODE_CHARACTER_MAP(self));
    self->preview_size = VALID_FONT_SIZE(size);
    set_font_desc_internal(self, self->font_desc);
    g_object_notify(G_OBJECT(self), "preview-size");
    return;
}

/**
 * font_manager_unicode_character_map_new:
 *
 * Returns: (transfer full): A newly created #FontManagerUnicodeCharacterMap.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_unicode_character_map_new (void)
{
    return GTK_WIDGET(g_object_new(FONT_MANAGER_TYPE_UNICODE_CHARACTER_MAP, NULL));
}


