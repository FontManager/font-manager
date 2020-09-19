/* font-manager-freetype.h
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

#ifndef __FREETYPE_H__
#define __FREETYPE_H__

#include <glib.h>
#include <glib-object.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>
#include <json-glib/json-glib.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TYPES_H
#include FT_BDF_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
#include FT_TYPE1_TABLES_H
#include FT_XFREE86_H

#include "font-manager-license.h"
#include "font-manager-utils.h"
#include "font-manager-vendor.h"

G_BEGIN_DECLS

GQuark font_manager_freetype_error_quark ();
#define FONT_MANAGER_FREETYPE_ERROR font_manager_freetype_error_quark()

/**
 * FontManagerFreetypeError:
 * @FONT_MANAGER_FREETYPE_ERROR_FAILED:     Call to Freetype library failed
 */
typedef enum
{
    FONT_MANAGER_FREETYPE_ERROR_FAILED
}
FontManagerFreetypeError;

/**
 * FontManagerfsType:
 * @FONT_MANAGER_FSTYPE_INSTALLABLE:
 * Installable embedding
 * @FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE:
 * Use prohibited without permission
 * @FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT:
 * Temporary read only access allowed.
 * @FONT_MANAGER_FSTYPE_EDITABLE:
 * Temporary read/write access allowed
 * @FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET:
 * Same as @PREVIEW_AND_PRINT with an additional restriction on subsetting
 * @FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET:
 * Same as @EDITABLE with an additional restriction on subsetting
 * @FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_BITMAP_ONLY:
 * Same as @PREVIEW_AND_PRINT but only bitmaps can be embeeded
 * @FONT_MANAGER_FSTYPE_EDITABLE_BITMAP_ONLY:
 * Same as @EDITABLE but only bitmaps can be embeeded
 * @FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY:
 * Same as @PREVIEW_AND_PRINT but only bitmaps can be embeeded and no subsetting is allowed
 * @FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET_BITMAP_ONLY:
 * Same as @EDITABLE but only bitmaps can be embeeded and no subsetting is allowed
 */
typedef enum
{
    FONT_MANAGER_FSTYPE_INSTALLABLE = 0,
    FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE = 2,
    FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT = 4,
    FONT_MANAGER_FSTYPE_EDITABLE = 8,
    FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET = 20,
    FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET = 24,
    FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_BITMAP_ONLY = 36,
    FONT_MANAGER_FSTYPE_EDITABLE_BITMAP_ONLY = 40,
    FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY = 52,
    FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET_BITMAP_ONLY = 56
}
FontManagerfsType;

GType font_manager_fsType_get_type (void) G_GNUC_CONST;
#define FONT_MANAGER_TYPE_FSTYPE (font_manager_fsType_get_type ())

const gchar * font_manager_fsType_to_string (FontManagerfsType fstype);

glong font_manager_get_face_count (const gchar * filepath);
JsonObject * font_manager_get_metadata (const gchar * filepath, gint index, GError **error);

gchar * font_manager_get_suggested_filename (JsonObject *metadata);
GFile * font_manager_get_installation_target (GFile *font_file, GFile *target_dir,
                                              gboolean create_directories, GError **error);

G_END_DECLS

#endif /* __FREETYPE_H__ */
