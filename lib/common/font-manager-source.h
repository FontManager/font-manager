/* font-manager-source.h
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

#ifndef __FONT_MANAGER_SOURCE_H__
#define __FONT_MANAGER_SOURCE_H__

#include <glib.h>
#include <gio/gio.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_SOURCE (font_manager_source_get_type())
G_DECLARE_FINAL_TYPE(FontManagerSource, font_manager_source, FONT_MANAGER, SOURCE, GObject)

FontManagerSource * font_manager_source_new (GFile *file);
void font_manager_source_update (FontManagerSource *self);
gchar * font_manager_source_get_status_message (FontManagerSource *self);

G_END_DECLS

#endif /* __FONT_MANAGER_SOURCE_H__ */
