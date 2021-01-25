/* thunar-font-manager-module.c
 *
 * Copyright (C) 2019 - 2021 Jerry Casiano
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

#include <thunarx/thunarx.h>

#include "config.h"
#include "font-manager-menu-provider.h"
#include "font-manager-renamer-provider.h"

static gboolean
have_compatible_thunarx_version ()
{
    return thunarx_check_version(THUNARX_MAJOR_VERSION, THUNARX_MINOR_VERSION, THUNARX_MICRO_VERSION) == NULL;
}

G_MODULE_EXPORT void
thunar_extension_initialize (ThunarxProviderPlugin *plugin)
{
    g_return_if_fail(have_compatible_thunarx_version());
    bindtextdomain(PACKAGE_NAME, NULL);
    bind_textdomain_codeset(PACKAGE_NAME, NULL);
    font_manager_menu_provider_load(plugin);
    font_manager_renamer_provider_load(plugin);
    return;
}

G_MODULE_EXPORT void
thunar_extension_shutdown (void)
{
    return;
}

G_MODULE_EXPORT void
thunar_extension_list_types (const GType **types,
                             int      *num_types)
{
    static GType type_list[2];
    type_list[0] = FONT_MANAGER_TYPE_MENU_PROVIDER;
    type_list[1] = FONT_MANAGER_TYPE_RENAMER_PROVIDER;
    *types = type_list;
    *num_types = 2;
    return;
}
