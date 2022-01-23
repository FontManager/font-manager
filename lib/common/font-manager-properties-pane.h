/* font-manager-properties-pane.h
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

#ifndef __FONT_MANAGER_PROPERTIES_PANE_H__
#define __FONT_MANAGER_PROPERTIES_PANE_H__

#include <glib/gi18n-lib.h>
#include <gtk/gtk.h>
#include <pango/pango-layout.h>

#include "font-manager-fontconfig.h"
#include "font-manager-font.h"
#include "font-manager-font-info.h"
#include "font-manager-gtk-utils.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_PROPERTIES_PANE (font_manager_properties_pane_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerPropertiesPane, font_manager_properties_pane, FONT_MANAGER, PROPERTIES_PANE, GtkPaned)

GtkWidget * font_manager_properties_pane_new ();
void font_manager_properties_pane_update (FontManagerPropertiesPane *self,
                                          FontManagerFont *font,
                                          FontManagerFontInfo *metadata);

G_END_DECLS

#endif /* __FONT_MANAGER_PROPERTIES_PANE_H__ */
