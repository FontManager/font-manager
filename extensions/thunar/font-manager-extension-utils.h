/* font-manager-extension-utils.h
 *
 * Copyright (C) 2020 Jerry Casiano
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

#ifndef __FONT_MANAGER_EXTENSION_UTILS_H__
#define __FONT_MANAGER_EXTENSION_UTILS_H__

#include <glib.h>
#include <thunarx/thunarx.h>

G_BEGIN_DECLS

gboolean thunarx_file_info_is_font_file (ThunarxFileInfo *fileinfo);
gboolean file_list_contains_font_files (GList *thunarx_file_info_list);

G_END_DECLS

#endif /* __FONT_MANAGER_EXTENSION_UTILS_H__ */
