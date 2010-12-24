/* fm-fontutils.c
 *
 * Font Manager, a font management application for the GNOME desktop
 *
 * Copyright (C) 2009, 2010 Jerry Casiano
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to:
 *
 *   Free Software Foundation, Inc.
 *   51 Franklin Street, Fifth Floor
 *   Boston, MA 02110-1301, USA
*/

#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>

#include <pango/pangofc-fontmap.h>
#include <fontconfig/fcfreetype.h>
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
#include FT_TYPES_H
#include FT_TYPE1_TABLES_H
#include FT_XFREE86_H

#include "fm-fontutils.h"

static int _vendor_matches(const FT_Char vendor[4], const FT_Char *vendor_id);
static void _get_base_font_info(FontInfo *fontinfo, const FT_Face face, const gchar *filepath, int index);
static void _get_ps_info(FontInfo *fontinfo, PS_FontInfoRec ps_info, FT_Face face);
static void _get_sfnt_info(FontInfo *fontinfo, FT_Face face);
static void _get_foundry_from_notice(const FT_String *notice, FontInfo *fontinfo);
static void _get_foundry_from_vendor_id(const FT_Char vendor[4], FontInfo *fontinfo);

/**
 * FcListFiles:
 *
 * Returns: a pointer to a GSList containing filepaths for installed font files
 *
 * Caller is responsible for freeing the returned list, i.e.
 *
 *      g_slist_foreach(list, (GFunc) g_free, NULL);
 *      g_slist_free(list);
 */
GSList *
FcListFiles()
{
    int         i;
    FcPattern   *pattern;
    FcFontSet   *fontset;
    FcObjectSet *objectset = 0;
    GSList      *filelist = NULL;

    g_assert(FcInit());

    pattern = FcNameParse((FcChar8 *) ":");
    objectset = FcObjectSetBuild (FC_FILE, NULL);
    fontset = FcFontList(0, pattern, objectset);

    for (i = 0; i < fontset->nfont; i++)
    {
        FcChar8         *file;

        FcPatternGetString(fontset->fonts[i], FC_FILE, 0, &file);
        filelist = g_slist_prepend(filelist, g_strdup((const gchar *) file));
    }

    if (objectset)
        FcObjectSetDestroy(objectset);
    if (pattern)
        FcPatternDestroy(pattern);
    if (fontset)
        FcFontSetDestroy(fontset);

    return filelist;
}

/**
 * FcListUserDirs:
 *
 * Returns: a pointer to a GSList containing filepaths for user font directories
 *
 * Caller is responsible for freeing the returned list, i.e.
 *
 *      g_slist_foreach(list, (GFunc) g_free, NULL);
 *      g_slist_free(list);
 */
GSList *
FcListUserDirs()
{
    FcChar8     *directory;
    FcStrList   *fdlist;
    GSList      *dirlist = NULL;

    g_assert(FcInit());

    fdlist = FcConfigGetFontDirs(NULL);
    while ((directory = FcStrListNext(fdlist)))
    {
        if (g_access((const gchar *) directory, W_OK) == 0)
            dirlist = g_slist_prepend(dirlist, directory);
    }

    FcStrListDone(fdlist);

    return dirlist;
}

/**
 * FT_Get_Face_Count:
 *
 * @filepath:   Filepath to a font file.
 *
 * Returns:     The number of faces contained in the font file.
 */
FT_Long
FT_Get_Face_Count(const char *filepath)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        error;
    FT_Long         num_faces;

    error = FT_Init_FreeType(&library);
    if (error)
    {
        /* Index 0 is always valid */
        return 1;
    }

    error = FT_New_Face(library, filepath, 0, &face);
    if (error)
    {
        FT_Done_FreeType(library);
        return 1;
    }

    num_faces = face->num_faces;
    FT_Done_Face(face);
    FT_Done_FreeType(library);

    return num_faces;
}

#define ADD_PROP(prop, val)                                                    \
    {                                                                          \
        if (val)                                                               \
        {                                                                      \
            g_free_and_nullify(prop);                                          \
            prop = g_strdup(val);                                              \
        }                                                                      \
    }                                                                          \

/**
 * FT_Get_Font_Info:
 *
 * @fontinfo:   A FontInfo structure to store information in.
 * @filepath:   The filepath of the font to examine
 * @index:      The face within the file to examine. 0 is always valid.
 *
 * Returns:     FreeType2 error code
 */
FT_Error
FT_Get_Font_Info(FontInfo *fontinfo, const char *filepath, int index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        error;
    TT_OS2          *os2;
    PS_FontInfoRec  ps_info;

    gsize           filesize = 0;
    gchar           *font       = NULL,
                    *checksum   = NULL;

    if (G_UNLIKELY(!g_file_get_contents(filepath, &font, &filesize, NULL)))
    {
        error = FT_Err_Cannot_Open_Resource;
        return error;
    }

    error = FT_Init_FreeType(&library);
    if (G_UNLIKELY(error))
        return error;

    error = FT_New_Memory_Face(library,
                                (const FT_Byte *) font,
                                (FT_Long) filesize, index, &face);
    if (G_UNLIKELY(error))
        return error;

    ADD_PROP(fontinfo->filepath, filepath);

    if (g_access((const gchar *) filepath, W_OK) == 0)
        ADD_PROP(fontinfo->owner, "User");

    if (G_UNLIKELY(index != 0))
    {
        g_free_and_nullify(fontinfo->face);
        fontinfo->face = g_strdup_printf("%i", index);
    }

    g_free_and_nullify(fontinfo->filesize);
    /* fontinfo->filesize = g_strdup_printf("%zu", (size_t) filesize); */
    fontinfo->filesize = g_format_size_for_display(filesize);
    g_free_and_nullify(checksum);
    checksum = g_compute_checksum_for_data(G_CHECKSUM_MD5,
                                            (const guchar *) font, filesize);
    ADD_PROP(fontinfo->checksum, checksum);
    g_free_and_nullify(checksum);

    _get_base_font_info(fontinfo, face, filepath, index);

    if (G_LIKELY(FT_IS_SFNT(face)))
    {
        _get_sfnt_info(fontinfo, face);
    }
    else if (FT_Get_PS_Font_Info(face, &ps_info) == 0)
    {
        _get_ps_info(fontinfo, ps_info, face);
    }

    if (G_LIKELY(FT_Get_X11_Font_Format(face) != NULL))
    {
        ADD_PROP(fontinfo->filetype, FT_Get_X11_Font_Format(face));
    }

    if (G_LIKELY(FT_Get_Postscript_Name(face) != NULL))
    {
        ADD_PROP(fontinfo->psname, FT_Get_Postscript_Name(face));
    }

    os2 = (TT_OS2 *) FT_Get_Sfnt_Table(face, ft_sfnt_os2);
    if (G_LIKELY(os2 && os2->version >= 0x0001 && os2->version != 0xffff))
    {
        _get_foundry_from_vendor_id(os2->achVendID, fontinfo);
        g_free_and_nullify(fontinfo->panose);
        fontinfo->panose = g_strdup_printf("%i:%i:%i:%i:%i:%i:%i:%i:%i:%i",
                                os2->panose[0], os2->panose[1], os2->panose[2],
                                os2->panose[3], os2->panose[4], os2->panose[5],
                                os2->panose[6], os2->panose[7], os2->panose[8],
                                os2->panose[9]);
    }

    FT_Done_Face(face);
    FT_Done_FreeType(library);
    g_free_and_nullify(font);

    return error;
}

static void
_get_base_font_info(FontInfo *fontinfo, const FT_Face face,
                        const gchar *filepath, int index)
{
    int                     i;
    FcBlanks                *blanks;
    FcPattern               *pattern;
    FcFontSet               *fontset;
    FcObjectSet             *os;
    PangoFontDescription    *descr;

    /* Need to add this font to the configuration, it may not be there in the
     * case where this the font is not installed yet or possibly just installed
     */
    FcConfigAppFontAddFile(FcConfigGetCurrent(), filepath);

    blanks = FcBlanksCreate();
    os = FcObjectSetBuild(FC_FAMILY, FC_STYLE, NULL);
    pattern = FcFreeTypeQueryFace(face, (const FcChar8 *) fontinfo->filepath,
                                                                index, blanks);
    fontset = FcFontList (NULL, pattern, os);

    for (i = 0; i < fontset->nfont; i++)
    {
        FcChar8         *family,
                        *style;

        FcPatternGetString(fontset->fonts[i], FC_FAMILY, 0, &family);
        FcPatternGetString(fontset->fonts[i], FC_STYLE, 0, &style);
        ADD_PROP(fontinfo->family, family);
        ADD_PROP(fontinfo->style, style);
    }

    descr = pango_fc_font_description_from_pattern(pattern, FALSE);
    ADD_PROP(fontinfo->pdescr, pango_font_description_to_string(descr));
    ADD_PROP(fontinfo->pfamily, (char *) pango_font_description_get_family(descr));

    switch(pango_font_description_get_style(descr))
    {
        case PANGO_STYLE_NORMAL:
            ADD_PROP(fontinfo->pstyle, "Roman");
            break;
        case PANGO_STYLE_OBLIQUE:
            ADD_PROP(fontinfo->pstyle, "Oblique");
            break;
        case PANGO_STYLE_ITALIC:
            ADD_PROP(fontinfo->pstyle, "Italic");
            break;
        default:
            break;
    }

    switch(pango_font_description_get_variant(descr))
    {
        case PANGO_VARIANT_NORMAL:
            ADD_PROP(fontinfo->pvariant, "Normal");
            break;
        case PANGO_VARIANT_SMALL_CAPS:
            ADD_PROP(fontinfo->pvariant, "Small Caps");
            break;
        default:
            break;
    }

    switch(pango_font_description_get_weight(descr))
    {
        case PANGO_WEIGHT_THIN:
            ADD_PROP(fontinfo->pweight, "Thin");
            break;
        case PANGO_WEIGHT_ULTRALIGHT:
            ADD_PROP(fontinfo->pweight, "Ultra-Light");
            break;
        case PANGO_WEIGHT_LIGHT:
            ADD_PROP(fontinfo->pweight, "Light");
            break;
        case PANGO_WEIGHT_BOOK:
            ADD_PROP(fontinfo->pweight, "Book");
            break;
        case PANGO_WEIGHT_NORMAL:
            ADD_PROP(fontinfo->pweight, "Regular");
            break;
        case PANGO_WEIGHT_MEDIUM:
            ADD_PROP(fontinfo->pweight, "Medium");
            break;
        case PANGO_WEIGHT_SEMIBOLD:
            ADD_PROP(fontinfo->pweight, "Semi-Bold");
            break;
        case PANGO_WEIGHT_BOLD:
            ADD_PROP(fontinfo->pweight, "Bold");
            break;
        case PANGO_WEIGHT_ULTRABOLD:
            ADD_PROP(fontinfo->pweight, "Ultra-Bold");
            break;
        case PANGO_WEIGHT_HEAVY:
            ADD_PROP(fontinfo->pweight, "Heavy");
            break;
        case PANGO_WEIGHT_ULTRAHEAVY:
            ADD_PROP(fontinfo->pweight, "Ultra-Heavy");
            break;
        default:
            break;
    }

    switch(pango_font_description_get_stretch(descr))
    {
        case PANGO_STRETCH_ULTRA_CONDENSED:
            ADD_PROP(fontinfo->pstretch, "Ultra-Condensed");
            break;
        case PANGO_STRETCH_EXTRA_CONDENSED:
            ADD_PROP(fontinfo->pstretch, "Extra-Condensed");
            break;
        case PANGO_STRETCH_CONDENSED:
            ADD_PROP(fontinfo->pstretch, "Condensed");
            break;
        case PANGO_STRETCH_SEMI_CONDENSED:
            ADD_PROP(fontinfo->pstretch, "Semi-Condensed");
            break;
        case PANGO_STRETCH_NORMAL:
            ADD_PROP(fontinfo->pstretch, "Normal");
            break;
        case PANGO_STRETCH_SEMI_EXPANDED:
            ADD_PROP(fontinfo->pstretch, "Semi-Expanded");
            break;
        case PANGO_STRETCH_EXPANDED:
            ADD_PROP(fontinfo->pstretch, "Expanded");
            break;
        case PANGO_STRETCH_EXTRA_EXPANDED:
            ADD_PROP(fontinfo->pstretch, "Extra-Expanded");
            break;
        case PANGO_STRETCH_ULTRA_EXPANDED:
            ADD_PROP(fontinfo->pstretch, "Ultra-Expanded");
            break;
        default:
            break;
    }

    pango_font_description_free(descr);

    if (os)
        FcObjectSetDestroy(os);
    if (blanks)
        FcBlanksDestroy(blanks);
    if (pattern)
        FcPatternDestroy(pattern);
    if (fontset)
        FcFontSetDestroy(fontset);
}

#define ADD_PS_PROP(prop, val)                                                 \
    {                                                                          \
        if (val && g_utf8_validate(val, -1, NULL))                            \
            {                                                                  \
                g_free_and_nullify(prop);                                      \
                prop = g_strdup(val);                                          \
            }                                                                  \
    }                                                                          \

/* These two are mostly lifted from fontilus by James Henstridge. Thanks. :-) */
static void
_get_ps_info(FontInfo *fontinfo, PS_FontInfoRec ps_info, const FT_Face face)
{
    ADD_PS_PROP(fontinfo->family, ps_info.family_name);
    ADD_PS_PROP(fontinfo->style, ps_info.weight);
    ADD_PS_PROP(fontinfo->version, ps_info.version);

    if (ps_info.notice && g_utf8_validate(ps_info.notice, -1, NULL))
    {
        ADD_PS_PROP(fontinfo->copyright, ps_info.notice);
        _get_foundry_from_notice(ps_info.notice, fontinfo);
    }
}

#define ADD_SFNT_PROP(prop, val)                                               \
    {                                                                          \
        if (val)                                                               \
        {                                                                      \
            g_free_and_nullify(prop);                                          \
            prop = g_strdup(val);                                              \
            g_free_and_nullify(val);                                           \
        }                                                                      \
    }                                                                          \

#define G_CONVERT_8_2_16BE(sname)                                              \
        g_convert((const gchar *) sname.string,                               \
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL)     \

static void
_get_sfnt_info(FontInfo *fontinfo, const FT_Face face)
{
    gint    index,
            namecount = FT_Get_Sfnt_Name_Count(face);
    gchar   *version = NULL,
            *copyright = NULL,
            *description = NULL,
            *license = NULL,
            *license_url = NULL,
            *foundry = NULL;

    for (index=0; index < namecount; index++)
    {
        FT_SfntName sname;

        if (FT_Get_Sfnt_Name(face, index, &sname) != 0)
            continue;

        /* Only handle the unicode names for US langid */
        if (!(sname.platform_id == TT_PLATFORM_MICROSOFT &&
                sname.encoding_id == TT_MS_ID_UNICODE_CS &&
                sname.language_id == TT_MS_LANGID_ENGLISH_UNITED_STATES))
            continue;

        switch (sname.name_id)
        {
            case TT_NAME_ID_COPYRIGHT:
                g_free_and_nullify(copyright);
                copyright = G_CONVERT_8_2_16BE(sname);
                break;
            case TT_NAME_ID_VERSION_STRING:
                g_free_and_nullify(version);
                version = G_CONVERT_8_2_16BE(sname);
                break;
            case TT_NAME_ID_DESCRIPTION:
                g_free_and_nullify(description);
                description = G_CONVERT_8_2_16BE(sname);
                break;
            case TT_NAME_ID_LICENSE:
                g_free_and_nullify(license);
                license = G_CONVERT_8_2_16BE(sname);
                break;
            case TT_NAME_ID_LICENSE_URL:
                g_free_and_nullify(license_url);
                license_url = G_CONVERT_8_2_16BE(sname);
                break;
            case TT_NAME_ID_MANUFACTURER:
                g_free_and_nullify(foundry);
                foundry = G_CONVERT_8_2_16BE(sname);
                break;
            default:
                break;
        }
    }

    ADD_SFNT_PROP(fontinfo->version, version);
    ADD_SFNT_PROP(fontinfo->copyright, copyright);
    ADD_SFNT_PROP(fontinfo->description, description);
    ADD_SFNT_PROP(fontinfo->license, license);
    ADD_SFNT_PROP(fontinfo->license_url, license_url);

    if (foundry)
    {
        if(g_strcmp0(foundry, "Unknown") == 0)
            _get_foundry_from_notice(foundry, fontinfo);

        if (g_strcmp0(fontinfo->foundry, "Unknown") == 0
                            && (int) strlen(foundry) < 50)
        {
            g_free_and_nullify(fontinfo->foundry);
            fontinfo->foundry = g_strstrip(g_strdup(foundry));
        }

        g_free_and_nullify(foundry);
    }
}

/*
 * Vendor/Notice data sourced from fcfreetype.c, ttmkfdir by Joerg Pommnitz and
 * of course http://developer.apple.com/fonts/TTRefMan/RM06/Chap6OS2.html
 */

/*
 * Order is significant for NoticeData.
 */
static const struct
{
    const char vendor[45];
    const char foundry[20];
}
NoticeData[] =
{
    {"Bigelow", "B&H"},
    {"Adobe", "Adobe"},
    {"Bitstream", "Bitstream"},
    {"Monotype", "Monotype"},
    {"Linotype", "Linotype"},
    {"LINOTYPE-HELL", "Linotype"},
    {"IBM", "IBM"},
    {"URW", "URW"},
    {"International Typeface Corporation", "ITC"},
    {"Tiro Typeworks", "Tiro"},
    {"XFree86", "XFree86"},
    {"Microsoft", "Microsoft"},
    {"Omega", "Omega"},
    {"Font21", "Hwan"},
    {"HanYang System", "HanYang"}
};

static const struct
{
    const FT_Char   vendor[5];
    const char      foundry[50];
}
VendorData[] =
{
    {"ACG ", "AGFA Compugraphic"},
    {"ADBE", "Adobe"},
    {"AGFA", "AGFA Compugraphic"},
    {"ALTS", "Altsys"},
    {"APPL", "Apple"},
    {"ARPH", "Arphic"},
    {"ATEC", "Alltype"},
    {"BERT", "Berthold"},
    {"B&H ", "Bigelow & Holmes"},
    {"B?  ", "Bigelow & Holmes"},
    {"BITS", "Bitstream"},
    {"CANO", "Cannon"},
    {"DTC ", "Digital Typeface Corp."},
    {"DYNA", "Dynalab"},
    {"EPSN", "Epson"},
    {"FJ  ", "Fujitsu"},
    {"HP  ", "Hewlett-Packard"},
    {"IBM ", "IBM"},
    {"ITC ", "ITC"},
    {"IMPR", "Impress"},
    {"KATF", "Kingsley/ATF"},
    {"LANS", "Lanston Type Co., Ltd."},
    {"LARA", "Larabie Fonts"},
    {"LEAF", "Interleaf"},
    {"LETR", "Letraset"},
    {"LINO", "Linotype"},
    {"MACR", "Macromedia"},
    {"MONO", "Monotype"},
    {"MS  ", "Microsoft"},
    {"MT  ", "Monotype"},
    {"NEC ", "NEC"},
    {"PARA", "Paratype"},
    {"QMSI", "QMS/Imagen"},
    {"RICO", "Ricoh"},
    {"URW ", "URW"},
    {"Y&Y ", "Y&Y"},
    {"ZSFT", "ZSoft"}
};

#define STRUCT_LEN(s) (int) (sizeof (s) / sizeof (s[0]))
#define NOTICE_ENTRIES STRUCT_LEN(NoticeData)
#define VENDOR_ENTRIES STRUCT_LEN(VendorData)

static gboolean
_vendor_matches(const FT_Char vendor[4], const FT_Char *vendor_id)
{
    gboolean    result;
    GString     *a, *b;

    /* vendor is not necessarily NUL-terminated. */
    a = g_string_new_len((const gchar *) vendor, 4);
    b = g_string_new_len((const gchar *) vendor_id, 4);
    result = g_string_equal(a, b);
    g_string_free(a, TRUE);
    g_string_free(b, TRUE);

    return result;
}

static void
_get_foundry_from_notice(const FT_String *notice, FontInfo *fontinfo)
{
    int     i;

    if (notice)
    {
        for(i = 0; i < NOTICE_ENTRIES; i++)
        {
            if (g_strrstr((const char *) notice, NoticeData[i].vendor))
            {
                g_free_and_nullify(fontinfo->foundry);
                fontinfo->foundry = g_strdup(NoticeData[i].foundry);
                break;
            }
        }
    }
}

static void
_get_foundry_from_vendor_id(const FT_Char vendor[4], FontInfo *fontinfo)
{
    int     i;

    if (vendor)
    {
        for(i = 0; i < VENDOR_ENTRIES; i++)
        {
            if (_vendor_matches(vendor, VendorData[i].vendor))
            {
                g_free_and_nullify(fontinfo->foundry);
                fontinfo->foundry = g_strdup(VendorData[i].foundry);
                break;
            }
        }
    }
}
