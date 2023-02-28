/* font-manager-preference-row.h
 *
 * Copyright (C) 2020-2023 Jerry Casiano
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

#include <gtk/gtk.h>

#include "font-manager-gtk-utils.h"

#define FONT_MANAGER_TYPE_PREFERENCE_ROW (font_manager_preference_row_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerPreferenceRow, font_manager_preference_row,
                     FONT_MANAGER, PREFERENCE_ROW, GtkWidget)

GtkWidget * font_manager_preference_row_new (const gchar *title,
                                             const gchar *subtitle,
                                             const gchar *icon_name,
                                             GtkWidget   *action_widget);

void font_manager_preference_row_set_action_widget (FontManagerPreferenceRow *self,
                                                    GtkWidget                *control);

void font_manager_preference_row_append_child (FontManagerPreferenceRow *parent,
                                               FontManagerPreferenceRow *child);

void font_manager_preference_row_set_reveal_child (FontManagerPreferenceRow *self,
                                                   gboolean                  visible);

GtkWidget * font_manager_preference_row_get_action_widget (FontManagerPreferenceRow *self);
