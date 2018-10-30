/* font-manager-orthography.c
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>

#include "font-manager-orthography.h"
#include "unicode-info.h"

#define GET_COVERAGE(o) json_object_get_double_member(json_node_get_object((JsonNode *) o), "coverage")
#define LEN_CHARSET(o) json_array_get_length(json_object_get_array_member(json_node_get_object((JsonNode *) o), "filter"));

static GList *
list_charset (const FcCharSet *charset)
{
    GList *result = NULL;
    FcChar32  ucs4, pos;
    FcChar32  map[FC_CHARSET_MAP_SIZE];

    for (ucs4 = FcCharSetFirstPage (charset, map, &pos);
         ucs4 != FC_CHARSET_DONE;
         ucs4 = FcCharSetNextPage (charset, map, &pos)) {

        for (int i = 0; i < FC_CHARSET_MAP_SIZE; i++) {
            int b = 0;
            FcChar32 bits = map[i];
            FcChar32 base = ucs4 + i * 32;
            while (bits) {
                if (bits & 1) {
                    gunichar ch = (base + b);
                    if (unicode_unichar_isgraph(ch))
                        result = g_list_prepend(result, GINT_TO_POINTER(ch));
                }
                bits >>= 1;
                b++;
            }
        }

    }

    return g_list_reverse(result);
}

static FcCharSet *
get_fccharset_from_filepath (const gchar *filepath, int index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error         error;

    gsize           filesize = 0;
    gchar           *font = NULL;

    FcCharSet *result = NULL;

    if (G_UNLIKELY(!g_file_get_contents(filepath, &font, &filesize, NULL))) {
        return result;
    }

    error = FT_Init_FreeType(&library);
    if (G_UNLIKELY(error)) {
        return result;
    }

    error = FT_New_Memory_Face(library, (const FT_Byte *) font, (FT_Long) filesize, index, &face);
    if (G_UNLIKELY(error)) {
        return result;
    }

    FcBlanks *blanks = FcBlanksCreate();
    result = FcFreeTypeCharSet(face, blanks);
    g_free(font);
    FT_Done_Face(face);
    FT_Done_FreeType(library);
    FcBlanksDestroy(blanks);
    return result;
}

static FcCharSet *
get_fccharset_from_font_object (JsonObject *font)
{
    int result = -1, index = json_object_get_int_member(font, "findex");
    const gchar *filepath = json_object_get_string_member(font, "filepath");
    FcPattern *pattern = FcPatternBuild(NULL,
                                         FC_FILE, FcTypeString, filepath,
                                         FC_INDEX, FcTypeInteger, index,
                                         NULL);
    FcObjectSet *objectset = FcObjectSetBuild(FC_CHARSET, NULL);
    FcFontSet *fontset = FcFontList(NULL, pattern, objectset);
    FcCharSet *charset = NULL;
    if (fontset->nfont > 0)
        result = FcPatternGetCharSet(fontset->fonts[0], FC_CHARSET, 0, &charset);
    FcObjectSetDestroy(objectset);
    FcPatternDestroy(pattern);
    FcFontSetDestroy(fontset);
    return result == FcResultMatch ? charset : get_fccharset_from_filepath(filepath, index);
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
get_sample_from_chars (GList *chars)
{
    GString *res = g_string_new(NULL);
    guint length = g_list_length(chars);
    if (length > 0)
        for (int i = 0; i < 24; i++) {
            int rand = g_random_int_range(0, length);
            g_string_append_unichar(res, (gunichar) GPOINTER_TO_INT(g_list_nth_data(chars, rand)));
        }
    return g_string_free(res, FALSE);
}

static JsonObject *
get_default_orthography (JsonObject *orthography)
{
    GList *orthographies = json_object_get_values(orthography);
    orthographies = g_list_sort(orthographies, sort_by_coverage);
    JsonObject *res = json_node_get_object(g_list_nth_data(orthographies, 0));
    g_list_free(orthographies);
    return res;
}

static double
get_coverage_from_charset (JsonObject *results, FcCharSet *charset, const OrthographyData *data)
{
    int hits = 0, tries = 0;
    JsonArray *filter = NULL;

    /* If it doesn't contain key there's no point in going further */
    if (!FcCharSetHasChar(charset, data->key))
        return 0;

    if (results)
        filter = json_array_new();

    for (int i = 0; data->values[i] != END_OF_DATA; i++) {

        if (data->values[i] == START_RANGE_PAIR) {

            gunichar start = data->values[++i];
            gunichar end = data->values[++i];

            for (gunichar ch = start; ch <= end; ch++) {
                tries++;
                if (FcCharSetHasChar(charset, ch))
                    hits++;
                if (results)
                    json_array_add_int_element(filter, (int) ch);
            }

        } else {

            tries++;
            if (FcCharSetHasChar(charset, data->values[i]))
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
check_orthography (JsonObject *results, FcCharSet *charset, const OrthographyData *data)
{
    JsonObject *res = NULL;
    if (results)
        res = json_object_new();
    double coverage = get_coverage_from_charset(res, charset, data);
    if (coverage == 0) {
        if (res)
            json_object_unref(res);
        return FALSE;
    }
    if (!results)
        return TRUE;
    json_object_set_string_member(res, "name", data->name);
    json_object_set_string_member(res, "native", data->native);
    json_object_set_string_member(res, "sample", data->sample);
    json_object_set_double_member(res, "coverage", coverage);
    json_object_set_object_member(results, data->name, res);
    return TRUE;
}

static void
check_orthographies (JsonObject *results, FcCharSet *charset, const OrthographyData orth[], int len)
{
    for (int i = 0; i < len; i++)
        check_orthography(results, charset, &orth[i]);
    return;
}

/* TODO :
 * Default to Basic Latin throughout the interface.
 * Provide for selection of preferred orthographies
 * Base sample strings on selected orthographies.
 */
/**
 * font_manager_get_sample_string_for_orthography:
 * @orthography: #JsonObject
 * @charset: (nullable) (transfer none) (element-type uint): GList of unichar
 *
 * Returns: (nullable) (transfer full): a sample string for the given orhtography/charset
 *                                      or %NULL if Basic Latin is supported
 */
gchar *
font_manager_get_sample_string_for_orthography (JsonObject *orthography, GList *charset)
{
    double basic_coverage = 0;

    if (json_object_has_member(orthography, "Basic Latin")) {
        JsonObject *latin = json_object_get_object_member(orthography, "Basic Latin");
        basic_coverage = json_object_get_double_member(latin, "coverage");
    }

    if (basic_coverage > 90)
        return NULL;

    if (json_object_get_size(orthography) > 0) {
        JsonObject *def = get_default_orthography(orthography);
        if (json_object_get_double_member(def, "coverage") > 90) {
            const gchar *sample = NULL;
            if (json_object_has_member(orthography, "sample"))
                sample = json_object_get_string_member(orthography, "sample");
            if (sample != NULL && g_strcmp0(sample, "") != 0)
                return g_strdup(sample);
        }
    }
    /* Return some nonsense composed from available characters */
    return get_sample_from_chars(charset);
}

/**
 * font_manager_get_orthography_results:
 * @font: (nullable) (transfer none): #JsonObject
 *
 * Returns: (nullable) (transfer full): #JsonObject containing results
 */
JsonObject *
font_manager_get_orthography_results (JsonObject *font)
{
    FcCharSet *charset = NULL;
    JsonObject *results = json_object_new();

    if (font)
        charset = get_fccharset_from_font_object(font);

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

    if (charset && json_object_get_size(results) == 0 && FcCharSetCount(charset) > 0) {
        JsonObject *uncategorized = json_object_new();
        json_object_set_string_member(uncategorized, "name", "Uncategorized");
        json_object_set_double_member(uncategorized, "coverage", 100);
        JsonArray *filter = json_array_new();
        json_object_set_array_member(uncategorized, "filter", filter);
        GList *_charset = list_charset(charset);
        for (GList *iter = _charset; iter != NULL; iter = iter->next)
            json_array_add_int_element(filter, GPOINTER_TO_INT(iter->data));
        json_object_set_object_member(results, "Uncategorized", uncategorized);
        g_list_free(_charset);
    }

    return results;
}
