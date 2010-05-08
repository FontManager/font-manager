/*
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

#include <Python.h>
/* <Python.h> includes <stdio.h>, <string.h>, <errno.h>, and <stdlib.h> */
#include <glib.h>
#include <glib/gstdio.h>
#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TYPES_H
#include FT_TYPE1_TABLES_H
#include FT_XFREE86_H

static PyObject * FcClose(PyObject *self, PyObject *args);
static PyObject * FcOpen(PyObject *self, PyObject *args);
static PyObject * FcAddAppFontDir(PyObject *self, PyObject *args);
static PyObject * FcAddAppFontFile(PyObject *self, PyObject *args);
static PyObject * FcClearAppFonts(PyObject *self, PyObject *args);
static PyObject * FcEnableHomeConfig(PyObject *self, PyObject *args);
static PyObject * FcGetFontDirs(PyObject *self, PyObject *args);
static PyObject * FcFileList(PyObject *self, PyObject *args);
static PyObject * FT_Get_File_Info(PyObject *self, PyObject *args);
static PyObject * _get_sfnt_info(FT_Face face);
static PyObject * _get_ps_info(FT_Face face, PS_FontInfoRec  ps_info);

static PyObject *
FcOpen(PyObject *self, PyObject *args)
{
    if (!FcInit())
    {
        PyErr_SetString(PyExc_EnvironmentError,
                        "Failed to initialize FontConfig library!\n");
        return NULL;
    }
    return Py_None;
}

/* Calling FcFini() can crash newer versions of FontConfig! */
static PyObject *
FcClose(PyObject *self, PyObject *args)
{
    FcFini();
    return Py_None;
}

/* Add an application specific font directory */
static PyObject *
FcAddAppFontDir(PyObject *self, PyObject *args)
{
    gchar   *dirpath = NULL,
            *error = NULL;

    if (!PyArg_ParseTuple(args, "s", &dirpath))
        return NULL;

    if (!g_file_test(dirpath, G_FILE_TEST_IS_DIR))
    {
        g_free(error);
        error = g_strdup_printf("No such directory : '%s'\n", dirpath);
        PyErr_SetString(PyExc_IOError, error);
        g_free(error);
        return NULL;
    }

    if (!FcConfigAppFontAddDir(FcConfigGetCurrent(), (const FcChar8 *) dirpath))
    {
        g_free(error);
        error = g_strdup_printf("Failed to add directory : '%s'\n", dirpath);
        PyErr_SetString(PyExc_EnvironmentError, error);
        g_free(error);
        return NULL;
    }

    return Py_None;
}

/* Add an application specific font */
static PyObject *
FcAddAppFontFile(PyObject *self, PyObject *args)
{
    gchar   *filepath = NULL,
            *error = NULL;

    if (!PyArg_ParseTuple(args, "s", &filepath))
        return NULL;

    if (!g_file_test(filepath, G_FILE_TEST_EXISTS))
    {
        g_free(error);
        error = g_strdup_printf("No such file : '%s'\n", filepath);
        PyErr_SetString(PyExc_IOError, error);
        g_free(error);
        return NULL;
    }

    if (!FcConfigAppFontAddFile(FcConfigGetCurrent(), (const FcChar8 *) filepath))
    {
        g_free(error);
        error = g_strdup_printf("Failed to add file : '%s'\n", filepath);
        PyErr_SetString(PyExc_EnvironmentError, error);
        g_free(error);
        return NULL;
    }

    return Py_None;
}

/* Clear any application specific fonts/directories */
static PyObject *
FcClearAppFonts(PyObject *self, PyObject *args)
{
    FcConfigAppFontClear(FcConfigGetCurrent());
    return Py_None;
}

/* This function enables the users files as configuration sources */
static PyObject *
FcEnableHomeConfig(PyObject *self, PyObject *args)
{
    FcBool  enable;

    if (!PyArg_ParseTuple(args, "i", &enable))
    {
        /* Clear any ignored errors, can cause serious issues! */
        PyErr_Clear();
        enable = TRUE;
    }

    FcConfigEnableHome(enable);

    return Py_None;
}

static PyObject *
FcGetFontDirs(PyObject *self, PyObject *args)
{
    gchar       *directory;
    FcStrList   *fdlist;
    PyObject    *dirlist = PyList_New(0);

    fdlist = FcConfigGetFontDirs(NULL);
    while ( directory = FcStrListNext(fdlist) )
        PyList_Append(dirlist, PyString_FromString(directory));
    FcStrListDone(fdlist);

    return dirlist;
}

/* This function is just a really simplified version of fc-list. */
static PyObject *
FcFileList(PyObject *self, PyObject *args)
{
    int         i;
    gboolean    exclude_vendor;
    FcPattern   *pattern;
    FcFontSet   *fontset;
    FcObjectSet *objectset = 0;
    PyObject    *fontlist = PyList_New(0);

    if (!PyArg_ParseTuple(args, "i", &exclude_vendor))
    {
        /* Clear any ignored errors, can cause serious issues! */
        PyErr_Clear();
        exclude_vendor = FALSE;
    }

    pattern = FcNameParse((FcChar8 *) ":");
    objectset = FcObjectSetCreate();
    FcObjectSetAdd(objectset, "file");
    if (!exclude_vendor)
        FcObjectSetAdd(objectset, "foundry");
    fontset = FcFontList(0, pattern, objectset);

    for (i = 0; i < fontset->nfont; i++)
    {
        FcChar8         *file;

        if (!exclude_vendor)
        {
            FcChar8         *foundry;
            PyObject        *details = PyDict_New();
            FcPatternGetString(fontset->fonts[i], FC_FILE, 0, &file);
            FcPatternGetString(fontset->fonts[i], FC_FOUNDRY, 0, &foundry);
            PyDict_SetItem(details,
                                PyString_FromString(file),
                                PyString_FromString(foundry));
            PyList_Append(fontlist, details);
        }
        else
        {
            FcPatternGetString(fontset->fonts[i], FC_FILE, 0, &file);
            PyList_Append(fontlist, PyString_FromString(file));
        }
    }

    if (objectset)
        FcObjectSetDestroy(objectset);
    if (pattern)
        FcPatternDestroy(pattern);
    if (fontset)
        FcFontSetDestroy(fontset);

    return fontlist;
}

/* This function uses FreeType to open a font and gather information about it. */
static PyObject *
FT_Get_File_Info(PyObject *self, PyObject *args)
{
    FT_Face         face;
    FT_Library      library;
    FT_Error        error;
    PS_FontInfoRec  ps_info;

    gsize           filesize;
    gchar           *filepath = NULL,
                    *font = NULL,
                    *foundry = NULL,
                    *hash = NULL;
    PyObject        *fileinfo = PyDict_New();

    if (!PyArg_ParseTuple(args, "s|s", &filepath, &foundry))
        return NULL;


    if (!g_file_get_contents(filepath, &font, &filesize, NULL))
    {
        gchar *err;

        if (!g_file_test(filepath, G_FILE_TEST_EXISTS))
            err = g_strdup_printf("No such file : '%s'\n", filepath);
        else
            err = g_strdup_printf("Open Failed : '%s'\n", filepath);
        PyErr_SetString(PyExc_IOError, err);
        g_free(err);
        return NULL;
    }

    error = FT_Init_FreeType(&library);
    if (error)
    {
        PyErr_SetString(PyExc_EnvironmentError,
                        "Failed to initialize FreeType library!\n");
        return NULL;
    }

    error = FT_New_Memory_Face(library,
                                (const FT_Byte *) font,
                                (FT_Long) filesize, 0, &face);
    if (error)
    {
        PyErr_SetString(PyExc_EnvironmentError, "Failed to load font!\n");
        return NULL;
    }

    PyDict_SetItem(fileinfo,
                    PyString_FromString("filepath"),
                    PyString_FromString(filepath));

    PyDict_SetItem(fileinfo,
                    PyString_FromString("filesize"),
                    PyString_FromFormat("%zu", (size_t) filesize));

    if (FT_IS_SFNT(face))
    {
        PyDict_Merge(fileinfo, _get_sfnt_info(face), TRUE);
    }
    else if (FT_Get_PS_Font_Info(face, &ps_info) == 0)
    {
        PyDict_Merge(fileinfo, _get_ps_info(face, ps_info), TRUE);
    }

    if ((const char*) FT_Get_X11_Font_Format(face) != NULL)
    {
        PyDict_SetItem(fileinfo,
                        PyString_FromString("filetype"),
                        PyString_FromString((const char*)
                                            FT_Get_X11_Font_Format(face)));
    }

    if ((const char*) FT_Get_Postscript_Name(face) != NULL)
    {
        PyDict_SetItem(fileinfo,
                        PyString_FromString("psname"),
                        PyString_FromString((const char*)
                                            FT_Get_Postscript_Name(face)));
    }

    if (foundry)
    {
        PyDict_SetItem(fileinfo,
                        PyString_FromString("foundry"),
                        PyString_FromString(foundry));
    }
    else
    {
        PyDict_SetItem(fileinfo,
                        PyString_FromString("foundry"),
                        PyString_FromString("unknown"));
    }

    g_free(hash);
    hash = g_compute_checksum_for_data(G_CHECKSUM_MD5,
                                        (const guchar *) font, filesize);
    PyDict_SetItem(fileinfo,
                    PyString_FromString("checksum"),
                    PyString_FromString(hash));
    g_free(hash);

    /* Use these if possible, it's what Pango does */
    if (face->family_name)
    {
        PyDict_SetItem(fileinfo,
                        PyString_FromString("family"),
                        PyString_FromString(face->family_name));
    }
    if (face->style_name)
    {
        PyDict_SetItem(fileinfo,
                        PyString_FromString("style"),
                        PyString_FromString(face->style_name));
    }

    FT_Done_Face(face);
    FT_Done_FreeType(library);
    g_free(font);

    return fileinfo;
}

/* These last two are lifted from fontilus by James Henstridge... thanks. :-) */
static PyObject *
_get_sfnt_info(FT_Face face)
{
    gint    index,
            namecount = FT_Get_Sfnt_Name_Count(face);
    gchar   *family = NULL,
            *style = NULL,
            *version = NULL,
            *copyright = NULL,
            *description = NULL,
            *license = NULL,
            *license_url = NULL;

    PyObject    *info = PyDict_New();

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
                g_free(family);
                family = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_FONT_SUBFAMILY:
                g_free(style);
                style = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_COPYRIGHT:
                g_free(copyright);
                copyright = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_VERSION_STRING:
                g_free(version);
                version = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_DESCRIPTION:
                g_free(description);
                description = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_LICENSE:
                g_free(license);
                license = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            case TT_NAME_ID_LICENSE_URL:
                g_free(license_url);
                license_url = g_convert(sname.string, sname.string_len,
                                "UTF-8", "UTF-16BE", NULL, NULL, NULL);
                break;
            default:
                break;
        }
    }

    if (family)
    {
        PyDict_SetItem(info,
                        PyString_FromString("family"),
                        PyString_FromString(family));
        g_free(family);
    }

    if (style)
    {
        PyDict_SetItem(info,
                        PyString_FromString("style"),
                        PyString_FromString(style));
        g_free(style);
    }

    if (version)
    {
        PyDict_SetItem(info,
                        PyString_FromString("version"),
                        PyString_FromString(version));
        g_free(version);
    }

    if (copyright)
    {
        PyDict_SetItem(info,
                        PyString_FromString("copyright"),
                        PyString_FromString(copyright));
        g_free(copyright);
    }

    if (description)
    {
        PyDict_SetItem(info,
                        PyString_FromString("description"),
                        PyString_FromString(description));
        g_free(description);
    }

    if (license)
    {
        PyDict_SetItem(info,
                        PyString_FromString("license"),
                        PyString_FromString(license));
        g_free(license);
    }

    if (license_url)
    {
        PyDict_SetItem(info,
                        PyString_FromString("license_url"),
                        PyString_FromString(license_url));
        g_free(license_url);
    }

    return info;
}

static PyObject *
_get_ps_info(FT_Face face, PS_FontInfoRec  ps_info)
{
    PyObject    *info = PyDict_New();

    if (ps_info.family_name && g_utf8_validate(ps_info.family_name, -1, NULL))
    {
        PyDict_SetItem(info,
                        PyString_FromString("family"),
                        PyString_FromString(ps_info.family_name));
    }

    if (ps_info.weight && g_utf8_validate(ps_info.weight, -1, NULL))
    {
        PyDict_SetItem(info,
                        PyString_FromString("style"),
                        PyString_FromString(ps_info.weight));
    }

    if (ps_info.version && g_utf8_validate(ps_info.version, -1, NULL))
    {
        PyDict_SetItem(info,
                        PyString_FromString("version"),
                        PyString_FromString(ps_info.version));
    }

    if (ps_info.notice && g_utf8_validate(ps_info.notice, -1, NULL))
    {
        PyDict_SetItem(info,
                        PyString_FromString("copyright"),
                        PyString_FromString(ps_info.notice));
    }

    return info;
}

static PyMethodDef Methods[] = {

    {"FcOpen", FcOpen, METH_NOARGS,
    "Initialize FontConfig Library.\n\n\
    This function takes no arguments and always returns None."},

    {"FcClose", FcClose, METH_NOARGS,
    "Finalize FontConfig Library.\n\n\
    This function takes no arguments and always returns None.\n\n\
    Note : This call can cause a crash in newer versions of FontConfig."},

    {"FcAddAppFontDir", FcAddAppFontDir, METH_VARARGS,
    "Add an application specific font directory\n\n\
    Takes one argument, the path to the directory to be added\n\n\
    Should call FcClearAppFonts when done."},

    {"FcAddAppFontFile", FcAddAppFontFile, METH_VARARGS,
    "Add an application specific font\n\n\
    Takes one argument, the filepath for the font to be added\n\n\
    Should call FcClearAppFonts when done."},

    {"FcClearAppFonts", FcClearAppFonts, METH_NOARGS,
    "Clear any application specific fonts\n\n\
    This function takes no arguments and always returns None."},

    {"FcEnableHomeConfig", FcEnableHomeConfig, METH_VARARGS,
    "True/False to Enable/Disable user specific files\n\n\
    Useful when the only thing we're interested in is \"system-wide\" files."},

    {"FcGetFontDirs", FcGetFontDirs, METH_NOARGS,
    "Return a list of configured font directories.\n\n\
    This function takes no arguments and always returns None."},

    {"FcFileList", FcFileList, METH_VARARGS,
    "Query FontConfig for all installed font files.\n\n\
     Returns a list of dictionaries -- {filepath:vendor}\n\n\
     False to exclude vendor information.\n\n\
     Returns a list of filepaths."},

    {"FT_Get_File_Info", FT_Get_File_Info, METH_VARARGS,
    "Query FreeType for file details.\n\n\
     Takes two arguments, the filepath and optionally the vendor.\n\n\
     Returns a dictionary."},

    {NULL, NULL, 0, NULL}           /* Signals end of method definitions */
};

PyMODINIT_FUNC
init_fontutils(void)
{
    (void) Py_InitModule3("_fontutils", Methods,
"This extension is a part of Font Manager.\n\n\
This extension allows interacting directly with FontConfig and FreeType,\n\
rather than having to call command line applications and parse their output.\n\n\
It also allows calling certain functions which are inaccessible from python.");
}

/* EOF */
