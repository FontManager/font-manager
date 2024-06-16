/* font-manager-preview-pane.h
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

#ifndef __FONT_MANAGER_PREVIEW_PANE_H__
#define __FONT_MANAGER_PREVIEW_PANE_H__

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <gtk/gtk.h>
#include <json-glib/json-glib.h>

#include "font-manager-gtk-utils.h"
#include "font-manager-database.h"
#include "font-manager-fontconfig.h"
#include "font-manager-preview-page.h"
#include "font-manager-character-map.h"
#include "font-manager-properties-page.h"
#include "font-manager-license-page.h"

G_BEGIN_DECLS

typedef enum
{
    FONT_MANAGER_PREVIEW_PANE_PAGE_PREVIEW,
    FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP,
    FONT_MANAGER_PREVIEW_PANE_PAGE_PROPERTIES,
    FONT_MANAGER_PREVIEW_PANE_PAGE_LICENSE
}
FontManagerPreviewPanePage;

GType font_manager_preview_pane_page_get_type (void);
#define FONT_MANAGER_TYPE_PREVIEW_PANE_PAGE (font_manager_preview_pane_page_get_type ())

const gchar * font_manager_preview_pane_page_to_string (FontManagerPreviewPanePage page);

#define FONT_MANAGER_TYPE_PREVIEW_PANE (font_manager_preview_pane_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerPreviewPane, font_manager_preview_pane, FONT_MANAGER, PREVIEW_PANE, GtkWidget)

GtkWidget * font_manager_preview_pane_new (void);
gboolean font_manager_preview_pane_show_uri (FontManagerPreviewPane *self, const gchar *uri, int index);
void font_manager_preview_pane_set_font (FontManagerPreviewPane *self, FontManagerFont *font);
void font_manager_preview_pane_set_orthography (FontManagerPreviewPane *self, FontManagerOrthography *orthography);
void font_manager_preview_pane_set_waterfall_size (FontManagerPreviewPane *self, gdouble min_size, gdouble max_size, gdouble ratio);
void font_manager_preview_pane_restore_state (FontManagerPreviewPane *self, GSettings *settings);
void font_manager_preview_pane_set_action_widget (FontManagerPreviewPane *self, GtkWidget *widget, GtkPackType pack_type);

G_END_DECLS

#endif /* __FONT_MANAGER_PREVIEW_PANE_H__ */

