/* unicode-info.h
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017 - 2021 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
 * Copyright (c) 2016 DaeHyun Sung
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

#ifndef __UNICODE_INFO_H__
#define __UNICODE_INFO_H__

#include <glib.h>

G_BEGIN_DECLS

/**
 * UnicodeStandard:
 * @UNICODE_VERSION_UNASSIGNED:     Not assigned
 * @UNICODE_VERSION_1_1:            Version 1.1
 * @UNICODE_VERSION_2_0:            Version 2.0
 * @UNICODE_VERSION_2_1:            Version 2.1
 * @UNICODE_VERSION_3_0:            Version 3.0
 * @UNICODE_VERSION_3_1:            Version 3.1
 * @UNICODE_VERSION_3_2:            Version 3.2
 * @UNICODE_VERSION_4_0:            Version 4.0
 * @UNICODE_VERSION_4_1:            Version 4.1
 * @UNICODE_VERSION_5_0:            Version 5.0
 * @UNICODE_VERSION_5_1:            Version 5.1
 * @UNICODE_VERSION_5_2:            Version 5.2
 * @UNICODE_VERSION_6_0:            Version 6.0
 * @UNICODE_VERSION_6_1:            Version 6.1
 * @UNICODE_VERSION_6_2:            Version 6.2
 * @UNICODE_VERSION_6_3:            Version 6.3
 * @UNICODE_VERSION_7_0:            Version 7.0
 * @UNICODE_VERSION_8_0:            Version 8.0
 * @UNICODE_VERSION_9_0:            Version 9.0
 * @UNICODE_VERSION_10_0:           Version 10.0
 * @UNICODE_VERSION_11_0:           Version 11.0
 * @UNICODE_VERSION_12_0:           Version 12.0
 * @UNICODE_VERSION_12_1:           Version 12.1
 * @UNICODE_VERSION_13_0:           Version 13.0
 * @UNICODE_VERSION_LATEST:         Version 13.0
 */
typedef enum {
    UNICODE_VERSION_UNASSIGNED,
    UNICODE_VERSION_1_1,
    UNICODE_VERSION_2_0,
    UNICODE_VERSION_2_1,
    UNICODE_VERSION_3_0,
    UNICODE_VERSION_3_1,
    UNICODE_VERSION_3_2,
    UNICODE_VERSION_4_0,
    UNICODE_VERSION_4_1,
    UNICODE_VERSION_5_0,
    UNICODE_VERSION_5_1,
    UNICODE_VERSION_5_2,
    UNICODE_VERSION_6_0,
    UNICODE_VERSION_6_1,
    UNICODE_VERSION_6_2,
    UNICODE_VERSION_6_3,
    UNICODE_VERSION_7_0,
    UNICODE_VERSION_8_0,
    UNICODE_VERSION_9_0,
    UNICODE_VERSION_10_0,
    UNICODE_VERSION_11_0,
    UNICODE_VERSION_12_0,
    UNICODE_VERSION_12_1,
    UNICODE_VERSION_13_0,
    /* private, will move forward with each revision */
    UNICODE_VERSION_LATEST = UNICODE_VERSION_13_0
} UnicodeStandard;

/* return values are read-only */

gint unicode_get_codepoint_data_name_count (void);
gint unicode_get_unihan_count (void);
gint unicode_unichar_to_printable_utf8 (gunichar uc, gchar *outbuf);
gboolean unicode_unichar_validate (gunichar  uc);
gboolean unicode_unichar_isdefined (gunichar  uc);
gboolean unicode_unichar_isgraph (gunichar  uc);
gunichar * unicode_get_nameslist_exes (gunichar  uc);
const gchar * unicode_get_codepoint_name (gunichar uc);
const gchar * unicode_get_codepoint_data_name (gunichar uc);
const gchar * unicode_get_category_name (gunichar uc);
const gchar * unicode_get_unicode_kDefinition (gunichar uc);
const gchar * unicode_get_unicode_kCantonese (gunichar uc);
const gchar * unicode_get_unicode_kMandarin (gunichar uc);
const gchar * unicode_get_unicode_kTang (gunichar uc);
const gchar * unicode_get_unicode_kKorean (gunichar uc);
const gchar * unicode_get_unicode_kJapaneseKun (gunichar uc);
const gchar * unicode_get_unicode_kJapaneseOn (gunichar uc);
const gchar * unicode_get_unicode_kHangul (gunichar uc);
const gchar * unicode_get_unicode_kVietnamese (gunichar uc);
const gchar *  unicode_get_script_for_char (gunichar wc);
const gchar ** unicode_get_nameslist_stars (gunichar  uc);
const gchar ** unicode_get_nameslist_equals (gunichar  uc);
const gchar ** unicode_get_nameslist_pounds (gunichar  uc);
const gchar ** unicode_get_nameslist_colons (gunichar  uc);
const gchar ** unicode_list_scripts (void);
const gchar * unicode_version_to_string (UnicodeStandard version);
UnicodeStandard unicode_get_version (gunichar uc);

G_END_DECLS

#endif  /* #ifndef __UNICODE_INFO_H__ */

