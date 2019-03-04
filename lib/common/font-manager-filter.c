/* font-manager-filter.c
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

#include "font-manager-filter.h"

G_DEFINE_INTERFACE(FontManagerFilter, font_manager_filter, G_TYPE_OBJECT)

static void
font_manager_filter_default_init (FontManagerFilterInterface *iface)
{
    g_return_if_fail(iface != NULL);

    g_object_interface_install_property(iface,
                                g_param_spec_string("name", NULL, NULL, NULL,
                                    G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    g_object_interface_install_property(iface,
                                g_param_spec_string("icon", NULL, NULL, NULL,
                                    G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    g_object_interface_install_property(iface,
                                g_param_spec_string("comment", NULL, NULL, NULL,
                                    G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    g_object_interface_install_property(iface,
                                g_param_spec_int("index", NULL, NULL,
                                    G_MININT, G_MAXINT, 0,
                                    G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

    g_object_interface_install_property(iface,
                                g_param_spec_int("size", NULL, NULL,
                                    G_MININT, G_MAXINT, 0,
                                    G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));

    return;
}

void
font_manager_filter_update (FontManagerFilter *self)
{
    g_return_if_fail(FONT_MANAGER_IS_FILTER(self));
    FontManagerFilterInterface *iface = FONT_MANAGER_FILTER_GET_IFACE(self);
    g_return_if_fail(iface->update != NULL);
    iface->update(self);
    return;
}

gboolean
font_manager_filter_visible_func (FontManagerFilter *self,
                                  GtkTreeModel *model,
                                  GtkTreeIter *iter)
{
    g_return_val_if_fail(FONT_MANAGER_IS_FILTER(self), TRUE);
    g_return_val_if_fail(GTK_IS_TREE_MODEL(model), TRUE);
    g_return_val_if_fail(iter != NULL, TRUE);
    FontManagerFilterInterface *iface = FONT_MANAGER_FILTER_GET_IFACE(self);
    g_return_val_if_fail(iface->visible_func != NULL, TRUE);
    return iface->visible_func(self, model, iter);
}

