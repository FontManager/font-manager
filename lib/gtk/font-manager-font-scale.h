/* font-manager-font-scale.h
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
#include <glib-object.h>
#include <gtk/gtk.h>

#include "font-manager-gtk-utils.h"

#define FONT_MANAGER_TYPE_FONT_SCALE (font_manager_font_scale_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFontScale, font_manager_font_scale, FONT_MANAGER, FONT_SCALE, GtkWidget)

GtkWidget * font_manager_font_scale_new (void);

GtkAdjustment * font_manager_font_scale_get_adjustment (FontManagerFontScale *self);
gdouble font_manager_font_scale_get_value (FontManagerFontScale *self);
void font_manager_font_scale_set_adjustment (FontManagerFontScale *self, GtkAdjustment *adjustment);
void font_manager_font_scale_set_value (FontManagerFontScale *self, gdouble value);

