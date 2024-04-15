/* font-manager-application-window.h
 *
 * Copyright (C) 2022-2024 Jerry Casiano
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

#include "config.h"

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib/gprintf.h>
#include <gtk/gtk.h>

#define FONT_MANAGER_TYPE_APPLICATION_WINDOW (font_manager_application_window_get_type())
G_DECLARE_DERIVABLE_TYPE(FontManagerApplicationWindow,
                         font_manager_application_window,
                         FONT_MANAGER,
                         APPLICATION_WINDOW,
                         GtkApplicationWindow)


struct _FontManagerApplicationWindowClass
{
    GtkApplicationWindowClass parent_class;
};

GtkWidget * font_manager_application_window_new (void);

void font_manager_application_window_show_about (FontManagerApplicationWindow *self);

void font_manager_application_window_show_help (FontManagerApplicationWindow *self);

void font_manager_application_window_restore_state (FontManagerApplicationWindow *self,
                                                    GSettings                    *settings);

