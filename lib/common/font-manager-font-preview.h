/* font-manager-font-preview.h
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

#ifndef __FONT_MANAGER_FONT_PREVIEW_H__
#define __FONT_MANAGER_FONT_PREVIEW_H__

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib-object.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <json-glib/json-glib.h>
#include <pango/pango-font.h>

#include "font-manager-font-scale.h"
#include "font-manager-preview-controls.h"
#include "font-manager-gtk-utils.h"

#define FONT_MANAGER_TYPE_FONT_PREVIEW (font_manager_font_preview_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFontPreview, font_manager_font_preview, FONT_MANAGER, FONT_PREVIEW, GtkBox);


/**
 * FontManagerFontPreviewMode:
 * @FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW:         Interactive preview
 * @FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL:       Waterfall preview
 * @FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM:     Body text preview
 */
typedef enum
{
    FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW,
    FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL,
    FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM
}
FontManagerFontPreviewMode;

GType font_manager_font_preview_mode_get_type (void) G_GNUC_CONST;
#define FONT_MANAGER_TYPE_FONT_PREVIEW_MODE (font_manager_font_preview_mode_get_type())

const gchar * font_manager_font_preview_mode_to_string (FontManagerFontPreviewMode mode);
const gchar * font_manager_font_preview_mode_to_translatable_string (FontManagerFontPreviewMode mode);

GtkWidget * font_manager_font_preview_new (void);

void font_manager_font_preview_set_preview_mode (FontManagerFontPreview *self, FontManagerFontPreviewMode mode);
void font_manager_font_preview_set_preview_size (FontManagerFontPreview *self, gdouble size_points);
void font_manager_font_preview_set_font_description (FontManagerFontPreview *self, const gchar *font);
void font_manager_font_preview_set_preview_text (FontManagerFontPreview *self, const gchar *preview_text);
void font_manager_font_preview_set_justification (FontManagerFontPreview *self, GtkJustification justification);
void font_manager_font_preview_set_sample_strings (FontManagerFontPreview *self, GHashTable *samples);
gdouble font_manager_font_preview_get_preview_size (FontManagerFontPreview *self);
gchar * font_manager_font_preview_get_font_description (FontManagerFontPreview *self);
gchar * font_manager_font_preview_get_preview_text (FontManagerFontPreview *self);
GtkJustification font_manager_font_preview_get_justification (FontManagerFontPreview *self);
FontManagerFontPreviewMode font_manager_font_preview_get_preview_mode (FontManagerFontPreview *self);

#endif /* __FONT_MANAGER_FONT_PREVIEW_H__ */
