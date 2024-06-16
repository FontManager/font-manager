/* font-manager-progress-data.h
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

#include <stdio.h>
#include <glib.h>
#include <glib-object.h>

#define FONT_MANAGER_TYPE_PROGRESS_DATA (font_manager_progress_data_get_type())
G_DECLARE_FINAL_TYPE(FontManagerProgressData, font_manager_progress_data, FONT_MANAGER, PROGRESS_DATA, GObject)

typedef gboolean (*FontManagerProgressCallback) (FontManagerProgressData *data);

FontManagerProgressData * font_manager_progress_data_new (const gchar *message, guint processed, guint total);
gboolean font_manager_progress_data_print (FontManagerProgressData *self);

