/* nautilus-font-manager-module.c
 *
 * Copyright (C) 2019 Jerry Casiano
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

#include <nautilus-extension.h>

#include "config.h"
#include "font-manager-menu-provider.h"

void
nautilus_module_initialize (GTypeModule *module)
{
    font_manager_menu_provider_load(module);
    return;
}

void
nautilus_module_shutdown (void)
{
    return;
}

void
nautilus_module_list_types (const GType **types,
                            int      *num_types)
{
    static GType type_list[1];
    type_list[0] = FONT_MANAGER_TYPE_MENU_PROVIDER;
    *types = type_list;
    *num_types = 1;
    return;
}
