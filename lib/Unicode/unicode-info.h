/*
 * Copyright © 2004 Noah Levitt
 * Copyright (c) 2016 DaeHyun Sung
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02110-1301  USA
 */

#ifndef GUCHARMAP_UNICODE_INFO_H
#define GUCHARMAP_UNICODE_INFO_H

#include <glib.h>

G_BEGIN_DECLS

typedef enum {
  GUCHARMAP_UNICODE_VERSION_UNASSIGNED,
  GUCHARMAP_UNICODE_VERSION_1_1,
  GUCHARMAP_UNICODE_VERSION_2_0,
  GUCHARMAP_UNICODE_VERSION_2_1,
  GUCHARMAP_UNICODE_VERSION_3_0,
  GUCHARMAP_UNICODE_VERSION_3_1,
  GUCHARMAP_UNICODE_VERSION_3_2,
  GUCHARMAP_UNICODE_VERSION_4_0,
  GUCHARMAP_UNICODE_VERSION_4_1,
  GUCHARMAP_UNICODE_VERSION_5_0,
  GUCHARMAP_UNICODE_VERSION_5_1,
  GUCHARMAP_UNICODE_VERSION_5_2,
  GUCHARMAP_UNICODE_VERSION_6_0,
  GUCHARMAP_UNICODE_VERSION_6_1,
  GUCHARMAP_UNICODE_VERSION_6_2,
  GUCHARMAP_UNICODE_VERSION_6_3,
  GUCHARMAP_UNICODE_VERSION_7_0,
  GUCHARMAP_UNICODE_VERSION_8_0,
  GUCHARMAP_UNICODE_VERSION_9_0,
  GUCHARMAP_UNICODE_VERSION_10_0,
  GUCHARMAP_UNICODE_VERSION_LATEST = GUCHARMAP_UNICODE_VERSION_10_0 /* private, will move forward with each revision */
} GucharmapUnicodeVersion;

/* return values are read-only */
const gchar *  unicode_get_codepoint_name                (gunichar uc);
const gchar *  unicode_get_codepoint_data_name           (gunichar uc);
gint                    unicode_get_codepoint_data_name_count     (void);
GucharmapUnicodeVersion unicode_get_version             (gunichar uc);
const gchar *  unicode_get_category_name       (gunichar uc);
gint                    unicode_get_unihan_count                (void);
const gchar *  unicode_get_unicode_kDefinition         (gunichar uc);
const gchar *  unicode_get_unicode_kCantonese          (gunichar uc);
const gchar *  unicode_get_unicode_kMandarin           (gunichar uc);
const gchar *  unicode_get_unicode_kTang               (gunichar uc);
const gchar *  unicode_get_unicode_kKorean             (gunichar uc);
const gchar *  unicode_get_unicode_kJapaneseKun        (gunichar uc);
const gchar *  unicode_get_unicode_kJapaneseOn         (gunichar uc);
const gchar *  unicode_get_unicode_kHangul             (gunichar uc);
const gchar *  unicode_get_unicode_kVietnamese         (gunichar uc);

/* nameslist stuff */
const gchar ** unicode_get_nameslist_stars             (gunichar  uc);
const gchar ** unicode_get_nameslist_equals            (gunichar  uc);
gunichar *              unicode_get_nameslist_exes              (gunichar  uc);
const gchar ** unicode_get_nameslist_pounds            (gunichar  uc);
const gchar ** unicode_get_nameslist_colons            (gunichar  uc);
gboolean                unicode_unichar_validate                (gunichar  uc);
gint                    unicode_unichar_to_printable_utf8       (gunichar  uc,
                                                                   gchar    *outbuf);
gboolean                unicode_unichar_isdefined               (gunichar  uc);
gboolean                unicode_unichar_isgraph                 (gunichar  uc);

const gchar ** unicode_list_scripts            (void);
const gchar *  unicode_get_script_for_char     (gunichar wc);

const gchar *  unicode_version_to_string       (GucharmapUnicodeVersion version);

/* doesn't really belong here, but no better place was available */
//gunichar     unicode_get_locale_character (void);

G_END_DECLS

#endif  /* #ifndef GUCHARMAP_UNICODE_INFO_H */

