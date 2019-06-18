/* font-manager-freetype.c
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

#include <glib.h>
#include <glib-object.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <json-glib/json-glib.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_TYPES_H
#include FT_BDF_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
#include FT_TYPE1_TABLES_H
#include FT_XFREE86_H

const char *FT_Error_Message (FT_Error err)
{
    #undef __FTERRORS_H__
    #define FT_ERRORDEF( e, v, s )  case e: return s;
    #define FT_ERROR_START_LIST     switch (err) {
    #define FT_ERROR_END_LIST       }
    #include FT_ERRORS_H
    return "(Unknown error)";
}

#include "font-manager-freetype.h"
#include "font-manager-json.h"
#include "font-manager-license.h"
#include "font-manager-utils.h"
#include "font-manager-vendor.h"

static void get_os2_info (JsonObject *json_obj, const FT_Face face);
static void get_sfnt_info (JsonObject *json_obj, const FT_Face face);
static void get_ps_info (JsonObject *json_obj, const FT_Face face);
static void get_license_info (JsonObject *json_obj);
static void get_fs_type (JsonObject *json_obj, const FT_Face face);
static void get_font_revision (JsonObject *json_obj, const FT_Face face);
static void ensure_vendor (JsonObject *json_obj, const FT_Face face);
static void cleanup_version_string (JsonObject *json_obj);
static void correct_filetype (JsonObject *json_obj);


/**
 * font_manager_get_face_count:
 * @filepath:       full path to font file to examine
 *
 * This function never fails. In case of an error this function returns 1.
 * Any valid font file should contain at least one variation.
 *
 * Returns:         the number of variations contained in filepath
 */
long
font_manager_get_face_count (const gchar *filepath)
{
    FT_Face         face;
    FT_Library      library;
    FT_Long         num_faces;

    /* Index 0 is always valid */
    if (G_UNLIKELY(FT_Init_FreeType(&library) != 0))
        return 1;

    if (G_UNLIKELY(FT_New_Face(library, filepath, 0, &face) != 0)) {
        FT_Done_FreeType(library);
        return 1;
    }

    num_faces = face->num_faces;
    FT_Done_Face(face);
    FT_Done_FreeType(library);
    return num_faces;
}

static const gchar *ensure_member [] = {
    "designer",
    "designer-url",
    "description",
    "license-data",
    "license-url",
    NULL
};

/**
 * font_manager_get_metadata:
 * @filepath:       full path to font file to examine
 * @index           face index to examine
 *
 * If an error is encontered, the returned object will have a member named err
 * set to %TRUE and a member named err_msg containing a description of the error.
 *
 * Returns: (transfer full): a newly created #JsonObject
 */
JsonObject *
font_manager_get_metadata (const gchar *filepath, gint index)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        ft_error;

    gsize           filesize = 0;
    gchar           *font = NULL;
    GError          *error = NULL;

    JsonObject *json_obj = json_object_new();

    json_object_set_string_member(json_obj, "filepath", filepath);
    json_object_set_int_member(json_obj, "findex", index);
    json_object_set_int_member(json_obj, "owner", font_manager_get_file_owner(filepath));

    if (G_UNLIKELY(!g_file_get_contents(filepath, &font, &filesize, &error))) {
        font_manager_set_json_error(json_obj, error->code, error->message);
        g_critical("%s : %s", error->message, filepath);
        g_error_free(error);
        return json_obj;
    }

    ft_error = FT_Init_FreeType(&library);

    if (G_UNLIKELY(ft_error)) {
        font_manager_set_json_error(json_obj, ft_error, FT_Error_Message(ft_error));
        return json_obj;
    }

    ft_error = FT_New_Memory_Face(library, (const FT_Byte *) font, (FT_Long) filesize, index, &face);

    if (G_UNLIKELY(ft_error)) {
        font_manager_set_json_error(json_obj, ft_error, FT_Error_Message(ft_error));
        return json_obj;
    }

    gchar *_size = g_format_size(filesize);
    gchar *_md5 = g_compute_checksum_for_data(G_CHECKSUM_MD5, (const guchar *) font, filesize);
    json_object_set_string_member(json_obj, "filesize", _size);
    json_object_set_string_member(json_obj, "checksum", _md5);
    g_free(_md5);
    g_free(_size);

    /* Fontconfig modifies invalid PostScript names by replacing illegal characters with - */
    json_object_set_string_member(json_obj, "psname", FT_Get_Postscript_Name(face));
    json_object_set_string_member(json_obj, "filetype", FT_Get_Font_Format(face));
    json_object_set_int_member(json_obj, "n-glyphs", face->num_glyphs);

    /* Order matters */
    get_os2_info(json_obj, face);
    get_font_revision(json_obj, face);
    get_sfnt_info(json_obj, face);
    get_ps_info(json_obj, face);
    get_license_info(json_obj);
    get_fs_type(json_obj, face);

    ensure_vendor(json_obj, face);
    correct_filetype(json_obj);

    /* Useful during font installation */
    if (!json_object_has_member(json_obj, "family"))
        json_object_set_string_member(json_obj, "family", (gchar *) face->family_name);
    if (!json_object_has_member(json_obj, "style"))
        json_object_set_string_member(json_obj, "style", (gchar *) face->style_name);

    if (!json_object_has_member(json_obj, "version"))
        json_object_set_string_member(json_obj, "version", "1.0");

    for (int i = 0; ensure_member[i] != NULL; i++)
        if (!json_object_has_member(json_obj, ensure_member[i]))
            json_object_set_string_member(json_obj, ensure_member[i], NULL);

    g_free(font);
    FT_Done_Face(face);
    FT_Done_FreeType(library);

    return json_obj;
}

/*
 * get_license_type:
 *
 * @license:        license data or %NULL
 * @copyright:      copyright data or %NULL
 * @url:            url data or %NULL
 *
 * Searches through known licenses for a match.
 * Returns an integer which can be used with get_license_name and get_license_url.
 *
 * Returns:         index
 */
static gint
get_license_type (const gchar *license, const gchar *copyright, const gchar *url)
{
    for (guint i = 0; i < FONT_MANAGER_LICENSE_ENTRIES; i++) {
        gint l = 0;
        while (FontManagerLicenseData[i].keywords[l]) {
            if ((copyright && g_strrstr(copyright, FontManagerLicenseData[i].keywords[l]))
                || (license && g_strrstr(license, FontManagerLicenseData[i].keywords[l]))
                || (url && g_strrstr(url, FontManagerLicenseData[i].keywords[l])))
                return i;
            l++;
        }
    }
    return FONT_MANAGER_LICENSE_ENTRIES - 1;
}

/*
 * get_license_name:
 *
 * @license_type:   index returned by get_license_type
 *
 * Returns: (transfer none): string suitable for display
 */
static const gchar *
get_license_name (gint license_type)
{
    return FontManagerLicenseData[license_type].license;
}

/*
 * get_license_url:
 *
 * @license_type:   index returned by get_license_type
 *
 * Returns: (transfer none): license URL or %NULL
 */
static const gchar *
get_license_url (gint license_type)
{
    return FontManagerLicenseData[license_type].license_url;
}

/*
 * get_vendor_from_notice:
 *
 * @notice:         notice data (PostScript Type 1)
 *
 * Attempts to find vendor from notice data in PS_FontInfoRec
 *
 * Returns: (transfer none): vendor name or %NULL
 */
static const gchar *
get_vendor_from_notice (const gchar *notice)
{
    if (notice)
        for(guint i = 0; i < FONT_MANAGER_NOTICE_ENTRIES; i++)
            if (g_strrstr(notice, FontManagerNoticeData[i].vendor_id))
                return FontManagerNoticeData[i].vendor;
    return NULL;
}

static gboolean
vendor_matches (const gchar vendor[FONT_MANAGER_MAX_VENDOR_ID_LENGTH], const gchar *vendor_id)
{
    gboolean result;
    GString *a, *b;
    /* vendor is not necessarily NUL-terminated. */
    a = g_string_new_len((const gchar *) vendor, FONT_MANAGER_MAX_VENDOR_ID_LENGTH);
    b = g_string_new_len((const gchar *) vendor_id, FONT_MANAGER_MAX_VENDOR_ID_LENGTH);
    result = g_string_equal(a, b);
    g_string_free(a, TRUE);
    g_string_free(b, TRUE);
    return result;
}

static gboolean
is_known_vendor (gchar *vendor)
{
    for (guint i = 0; i < FONT_MANAGER_VENDOR_ENTRIES; i++)
        if (g_strcmp0(FontManagerVendorData[i].vendor, vendor) == 0)
            return TRUE;
    return FALSE;
}

/*
 * get_vendor_from_vendor_id:
 *
 * @vendor:         vendor ID
 *
 * Attempts to find actual name by matching ID to a list of known foundries
 *
 * Returns: (transfer none): string suitable for display or %NULL
 */
static const gchar *
get_vendor_from_vendor_id (const gchar vendor[FONT_MANAGER_MAX_VENDOR_ID_LENGTH])
{
    if (vendor)
        for (guint i = 0; i < FONT_MANAGER_VENDOR_ENTRIES; i++)
            if (vendor_matches(vendor, FontManagerVendorData[i].vendor_id))
                return FontManagerVendorData[i].vendor;
    return NULL;
}

/*
 * The functions in this section gather information which is either not
 * available through fontconfig or for which the information available
 * from fontconfig is not suitable for our needs.
 */

#define PANOSE_ENTRIES 10

static void
get_os2_info (JsonObject *json_obj, const FT_Face face)
{
    TT_OS2 *os2 = (TT_OS2 *) FT_Get_Sfnt_Table(face, FT_SFNT_OS2);
    if (G_LIKELY(os2 && os2->version >= 0x0001 && os2->version != 0xffff)) {
        const gchar *_vendor = get_vendor_from_vendor_id((gchar *) os2->achVendID);
        if (_vendor)
            json_object_set_string_member(json_obj, "vendor", _vendor);
        JsonArray *json_arr = json_array_sized_new(PANOSE_ENTRIES);
        for (gint i = 0; i < PANOSE_ENTRIES; i++)
            json_array_add_int_element(json_arr, os2->panose[i]);
        json_object_set_array_member(json_obj, "panose", json_arr);
    }
    return;
}

#define SNAME_2_UTF8(s, c)                                                    \
g_convert((const gchar *) s.string, s.string_len, "UTF-8", c, NULL, NULL, NULL) \

/* Mostly lifted from fontilus by James Henstridge. Thanks. :-) */
static void
get_sfnt_info (JsonObject *json_obj, const FT_Face face)
{

    if (!FT_IS_SFNT(face))
        return;

    gint namecount = FT_Get_Sfnt_Name_Count(face);
    gchar *vendor = NULL;
    gboolean vendor_set = FALSE;

    for (gint index = 0; index < namecount; index++) {

        FT_SfntName sname;
        if (FT_Get_Sfnt_Name(face, index, &sname) != 0)
            continue;

        if (sname.platform_id != TT_PLATFORM_MICROSOFT)
            continue;

        gchar *val = NULL;

        switch (sname.encoding_id) {
            case TT_MS_ID_SJIS:
                val = SNAME_2_UTF8(sname, "SJIS-WIN");
                break;
            case TT_MS_ID_PRC:
                val = SNAME_2_UTF8(sname, "GB2312");
                break;
            case TT_MS_ID_BIG_5:
                val = SNAME_2_UTF8(sname, "BIG-5");
                break;
            case TT_MS_ID_WANSUNG:
                val = SNAME_2_UTF8(sname, "WANSUNG");
                break;
            case TT_MS_ID_JOHAB:
                val = SNAME_2_UTF8(sname, "JOHAB");
                break;
            case TT_MS_ID_UCS_4:
                val = SNAME_2_UTF8(sname, "UCS4");
                break;
            default:
                val = SNAME_2_UTF8(sname, "UTF-16BE");
                break;
        }

        if (!val)
            continue;

        switch (sname.name_id) {
            case TT_NAME_ID_FONT_FAMILY:
            case TT_NAME_ID_WWS_FAMILY:
            case TT_NAME_ID_TYPOGRAPHIC_FAMILY:
                if (json_object_has_member(json_obj, "family")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "family", val);
                break;
            case TT_NAME_ID_FONT_SUBFAMILY:
            case TT_NAME_ID_WWS_SUBFAMILY:
            case TT_NAME_ID_TYPOGRAPHIC_SUBFAMILY:
                if (json_object_has_member(json_obj, "style")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "style", val);
                break;
            case TT_NAME_ID_COPYRIGHT:
                if (json_object_has_member(json_obj, "copyright")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "copyright", val);
                break;
            case TT_NAME_ID_VERSION_STRING:
                if (!json_object_has_member(json_obj, "version")) {
                    json_object_set_string_member(json_obj, "version", val);
                    cleanup_version_string(json_obj);
                }
                break;
            case TT_NAME_ID_DESCRIPTION:
                if (json_object_has_member(json_obj, "description")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "description", val);
                break;
            case TT_NAME_ID_LICENSE:
                if (json_object_has_member(json_obj, "license-data")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "license-data", val);
                break;
            case TT_NAME_ID_LICENSE_URL:
                if (json_object_has_member(json_obj, "license-url")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "license-url", val);
                break;
            case TT_NAME_ID_DESIGNER:
                if (json_object_has_member(json_obj, "designer")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "designer", val);
                break;
            case TT_NAME_ID_DESIGNER_URL:
                if (json_object_has_member(json_obj, "designer-url")
                    && sname.language_id != TT_MS_LANGID_ENGLISH_UNITED_STATES)
                    break;
                json_object_set_string_member(json_obj, "designer-url", val);
                break;
            case TT_NAME_ID_TRADEMARK:
                if (vendor_set)
                    break;
                if (!vendor)
                    vendor = g_strdup(val);
                break;
            case TT_NAME_ID_MANUFACTURER:
                if (vendor_set)
                    break;
                if (vendor)
                    g_free(vendor);
                vendor = g_strdup(val);
                vendor_set = (sname.language_id == TT_MS_LANGID_ENGLISH_UNITED_STATES);
                break;
            default:
                break;
        }
        g_free(val);
    }

    if (vendor) {
        if (!json_object_has_member(json_obj, "vendor")) {
            if (is_known_vendor(vendor))
                json_object_set_string_member(json_obj, "vendor", vendor);
            else {
                const gchar *_vendor = get_vendor_from_notice(vendor);
                if (_vendor)
                    json_object_set_string_member(json_obj, "vendor", _vendor);
            }
        }
        g_free(vendor);
    }

    return;
}

static void
get_ps_info (JsonObject *json_obj, const FT_Face face)
{
    PS_FontInfoRec  ps_info;

    /* Error here means it's probably not a PostScript font */
    if (FT_Get_PS_Font_Info(face, &ps_info) != 0)
        return;

    if (!json_object_has_member(json_obj, "version"))
        json_object_set_string_member(json_obj, "version", ps_info.version);
    if (ps_info.notice && g_utf8_validate(ps_info.notice, -1, NULL)) {
        if (!json_object_has_member(json_obj, "copyright"))
            json_object_set_string_member(json_obj, "copyright", ps_info.notice);
        if (!json_object_has_member(json_obj, "vendor")) {
            const gchar *_vendor = get_vendor_from_notice(ps_info.notice);
            if (_vendor)
                json_object_set_string_member(json_obj, "vendor", _vendor);
        }
    }

    return;
}

static void
get_license_info (JsonObject *json_obj)
{
    const gchar *license_data = NULL;
    const gchar *copyright = NULL;
    const gchar *license_url = NULL;

    if (json_object_has_member(json_obj, "license-data"))
        license_data = json_object_get_string_member(json_obj, "license-data");
    if (json_object_has_member(json_obj, "copyright"))
        copyright = json_object_get_string_member(json_obj, "copyright");
    if (json_object_has_member(json_obj, "license-url"))
        license_url = json_object_get_string_member(json_obj, "license-url");

    gint license_type = get_license_type(license_data, copyright, license_url);
    const gchar *license_name = get_license_name(license_type);
    json_object_set_string_member(json_obj, "license-type", license_name);

    if (license_type < (gint) (FONT_MANAGER_LICENSE_ENTRIES - 1)) {
        license_url = get_license_url(license_type);
        if (license_url)
            json_object_set_string_member(json_obj, "license-url", license_url);
    }

    return;
}

static void
get_fs_type (JsonObject *json_obj, const FT_Face face)
{
    FT_UShort flags = FT_Get_FSType_Flags(face);

    /* Default to FT_FSTYPE_INSTALLABLE_EMBEDDING */
    int fsType = 0;

    /* Least restrictive bit set takes precedence */
    if (flags & FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING)
        fsType = 2;
    if (flags & FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING)
        fsType = 4;
    if (flags & FT_FSTYPE_EDITABLE_EMBEDDING)
        fsType = 8;

    /* Additional restrictions */
    if (fsType == 4 || fsType == 8) {
        if (flags & FT_FSTYPE_NO_SUBSETTING)
            fsType += 256;
        if (flags & FT_FSTYPE_BITMAP_EMBEDDING_ONLY){
            if (FT_HAS_FIXED_SIZES(face)) {
                fsType += 512;
            } else {
                /* Restricts embedding to bitmaps but contains none. */
                fsType = 2;
            }
        }
    }

    json_object_set_int_member(json_obj, "fsType", fsType);
    return;
}

/* NOTE :
 * These functions set defaults that are suitable for display.
 * In some cases, they may not set correct information or possibly even
 * modify correct information to something expected to be more useful
 * to the user.
 */

static void
ensure_vendor (JsonObject *json_obj, const FT_Face face)
{
    if (!json_object_has_member(json_obj, "vendor")) {
        json_object_set_string_member(json_obj, "vendor", "Unknown Vendor");
        /* XXX : Is this even worth checking for? */
        BDF_PropertyRec prop;
        int result = FT_Get_BDF_Property(face, "FOUNDRY", &prop);
        if (G_UNLIKELY(result == 0 && prop.type == BDF_PROPERTY_TYPE_ATOM)) {
            json_object_set_string_member(json_obj, "vendor", prop.u.atom);
        }
    }
    return;
}

static void
get_font_revision (JsonObject *json_obj, const FT_Face face)
{
    TT_Header *head = (TT_Header *) FT_Get_Sfnt_Table(face, FT_SFNT_HEAD);
    if (head) {
        if (head->Font_Revision) {
            gchar *rev = g_strdup_printf("%.2f", (float) head->Font_Revision / 65536.0);
            json_object_set_string_member(json_obj, "version", rev);
            g_free(rev);
            return;
        }
    }
    return;
}

static void
correct_filetype (JsonObject *json_obj)
{
    const gchar *filetype = json_object_get_string_member(json_obj, "filetype");
    /* Compact Font Format doesn't really mean much. */
    if (g_strcmp0(filetype, "CFF") == 0) {
        const gchar *filepath = json_object_get_string_member(json_obj, "filepath");
        gchar *ext = font_manager_get_file_extension(filepath);
        if (g_ascii_strcasecmp(ext, "otf") == 0
            || g_ascii_strcasecmp(ext, "ttf") == 0
            || g_ascii_strcasecmp(ext, "ttc") == 0) {
            json_object_set_string_member(json_obj, "filetype", "OpenType");
        }
        g_free(ext);
    }
    return;
}

/* A lot of version strings have garbage in them. Try to pull just a number. */

static const gchar *VERSION_STRING_EXCLUDES[] = {
    "Version",
    "version",
    "Revision",
    "revision",
    "$Revision",
    "$:",
    "$",
    /* These do not even contain actual version numbers, completely pointless */
    ";FFEdit",
    "Altsys Metamorphosis:",
    "Altsys Fontographer",
    "Macromedia Fontographer",
    "Fontmaker"
};

static void
_cleanup_version_string (JsonObject *json_obj, const gchar *ch)
{
    const gchar *version = json_object_get_string_member(json_obj, "version");
    if (g_strrstr(version, ch) != NULL) {
        gchar ** str_arr = g_strsplit(version, ch, 0);
        int i = 0;
        while (str_arr[i] != NULL) {
            /* Take the first thing that even looks like a double to be a version number */
            if (g_strrstr(str_arr[i], ".") != NULL) {
                json_object_set_string_member(json_obj, "version", g_strstrip(str_arr[i]));
                break;
            }
            i++;
        }
        g_strfreev(str_arr);
    }
    return;
}

static void
cleanup_version_string (JsonObject *json_obj)
{
    const gchar **excludes = VERSION_STRING_EXCLUDES;
    const gchar *version = json_object_get_string_member(json_obj, "version");

    for (guint i = 0; i < G_N_ELEMENTS(VERSION_STRING_EXCLUDES); i++) {
        if (g_strrstr(version, excludes[i]) != NULL) {
            gchar *res = font_manager_str_replace(version, excludes[i], "");
            if (res) {
                json_object_set_string_member(json_obj, "version", g_strstrip(res));
                g_free(res);
                version = json_object_get_string_member(json_obj, "version");
            }
        }
    }

    _cleanup_version_string(json_obj, ";");
    _cleanup_version_string(json_obj, ":");
    return;
}
