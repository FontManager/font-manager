/* font-manager-orthography.c
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

#include "font-manager-orthography.h"

/**
 * SECTION: font-manager-orthography
 * @short_description: Font language support
 * @title: Orthography
 * @include: font-manager-orthography.h
 *
 * A #FontManagerOrthography holds information about the extent to which a
 * font supports a particular language.
 *
 * In addition to the english name, it includes the untranslated name of the orthography
 * along with a pangram or sample string for the language, if available.
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
charset_to_list (const FcCharSet *charset)
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

static JsonArray *
charset_to_json_array (const FcCharSet *charset)
{
    JsonArray *result = json_array_new();
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
                        json_array_add_int_element(result, ch);
                }
                bits >>= 1;
                b++;
            }
        }

    }

    return result;
}

static FcCharSet *
get_fccharset_from_filepath (const gchar *filepath, int index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error         error;

    gsize           filesize = 0;
    g_autofree gchar *font = NULL;

    FcCharSet *result = NULL;

    if (G_UNLIKELY(!g_file_get_contents(filepath, &font, &filesize, NULL))) {
        return result;
    }

    error = FT_Init_FreeType(&library);
    if (G_UNLIKELY(error)) {
        return result;
    }

    error = FT_New_Memory_Face(library, (const FT_Byte *) font,
                               (FT_Long) filesize, index, &face);

    if (G_UNLIKELY(error)) {
        return result;
    }

    FcBlanks *blanks = FcBlanksCreate();
    result = FcFreeTypeCharSet(face, blanks);
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
get_sample_from_charlist (GList *charset)
{
    GString *res = g_string_new(NULL);
    guint length = g_list_length(charset);
    if (length > 0)
        for (int i = 0; i < 24; i++) {
            int rand = g_random_int_range(0, length);
            gunichar ch = GPOINTER_TO_INT(g_list_nth_data(charset, rand));
            g_string_append_unichar(res, ch);
        }
    return g_string_free(res, FALSE);
}

static gchar *
get_sample_from_charset (FcCharSet *charset)
{
    GList *charlist = charset_to_list(charset);
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
        res = json_node_get_object(g_list_nth_data(orthographies, 0));
    }
    g_list_free(orthographies);
    return res;
}

static double
get_coverage_from_charset (JsonObject *results,
                           FcCharSet *charset,
                           const FontManagerOrthographyData *data)
{
    int hits = 0, tries = 0;
    JsonArray *filter = NULL;

    /* If it doesn't contain key there's no point in going further */
    if (!FcCharSetHasChar(charset, data->key))
        return 0;

    if (results)
        filter = json_array_new();

    for (int i = 0; data->values[i] != FONT_MANAGER_END_OF_DATA; i++) {

        if (data->values[i] == FONT_MANAGER_START_RANGE_PAIR) {

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
check_orthography (JsonObject *results,
                   FcCharSet *charset,
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
charlist_contains_sample_string (GList *charlist, const char *sample)
{
    const char *p = sample;
    while (*p) {
        gunichar ch = g_utf8_get_char(p);
        if (!g_list_find(charlist, GINT_TO_POINTER(ch)))
            return FALSE;
        p = g_utf8_next_char(p);
    }
    return TRUE;
}

static gboolean
charset_contains_sample_string (const FcCharSet *charset, const char *sample)
{
    const char *p = sample;
    while (*p) {
        gunichar ch = g_utf8_get_char(p);
        if (!FcCharSetHasChar(charset, ch))
            return FALSE;
        p = g_utf8_next_char(p);
    }
    return TRUE;
}

static void
check_orthographies (JsonObject *results,
                     FcCharSet *charset,
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
    if (json_object_has_member(orthography, "Basic Latin")) {
        JsonObject *latin = json_object_get_object_member(orthography, "Basic Latin");
        if (json_object_get_double_member(latin, "coverage") > 90) {
            PangoLanguage *xx = pango_language_from_string("xx");
            return g_strdup(pango_language_get_sample_string(xx));
        }
    }

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

    return NULL;
}

static gchar *
font_manager_get_sample_string (JsonObject *orthography, FcCharSet *charset)
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

    if (charset && FcCharSetCount(charset) > 0) {

        if (json_object_get_size(results) == 0) {
            JsonObject *uncategorized = json_object_new();
            JsonArray *char_array = charset_to_json_array(charset);
            json_object_set_string_member(uncategorized, "name", "Uncategorized");
            json_object_set_double_member(uncategorized, "coverage", 100);
            json_object_set_array_member(uncategorized, "filter", char_array);
            json_object_set_object_member(results, "Uncategorized", uncategorized);
        }

        g_autofree gchar *sample = font_manager_get_sample_string(results, charset);
        json_object_set_string_member(results, "sample", sample);

    } else {

        json_object_set_string_member(results, "sample", NULL);

    }

    return results;
}

/**
 * font_manager_get_sample_string_for_orthography:
 * @orthography: #JsonObject containing orthography results
 * @charset: (nullable) (transfer none) (element-type uint): #GList of unichar or %NULL
 *
 * @orthography should be one of the members of the object returned
 * by #font_manager_get_orthography_results()
 *
 * Returns: (nullable) (transfer full): a sample string for the given orthography/charset
 *                                      or %NULL if the systems default language is supported
 */
gchar *
font_manager_get_sample_string_for_orthography (JsonObject *orthography, GList *charset)
{
    const char *local_sample = pango_language_get_sample_string(NULL);
    if (charlist_contains_sample_string(charset, local_sample))
        return NULL;
    gchar *sample = get_default_sample_string_for_orthography(orthography);
    return sample ? sample : get_sample_from_charlist(charset);
}

#define PROPERTIES OrthographyProperties
#define N_PROPERTIES G_N_ELEMENTS(PROPERTIES)
static GParamSpec *obj_properties[N_PROPERTIES] = {0};

struct _FontManagerOrthography
{
    GObjectClass parent_class;
};

G_DEFINE_TYPE(FontManagerOrthography, font_manager_orthography, FONT_MANAGER_TYPE_JSON_PROXY)

static void
font_manager_orthography_class_init (FontManagerOrthographyClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GObjectClass *parent_class = G_OBJECT_CLASS(font_manager_orthography_parent_class);
    object_class->get_property = parent_class->get_property;
    object_class->set_property = parent_class->set_property;
    font_manager_json_proxy_generate_properties(obj_properties, PROPERTIES, N_PROPERTIES);
    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_orthography_init (G_GNUC_UNUSED FontManagerOrthography *self)
{
    g_return_if_fail(self != NULL);
}

/**
 * font_manager_orthography_get_filter:
 * @self: #FontManagerOrthography
 *
 * Returns: (element-type uint) (transfer container) (nullable): #GList containing codepoints.
 * Free the returned #GList using #g_list_free().
 */
GList *
font_manager_orthography_get_filter (FontManagerOrthography *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    GList *charlist = NULL;
    g_autoptr(JsonObject) source = NULL;
    g_object_get(self, FONT_MANAGER_JSON_PROXY_SOURCE, &source, NULL);
    g_return_val_if_fail(source != NULL, charlist);
    if (json_object_has_member(source, "filter")) {
        JsonArray *arr = json_object_get_array_member(source, "filter");
        guint arr_length = json_array_get_length(arr);
        for (guint index = 0; index < arr_length; index++) {
            gunichar uc = (gunichar) json_array_get_int_element(arr, index);
            charlist = g_list_prepend(charlist, GINT_TO_POINTER(uc));
        }
        charlist = g_list_reverse(charlist);
    }
    return charlist;
}

/**
 * font_manager_orthography_new:
 * @orthography:    #JsonObject containing orthography results
 *
 * @orthography should be one of the members of the object returned
 * by #font_manager_get_orthography_results()
 *
 * Returns: (transfer full): A newly created #FontManagerOrthography.
 * Free the returned object using #g_object_unref().
 */
FontManagerOrthography *
font_manager_orthography_new (JsonObject *orthography)
{
    return g_object_new(FONT_MANAGER_TYPE_ORTHOGRAPHY, FONT_MANAGER_JSON_PROXY_SOURCE, orthography, NULL);
}
