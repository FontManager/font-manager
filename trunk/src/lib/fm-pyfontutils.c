/* fm-pyfontutils.c
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

#include <Python.h>
/* <Python.h> includes <stdio.h>, <string.h>, <errno.h>, and <stdlib.h> */

#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <glib.h>
#include <glib/gprintf.h>
#include <pango/pango-language.h>

#include "fm-common.h"
#include "fm-database.h"
#include "fm-fontutils.h"

static PyObject * FcAddAppFontDirs(PyObject *self, PyObject *args);
static PyObject * FcClearAppFonts(PyObject *self, PyObject *args);
static PyObject * FcEnableHomeConfig(PyObject *self, PyObject *args);
static PyObject * FcFileList(PyObject *self, PyObject *args);
static PyObject * FcParseConfigFile(PyObject *self, PyObject *args);
static PyObject * FT_Get_File_Info(PyObject *self, PyObject *args);
static PyObject * pango_get_sample_string(PyObject *self, PyObject *args);
static PyObject * set_progress_callback(PyObject *self, PyObject *args);
static PyObject * sync_font_database(PyObject *self, PyObject *args);
static void _trigger_callback(const char *msg, int total, int processed);

static PyObject * progress_callback = NULL;

/* Add an application specific directory or list of font directories */
static PyObject *
FcAddAppFontDirs(PyObject *self, PyObject *args)
{
    int        i;
    char       *error = NULL;
    PyObject    *dirlist;
    Py_ssize_t  len = 0;

    if (!PyArg_ParseTuple(args, "O:FcAddAppFontDirs", &dirlist))
        return NULL;

    len = PySequence_Length(dirlist);
    for (i = 0; i < len; i++)
    {
        int     dir = 0;
        char    *dirpath;

        dirpath = PyString_AsString(PySequence_GetItem(dirlist,i));
        if (strlen(dirpath) == 1)
        {
            dirpath = PyString_AsString(dirlist);
            dir = 1;
        }

        if (!g_file_test(dirpath, G_FILE_TEST_IS_DIR))
        {
            g_free_and_nullify(error);
            error = g_strdup_printf("No such directory : '%s'", dirpath);
            PyErr_SetString(PyExc_IOError, error);
            g_free_and_nullify(error);
            return NULL;
        }

        if (!FcConfigAppFontAddDir(FcConfigGetCurrent(),
                                    (const FcChar8 *) dirpath))
        {
            g_free_and_nullify(error);
            error = g_strdup_printf("Failed to add font directory : '%s'", dirpath);
            PyErr_SetString(PyExc_EnvironmentError, error);
            g_free_and_nullify(error);
            return NULL;
        }

        if (dir)
            break;
    }

    Py_INCREF(Py_None);
    return Py_None;
}

/* Clear any application specific fonts/directories */
static PyObject *
FcClearAppFonts(PyObject *self, PyObject *args)
{
    FcConfigAppFontClear(FcConfigGetCurrent());

    Py_INCREF(Py_None);
    return Py_None;
}

/* This function enables/disables the users files as configuration sources */
static PyObject *
FcEnableHomeConfig(PyObject *self, PyObject *args)
{
    FcBool  enable;

    if (!PyArg_ParseTuple(args, "i:FcEnableHomeConfig", &enable))
    {
        /* Clear any ignored errors, can cause serious issues if not cleared! */
        PyErr_Clear();
        enable = TRUE;
    }

    FcConfigEnableHome(enable);

    Py_INCREF(Py_None);
    return Py_None;
}

/* This function is just a really simplified version of fc-list. */
static PyObject *
FcFileList(PyObject *self, PyObject *args)
{
    GSList      *iter = NULL,
                *filelist = NULL;
    PyObject    *fontlist = PyList_New(0);

    filelist = FcListFiles(FALSE);

    for (iter = filelist; iter; iter = iter->next)
        PyList_Append(fontlist, PyString_FromString(iter->data));

    g_slist_foreach(filelist, (GFunc) g_free_and_nullify, NULL);
    g_slist_free(filelist);
    g_slist_free(iter);

    return fontlist;
}

/* This function just parses and loads the given file */
static PyObject *
FcParseConfigFile(PyObject *self, PyObject *args)
{
    char       *filepath;
    PyObject    *result;

    if (!PyArg_ParseTuple(args, "s:FcParseConfigFile", &filepath))
        return NULL;

    if (!FcConfigParseAndLoad(FcConfigGetCurrent(),
                                (const FcChar8 *) filepath, (FcBool) FALSE))
        result = Py_False;
    else
        result = Py_True;

    Py_INCREF(result);
    return result;
}

#define PyDict_SetStringItem(dictionary, item, val)                            \
PyDict_SetItem(dictionary, PyString_FromString(item), PyString_FromString(val));

static PyObject *
FT_Get_File_Info(PyObject *self, PyObject *args)
{
    FT_Error        error;
    int             index = 0;
    char           *filepath = NULL;
    PyObject        *fileinfo = PyDict_New();
    FontInfo       *fontinfo, f;

    if (!PyArg_ParseTuple(args, "s|i:FT_Get_File_Info", &filepath, &index))
        return NULL;

    fontinfo = &f;
    fontinfo_init(fontinfo);

    error = FT_Get_Font_Info(fontinfo, filepath, index);
    if (error)
    {
        char *err;
        err = g_strdup_printf("Failed to load font! : '%s'", filepath);
        PyErr_SetString(PyExc_EnvironmentError, err);
        g_free_and_nullify(err);
        fontinfo_destroy(fontinfo);
        return NULL;
    }

    /* A for loop would have been nice... */
    PyDict_SetStringItem(fileinfo, "owner", fontinfo->owner);
    PyDict_SetStringItem(fileinfo, "filepath", fontinfo->filepath);
    PyDict_SetStringItem(fileinfo, "filetype", fontinfo->filetype);
    PyDict_SetStringItem(fileinfo, "filesize", fontinfo->filesize);
    PyDict_SetStringItem(fileinfo, "checksum", fontinfo->checksum);
    PyDict_SetStringItem(fileinfo, "psname", fontinfo->psname);
    PyDict_SetStringItem(fileinfo, "family", fontinfo->family);
    PyDict_SetStringItem(fileinfo, "style", fontinfo->style);
    PyDict_SetStringItem(fileinfo, "foundry", fontinfo->foundry);
    PyDict_SetStringItem(fileinfo, "copyright", fontinfo->copyright);
    PyDict_SetStringItem(fileinfo, "version", fontinfo->version);
    PyDict_SetStringItem(fileinfo, "description", fontinfo->description);
    PyDict_SetStringItem(fileinfo, "license", fontinfo->license);
    PyDict_SetStringItem(fileinfo, "license_url", fontinfo->license_url);
    PyDict_SetStringItem(fileinfo, "panose", fontinfo->panose);
    PyDict_SetStringItem(fileinfo, "face", fontinfo->face);
    PyDict_SetStringItem(fileinfo, "pfamily", fontinfo->pfamily);
    PyDict_SetStringItem(fileinfo, "pstyle", fontinfo->pstyle);
    PyDict_SetStringItem(fileinfo, "pvariant", fontinfo->pvariant);
    PyDict_SetStringItem(fileinfo, "pweight", fontinfo->pweight);
    PyDict_SetStringItem(fileinfo, "pstretch", fontinfo->pstretch);
    PyDict_SetStringItem(fileinfo, "pdescr", fontinfo->pdescr);

    fontinfo_destroy(fontinfo);

    return fileinfo;
}

/* Sadly there is no python equivalent... or maybe I didn't look hard enough */
static PyObject *
pango_get_sample_string(PyObject *self, PyObject *args)
{
    char    *lang;

    if (!PyArg_ParseTuple(args, "s:pango_get_sample_string", &lang))
        lang = NULL;

    return PyString_FromString((const char *) pango_language_get_sample_string
                                    (pango_language_from_string(lang)));
}

static PyObject *
set_progress_callback(PyObject *self, PyObject *args)
{
    PyObject *callback;

    if (PyArg_ParseTuple(args, "O:set_progress_callback", &callback))
    {
        if (!PyCallable_Check(callback))
        {
            PyErr_SetString(PyExc_TypeError, "Expected a callback function");
            return NULL;
        }
        /* Add a reference to new callback */
        Py_XINCREF(callback);
        /* Dispose of previous callback */
        Py_XDECREF(progress_callback);
        /* Remember new callback */
        progress_callback = callback;
    }

    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject *
sync_font_database(PyObject *self, PyObject *args)
{
    char  *pmsg = "Syncing Database...";

    if (!PyArg_ParseTuple(args, "|s:sync_font_database", &pmsg))
        return NULL;

    if (progress_callback != NULL)
        sync_database(pmsg, &_trigger_callback);
    else
        sync_database(NULL, NULL);

    Py_INCREF(Py_None);
    return Py_None;
}

static void
_trigger_callback(const char *msg, int total, int processed)
{
    PyObject *arglist, *result;

    arglist = Py_BuildValue("sii", msg, total, processed);
    result = PyObject_CallObject(progress_callback, arglist);
    Py_XDECREF(arglist);
    if (result == NULL)
        /* Progress callback failed... don't care */
        PyErr_Clear();
    Py_XDECREF(result);
}

static PyMethodDef Methods[] = {

    {"FcAddAppFontDirs", FcAddAppFontDirs, METH_VARARGS,
    "Add an application specific directory or list of font directories.\n\n\
    Takes a python list of filepaths.\n\n\
    Should call FcClearAppFonts when done."},

    {"FcClearAppFonts", FcClearAppFonts, METH_NOARGS,
    "Clear any application specific fonts.\n\n\
    This function takes no arguments and always returns None."},

    {"FcEnableHomeConfig", FcEnableHomeConfig, METH_VARARGS,
    "True/False to Enable/Disable user specific configuration files."},

    {"FcFileList", FcFileList, METH_NOARGS,
    "Query FontConfig for all installed font files.\n\n\
     This function takes no arguments and returns a list of filepaths."},

    {"FcParseConfigFile", FcParseConfigFile, METH_VARARGS,
    "Parse and load the given configuration file.\n\n\
     Returns True on success."},

    {"FT_Get_File_Info", FT_Get_File_Info, METH_VARARGS,
    "Query file for font details.\n\n\
     Takes two arguments, the filepath, and optionally the face index.\n\n\
     Returns a dictionary."},

    {"pango_get_sample_string", pango_get_sample_string, METH_VARARGS,
    "Ask pango for a sample string appropriate for specified language.\n\n\
    Takes lang as a string, i.e en-us, de-de, returns sample string."},

    {"set_progress_callback", set_progress_callback, METH_VARARGS,
    "Set callback function for database sync.\n\n\
    Returns None."},

    {"sync_font_database", sync_font_database, METH_VARARGS,
    "Sync the database.\n\n\
    This function takes one optional argument, a string to forward to the\n\n\
    progress callback and always returns None."},

    {NULL, NULL, 0, NULL}           /* Signals end of method definitions */
};

PyMODINIT_FUNC
initfontutils(void)
{
    (void) Py_InitModule3("fontutils", Methods,
"This extension is a part of Font Manager.\n\n\
This extension allows interacting directly with FontConfig and FreeType,\n\
rather than having to call command line applications and parse their output.\n\n\
It also allows calling certain functions which are inaccessible from python.");
}
