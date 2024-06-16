/* font-manager-properties-page.h
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

#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gi18n-lib.h>
#include <gtk/gtk.h>
#include <pango/pango-layout.h>
#include <json-glib/json-glib.h>

#include "font-manager-gtk-utils.h"

#define FONT_MANAGER_TYPE_PROPERTIES_PAGE (font_manager_font_properties_page_get_type ())

G_DECLARE_FINAL_TYPE(FontManagerPropertiesPage,
                     font_manager_font_properties_page,
                     FONT_MANAGER,
                     PROPERTIES_PAGE,
                     GtkWidget)

GtkWidget * font_manager_font_properties_page_new ();

void font_manager_font_properties_page_update (FontManagerPropertiesPage *self,
                                               JsonObject                *properties);

