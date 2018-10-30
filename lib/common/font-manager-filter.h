/* font-manager-filter.h
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

#ifndef __FONT_MANAGER_FILTER_H__
#define __FONT_MANAGER_FILTER_H__

#include <glib.h>
#include <glib-object.h>

#include <gtk/gtk.h>

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_FILTER (font_manager_filter_get_type ())
G_DECLARE_INTERFACE(FontManagerFilter, font_manager_filter, FONT_MANAGER, FILTER, GObject)

struct _FontManagerFilterInterface
{
    GTypeInterface parent_iface;

    void (* update) (FontManagerFilter *self);
    /* GtkTreeModelFilterVisibleFunc */
    gboolean (* visible_func) (FontManagerFilter *self,
                                GtkTreeModel *model,
                                GtkTreeIter *iter);
};

void font_manager_filter_update (FontManagerFilter *self);

gboolean font_manager_filter_visible_func (FontManagerFilter *self,
                                            GtkTreeModel *model,
                                            GtkTreeIter *iter);

G_END_DECLS

#endif /* __FONT_MANAGER_FILTER_H__ */
