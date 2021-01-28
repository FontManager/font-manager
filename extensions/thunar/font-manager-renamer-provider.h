/* font-manager-renamer-provider.h
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


#ifndef __FONT_MANAGER_RENAMER_PROVIDER_H__
#define __FONT_MANAGER_RENAMER_PROVIDER_H__

#include <glib.h>
#include <glib-object.h>
#include <glib/gi18n-lib.h>
#include <thunarx/thunarx.h>

#include "font-manager-utils.h"
#include "font-manager-extension-utils.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_RENAMER (font_manager_renamer_get_type())
G_DECLARE_FINAL_TYPE (FontManagerRenamer, font_manager_renamer, FONT_MANAGER, RENAMER, ThunarxRenamer)

ThunarxRenamer * font_manager_renamer_new (void);

#define FONT_MANAGER_TYPE_RENAMER_PROVIDER (font_manager_renamer_provider_get_type())
G_DECLARE_FINAL_TYPE (FontManagerRenamerProvider, font_manager_renamer_provider, FONT_MANAGER, RENAMER_PROVIDER, GObject)

void font_manager_renamer_provider_load (ThunarxProviderPlugin *module);

G_END_DECLS

#endif /* __FONT_MANAGER_RENAMER_PROVIDER_H__ */
