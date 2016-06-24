/* _Common_.c
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <gee.h>
#include <fontconfig/fontconfig.h>

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

gboolean
FcCacheUpdate (void) {
    FcConfigDestroy(FcConfigGetCurrent());
    return !FcConfigUptoDate(NULL) && FcInitReinitialize();
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
