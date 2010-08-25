/* fm-fontutils.c
 *
 * Copyright (C) 2009, 2010 Jerry Casiano
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to:
 *
 *   Free Software Foundation, Inc.
 *   51 Franklin Street, Fifth Floor
 *   Boston, MA 02110-1301, USA
*/

#include "fm-fontutils.h"

static int _vendor_matches(const FT_Char vendor[4], const FT_Char *vendor_id);
static void _get_sfnt_info(FontInfo *fontinfo, FT_Face face);
static void _get_foundry_from_notice(const FT_String *notice, FontInfo *fontinfo);
static void _get_foundry_from_vendor_id(const FT_Char vendor[4], FontInfo *fontinfo);

/**
 * FcListFiles:
 *
 * Returns a pointer to a GSList containing filepaths for installed font files
 * Caller is responsible for freeing the returned list, i.e.
 *
 *      g_slist_foreach(list, (GFunc) g_free, NULL);
 *      g_slist_free(list);
 *
 * @Fini:   Free resources by calling FcFini()
 *
 * Note:    Calling FcFini from a graphical application which uses Pango
 *          can cause it to crash depending on FontConfig version.
 *
 * See http://code.google.com/p/chromium/issues/detail?id=32091 for an example
 */
GSList *
FcListFiles(int Fini)
{
    int         i;
    FcPattern   *pattern;
    FcFontSet   *fontset;
    FcObjectSet *objectset = 0;
    GSList      *filelist = NULL;

    g_assert(FcInit());

    pattern = FcNameParse((FcChar8 *) ":");
    objectset = FcObjectSetCreate();
    FcObjectSetAdd(objectset, "file");
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
    if (Fini)
        FcFini();

    return filelist;
}

/**
 * FcListUserDirs:
 *
 * Returns a pointer to a GSList containing filepaths for user font directories
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

    fdlist = FcConfigGetFontDirs(NULL);
    while ( (directory = FcStrListNext(fdlist)) )
    {
        if ( g_access((const gchar *) directory, W_OK) == 0 )
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
FT_Get_Face_Count(const gchar *filepath)
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

#define _ADD_SFNT_PROP(prop, val)                                              \
    {                                                                          \
        if (val)                                                               \
        {                                                                      \
            g_free_and_nullify(prop);                                          \
            prop = g_strdup(val);                                              \
            g_free_and_nullify(val);                                           \
        }                                                                      \
    }                                                                          \

#define _ADD_PS_PROP(prop, val)                                                \
    {                                                                          \
        if (val && g_utf8_validate(val, -1, NULL))                            \
            {                                                                  \
                g_free_and_nullify(prop);                                      \
                prop = g_strdup(val);                                          \
            }                                                                  \
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
FT_Get_Font_Info(FontInfo *fontinfo, const gchar *filepath, int index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        error;
    PS_FontInfoRec  ps_info;
    TT_OS2          *os2;

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
    {
        return error;
    }

    error = FT_New_Memory_Face(library,
                                (const FT_Byte *) font,
                                (FT_Long) filesize, index, &face);
    if (G_UNLIKELY(error))
    {
        return error;
    }

    g_free_and_nullify(fontinfo->owner);
    if (g_access((const gchar *) filepath, W_OK) == 0)
    {
        fontinfo->owner = g_strdup("User");
    }
    else
    {
        fontinfo->owner = g_strdup("System");
    }

    g_free_and_nullify(fontinfo->filepath);
    fontinfo->filepath = g_strdup(filepath);
    g_free_and_nullify(fontinfo->filesize);
    fontinfo->filesize = g_strdup_printf("%zu", (size_t) filesize);
    g_free_and_nullify(checksum);
    g_free_and_nullify(fontinfo->checksum);
    checksum = g_compute_checksum_for_data(G_CHECKSUM_MD5,
                                            (const guchar *) font, filesize);
    fontinfo->checksum = g_strdup(checksum);
    g_free_and_nullify(checksum);

    os2 = (TT_OS2 *) FT_Get_Sfnt_Table (face, ft_sfnt_os2);
    if (G_LIKELY(os2 && os2->version >= 0x0001 && os2->version != 0xffff))
    {
        _get_foundry_from_vendor_id(os2->achVendID, fontinfo);
        /*
        g_free_and_nullify(fontinfo->panose);
        fontinfo->panose = g_strdup_printf("%i:%i:%i:%i:%i:%i:%i:%i:%i:%i",
                                os2->panose[0], os2->panose[1], os2->panose[2],
                                os2->panose[3], os2->panose[4], os2->panose[5],
                                os2->panose[6], os2->panose[7], os2->panose[8],
                                os2->panose[9]);
                                */
    }

    if (G_LIKELY(FT_IS_SFNT(face)))
    {
        _get_sfnt_info(fontinfo, face);
    }
    else if (FT_Get_PS_Font_Info(face, &ps_info) == 0)
    {
        _ADD_PS_PROP(fontinfo->family, ps_info.family_name);
        _ADD_PS_PROP(fontinfo->style, ps_info.weight);
        _ADD_PS_PROP(fontinfo->version, ps_info.version);

        if (ps_info.notice && g_utf8_validate(ps_info.notice, -1, NULL))
        {
            _ADD_PS_PROP(fontinfo->copyright, ps_info.notice);
            _get_foundry_from_notice(ps_info.notice, fontinfo);
        }
    }

    if (G_LIKELY(FT_Get_X11_Font_Format(face) != NULL))
    {
        g_free_and_nullify(fontinfo->filetype);
        fontinfo->filetype = g_strdup(FT_Get_X11_Font_Format(face));
    }

    if (G_LIKELY(FT_Get_Postscript_Name(face) != NULL))
    {
        g_free_and_nullify(fontinfo->psname);
        fontinfo->psname = g_strdup(FT_Get_Postscript_Name(face));
    }

    /* Use these if possible */
    if (G_LIKELY(face->family_name))
    {
        gchar   *family;

        family = g_convert((const gchar *) face->family_name,
                            -1, "UTF-8", "ASCII", NULL, NULL, NULL);
        /* A ? more than likely means non-ASCII characters,
         * if that is the case then we just keep the current
         * value since this one will most definitely be broken.
         */
        if (family != NULL && !g_strrstr((const gchar *) family, "?"))
        {
            g_free_and_nullify(fontinfo->family);
            fontinfo->family = g_strdup(family);
        }
        g_free_and_nullify(family);
    }
    if (G_LIKELY(face->style_name))
    {
        gchar   *style;

        style = g_convert((const gchar *) face->style_name,
                            -1, "UTF-8", "ASCII", NULL, NULL, NULL);
        if (style != NULL && !g_strrstr((const gchar *) style, "?"))
        {
            g_free_and_nullify(fontinfo->style);
            fontinfo->style = g_strdup(style);
        }
        g_free_and_nullify(style);
    }

    FT_Done_Face(face);
    FT_Done_FreeType(library);
    g_free_and_nullify(font);

    return error;
}

/* These two are mostly lifted from fontilus by James Henstridge. Thanks. :-) */
static void
_get_sfnt_info(FontInfo *fontinfo, const FT_Face face)
{
    gint    index,
            namecount = FT_Get_Sfnt_Name_Count(face);
    gchar   *family = NULL,
            *style = NULL,
            *version = NULL,
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
            case TT_NAME_ID_FONT_FAMILY:
                g_free_and_nullify(family);
                family = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_FONT_SUBFAMILY:
                g_free_and_nullify(style);
                style = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_COPYRIGHT:
                g_free_and_nullify(copyright);
                copyright = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_VERSION_STRING:
                g_free_and_nullify(version);
                version = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_DESCRIPTION:
                g_free_and_nullify(description);
                description = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_LICENSE:
                g_free_and_nullify(license);
                license = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_LICENSE_URL:
                g_free_and_nullify(license_url);
                license_url = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_MANUFACTURER:
                g_free_and_nullify(foundry);
                foundry = g_convert((const gchar *) sname.string,
                sname.string_len, "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            default:
                break;
        }
    }

    _ADD_SFNT_PROP(fontinfo->family, family);
    _ADD_SFNT_PROP(fontinfo->style, style);
    _ADD_SFNT_PROP(fontinfo->version, version);
    _ADD_SFNT_PROP(fontinfo->copyright, copyright);
    _ADD_SFNT_PROP(fontinfo->description, description);
    _ADD_SFNT_PROP(fontinfo->license, license);
    _ADD_SFNT_PROP(fontinfo->license_url, license_url);

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
 * Vendor data sourced from fcfreetype.c, ttmkfdir by Joerg Pommnitz and
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
    { "Bigelow", "B&H"},
    { "Adobe", "Adobe"},
    { "Bitstream", "Bitstream"},
    { "Monotype", "Monotype"},
    { "Linotype", "Linotype"},
    { "LINOTYPE-HELL", "Linotype"},
    { "IBM", "IBM"},
    { "URW", "URW"},
    { "International Typeface Corporation", "ITC"},
    { "Tiro Typeworks", "Tiro"},
    { "XFree86", "XFree86"},
    { "Microsoft", "Microsoft"},
    { "Omega", "Omega"},
    { "Font21", "Hwan"},
    { "HanYang System", "HanYang"}
};

static const struct
{
    const FT_Char   vendor[5];
    const char     foundry[50];
}
VendorData[] =
{
    { "ACG ", "AGFA Compugraphic"},
    { "ADBE", "Adobe"},
    { "AGFA", "AGFA Compugraphic"},
    { "ALTS", "Altsys"},
    { "APPL", "Apple"},
    { "ARPH", "Arphic"},
    { "ATEC", "Alltype"},
    { "BERT", "Berthold"},
    { "B&H ", "Bigelow & Holmes"},
    { "B?  ", "Bigelow & Holmes"},
    { "BITS", "Bitstream"},
    { "CANO", "Cannon"},
    { "DTC ", "Digital Typeface Corp."},
    { "DYNA", "Dynalab"},
    { "EPSN", "Epson"},
    { "FJ  ", "Fujitsu"},
    { "HP  ", "Hewlett-Packard"},
    { "IBM ", "IBM"},
    { "ITC ", "ITC"},
    { "IMPR", "Impress"},
    { "KATF", "Kingsley/ATF"},
    { "LANS", "Lanston Type Co., Ltd."},
    { "LARA", "Larabie Fonts"},
    { "LEAF", "Interleaf"},
    { "LETR", "Letraset"},
    { "LINO", "Linotype"},
    { "MACR", "Macromedia"},
    { "MONO", "Monotype"},
    { "MS  ", "Microsoft"},
    { "MT  ", "Monotype"},
    { "NEC ", "NEC"},
    { "PARA", "Paratype"},
    { "QMSI", "QMS/Imagen"},
    { "RICO", "Ricoh"},
    { "URW ", "URW"},
    { "Y&Y ", "Y&Y"},
    { "ZSFT", "ZSoft"}
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
    g_string_free(a, TRUE); g_string_free(b, TRUE);

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
            }
        }
    }
}
