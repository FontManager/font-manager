/* font-manager-license-page.h
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

#pragma once

#include <gtk/gtk.h>
#include <glib/gi18n-lib.h>
#include <pango/pango-attributes.h>

#include "font-manager-fsType.h"
#include "font-manager-gtk-utils.h"
#include "font-manager-place-holder.h"

#define FONT_MANAGER_TYPE_LICENSE_PAGE (font_manager_license_page_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerLicensePage, font_manager_license_page, FONT_MANAGER, LICENSE_PAGE, GtkWidget)

GtkWidget * font_manager_license_page_new (void);

gchar * font_manager_license_page_get_license_data (FontManagerLicensePage *self);
gchar * font_manager_license_page_get_license_url (FontManagerLicensePage *self);
gint font_manager_license_page_get_fsType (FontManagerLicensePage *self);
void font_manager_license_page_set_fsType (FontManagerLicensePage *self, gint fstype);
void font_manager_license_page_set_license_data (FontManagerLicensePage *self, const gchar *license_data);
void font_manager_license_page_set_license_url (FontManagerLicensePage *self, const gchar *url);
