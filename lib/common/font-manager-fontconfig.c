/* font-manager-fontconfig.c
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

#include <stdio.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>
#include <json-glib/json-glib.h>
#include <pango/pango-font.h>
#include <pango/pangofc-font.h>
#include <pango/pangofc-fontmap.h>

#include "font-manager-fontconfig.h"
#include "font-manager-json.h"
#include "font-manager-utils.h"

#include "unicode-info.h"

static GList * list_charset (const FcCharSet *charset);
static void process_fontset (const FcFontSet *fontset, JsonObject *json_obj);

static const gchar *DEFAULT_VARIANTS[5] = {
    "Regular",
    "Roman",
    "Medium",
    "Normal",
    "Book"
};

/**
 * font_manager_update_font_configuration:
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_update_font_configuration (void) {
    return (FcConfigDestroy(FcConfigGetCurrent()), FcInitReinitialize());
}

/**
 * font_manager_enable_user_font_configuration:
 * @enable: %TRUE to include configuration files stored in users home directory.
 * %FALSE to exclude configuration files stored in users home directory.
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_enable_user_font_configuration (gboolean enable)
{
    return (FcConfigEnableHome(enable), (FcConfigEnableHome(enable) == enable));
}

/**
 * font_manager_add_application_font:
 * @filepath: full path to font file to add to configuration
 *
 * Equivalent to #FcConfigAppFontAddFile
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_add_application_font (const gchar *filepath)
{
    return FcConfigAppFontAddFile(FcConfigGetCurrent(), (FcChar8 *) filepath);
}

/**
 * font_manager_add_application_font_directory:
 * @dir: full path to directory to add to application specific configuration
 *
 * Equivalent to #FcConfigAppFontAddDir
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_add_application_font_directory (const gchar *dir)
{
    return FcConfigAppFontAddDir(FcConfigGetCurrent(), (FcChar8 *) dir);
}

/**
 * font_manager_clear_application_fonts:
 *
 * Equivalent to #FcConfigAppFontClear
 */
void
font_manager_clear_application_fonts (void)
{
    FcConfigAppFontClear(FcConfigGetCurrent());
    return;
}

/**
 * font_manager_load_font_configuration_file:
 * @filepath: full path to a valid fontconfig configuration file
 *
 * Equivalent to #FcConfigParseAndLoad
 *
 * Returns: %TRUE on success
 */
gboolean
font_manager_load_font_configuration_file (const gchar *filepath)
{
    return FcConfigParseAndLoad(FcConfigGetCurrent(), (FcChar8 *) filepath, FALSE);
}

/**
 * font_manager_list_available_font_files:
 *
 * Returns: (element-type utf8) (transfer full) (nullable):
 * a newly created #GSList containing filepaths or %NULL.
 * Free the returned list using #g_slist_free_full(list, g_free)
 */
GList *
font_manager_list_available_font_files (void)
{
    FcPattern *pattern = FcPatternBuild(NULL,NULL);
    FcObjectSet *objectset = FcObjectSetBuild (FC_FILE, NULL);
    FcFontSet *fontset = FcFontList(FcConfigGetCurrent(), pattern, objectset);
    GList *result = NULL;

    for (int i = 0; i < fontset->nfont; i++) {
        FcChar8 *file;
        if (FcPatternGetString(fontset->fonts[i], FC_FILE, 0, &file) == FcResultMatch)
            result = g_list_prepend(result, g_strdup_printf("%s", file));
    }

    FcObjectSetDestroy(objectset);
    FcPatternDestroy(pattern);
    FcFontSetDestroy(fontset);
    result = g_list_sort(result, (GCompareFunc) font_manager_natural_sort);
    return result;
}

/**
 * font_manager_list_font_directories:
 * @recursive: whether to include subfolders in listing
 *
 * Returns: (element-type utf8) (transfer full) (nullable):
 * a newly created #GSList containing filepaths or %NULL
 * Free the returned list using #g_slist_free_full(list, g_free);
 */
GList *
font_manager_list_font_directories (gboolean recursive)
{
    FcChar8 *directory = NULL;
    FcStrList *fdlist = NULL;
    GList *result = NULL;

    fdlist = FcConfigGetFontDirs(FcConfigGetCurrent());

    while ((directory = FcStrListNext(fdlist))) {
        gboolean subdir = FALSE;
        if (!recursive) {
            for (GList *iter = result; iter != NULL; iter = iter->next) {
                if (g_strrstr((const gchar *) directory, iter->data)) {
                    subdir = TRUE;
                    break;
                }
            }
        }
        if (!subdir)
            result = g_list_prepend(result, g_strdup_printf("%s", directory));
    }

    FcStrListDone(fdlist);
    result = g_list_sort(result, (GCompareFunc) font_manager_natural_sort);
    return result;
}

/**
 * font_manager_list_user_font_directories:
 *
 * Only returns directories which are writeable by user
 *
 * Returns: (element-type utf8) (transfer full) (nullable):
 * a newly created #GSList containing filepaths or %NULL
 * Free the returned list using #g_slist_free_full(list, g_free);
 */
GList *
font_manager_list_user_font_directories (gboolean recursive)
{
    FcChar8 *directory = NULL;
    FcStrList *fdlist = NULL;
    GList *result = NULL;

    fdlist = FcConfigGetFontDirs(FcConfigGetCurrent());

    while ((directory = FcStrListNext(fdlist))) {
        if (font_manager_get_file_owner((const gchar *) directory) == 0) {
            gboolean subdir = FALSE;
            if (!recursive) {
                for (GList *iter = result; iter != NULL; iter = iter->next) {
                    if (g_strrstr((const gchar *) directory, iter->data)) {
                        subdir = TRUE;
                        break;
                    }
                }
            }
            if (!subdir)
                result = g_list_prepend(result, g_strdup_printf("%s", directory));
        }
    }

    FcStrListDone(fdlist);
    result = g_list_sort(result, (GCompareFunc) font_manager_natural_sort);
    return result;
}

/**
 * font_manager_list_available_font_families:
 *
 * Returns: (element-type utf8) (transfer full) (nullable):
 * a newly created #GSList containing family names or %NULL
 * Free the returned list using #g_slist_free_full(list, g_free);
 */
GList *
font_manager_list_available_font_families (void)
{
    GList *result = NULL;
    FcPattern *pattern = FcPatternBuild(NULL,NULL);
    FcObjectSet *objectset = FcObjectSetBuild(FC_FAMILY, NULL);
    FcFontSet *fontset = FcFontList(FcConfigGetCurrent(), pattern, objectset);

    for (int i = 0; i < fontset->nfont; i++) {
        FcChar8 *family;
        if (FcPatternGetString(fontset->fonts[i], FC_FAMILY, 0, &family) == FcResultMatch) {
            if (g_list_find_custom(result, (const gchar *) family, (GCompareFunc) g_strcmp0) == NULL)
                result = g_list_prepend(result, g_strdup_printf("%s", family));
        }
    }

    FcObjectSetDestroy(objectset);
    FcPatternDestroy(pattern);
    FcFontSetDestroy(fontset);
    result = g_list_sort(result, (GCompareFunc) font_manager_natural_sort);
    return result;
}

/**
 * font_manager_get_available_fonts:
 * @family_name: (nullable): family name or %NULL
 *
 * If @family_name is not %NULL, only information for fonts belonging to
 * specified family will be returned.
 *
 * Returns: (transfer full): a newly created #JsonObject
 */
JsonObject *
font_manager_get_available_fonts (const gchar *family_name)
{
    FcPattern *pattern = NULL;

    if (family_name)
        pattern = FcPatternBuild (NULL, FC_FAMILY, FcTypeString, family_name, NULL);
    else
        pattern = FcPatternBuild (NULL, NULL);

    FcObjectSet *objectset = FcObjectSetBuild(FC_FILE,
                                              FC_INDEX,
                                              FC_FAMILY,
                                              FC_STYLE,
                                              FC_SLANT,
                                              FC_WEIGHT,
                                              FC_WIDTH,
                                              FC_SPACING,
                                              FC_LANG,
                                              NULL);

    FcFontSet *fontset = FcFontList(FcConfigGetCurrent(), pattern, objectset);
    JsonObject *result = json_object_new();
    process_fontset(fontset, result);
    FcObjectSetDestroy(objectset);
    FcPatternDestroy(pattern);
    FcFontSetDestroy(fontset);
    return result;
}

/**
 * font_manager_get_available_fonts_for_lang:
 * @lang_id: should be of the form Ll-Tt where Ll is a two or three letter
 * language from ISO 639 and Tt is a territory from ISO 3166.
 *
 * Returns: (transfer full): a newly created #JsonObject
 */
JsonObject *
font_manager_get_available_fonts_for_lang (const gchar *lang_id)
{
    FcPattern *pattern = FcPatternCreate();
    FcLangSet *langset = FcLangSetCreate();
    FcChar8 *language = FcLangNormalize((const FcChar8 *) lang_id);

    g_assert(FcLangSetAdd(langset, language));
    g_assert(FcPatternAddLangSet(pattern, FC_LANG, langset));

    FcObjectSet *objectset = FcObjectSetBuild(FC_FILE,
                                              FC_INDEX,
                                              FC_FAMILY,
                                              FC_STYLE,
                                              FC_SLANT,
                                              FC_WEIGHT,
                                              FC_WIDTH,
                                              FC_SPACING,
                                              FC_LANG,
                                              NULL);

    FcFontSet *fontset = FcFontList(FcConfigGetCurrent(), pattern, objectset);
    JsonObject *result = json_object_new();
    process_fontset(fontset, result);
    FcStrFree(language);
    FcLangSetDestroy(langset);
    FcObjectSetDestroy(objectset);
    FcPatternDestroy(pattern);
    FcFontSetDestroy(fontset);
    return result;
}

/**
 * font_manager_get_available_fonts_for_chars:
 * @chars: string of characters to search for
 *
 * Returns: (transfer full): a newly created #JsonObject
 */
JsonObject *
font_manager_get_available_fonts_for_chars (const gchar *chars)
{
    FcObjectSet  *objectset = FcObjectSetBuild(FC_FILE,
                                               FC_INDEX,
                                               FC_FAMILY,
                                               FC_STYLE,
                                               FC_SLANT,
                                               FC_WEIGHT,
                                               FC_WIDTH,
                                               FC_SPACING,
                                               FC_CHARSET,
                                               NULL);

    gunichar wc;
    const gchar *p = chars;
    glong n_chars = g_utf8_strlen(p, -1);
    JsonObject *result = json_object_new();

    for (int i = 0; i < n_chars; i++) {
        wc = g_utf8_get_char(p);
        FcPattern *pattern = FcPatternCreate();
        FcCharSet *charset = FcCharSetCreate();
        g_assert(FcCharSetAddChar(charset, wc));
        g_assert(FcPatternAddCharSet(pattern, FC_CHARSET, charset));
        FcFontSet *fontset = FcFontList(FcConfigGetCurrent(), pattern, objectset);
        process_fontset(fontset, result);
        FcFontSetDestroy(fontset);
        FcCharSetDestroy(charset);
        FcPatternDestroy(pattern);
        p = g_utf8_next_char(p);
    }

    FcObjectSetDestroy(objectset);
    return result;
}

/**
 * font_manager_get_langs_from_fontconfig_pattern: (skip)
 * @pattern: #FcPattern to examine
 *
 * Supplied FcPattern must contain an FcLangSet.
 *
 * Returns: (element-type utf8) (transfer full) (nullable):
 * a newly created #GSList or %NULL
 * The returned list contains dynamically allocated strings and should be
 * freed using #g_slist_free_full(slist, g_free) when no longer needed.
 */
GList *
font_manager_get_langs_from_fontconfig_pattern (FcPattern *pattern)
{
    GList *result = NULL;
    FcLangSet *lang_set = NULL;

    if (FcPatternGetLangSet(pattern, FC_LANG, 0, &lang_set) == FcResultMatch) {
        FcChar8 *lang = NULL;
        FcStrSet *_lang_set = FcLangSetGetLangs(lang_set);
        FcStrList *langs = FcStrListCreate(_lang_set);
        while ((lang = FcStrListNext(langs)))
            result = g_list_prepend(result, g_strdup((const gchar *) lang));
        FcStrSetDestroy(_lang_set);
        FcStrListDone(langs);
    }

    return g_list_reverse(result);
}

/**
 * font_manager_get_attributes_from_fontconfig_pattern: (skip)
 * @pattern: #FcPattern to examine
 *
 * The supplied FcPattern must supply file and family information,
 * otherwise this function will fail.
 * It is also expected to contain index, style, slant, weight, width, language,
 * character set and spacing information, however default values will be used
 * if those fields are missing. All other fields are ignored.
 *
 * Returns: (transfer full): a newly created #JsonObject
 */
JsonObject *
font_manager_get_attributes_from_fontconfig_pattern (FcPattern *pattern)
{
    int index;
    int slant;
    int weight;
    int width;
    int spacing;
    FcChar8 *file;
    FcChar8 *family;
    FcChar8 *style;

    JsonObject *json_obj = json_object_new();

    /* These should never fail. If they do, we're screwed */
    g_assert(FcPatternGetString(pattern, FC_FILE, 0, &file) == FcResultMatch);
    json_object_set_string_member(json_obj, "filepath", (const gchar *) file);
    g_assert(FcPatternGetString(pattern, FC_FAMILY, 0, &family) == FcResultMatch);
    json_object_set_string_member(json_obj, "family", (const gchar *) family);

    /* If any of these fail, just set a sane default and continue on */
    if (FcPatternGetInteger(pattern, FC_INDEX, 0, &index) != FcResultMatch)
        index = 0;

    if (FcPatternGetInteger(pattern, FC_SPACING, 0, &spacing) != FcResultMatch)
        spacing = FC_PROPORTIONAL;

    if (FcPatternGetInteger(pattern, FC_SLANT, 0, &slant) != FcResultMatch)
        slant = FC_SLANT_ROMAN;

    if (FcPatternGetInteger(pattern, FC_WEIGHT, 0, &weight) != FcResultMatch)
        weight = FC_WEIGHT_MEDIUM;

    if (FcPatternGetInteger(pattern, FC_WIDTH, 0, &width) != FcResultMatch)
        width = FC_WIDTH_NORMAL;

    json_object_set_int_member(json_obj, "findex", index);
    json_object_set_int_member(json_obj, "spacing", spacing);
    json_object_set_int_member(json_obj, "slant", slant);
    json_object_set_int_member(json_obj, "weight", weight);
    json_object_set_int_member(json_obj, "width", width);

    if (FcPatternGetString (pattern, FC_STYLE, 0, &style) == FcResultMatch) {
        json_object_set_string_member(json_obj, "style", (const gchar *) style);
    } else {
        /* Use the same style Pango would if none is given */
        if (weight <= FC_WEIGHT_MEDIUM) {
            if (slant == FC_SLANT_ROMAN)
                json_object_set_string_member(json_obj, "style", "Regular");
            else
                json_object_set_string_member(json_obj, "style", "Italic");
        } else {
            if (slant == FC_SLANT_ROMAN)
                json_object_set_string_member(json_obj, "style", "Bold");
            else
                json_object_set_string_member(json_obj, "style", "Bold Italic");
        }
    }

    PangoFontDescription *descr = pango_fc_font_description_from_pattern(pattern, FALSE);
    gchar *font_desc = pango_font_description_to_string(descr);
    pango_font_description_free(descr);
    json_object_set_string_member(json_obj, "description", font_desc);
    g_free(font_desc);

    return json_obj;
}

/**
 * font_manager_get_attributes_from_filepath:
 * @filepath: full path to font file to query
 * @index: index of face within file to select
 *
 * If an error is encontered, the returned object will have a member named err
 * set to %TRUE and a member named err_msg containing a description of the error.
 *
 * Returns: (transfer full): a newly created #JsonObject
 */
JsonObject *
font_manager_get_attributes_from_filepath (const gchar *filepath, int index)
{
    int count;
    FcBlanks *blanks = FcBlanksCreate();
    FcPattern *pattern = FcFreeTypeQuery((const FcChar8 *) filepath, index, blanks, &count);

    JsonObject *json_obj = NULL;

    if (pattern) {
        json_obj = font_manager_get_attributes_from_fontconfig_pattern(pattern);
    } else {
        json_obj = json_object_new();
        font_manager_set_json_error(json_obj, 0, "Failed to create FontConfig pattern for file");
        if (blanks)
            FcBlanksDestroy(blanks);
        return json_obj;
    }

    FcBlanksDestroy(blanks);
    FcPatternDestroy(pattern);
    return json_obj;
}

/**
 * font_manager_get_charset_from_fontconfig_pattern: (skip)
 * @pattern: #FcPattern to examine
 *
 * Supplied FcPattern must contain an FcCharSet.
 *
 * Returns: (element-type gunichar) (transfer container) (nullable):
 * a newly created #GSList of codepoints or %NULL.
 * The returned list should be freed using #g_slist_free when no longer needed.
 */
GList *
font_manager_get_charset_from_fontconfig_pattern (FcPattern *pattern)
{
    GList *result = NULL;
    FcCharSet *charset = NULL;
    if (FcPatternGetCharSet(pattern, FC_CHARSET, 0, &charset) == FcResultMatch)
        result = list_charset(charset);
    return result;
}

/**
 * font_manager_get_charset_from_font_object:
 * @font_object: #JsonObject
 *
 * Returns: (element-type gunichar) (transfer container) (nullable):
 * a newly created #GSList of codepoints or %NULL.
 * The returned list should be freed using #g_slist_free when no longer needed.
 */
GList *
font_manager_get_charset_from_font_object (JsonObject *font_object)
{
    int index = json_object_get_int_member(font_object, "findex");
    const gchar *filepath = json_object_get_string_member(font_object, "filepath");
    FcPattern *pattern = FcPatternBuild(NULL,
                                         FC_FILE, FcTypeString, filepath,
                                         FC_INDEX, FcTypeInteger, index,
                                         NULL);
    FcObjectSet *objectset = FcObjectSetBuild(FC_CHARSET, NULL);
    FcFontSet *fontset = FcFontList(FcConfigGetCurrent(), pattern, objectset);
    GList *result = NULL;
    if (fontset->nfont > 0)
        result = font_manager_get_charset_from_fontconfig_pattern(fontset->fonts[0]);
    FcObjectSetDestroy(objectset);
    FcPatternDestroy(pattern);
    FcFontSetDestroy(fontset);
    return result ? result : font_manager_get_charset_from_filepath(filepath, index);
}

/**
 * font_manager_get_charset_from_filepath:
 * @filepath: full path to font file to query
 * @index: index of face within file to select
 *
 * Returns: (element-type gunichar) (transfer container) (nullable):
 * a newly created #GSList of codepoints or %NULL.
 * The returned list should be freed using #g_slist_free when no longer needed.
 */
GList *
font_manager_get_charset_from_filepath (const gchar *filepath, int index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error         error;

    gsize           filesize = 0;
    gchar           *font = NULL;

    GList *result = NULL;

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
    FcCharSet *charset = FcFreeTypeCharSet(face, blanks);
    result = list_charset(charset);
    if (!result && ((int) FcCharSetCount(charset) > 0))
        g_warning(G_STRLOC " : Failed to create FcCharSet for %s", filepath);
    g_free(font);
    FT_Done_Face(face);
    FT_Done_FreeType(library);
    FcBlanksDestroy(blanks);
    FcCharSetDestroy(charset);
    return result;
}

/**
 * font_manager_sort_json_font_listing:
 * @json_obj: #JsonObject returned from #font_manager_get_available_fonts*
 *
 * Returns : (transfer full) : #JsonArray
 */
JsonArray *
font_manager_sort_json_font_listing (JsonObject *json_obj)
{
    GList *members = json_object_get_members(json_obj);
    members = g_list_sort(members, (GCompareFunc) font_manager_natural_sort);
    JsonArray *result = json_array_sized_new(g_list_length(members));
    gint index = 0;
    GList *iter;
    for (iter = members; iter != NULL; iter = iter->next) {
        JsonObject *family_obj = json_object_get_object_member(json_obj, iter->data);
        GList *variations = json_object_get_values(family_obj);
        gint n_variations = g_list_length(variations);
        JsonArray *_variations = json_array_sized_new(n_variations);
        JsonObject *_family_obj = json_object_new();
        json_object_set_string_member(_family_obj, "family", iter->data);
        json_object_set_int_member(_family_obj, "n_variations", n_variations);
        json_object_set_array_member(_family_obj, "variations", _variations);
        json_object_set_int_member(_family_obj, "_index", index);
        variations = g_list_sort(variations, (GCompareFunc) font_manager_compare_json_font_node);
        gint _index = 0;
        GList *_iter;
        for (_iter = variations; _iter != NULL; _iter = _iter->next) {
            JsonObject *style_obj = json_node_dup_object(_iter->data);
            json_object_set_int_member(style_obj, "_index", _index);
            json_array_add_object_element(_variations, style_obj);
            /* Try to find "default" variation for this family */
            if (!json_object_get_member(_family_obj, "description")) {
                const gchar *style = json_object_get_string_member(style_obj, "style");
                for (guint i = 0; i < G_N_ELEMENTS(DEFAULT_VARIANTS); i++) {
                    if (g_strrstr(style, DEFAULT_VARIANTS[i]) != NULL) {
                        const gchar *font_desc = json_object_get_string_member(style_obj, "description");
                        json_object_set_string_member(_family_obj, "description", font_desc);
                        break;
                    }
                }
            }
            _index++;
        }
        /* No suitable "default" found for this family, set the first result as default */
        if (!json_object_get_member(_family_obj, "description")) {
            JsonObject *_default_ = json_array_get_object_element(_variations, 0);
            const gchar *fallback = json_object_get_string_member(_default_, "description");
            json_object_set_string_member(_family_obj, "description", fallback);
        }
        json_array_add_object_element(result, _family_obj);
        g_list_free(variations);
        index++;
    }
    g_list_free(members);
    return result;
}

/* From pangofc-fontmap.c */
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

static void
process_fontset (const FcFontSet *fontset, JsonObject *json_obj)
{
    for (int i = 0; i < fontset->nfont; i++) {
        JsonObject *font_obj = font_manager_get_attributes_from_fontconfig_pattern(fontset->fonts[i]);
        const gchar *family = json_object_get_string_member(font_obj, "family");
        const gchar *style = json_object_get_string_member(font_obj, "style");
        if (!json_object_get_member(json_obj, family))
            json_object_set_object_member(json_obj, family, json_object_new());
        JsonObject *family_obj = json_object_get_object_member(json_obj, family);
        json_object_set_object_member(family_obj, style, font_obj);
    }
    return;
}
