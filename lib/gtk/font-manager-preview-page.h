/* font-manager-preview-page.h
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

#pragma once

#include <math.h>
#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib-object.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <json-glib/json-glib.h>
#include <pango/pango.h>

#include "font-manager-font.h"
#include "font-manager-font-scale.h"
#include "font-manager-preview-controls.h"
#include "font-manager-gtk-utils.h"

#define FONT_MANAGER_TYPE_PREVIEW_PAGE (font_manager_preview_page_get_type())
G_DECLARE_FINAL_TYPE(FontManagerPreviewPage, font_manager_preview_page, FONT_MANAGER, PREVIEW_PAGE, GtkBox);

/**
 * FontManagerPreviewPageMode:
 * @FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW:         Interactive preview
 * @FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL:       Waterfall preview
 * @FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM:     Body text preview
 */
typedef enum
{
    FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW,
    FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL,
    FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM
}
FontManagerPreviewPageMode;

GType font_manager_preview_page_mode_get_type (void);
#define FONT_MANAGER_TYPE_PREVIEW_PAGE_MODE (font_manager_preview_page_mode_get_type())

const gchar * font_manager_preview_page_mode_to_string (FontManagerPreviewPageMode mode);
const gchar * font_manager_preview_page_mode_to_translatable_string (FontManagerPreviewPageMode mode);

GtkWidget * font_manager_preview_page_new (void);

GtkWidget * font_manager_preview_page_get_action_widget (FontManagerPreviewPage *self);
FontManagerFont * font_manager_preview_page_get_font (FontManagerPreviewPage *self);
GtkJustification font_manager_preview_page_get_justification (FontManagerPreviewPage *self);
FontManagerPreviewPageMode font_manager_preview_page_get_preview_mode (FontManagerPreviewPage *self);
gdouble font_manager_preview_page_get_preview_size (FontManagerPreviewPage *self);
gchar * font_manager_preview_page_get_preview_text (FontManagerPreviewPage *self);
void font_manager_preview_page_set_font (FontManagerPreviewPage *self, FontManagerFont *font);
void font_manager_preview_page_set_justification (FontManagerPreviewPage *self, GtkJustification justification);
void font_manager_preview_page_set_preview_mode (FontManagerPreviewPage *self, FontManagerPreviewPageMode mode);
void font_manager_preview_page_set_preview_size (FontManagerPreviewPage *self, gdouble size_points);
void font_manager_preview_page_set_preview_text (FontManagerPreviewPage *self, const gchar *preview_text);
void font_manager_preview_page_set_waterfall_size (FontManagerPreviewPage *self, gdouble min_size, gdouble max_size, gdouble ratio);
void font_manager_preview_page_restore_state (FontManagerPreviewPage *self, GSettings *settings);

