/* font-manager-renamer-provider.c
 *
 * Copyright (C) 2018-2022 Jerry Casiano
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

#include <gio/gio.h>

#include "font-manager-renamer-provider.h"

struct _FontManagerRenamerProvider
{
    GObject parent_instance;
};

struct _FontManagerRenamer
{
    ThunarxRenamer parent_instance;
};

G_DEFINE_TYPE (FontManagerRenamer, font_manager_renamer, THUNARX_TYPE_RENAMER)

static void font_manager_renamer_provider_interface_init (ThunarxRenamerProviderIface *iface);

THUNARX_DEFINE_TYPE_WITH_CODE (FontManagerRenamerProvider,
                               font_manager_renamer_provider,
                               G_TYPE_OBJECT,
                               THUNARX_IMPLEMENT_INTERFACE(THUNARX_TYPE_RENAMER_PROVIDER,
                                                           font_manager_renamer_provider_interface_init))

static gchar *
font_manager_renamer_process (ThunarxRenamer *renamer,
                              ThunarxFileInfo *file,
                              const gchar *text,
                              guint index)
{
    if (!thunarx_file_info_is_font_file(file))
        return NULL;
    g_autoptr(GFile) gfile = thunarx_file_info_get_location(file);
    g_autofree gchar *path = g_file_get_path(gfile);
    g_autoptr(JsonObject) metadata = font_manager_get_metadata(path, 0, NULL);
    if (!metadata)
        return NULL;
    gchar * suggested_filename = NULL;
    if (g_strrstr(text, ".")) {
        g_autofree gchar *ext = font_manager_get_file_extension(text);
        g_autofree gchar *filename = font_manager_get_suggested_filename(metadata);
        suggested_filename = g_strdup_printf("%s.%s", filename, ext);
    } else {
        suggested_filename = font_manager_get_suggested_filename(metadata);
    }
    return suggested_filename;
}

static void
font_manager_renamer_class_init (FontManagerRenamerClass *klass)
{
    ThunarxRenamerClass *parent_class = (ThunarxRenamerClass *) klass;
    parent_class->process = font_manager_renamer_process;
    return;
}

static void
font_manager_renamer_init (FontManagerRenamer *self)
{
    return;
}

ThunarxRenamer *
font_manager_renamer_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_RENAMER, "name", _("Font Properties"), NULL);
}

GList *
font_manager_renamer_provider_get_renamers (ThunarxRenamerProvider *provider)
{
    GList *renamers = NULL;
    renamers = g_list_append(renamers, font_manager_renamer_new());
    return renamers;
}

static void
font_manager_renamer_provider_interface_init (ThunarxRenamerProviderIface *iface)
{
    iface->get_renamers = font_manager_renamer_provider_get_renamers;
    return;
}

static void
font_manager_renamer_provider_class_init (FontManagerRenamerProviderClass *klass)
{
    return;
}

static void
font_manager_renamer_provider_init (FontManagerRenamerProvider *self)
{
    return;
}

void
font_manager_renamer_provider_load (ThunarxProviderPlugin *plugin)
{
    font_manager_renamer_provider_register_type(plugin);
    return;
}

