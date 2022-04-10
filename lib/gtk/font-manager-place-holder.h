/* font-manager-place-holder.h
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

#include <string.h>
#include <gtk/gtk.h>

#include "font-manager-gtk-utils.h"

#define FONT_MANAGER_TYPE_PLACE_HOLDER (font_manager_place_holder_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerPlaceHolder, font_manager_place_holder, FONT_MANAGER, PLACE_HOLDER, GtkWidget)

GtkWidget * font_manager_place_holder_new (const gchar *title,
                                           const gchar *subtitle,
                                           const gchar *message,
                                           const gchar *icon_name);

