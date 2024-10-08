/* font-manager-orthography.c
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

#include "font-manager-orthographies.h"

/**
 * SECTION: font-manager-orthographies
 * @short_description: Font language support
 * @title: Orthographies
 * @include: font-manager-orthographies.h
 */

#define N_ARABIC G_N_ELEMENTS(ArabicOrthographies)
#define N_CHINESE G_N_ELEMENTS(ChineseOrthographies)
#define N_GREEK G_N_ELEMENTS(GreekOrthographies)
#define N_JAPANESE G_N_ELEMENTS(JapaneseOrthographies)
#define N_KOREAN G_N_ELEMENTS(KoreanOrthographies)
#define N_LATIN G_N_ELEMENTS(LatinOrthographies)
#define N_MISC G_N_ELEMENTS(UncategorizedOrthographies)

#define GET_OBJECT(n) json_node_get_object((JsonNode *) n)
#define HAS_COVERAGE(n) JSON_NODE_HOLDS_OBJECT((JsonNode *) n)  && json_object_has_member(GET_OBJECT(n), "coverage")
#define GET_COVERAGE(n) HAS_COVERAGE(n) ? json_object_get_double_member(GET_OBJECT(n), "coverage") : 0.0
#define LEN_CHARSET(n) json_array_get_length(json_object_get_array_member(GET_OBJECT(n), "filter"))

static GList *
_hb_set_to_list (const hb_set_t *charset)
{
    GList *result = NULL;
    hb_codepoint_t codepoint = HB_SET_VALUE_INVALID;
    while (hb_set_next(charset, &codepoint))
        if (font_manager_unicode_unichar_isgraph(codepoint))
            result = g_list_prepend(result, GINT_TO_POINTER(codepoint));
    return g_list_reverse(result);
}

static JsonArray *
_hb_set_to_json_array (const hb_set_t *charset)
{
    JsonArray *result = json_array_new();
    hb_codepoint_t codepoint = HB_SET_VALUE_INVALID;
    while (hb_set_next(charset, &codepoint))
        if (font_manager_unicode_unichar_isgraph(codepoint))
            json_array_add_int_element(result, codepoint);
    return result;
}

static hb_set_t *
get_charset_from_font_object (JsonObject *font)
{
    hb_blob_t *blob = hb_blob_create_from_file(json_object_get_string_member(font, "filepath"));
    hb_face_t *face = hb_face_create(blob, json_object_get_int_member(font, "findex"));
    hb_set_t *charset = hb_set_create();
    hb_face_collect_unicodes(face, charset);
    hb_blob_destroy(blob);
    hb_face_destroy(face);
    return charset;
}

static gint
sort_by_charset_size (gconstpointer a, gconstpointer b)
{
    /* Using variables to avoid unused value warning */
    gint len_a = LEN_CHARSET(a);
    gint len_b = LEN_CHARSET(b);
    return len_a - len_b;
}

static gint
sort_by_coverage (gconstpointer a, gconstpointer b)
{
    gint order = (int) GET_COVERAGE(a) - GET_COVERAGE(b);
    return order != 0 ? order : sort_by_charset_size(a, b);
}

static gchar *
get_sample_from_charlist (GList *charlist)
{
    GString *res = g_string_new(NULL);
    guint length = g_list_length(charlist);
    if (length > 0)
        for (int i = 0; i < 24; i++) {
            int rand = g_random_int_range(0, length);
            gunichar ch = GPOINTER_TO_INT(g_list_nth_data(charlist, rand));
            g_string_append_unichar(res, ch);
        }
    return g_string_free(res, FALSE);
}

static gchar *
get_sample_from_charset (hb_set_t *charset)
{
    GList *charlist = _hb_set_to_list(charset);
    gchar *res = get_sample_from_charlist(charlist);
    g_list_free(charlist);
    return res;
}

static JsonObject *
get_default_orthography (JsonObject *orthography)
{
    GList *orthographies = json_object_get_values(orthography);
    JsonObject *res = NULL;
    if (g_list_length(orthographies) > 0) {
        orthographies = g_list_sort(orthographies, sort_by_coverage);
        JsonNode *node = g_list_nth_data(orthographies, 0);
        if (node && json_node_get_node_type(node) == JSON_NODE_OBJECT)
            res = json_node_get_object(node);
    }
    g_list_free(orthographies);
    return res;
}

static double
get_coverage_from_charset (JsonObject *results,
                           hb_set_t *charset,
                           const FontManagerOrthographyData *data)
{
    int hits = 0, tries = 0;
    JsonArray *filter = NULL;

    /* If it doesn't contain key there's no point in going further */
    if (!hb_set_has(charset, data->key))
        return 0;

    if (results)
        filter = json_array_new();

    for (int i = 0; data->values[i] != FONT_MANAGER_END_OF_DATA; i++) {

        if (data->values[i] == FONT_MANAGER_START_RANGE_PAIR) {

            gunichar start = data->values[++i];
            gunichar end = data->values[++i];

            for (gunichar codepoint = start; codepoint <= end; codepoint++) {
                tries++;
                if (hb_set_has(charset, codepoint))
                    hits++;
                if (results)
                    json_array_add_int_element(filter, (int) codepoint);
            }

        } else {

            tries++;
            if (hb_set_has(charset, data->values[i]))
                hits++;
            if (results)
                json_array_add_int_element(filter, (int) data->values[i]);

        }

    }

    if (results)
        json_object_set_array_member(results, "filter", filter);

    return ((double) 100 * hits/tries );
}

static gboolean
check_orthography (JsonObject *results,
                   hb_set_t *charset,
                   const FontManagerOrthographyData *data)
{
    g_autoptr(JsonObject) res = NULL;
    if (results)
        res = json_object_new();
    double coverage = get_coverage_from_charset(res, charset, data);
    if (coverage == 0)
        return FALSE;
    if (!results)
        return TRUE;
    json_object_set_string_member(res, "name", data->name);
    json_object_set_string_member(res, "native", data->native);
    json_object_set_string_member(res, "sample", data->sample);
    json_object_set_double_member(res, "coverage", coverage);
    json_object_set_object_member(results, data->name, json_object_ref(res));
    return TRUE;
}

static gboolean
charset_contains_sample_string (const hb_set_t *charset, const char *sample)
{
    const char *p = sample;
    while (*p) {
        gunichar codepoint = g_utf8_get_char(p);
        if (!hb_set_has(charset, codepoint))
            return FALSE;
        p = g_utf8_next_char(p);
    }
    return TRUE;
}

static void
check_orthographies (JsonObject *results,
                     hb_set_t *charset,
                     const FontManagerOrthographyData orth[],
                     int len)
{
    for (int i = 0; i < len; i++)
        check_orthography(results, charset, &orth[i]);
    return;
}

static gchar *
get_default_sample_string_for_orthography (JsonObject *orthography)
{
    if (json_object_get_size(orthography) > 0) {
        JsonObject *def = get_default_orthography(orthography);
        if (def && json_object_get_double_member(def, "coverage") > 90) {
            const gchar *sample = NULL;
            if (json_object_has_member(orthography, "sample"))
                sample = json_object_get_string_member(orthography, "sample");
            if (sample != NULL && g_strcmp0(sample, "") != 0)
                return g_strdup(sample);
        }
    }

    if (json_object_has_member(orthography, "Basic Latin")) {
        JsonObject *latin = json_object_get_object_member(orthography, "Basic Latin");
        if (json_object_get_double_member(latin, "coverage") > 90) {
            PangoLanguage *xx = pango_language_from_string("xx");
            return g_strdup(pango_language_get_sample_string(xx));
        }
    }

    return NULL;
}

static gchar *
get_sample_string (JsonObject *orthography, hb_set_t *charset)
{
    const char *local_sample = pango_language_get_sample_string(NULL);
    if (charset_contains_sample_string(charset, local_sample))
        return NULL;
    gchar *sample = get_default_sample_string_for_orthography(orthography);
    return sample ? sample : get_sample_from_charset(charset);
}

/**
 * font_manager_get_orthography_results:
 * @font: (nullable) (transfer none): #JsonObject
 *
 * The #JsonObject returned will have the following structure:
 *
 *|[
 * {
 *   "Basic Latin": {
 *     "filter": [65, 66, ... 122],
 *     "name": "Basic Latin",
 *     "native": "Basic Latin",
 *     "sample": "AaBbCcGgQqRrSsZz",
 *     "coverage": 100.0
 *   },
 *   ...,
 *   "sample" : null
 * }
 *]|
 *
 * The returned object contains a member for each orthography detected in @font.
 *
 * sample will be set to %NULL if the font supports rendering the sample string returned
 * by #font_manager_get_localized_pangram, otherwise sample will be set to the
 * sample string from the member with the highest coverage, if that should fail then
 * sample will be set to a string randomly generated from the characters available in @font.
 *
 * Returns: (nullable) (transfer full): #JsonObject containing orthography results
 */
JsonObject *
font_manager_get_orthography_results (JsonObject *font)
{
    hb_set_t *charset = NULL;
    JsonObject *results = json_object_new();

    if (font)
        charset = get_charset_from_font_object(font);

    if (charset) {
        if (check_orthography(NULL, charset, LatinOrthographies))
            check_orthographies(results, charset, LatinOrthographies, N_LATIN);

        if (check_orthography(NULL, charset, GreekOrthographies))
            check_orthographies(results, charset, GreekOrthographies, N_GREEK);

        if (check_orthography(NULL, charset, ArabicOrthographies))
            check_orthographies(results, charset, ArabicOrthographies, N_ARABIC);

        check_orthographies(results, charset, ChineseOrthographies, N_CHINESE);
        check_orthographies(results, charset, JapaneseOrthographies, N_JAPANESE);
        check_orthographies(results, charset, KoreanOrthographies, N_KOREAN);
        check_orthographies(results, charset, UncategorizedOrthographies, N_MISC);
    }

    if (charset && !hb_set_is_empty(charset)) {

        if (json_object_get_size(results) == 0) {
            JsonObject *uncategorized = json_object_new();
            JsonArray *char_array = _hb_set_to_json_array(charset);
            json_object_set_string_member(uncategorized, "name", "Uncategorized");
            json_object_set_double_member(uncategorized, "coverage", 100);
            json_object_set_array_member(uncategorized, "filter", char_array);
            json_object_set_object_member(results, "Uncategorized", uncategorized);
        }

        g_autofree gchar *sample = get_sample_string(results, charset);
        json_object_set_string_member(results, "sample", sample);

    } else {

        json_object_set_string_member(results, "sample", NULL);

    }

    if (charset)
        hb_set_destroy(charset);

    return results;
}

/**
 * font_manager_get_sample_string:
 * @font:        #JsonObject
 *
 * Returns: (nullable) (transfer full): A newly allocated string that must be freed with #g_free
 *                                      or %NULL if the systems default language is supported
 */
gchar *
font_manager_get_sample_string (JsonObject *font)
{
    const char *local_sample = pango_language_get_sample_string(NULL);
    hb_set_t *charset = get_charset_from_font_object(font);
    if (charset_contains_sample_string(charset, local_sample)) {
        hb_set_destroy(charset);
        return NULL;
    }
    g_autoptr(JsonObject) orthography = font_manager_get_orthography_results(font);
    gchar *sample = get_default_sample_string_for_orthography(orthography);
    if (!sample)
        sample = get_sample_from_charset(charset);
    hb_set_destroy(charset);
    return sample;
}

