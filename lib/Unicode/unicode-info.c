/* unicode-info.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright © 2017 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
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

#include <gtk/gtk.h>

#include <glib/gi18n-lib.h>

#include "unicode.h"

#include "unicode-names.h"
#include "unicode-blocks.h"
#include "unicode-nameslist.h"
#include "unicode-categories.h"
#include "unicode-versions.h"
#include "unicode-unihan.h"
#include "unicode-scripts.h"


/* constants for hangul (de)composition, see UAX #15 */
#define SBase 0xAC00
#define LCount 19
#define VCount 21
#define TCount 28
#define NCount (VCount * TCount)
#define SCount (LCount * NCount)

static const gchar JAMO_L_TABLE[][4] = {
    "G", "GG", "N", "D", "DD", "R", "M", "B", "BB",
    "S", "SS", "", "J", "JJ", "C", "K", "T", "P", "H"
};

static const gchar JAMO_V_TABLE[][4] = {
    "A", "AE", "YA", "YAE", "EO", "E", "YEO", "YE",
    "O", "WA", "WAE", "OE", "YO", "U", "WEO", "WE",
    "WI", "YU", "EU", "YI", "I"
};

static const gchar JAMO_T_TABLE[][4] = {
    "", "G", "GG", "GS", "N", "NJ", "NH", "D", "L", "LG",
    "LM", "LB", "LS", "LT", "LP", "LH", "M", "B", "BS",
    "S", "SS", "NG", "J", "C", "K", "T", "P", "H"
};

/* Compute hangul syllable name as per UAX #15 */
const gchar *
get_hangul_syllable_name (gunichar ch)
{
    static gchar buf[32];
    gint SIndex = ch - SBase;
    gint LIndex, VIndex, TIndex;

    if (SIndex < 0 || SIndex >= SCount)
        return "";

    LIndex = SIndex / NCount;
    VIndex = (SIndex % NCount) / TCount;
    TIndex = SIndex % TCount;

    g_snprintf(buf, sizeof(buf),
                "HANGUL SYLLABLE %s%s%s",
                JAMO_L_TABLE[LIndex],
                JAMO_V_TABLE[VIndex],
                JAMO_T_TABLE[TIndex]);
    return buf;
}

static const struct
{
    guint32 start;
    guint32 end;
}
CJK_Compat [] =
{
    {0xf900, 0xfaff},
    {0x2f800, 0x2fa1d}
};

static const struct
{
    guint32 start;
    guint32 end;
}
CJK_Unified [] =
{
    {0x3400, 0x4db5},
    {0x4e00, 0x9fea},
    {0x20000, 0x2a6d6},
    {0x2a700, 0x2b734},
    {0x2b740, 0x2b81d},
    {0x2b820, 0x2cea1},
    {0x2ceb0, 0x2ebe0}
};

static gboolean
is_cjk_compat (gunichar ch)
{
    for (guint i = 0; i < G_N_ELEMENTS(CJK_Compat); i++) {
        if (ch >= CJK_Compat[i].start && ch <= CJK_Compat[i].end)
            return TRUE;
        continue;
    }
    return FALSE;
}

static gboolean
is_cjk_unified (gunichar ch)
{
    for (guint i = 0; i < G_N_ELEMENTS(CJK_Unified); i++) {
        if (ch >= CJK_Unified[i].start && ch <= CJK_Unified[i].end)
            return TRUE;
        continue;
    }
    return FALSE;
}


const gchar *
unicode_get_codepoint_data_name (gunichar uc)
{
    /* does a binary search on unicode_names */
    gint min = 0, mid, max = G_N_ELEMENTS(unicode_names) - 1;

    if (uc < unicode_names[0].index || uc > unicode_names[max].index)
        return "";

    while (max >= min) {
        mid = (min + max) / 2;
        if (uc > unicode_names[mid].index)
            min = mid + 1;
        else if (uc < unicode_names[mid].index)
            max = mid - 1;
        else
            return unicode_name_get_name(&unicode_names[mid]);
    }

    return NULL;
}

/**
 * get_unicode_name:
 * @ch: a #gunichar
 *
 * Return value: (transfer none): unicode character name or %NULL
 */
const gchar *
unicode_get_codepoint_name (gunichar ch)
{
    static gchar buf[32];

    //unicode_intl_ensure_initialized ();

    if G_UNLIKELY(is_cjk_unified(ch)) {
        g_snprintf (buf, sizeof(buf), "CJK UNIFIED IDEOGRAPH-%04X", ch);
        return buf;
    } else if G_UNLIKELY(is_cjk_compat(ch)) {
        g_snprintf (buf, sizeof(buf), "CJK COMPATIBILITY IDEOGRAPH-%04X", ch);
        return buf;
    } else if G_UNLIKELY(ch >= 0x17000 && ch <= 0x187ec) {
        g_snprintf (buf, sizeof(buf), "TANGUT IDEOGRAPH-%05X", ch);
        return buf;
    } else if G_UNLIKELY(ch >= 0x18800 && ch <= 0x18af2) {
        g_snprintf (buf, sizeof(buf), "TANGUT COMPONENT-%03u", ch - 0x18800 + 1);
        return buf;
    } else if G_UNLIKELY(ch >= 0xac00 && ch <= 0xd7af) {
        return get_hangul_syllable_name(ch);
    } else if G_UNLIKELY(ch >= 0xD800 && ch <= 0xDB7F)
        return _("<Non Private Use High Surrogate>");
    else if G_UNLIKELY(ch >= 0xDB80 && ch <= 0xDBFF)
        return _("<Private Use High Surrogate>");
    else if G_UNLIKELY(ch >= 0xDC00 && ch <= 0xDFFF)
        return _("<Low Surrogate>");
    else if G_UNLIKELY(ch >= 0xE000 && ch <= 0xF8FF)
        return _("<Private Use>");
    else if G_UNLIKELY(ch >= 0xF0000 && ch <= 0xFFFFD)
        return _("<Plane 15 Private Use>");
    else if G_UNLIKELY(ch >= 0x100000 && ch <= 0x10FFFD)
        return _("<Plane 16 Private Use>");
    else {
        const gchar *x = unicode_get_codepoint_data_name(ch);
        if (x == NULL)
            return _("<not assigned>");
        else
            return x;
    }
}

/**
 * get_unicode_category_name:
 * @ch: a #gunichar
 *
 * Return value: (transfer none): unicode category name or %NULL
 */
const gchar *
unicode_get_category_name (gunichar ch)
{
    //unicode_intl_ensure_initialized ();

    switch (g_unichar_type(ch)) {
        case G_UNICODE_CONTROL:
            return _("Other, Control");
        case G_UNICODE_FORMAT:
            return _("Other, Format");
        case G_UNICODE_UNASSIGNED:
            return _("Other, Not Assigned");
        case G_UNICODE_PRIVATE_USE:
            return _("Other, Private Use");
        case G_UNICODE_SURROGATE:
            return _("Other, Surrogate");
        case G_UNICODE_LOWERCASE_LETTER:
            return _("Letter, Lowercase");
        case G_UNICODE_MODIFIER_LETTER:
            return _("Letter, Modifier");
        case G_UNICODE_OTHER_LETTER:
            return _("Letter, Other");
        case G_UNICODE_TITLECASE_LETTER:
            return _("Letter, Titlecase");
        case G_UNICODE_UPPERCASE_LETTER:
            return _("Letter, Uppercase");
        case G_UNICODE_COMBINING_MARK:
            return _("Mark, Spacing Combining");
        case G_UNICODE_ENCLOSING_MARK:
            return _("Mark, Enclosing");
        case G_UNICODE_NON_SPACING_MARK:
            return _("Mark, Non-Spacing");
        case G_UNICODE_DECIMAL_NUMBER:
            return _("Number, Decimal Digit");
        case G_UNICODE_LETTER_NUMBER:
            return _("Number, Letter");
        case G_UNICODE_OTHER_NUMBER:
            return _("Number, Other");
        case G_UNICODE_CONNECT_PUNCTUATION:
            return _("Punctuation, Connector");
        case G_UNICODE_DASH_PUNCTUATION:
            return _("Punctuation, Dash");
        case G_UNICODE_CLOSE_PUNCTUATION:
            return _("Punctuation, Close");
        case G_UNICODE_FINAL_PUNCTUATION:
            return _("Punctuation, Final Quote");
        case G_UNICODE_INITIAL_PUNCTUATION:
            return _("Punctuation, Initial Quote");
        case G_UNICODE_OTHER_PUNCTUATION:
            return _("Punctuation, Other");
        case G_UNICODE_OPEN_PUNCTUATION:
            return _("Punctuation, Open");
        case G_UNICODE_CURRENCY_SYMBOL:
            return _("Symbol, Currency");
        case G_UNICODE_MODIFIER_SYMBOL:
            return _("Symbol, Modifier");
        case G_UNICODE_MATH_SYMBOL:
            return _("Symbol, Math");
        case G_UNICODE_OTHER_SYMBOL:
            return _("Symbol, Other");
        case G_UNICODE_LINE_SEPARATOR:
            return _("Separator, Line");
        case G_UNICODE_PARAGRAPH_SEPARATOR:
            return _("Separator, Paragraph");
        case G_UNICODE_SPACE_SEPARATOR:
            return _("Separator, Space");
        default:
            return NULL;
    }
}



gint
unicode_get_codepoint_data_name_count (void)
{
    return G_N_ELEMENTS(unicode_names);
}


UnicodeStandard
unicode_get_version (gunichar uc)
{
    /* does a binary search on unicode_versions */
    gint min = 0, mid, max = G_N_ELEMENTS (unicode_versions) - 1;

    if (uc < unicode_versions[0].start || uc > unicode_versions[max].end)
        return UNICODE_VERSION_UNASSIGNED;

    while (max >= min)
    {
        mid = (min + max) / 2;

        if (uc > unicode_versions[mid].end)
            min = mid + 1;
        else if (uc < unicode_versions[mid].start)
            max = mid - 1;
        else if ((uc >= unicode_versions[mid].start) && (uc <= unicode_versions[mid].end))
            return unicode_versions[mid].version;
    }

    return UNICODE_VERSION_UNASSIGNED;
}

const gchar *
unicode_version_to_string (UnicodeStandard version)
{
    g_return_val_if_fail(version >= UNICODE_VERSION_UNASSIGNED, NULL);
    g_return_val_if_fail(version <= UNICODE_VERSION_LATEST, NULL);

    if G_UNLIKELY(version == UNICODE_VERSION_UNASSIGNED)
        return NULL;

    return unicode_version_strings + unicode_version_string_offsets[version - 1];
}

gint
unicode_get_unihan_count (void)
{
    return G_N_ELEMENTS(unihan);
}

/* does a binary search; also caches most recent, since it will often be
 * called in succession on the same character */
static const NamesList *
get_nameslist (gunichar uc)
{
  static gunichar most_recent_searched;
  static const NamesList *most_recent_result;
  gint min = 0;
  gint mid;
  gint max = G_N_ELEMENTS (names_list) - 1;

  if (uc < names_list[0].index || uc > names_list[max].index)
    return NULL;

  if (uc == most_recent_searched)
    return most_recent_result;

  most_recent_searched = uc;

  while (max >= min)
    {
      mid = (min + max) / 2;
      if (uc > names_list[mid].index)
        min = mid + 1;
      else if (uc < names_list[mid].index)
        max = mid - 1;
      else
        {
          most_recent_result = names_list + mid;
          return names_list + mid;
        }
    }

  most_recent_result = NULL;
  return NULL;
}


/* XXX: This can go away? */
G_GNUC_INTERNAL gboolean
_gucharmap_unicode_has_nameslist_entry (gunichar uc)
{
  return get_nameslist (uc) != NULL;
}

/* returns newly allocated array of gunichar terminated with -1 */
gunichar *
unicode_get_nameslist_exes (gunichar uc)
{
  const NamesList *nl;
  gunichar *exes;
  gunichar i, count;

  nl = get_nameslist (uc);

  if (nl == NULL || nl->exes_index == -1)
    return NULL;

  /* count the number of exes */
  for (i = 0;  names_list_exes[nl->exes_index + i].index == uc;  i++);
  count = i;

  exes = g_malloc ((count + 1) * sizeof(gunichar));
  for (i = 0;  i < count;  i++)
    exes[i] = names_list_exes[nl->exes_index + i].value;
  exes[count] = (gunichar)(-1);

  return exes;
}

/**
 * unicode_get_nameslist_equals:
 * @uc: a gunichar
 *
 * Returns: (transfer container): newly allocated null-terminated array of gchar*
 * the items are const, but the array should be freed by the caller
 */
const gchar **
unicode_get_nameslist_equals (gunichar uc)
{
  const NamesList *nl;
  const gchar **equals;
  gunichar i, count;

  nl = get_nameslist (uc);

  if (nl == NULL || nl->equals_index == -1)
    return NULL;

  /* count the number of equals */
  for (i = 0;  names_list_equals[nl->equals_index + i].index == uc;  i++);
  count = i;

  equals = g_malloc ((count + 1) * sizeof(gchar *));
  for (i = 0;  i < count;  i++)
    equals[i] = names_list_equals_strings + names_list_equals[nl->equals_index + i].string_index;
  equals[count] = NULL;

  return equals;
}

/**
 * unicode_get_nameslist_stars:
 * @uc: a #gunichar
 *
 * Returns: (transfer container): newly allocated null-terminated array of gchar*
 * the items are const, but the array should be freed by the caller
 */
const gchar **
unicode_get_nameslist_stars (gunichar uc)
{
  const NamesList *nl;
  const gchar **stars;
  gunichar i, count;

  nl = get_nameslist (uc);

  if (nl == NULL || nl->stars_index == -1)
    return NULL;

  /* count the number of stars */
  for (i = 0;  names_list_stars[nl->stars_index + i].index == uc;  i++);
  count = i;

  stars = g_malloc ((count + 1) * sizeof(gchar *));
  for (i = 0;  i < count;  i++)
    stars[i] = names_list_stars_strings + names_list_stars[nl->stars_index + i].string_index;
  stars[count] = NULL;

  return stars;
}

/**
 * unicode_get_nameslist_pounds:
 * @uc: a #gunichar
 *
 * Returns: (transfer container): newly allocated null-terminated array of gchar*
 * the items are const, but the array should be freed by the caller
 */
const gchar **
unicode_get_nameslist_pounds (gunichar uc)
{
  const NamesList *nl;
  const gchar **pounds;
  gunichar i, count;

  nl = get_nameslist (uc);

  if (nl == NULL || nl->pounds_index == -1)
    return NULL;

  /* count the number of pounds */
  for (i = 0;  names_list_pounds[nl->pounds_index + i].index == uc;  i++);
  count = i;

  pounds = g_malloc ((count + 1) * sizeof(gchar *));
  for (i = 0;  i < count;  i++)
    pounds[i] = names_list_pounds_strings + names_list_pounds[nl->pounds_index + i].string_index;
  pounds[count] = NULL;

  return pounds;
}

/**
 * unicode_get_nameslist_colons:
 * @uc: a #gunichar
 *
 * Returns: (transfer container): newly allocated null-terminated array of gchar*
 * the items are const, but the array should be freed by the caller
 */
const gchar **
unicode_get_nameslist_colons (gunichar uc)
{
  const NamesList *nl;
  const gchar **colons;
  gunichar i, count;

  nl = get_nameslist (uc);

  if (nl == NULL || nl->colons_index == -1)
    return NULL;

  /* count the number of colons */
  for (i = 0;  names_list_colons[nl->colons_index + i].index == uc;  i++);
  count = i;

  colons = g_malloc ((count + 1) * sizeof(gchar *));
  for (i = 0;  i < count;  i++)
    colons[i] = names_list_colons_strings + names_list_colons[nl->colons_index + i].string_index;
  colons[count] = NULL;

  return colons;
}

/* Wrapper, in case we want to support a newer unicode version than glib */
gboolean
unicode_unichar_validate (gunichar ch)
{
  return g_unichar_validate (ch);
}

/**
 * unicode_unichar_to_printable_utf8:
 * @uc: a unicode character
 * @outbuf: output buffer, must have at least 10 bytes of space.
 *          If %NULL, the length will be computed and returned
 *          and nothing will be written to @outbuf.
 *
 * Converts a single character to UTF-8 suitable for rendering. Check the
 * source to see what this means. ;-)
 *
 *
 * Return value: number of bytes written
 **/
gint
unicode_unichar_to_printable_utf8 (gunichar uc, gchar *outbuf)
{
  /* Unicode Standard 3.2, section 2.6, "By convention, diacritical marks
   * used by the Unicode Standard may be exhibited in (apparent) isolation
   * by applying them to U+0020 SPACE or to U+00A0 NO BREAK SPACE." */

  /* 17:10 < owen> noah: I'm *not* claiming that what Pango does currently
   *               is right, but convention isn't a requirement. I think
   *               it's probably better to do the Uniscribe thing and put
   *               the lone combining mark on a dummy character and require
   *               ZWJ
   * 17:11 < noah> owen: do you mean that i should put a ZWJ in there, or
   *               that pango will do that?
   * 17:11 < owen> noah: I mean, you should (assuming some future more
   *               capable version of Pango) put it in there
   */

  if (! unicode_unichar_validate (uc) || (! unicode_unichar_isgraph (uc)
      && g_unichar_type (uc) != G_UNICODE_PRIVATE_USE))
    return 0;
  else if (g_unichar_type (uc) == G_UNICODE_COMBINING_MARK
      || g_unichar_type (uc) == G_UNICODE_ENCLOSING_MARK
      || g_unichar_type (uc) == G_UNICODE_NON_SPACING_MARK)
    {
      gint x;

      outbuf[0] = ' ';
      outbuf[1] = '\xe2'; /* ZERO */
      outbuf[2] = '\x80'; /* WIDTH */
      outbuf[3] = '\x8d'; /* JOINER (0x200D) */

      x = g_unichar_to_utf8 (uc, outbuf + 4);

      return x + 4;
    }
  else
    return g_unichar_to_utf8 (uc, outbuf);
}

/**
 * unicode_unichar_isdefined:
 * @uc: a Unicode character
 *
 * Determines if a given character is assigned in the Unicode
 * standard.
 *
 * Return value: %TRUE if the character has an assigned value
 **/
gboolean
unicode_unichar_isdefined (gunichar uc)
{
    return g_unichar_isdefined(uc);
  //return g_unichar_type (uc) != G_UNICODE_UNASSIGNED;
}

/**
 * unicode_unichar_isgraph:
 * @uc: a Unicode character
 *
 * Determines whether a character is printable and not a space
 * (returns %FALSE for control characters, format characters, and
 * spaces). g_unichar_isprint() is similar, but returns %TRUE for
 * spaces. Given some UTF-8 text, obtain a character value with
 * g_utf8_get_char().
 *
 * Return value: %TRUE if @c is printable unless it's a space
 **/
gboolean
unicode_unichar_isgraph (gunichar uc)
{
  GUnicodeType t = g_unichar_type (uc);

  /* From http://www.unicode.org/versions/Unicode9.0.0/ch09.pdf, p16
   * "Unlike most other format control characters, however, they should be
   *  rendered with a visible glyph, even in circumstances where no suitable
   *  digit or sequence of digits follows them in logical order."
   * There the standard talks about the ar signs spanning numbers, but
   * I think this should apply to all Prepended_Concatenation_Mark format
   * characters.
   * Instead of parsing the corresponding data file, just hardcode the
   * (few!) existing characters here.
   */
  if (t == G_UNICODE_FORMAT)
    return (uc >= 0x0600 && uc <= 0x0605) ||
       uc == 0x06DD ||
           uc == 0x070F ||
           uc == 0x08E2 ||
           uc == 0x110BD;

  return (t != G_UNICODE_CONTROL
          && t != G_UNICODE_UNASSIGNED
          && t != G_UNICODE_PRIVATE_USE
          && t != G_UNICODE_SURROGATE
          && t != G_UNICODE_SPACE_SEPARATOR);
}

/**
 * unicode_list_scripts:
 *
 * Returns an array of untranslated script names.
 *
 * The strings in the array are owned by gucharmap and should not be
 * modified or free; the array itself however is allocated and should
 * be freed with g_free().
 *
 * Returns: (transfer container): a newly allocated %NULL-terminated array of strings
 **/
const gchar **
unicode_list_scripts (void)
{
    guint i;
    const char **scripts;

    scripts = (const char **) g_new(char*, G_N_ELEMENTS(unicode_script_list_offsets) + 1);
    for (i = 0; i < G_N_ELEMENTS(unicode_script_list_offsets); ++i)
        scripts[i] = unicode_script_list_strings + unicode_script_list_offsets[i];
    scripts[i] = NULL;
    return scripts;
}

/**
 * unicode_get_script_for_char:
 * @wc: a character
 *
 * Return value: The English (untranslated) name of the script to which the
 * character belongs. Characters that don't belong to an actual script
 * return %"Common".
 **/
const gchar *
unicode_get_script_for_char (gunichar wc)
{
    gint min = 0;
    gint mid;
    gint max = sizeof(unicode_scripts) / sizeof(UnicodeScript) - 1;

    if (wc > UNICHAR_MAX)
        return NULL;

    while (max >= min) {
        mid = (min + max) / 2;
        if (wc > unicode_scripts[mid].end)
            min = mid + 1;
        else if (wc < unicode_scripts[mid].start)
            max = mid - 1;
        else
            return unicode_script_list_strings + unicode_script_list_offsets[unicode_scripts[mid].script_index];
    }

    /* Unicode assigns "Common" as the script name for any character not
    * specifically listed in Scripts.txt */
    return N_("Common");
}
