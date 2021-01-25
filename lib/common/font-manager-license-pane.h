/* font-manager-license-pane.h
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

#ifndef __FONT_MANAGER_FONT_LICENSE_H__
#define __FONT_MANAGER_FONT_LICENSE_H__

#include <gtk/gtk.h>
#include <pango/pango-attributes.h>

#include "font-manager-freetype.h"
#include "font-manager-gtk-utils.h"
#include "font-manager-place-holder.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_LICENSE_PANE (font_manager_license_pane_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerLicensePane, font_manager_license_pane, FONT_MANAGER, LICENSE_PANE, GtkEventBox)

GtkWidget * font_manager_license_pane_new (void);

gchar * font_manager_license_pane_get_license_data (FontManagerLicensePane *self);
gchar * font_manager_license_pane_get_license_url (FontManagerLicensePane *self);
gint font_manager_license_pane_get_fsType (FontManagerLicensePane *self);
void font_manager_license_pane_set_fsType (FontManagerLicensePane *self, gint fstype);
void font_manager_license_pane_set_license_data (FontManagerLicensePane *self, const gchar *license_data);
void font_manager_license_pane_set_license_url (FontManagerLicensePane *self, const gchar *url);

G_END_DECLS

#endif /* __FONT_MANAGER_FONT_LICENSE_H__ */

