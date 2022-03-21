/* font-manager-fsType.c
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

#include "font-manager-fsType.h"

/**
 * SECTION: font-manager-fsType
 * @short_description: fsType enum
 * @title: Font embedding restrictions
 * @include: font-manager-fsType.h
 *
 * The main purpose of this enumeration is to provide a description of the
 * fsType field of font files in a user friendly manner.
 */

GType
font_manager_fsType_get_type (void)
{
    static gsize g_define_type_id__volatile = 0;

    if (g_once_init_enter (&g_define_type_id__volatile)) {
        static const GEnumValue values[] = {
            { FONT_MANAGER_FSTYPE_INSTALLABLE, "FONT_MANAGER_FSTYPE_INSTALLABLE", "installable" },
            { FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE, "FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE", "restricted_license" },
            { FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT, "FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT", "preview_and_print" },
            { FONT_MANAGER_FSTYPE_EDITABLE, "FONT_MANAGER_FSTYPE_EDITABLE", "editable" },
            { FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET, "FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET", "preview_and_print_no_subset" },
            { FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET, "FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET", "editable_no_subset" },
            { FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_BITMAP_ONLY, "FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_BITMAP_ONLY", "preview_and_print_bitmap_only" },
            { FONT_MANAGER_FSTYPE_EDITABLE_BITMAP_ONLY, "FONT_MANAGER_FSTYPE_EDITABLE_BITMAP_ONLY", "editable_bitmap_only" },
            { FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY, "FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY", "preview_and_print_no_subset_bitmap_only" },
            { FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET_BITMAP_ONLY, "FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET_BITMAP_ONLY", "editable_no_subset_bitmap_only" },
            { 0, NULL, NULL }
        };
        GType g_define_type_id = g_enum_register_static (g_intern_static_string ("FontManagerfsType"), values);
        g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

    return g_define_type_id__volatile;
}

/**
 * font_manager_fsType_to_string: (skip)
 * @fstype: #FontManagerfsType
 *
 * Returns a description of the fsType field suitable for display.
 *
 * The least restrictive bit set is used.
 * Embedding-aware applications may interpret the fsType field differently.
 *
 * Returns: (transfer none) (nullable): @fstype as a string
 */
const gchar *
font_manager_fsType_to_string (gint fstype) {
    switch (fstype) {
        case FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE:
            return _("Restricted License Embedding");
        case FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT:
            return _("Preview & Print Embedding");
        case FONT_MANAGER_FSTYPE_EDITABLE:
            return _("Editable Embedding");
        case FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET:
            return _("Preview & Print Embedding | No Subsetting");
        case FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET:
            return _("Editable Embedding | No Subsetting");
        case FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_BITMAP_ONLY:
            return _("Preview & Print Embedding | Bitmap Embedding Only");
        case FONT_MANAGER_FSTYPE_EDITABLE_BITMAP_ONLY:
            return _("Editable Embedding | Bitmap Embedding Only");
        case FONT_MANAGER_FSTYPE_PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY:
            return _("Preview & Print Embedding | No Subsetting | Bitmap Embedding Only");
        case FONT_MANAGER_FSTYPE_EDITABLE_NO_SUBSET_BITMAP_ONLY:
            return _("Editable Embedding | No Subsetting | Bitmap Embedding Only");
        default:
            return _("Installable Embedding");
    }
}
