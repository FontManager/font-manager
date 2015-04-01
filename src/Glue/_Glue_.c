/* _Glue_.c
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

#include <unistd.h>
#include <gee.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TYPES_H
#include FT_BDF_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
#include FT_TYPE1_TABLES_H
#include FT_XFREE86_H
#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>

#include <pango/pangofc-font.h>
#include <pango/pangofc-fontmap.h>

#include "Private.h"


#define UTF16BE_2_UTF8(s)                                                                          \
g_convert((const gchar *) s.string, s.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL)         \

static void
g_free0(gpointer p)
{
    g_free(p);
    g_nullify_pointer(&p);
}

static int
get_file_owner (const gchar * filepath)
{
    int owner;
    GFile *fhandle = g_file_new_for_path(filepath);
    GFileInfo * finfo = g_file_query_info(fhandle,
                                        G_FILE_ATTRIBUTE_OWNER_USER,
                                        G_FILE_QUERY_INFO_NONE,
                                        NULL,
                                        NULL);
    if (finfo == NULL) {
        owner = g_access(filepath, W_OK);
    } else {
        owner = g_strcmp0(g_file_info_get_attribute_string(finfo, G_FILE_ATTRIBUTE_OWNER_USER), g_get_user_name());
        g_object_unref(finfo);
    }
    g_object_unref(fhandle);
    return owner;
}

static void
get_font_details_from_pattern (FontConfigFont * font, FcPattern * pattern)
{
    int index;
    int slant;
    int weight;
    int width;
    int spacing;
    FcChar8 * file;
    FcChar8 * family;
    FcChar8 * style;

    g_assert(FcInit());
    g_assert(FcPatternGetString(pattern, FC_FILE, 0, &file) == FcResultMatch);
    font_config_font_set_filepath(font, (const gchar *) file);
    font_config_font_set_owner(font, get_file_owner((const gchar *) file));
    g_assert(FcPatternGetString(pattern, FC_FAMILY, 0, &family) == FcResultMatch);
    font_config_font_set_family(font, (const gchar *) family);
    if (FcPatternGetInteger(pattern, FC_INDEX, 0, &index) != FcResultMatch)
        index = 0;
    font_config_font_set_index(font, index);
    if (FcPatternGetInteger(pattern, FC_SPACING, 0, &spacing) != FcResultMatch)
        spacing = FC_PROPORTIONAL;
    font_config_font_set_spacing(font, spacing);
    if (FcPatternGetInteger(pattern, FC_SLANT, 0, &slant) != FcResultMatch)
        slant = FC_SLANT_ROMAN;
    font_config_font_set_slant(font, slant);
    if (FcPatternGetInteger(pattern, FC_WEIGHT, 0, &weight) != FcResultMatch)
        weight = FC_WEIGHT_MEDIUM;
    font_config_font_set_weight(font, weight);
    if (FcPatternGetInteger(pattern, FC_WIDTH, 0, &width) != FcResultMatch)
        width = FC_WIDTH_NORMAL;
    font_config_font_set_width(font, width);
    if (FcPatternGetString (pattern, FC_STYLE, 0, &style) != FcResultMatch) {
        /* Use the same style Pango would if none is given */
        if (weight <= FC_WEIGHT_MEDIUM) {
            if (slant == FC_SLANT_ROMAN)
                font_config_font_set_style(font, "Regular");
            else
                font_config_font_set_style(font, "Italic");
        } else {
            if (slant == FC_SLANT_ROMAN)
                font_config_font_set_style(font, "Bold");
            else
                font_config_font_set_style(font, "Bold Italic");
        }
    } else {
        font_config_font_set_style(font, (const gchar *) style);
    }

    PangoFontDescription * descr = pango_fc_font_description_from_pattern(pattern, FALSE);
    gchar * desc_string = pango_font_description_to_string(descr);
    font_config_font_set_description(font, desc_string);
    pango_font_description_free(descr);
    g_free0(desc_string);
    return;
}

gboolean
FcCacheUpdate (void) {
    FcConfigDestroy(FcConfigGetCurrent());
    return !FcConfigUptoDate(NULL) && FcInitReinitialize();
}

FontConfigFont *
FcGetFontFromFile (gchar * filepath, int index) {
    g_assert(FcInit());
    int count;
    FontConfigFont * font = font_config_font_new();
    FcBlanks * blanks = FcBlanksCreate();
    FcPattern * pattern = FcFreeTypeQuery((const FcChar8 *) filepath, index, blanks, &count);
    if (!pattern) {
        g_warning("Failed to create FontConfig pattern for file : %s", filepath);
        if (font)
            g_object_unref(font);
        if (blanks)
            FcBlanksDestroy(blanks);
        return NULL;
    } else {
        get_font_details_from_pattern(font, pattern);
    }

    if (blanks)
        FcBlanksDestroy(blanks);
    if (pattern)
        FcPatternDestroy(pattern);

    return font;
}

GeeArrayList *
FcListFonts(gchar * family_name)
{
    int          i;
    FcPattern    * pattern;
    FcFontSet    * fontset;
    FcObjectSet  * objectset = 0;
    GeeArrayList * fontlist = gee_array_list_new(G_TYPE_OBJECT,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL);
    g_assert(FcInit());
    if (family_name)
        pattern = FcPatternBuild (NULL, FC_FAMILY, FcTypeString, family_name, NULL);
    else
        pattern = FcNameParse((FcChar8 *) ":");

    objectset = FcObjectSetBuild (FC_FILE,
                                  FC_INDEX,
                                  FC_FAMILY,
                                  FC_STYLE,
                                  FC_SLANT,
                                  FC_WEIGHT,
                                  FC_WIDTH,
                                  FC_SPACING,
                                  NULL);
    fontset = FcFontList(NULL, pattern, objectset);

    for (i = 0; i < fontset->nfont; i++) {
        FontConfigFont * font = font_config_font_new();
        get_font_details_from_pattern(font, fontset->fonts[i]);
        gee_abstract_collection_add((GeeAbstractCollection *) fontlist, font);
    }

    if (objectset)
        FcObjectSetDestroy(objectset);
    if (pattern)
        FcPatternDestroy(pattern);
    if (fontset)
        FcFontSetDestroy(fontset);

    return fontlist;
}

GeeArrayList *
FcListFamilies(void)
{
    int          i;
    FcPattern    * pattern;
    FcFontSet    * fontset;
    FcObjectSet  * objectset = 0;
    GeeArrayList * famlist = gee_array_list_new(G_TYPE_STRING,
                                                (GBoxedCopyFunc) g_strdup,
                                                (GDestroyNotify) g_free0,
                                                NULL,
                                                NULL,
                                                NULL);
    g_assert(FcInit());
    pattern = FcNameParse((FcChar8 *) ":");
    objectset = FcObjectSetBuild (FC_FAMILY, NULL);
    fontset = FcFontList(NULL, pattern, objectset);

    for (i = 0; i < fontset->nfont; i++) {
        FcChar8 * family;
        if (FcPatternGetString(fontset->fonts[i], FC_FAMILY, 0, &family) == FcResultMatch) {
            if (gee_abstract_collection_contains((GeeAbstractCollection *) famlist, family))
                continue;
            else
                gee_abstract_collection_add((GeeAbstractCollection *) famlist, family);
        }
    }

    if (objectset)
        FcObjectSetDestroy(objectset);
    if (pattern)
        FcPatternDestroy(pattern);
    if (fontset)
        FcFontSetDestroy(fontset);

    return famlist;
}

GeeArrayList *
FcListFiles(void)
{
    int          i;
    FcPattern    * pattern;
    FcFontSet    * fontset;
    FcObjectSet  * objectset = 0;
    GeeArrayList * filelist = gee_array_list_new(G_TYPE_STRING,
                                                (GBoxedCopyFunc) g_strdup,
                                                (GDestroyNotify) g_free0,
                                                NULL,
                                                NULL,
                                                NULL);
    g_assert(FcInit());
    pattern = FcNameParse((FcChar8 *) ":");
    objectset = FcObjectSetBuild (FC_FILE, NULL);
    fontset = FcFontList(NULL, pattern, objectset);

    for (i = 0; i < fontset->nfont; i++) {
        FcChar8 * file;
        if (FcPatternGetString(fontset->fonts[i], FC_FILE, 0, &file) == FcResultMatch)
            gee_abstract_collection_add((GeeAbstractCollection *) filelist, file);
    }

    if (objectset)
        FcObjectSetDestroy(objectset);
    if (pattern)
        FcPatternDestroy(pattern);
    if (fontset)
        FcFontSetDestroy(fontset);

    return filelist;
}

GeeArrayList *
FcListDirs(gboolean recursive)
{
    FcChar8      * directory;
    FcStrList    * fdlist;
    GeeArrayList * dirlist = gee_array_list_new(G_TYPE_STRING,
                                              (GBoxedCopyFunc) g_strdup,
                                              (GDestroyNotify) g_free0,
                                              NULL,
                                              NULL,
                                              NULL);
    g_assert(FcInit());
    if (recursive)
        fdlist = FcConfigGetFontDirs(NULL);
    else
        fdlist = FcConfigGetConfigDirs(NULL);
    while ((directory = FcStrListNext(fdlist)))
        gee_abstract_collection_add((GeeAbstractCollection *) dirlist, directory);
    FcStrListDone(fdlist);
    return dirlist;
}

GeeArrayList *
FcListUserDirs(void)
{
    FcChar8      * directory;
    FcStrList    * fdlist;
    GeeArrayList * dirlist = gee_array_list_new(G_TYPE_STRING,
                                              (GBoxedCopyFunc) g_strdup,
                                              (GDestroyNotify) g_free0,
                                              NULL,
                                              NULL,
                                              NULL);
    g_assert(FcInit());
    fdlist = FcConfigGetConfigDirs(NULL);
    while ((directory = FcStrListNext(fdlist)))
        if (get_file_owner((const gchar *) directory) == 0)
            gee_abstract_collection_add((GeeAbstractCollection *) dirlist, directory);
    FcStrListDone(fdlist);
    return dirlist;
}

gboolean
FcEnableUserConfig(gboolean enable)
{
    g_assert(FcInit());
    gboolean result = FcConfigEnableHome(enable);
    return result;
}

gboolean
FcAddAppFont(const gchar * filepath)
{
    g_assert(FcInit());
    gboolean result = FcConfigAppFontAddFile(NULL, (FcChar8 *) filepath);
    return result;
}

gboolean
FcAddAppFontDir(const gchar * dir)
{
    g_assert(FcInit());
    gboolean result = FcConfigAppFontAddDir(NULL, (FcChar8 *) dir);
    return result;
}

void
FcClearAppFonts(void)
{
    g_assert(FcInit());
    FcConfigAppFontClear(NULL);
    return;
}

gboolean
FcLoadConfig(const gchar * filepath)
{
    g_assert(FcInit());
    gboolean result = FcConfigParseAndLoad(FcConfigGetCurrent(), (FcChar8 *) filepath, FALSE);
    return result;
}


gint
get_license_type(const gchar * license, const gchar * copyright, const gchar * url)
{
    gint i;
    for (i = 0; i < LICENSE_ENTRIES; i++) {
        gint l = 0;
        while (LicenseData[i].keywords[l]) {
            if ((copyright && g_strrstr(copyright, LicenseData[i].keywords[l]))
                || (license && g_strrstr(license, LicenseData[i].keywords[l]))
                || (url && g_strrstr(url, LicenseData[i].keywords[l])))
                return i;
            l++;
        }
    }
    return LICENSE_ENTRIES - 1;
}

gchar *
get_license_name (gint license_type)
{
    return g_strdup(LicenseData[license_type].license);
}

gchar *
get_license_url (gint license_type)
{
    return g_strdup(LicenseData[license_type].license_url);
}

static gboolean
vendor_matches(const gchar vendor[MAX_VENDOR_ID_LENGTH], const gchar * vendor_id)
{
    gboolean    result;
    GString     * a, * b;
    /* vendor is not necessarily NUL-terminated. */
    a = g_string_new_len((const gchar *) vendor, MAX_VENDOR_ID_LENGTH);
    b = g_string_new_len((const gchar *) vendor_id, MAX_VENDOR_ID_LENGTH);
    result = g_string_equal(a, b);
    g_string_free(a, TRUE);
    g_string_free(b, TRUE);
    return result;
}

gchar *
get_vendor_from_notice(const gchar * notice)
{
    gint i;
    if (notice)
        for(i = 0; i < NOTICE_ENTRIES; i++)
            if (g_strrstr(notice, NoticeData[i].vendor_id))
                return g_strdup(NoticeData[i].vendor);
    return NULL;
}

gchar *
get_vendor_from_vendor_id(const gchar vendor[MAX_VENDOR_ID_LENGTH])
{
    gint i;
    if (vendor)
        for(i = 0; i < VENDOR_ENTRIES; i++)
            if (vendor_matches(vendor, VendorData[i].vendor_id))
                return g_strdup(VendorData[i].vendor);
    return NULL;
}

static void
get_ps_info(FontManagerFontInfo * fileinfo, PS_FontInfoRec ps_info, const FT_Face face)
{
    if (!font_manager_font_info_get_version(fileinfo))
        font_manager_font_info_set_version(fileinfo, ps_info.version);
    if (ps_info.notice && g_utf8_validate(ps_info.notice, -1, NULL)) {
        if (!font_manager_font_info_get_copyright(fileinfo))
            font_manager_font_info_set_copyright(fileinfo, ps_info.notice);
        if (!font_manager_font_info_get_vendor(fileinfo)) {
            gchar * _vendor = get_vendor_from_notice(ps_info.notice);
            if (_vendor) {
                font_manager_font_info_set_vendor(fileinfo, _vendor);
                g_free0(_vendor);
            }
        }
    }
}

/* Mostly lifted from fontilus by James Henstridge. Thanks. :-) */
static void
get_sfnt_info(FontManagerFontInfo * fileinfo, const FT_Face face)
{
    gint    index,
            namecount = FT_Get_Sfnt_Name_Count(face);
    gchar * vendor = NULL;

    for (index = 0; index < namecount; index++) {
        FT_SfntName sname;
        if (FT_Get_Sfnt_Name(face, index, &sname) != 0)
            continue;

        /* Only handle the unicode names for US langid */
        if (!(sname.platform_id == TT_PLATFORM_MICROSOFT
            && sname.encoding_id == TT_MS_ID_UNICODE_CS
            && sname.language_id == TT_MS_LANGID_ENGLISH_UNITED_STATES))
            continue;

        gchar * val = UTF16BE_2_UTF8(sname);
        switch (sname.name_id) {
            case TT_NAME_ID_COPYRIGHT:
                font_manager_font_info_set_copyright(fileinfo, val);
                break;
            case TT_NAME_ID_VERSION_STRING:
                font_manager_font_info_set_version(fileinfo, val);
                break;
            case TT_NAME_ID_DESCRIPTION:
                font_manager_font_info_set_description(fileinfo, val);
                break;
            case TT_NAME_ID_LICENSE:
                font_manager_font_info_set_license_data(fileinfo, val);
                break;
            case TT_NAME_ID_LICENSE_URL:
                font_manager_font_info_set_license_url(fileinfo, val);
                break;
            case TT_NAME_ID_TRADEMARK:
                if (!vendor)
                    vendor = UTF16BE_2_UTF8(sname);
                break;
            case TT_NAME_ID_MANUFACTURER:
                if (vendor)
                    g_free0(vendor);
                vendor = UTF16BE_2_UTF8(sname);
                break;
            default:
                break;
        }
        g_free0(val);
    }

    if (vendor) {
        if (!font_manager_font_info_get_vendor(fileinfo)) {
            gchar * _vendor = get_vendor_from_notice(vendor);
            if (_vendor) {
                font_manager_font_info_set_vendor(fileinfo, _vendor);
                g_free0(_vendor);
            }
        }
        g_free0(vendor);
    }
}

long
get_face_count(const char *filepath)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        error;
    FT_Long         num_faces;

    error = FT_Init_FreeType(&library);
    if (error)
        /* Index 0 is always valid */
        return 1;

    error = FT_New_Face(library, filepath, 0, &face);
    if (error) {
        FT_Done_FreeType(library);
        return 1;
    }

    num_faces = face->num_faces;
    FT_Done_Face(face);
    FT_Done_FreeType(library);
    return num_faces;
}

FT_Error
get_file_info(FontManagerFontInfo *fileinfo, const gchar * filepath, gint index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        error;
    PS_FontInfoRec  ps_info;
    BDF_PropertyRec prop;

    gsize   filesize = 0;
    gchar   * font = NULL;

    if (G_UNLIKELY(!g_file_get_contents(filepath, &font, &filesize, NULL))) {
        g_warning("Failed to load file : %s", filepath);
        return FT_Err_Cannot_Open_Resource;
    }

    error = FT_Init_FreeType(&library);
    if (G_UNLIKELY(error))
        return error;

    error = FT_New_Memory_Face(library, (const FT_Byte *) font, (FT_Long) filesize, index, &face);
    if (G_UNLIKELY(error)) {
        g_warning("Failed to create FT_Face for file : %s", filepath);
        return error;
    }

    font_manager_font_info_set_owner(fileinfo, get_file_owner(filepath));
    font_manager_font_info_set_filetype(fileinfo, FT_Get_X11_Font_Format(face));

    gchar * _size = g_format_size(filesize);
    font_manager_font_info_set_filesize(fileinfo, _size);
    g_free0(_size);

    gchar * _md5 = g_compute_checksum_for_data(G_CHECKSUM_MD5, (const guchar *) font, filesize);
    font_manager_font_info_set_checksum(fileinfo, _md5);
    g_free0(_md5);

    font_manager_font_info_set_psname(fileinfo, FT_Get_Postscript_Name(face));

    TT_OS2 * os2 = (TT_OS2 *) FT_Get_Sfnt_Table(face, ft_sfnt_os2);
    if (G_LIKELY(os2 && os2->version >= 0x0001 && os2->version != 0xffff)) {
        gchar * _vendor = get_vendor_from_vendor_id((gchar *) os2->achVendID);
        font_manager_font_info_set_vendor(fileinfo, _vendor);
        g_free0(_vendor);
        gchar * panose = g_strdup_printf("%i:%i:%i:%i:%i:%i:%i:%i:%i:%i", os2->panose[0],
                                          os2->panose[1], os2->panose[2], os2->panose[3],
                                          os2->panose[4], os2->panose[5], os2->panose[6],
                                          os2->panose[7], os2->panose[8], os2->panose[9]);
        font_manager_font_info_set_panose(fileinfo, panose);
        g_free0(panose);
    }

    if (G_LIKELY(FT_IS_SFNT(face)))
        get_sfnt_info(fileinfo, face);
    if (FT_Get_PS_Font_Info(face, &ps_info) == 0)
        get_ps_info(fileinfo, ps_info, face);

    gint lic_type = get_license_type(font_manager_font_info_get_license_data(fileinfo),
                                     font_manager_font_info_get_copyright(fileinfo),
                                     font_manager_font_info_get_license_url(fileinfo));
    gchar * _name = get_license_name(lic_type);
    font_manager_font_info_set_license_type(fileinfo, _name);
    g_free0(_name);

    if (!font_manager_font_info_get_license_url(fileinfo)) {
        gchar * _url = get_license_url(lic_type);
        if (_url)
            font_manager_font_info_set_license_url(fileinfo, _url);
        g_free0(_url);
    }

    if (!font_manager_font_info_get_version(fileinfo)) {
        TT_Header * head = (TT_Header *) FT_Get_Sfnt_Table (face, ft_sfnt_head);
        if (head)
            if (head->Font_Revision) {
                gchar * rev = g_strdup_printf("%f", (float) head->Font_Revision);
                font_manager_font_info_set_version(fileinfo, rev);
                g_free0(rev);
            }
    }

    if (!font_manager_font_info_get_vendor(fileinfo)) {
        int result = FT_Get_BDF_Property(face, "FOUNDRY", &prop);
        if(result == 0 && prop.type == BDF_PROPERTY_TYPE_ATOM)
            font_manager_font_info_set_vendor(fileinfo, prop.u.atom);
        else
            font_manager_font_info_set_vendor(fileinfo, "Unknown Vendor");
    }

    FT_Done_Face(face);
    error = FT_Done_FreeType(library);
    g_free0(font);
    return error;
}

const GValue *
pspec_get_default (GParamSpec * pspec)
{
    GValue * val;
    g_value_unset(val);
    g_value_init(&val, G_PARAM_SPEC_TYPE(pspec));
    g_value_copy(g_param_spec_get_default_value(pspec), val);
    return val;
}
