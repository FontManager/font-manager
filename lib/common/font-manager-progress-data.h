/* font-manager-progress-data.h
 *
 * Copyright (C) 2018 Jerry Casiano
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

#ifndef __FONT_MANAGER_PROGRESS_DATA_H__
#define __FONT_MANAGER_PROGRESS_DATA_H__

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_PROGRESS_DATA (font_manager_progress_data_get_type())
G_DECLARE_FINAL_TYPE(FontManagerProgressData, font_manager_progress_data, FONT_MANAGER, PROGRESS_DATA, GObject)

FontManagerProgressData * font_manager_progress_data_new (const gchar *message, guint processed, guint total);

typedef gboolean (*FontManagerProgressCallback) (FontManagerProgressData *data);

G_END_DECLS

#endif /* __FONT_MANAGER_PROGRESS_DATA_H__ */

