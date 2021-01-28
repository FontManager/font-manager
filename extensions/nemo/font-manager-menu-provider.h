/* font-manager-menu-provider.h
 *
 * Copyright (C) 2018 - 2021 Jerry Casiano
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


#ifndef __FONT_MANAGER_MENU_PROVIDER_H__
#define __FONT_MANAGER_MENU_PROVIDER_H__

#include <glib.h>
#include <glib-object.h>
#include <glib/gi18n-lib.h>
#include <libnemo-extension/nemo-menu-provider.h>

#include "font-manager-utils.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_MENU_PROVIDER (font_manager_menu_provider_get_type())
G_DECLARE_FINAL_TYPE (FontManagerMenuProvider, font_manager_menu_provider, FONT_MANAGER, MENU_PROVIDER, GObject)

void font_manager_menu_provider_load (GTypeModule *module);

G_END_DECLS

#endif /* __FONT_MANAGER_MENU_PROVIDER_H__ */
