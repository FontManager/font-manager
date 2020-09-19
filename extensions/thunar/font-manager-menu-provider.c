/* font-manager-menu-provider.c
 *
 * Copyright (C) 2018 - 2020 Jerry Casiano
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

#include "font-manager-menu-provider.h"

#define FONT_VIEWER_BUS_ID "org.gnome.FontViewer"
#define FONT_VIEWER_BUS_PATH "/org/gnome/FontViewer"

struct _FontManagerMenuProvider
{
    GObject parent_instance;

    guint watch_id;
    gboolean active;
    gchar *uri;

    GDBusConnection *connection;
};

static void font_manager_menu_provider_interface_init (ThunarxMenuProviderIface *iface);

THUNARX_DEFINE_TYPE_WITH_CODE (FontManagerMenuProvider,
                                font_manager_menu_provider,
                                G_TYPE_OBJECT,
                                THUNARX_IMPLEMENT_INTERFACE(THUNARX_TYPE_MENU_PROVIDER,
                                                            font_manager_menu_provider_interface_init))

static void
install_task (GTask *task,
              FontManagerMenuProvider *self,
              ThunarxMenuItem *item,
              GCancellable *cancellable)
{
    GList *filelist = g_object_get_data(G_OBJECT(item), "filelist");
    g_return_if_fail(filelist != NULL);
    for (GList *iter = filelist; iter != NULL; iter = iter->next) {
        if (!thunarx_file_info_is_font_file(iter->data))
            continue;
        g_autoptr(GFile) file = thunarx_file_info_get_location(iter->data);
        g_autofree gchar *dir = font_manager_get_user_font_directory();
        g_autoptr(GFile) directory = g_file_new_for_path(dir);
        font_manager_install_file(file, directory, NULL);
    }
    return;
}

static void
on_install_selected (FontManagerMenuProvider *self, ThunarxMenuItem *item)
{
    g_autoptr(GTask) task = g_task_new(self, NULL, NULL, NULL);
    g_task_set_task_data(task, item, NULL);
    g_task_run_in_thread(task, (GTaskThreadFunc) install_task);
    return;
}

static GList *
font_manager_menu_provider_get_file_items (ThunarxMenuProvider *provider,
                                           G_GNUC_UNUSED GtkWidget *widget,
                                           GList *filelist)
{
    if (filelist == NULL)
        return NULL;

    FontManagerMenuProvider *self = FONT_MANAGER_MENU_PROVIDER(provider);

    GList *items = NULL;

    gboolean single_selection = (filelist->next == NULL);

    if (single_selection) {

        ThunarxFileInfo *fileinfo = g_list_nth_data(filelist, 0);

        if (!thunarx_file_info_is_font_file(fileinfo))
            goto menu;

        if (!self->active)
            goto menu;

        g_autoptr(GFile) file = thunarx_file_info_get_location(fileinfo);
        g_autofree gchar *uri = g_file_get_uri(file);

        if (g_strcmp0(self->uri, uri) == 0)
            goto menu;

        if (self->connection && !g_dbus_connection_is_closed(self->connection)) {

            g_dbus_connection_call(self->connection,
                                   FONT_VIEWER_BUS_ID,
                                   FONT_VIEWER_BUS_PATH,
                                   FONT_VIEWER_BUS_ID,
                                   "ShowUri",
                                   g_variant_new("(s)", uri),
                                   NULL,
                                   G_DBUS_CALL_FLAGS_NONE,
                                   -1,
                                   NULL,
                                   NULL,
                                   NULL);

        }

        g_free(self->uri);
        self->uri = g_strdup(uri);

    }

menu:

    if (file_list_contains_font_files(filelist)) {
        ThunarxMenuItem *install = thunarx_menu_item_new("FontManager:install",
                                                           _("Install"),
                                                           single_selection ?
                                                           _("Install the selected font file") :
                                                           _("Install the selected font files"),
                                                           NULL);
        g_object_set_data_full(G_OBJECT(install), "filelist",
                                thunarx_file_info_list_copy(filelist),
                                (GDestroyNotify) thunarx_file_info_list_free);
        g_signal_connect_swapped(install, "activate", G_CALLBACK(on_install_selected), self);
        items = g_list_append(items, install);
    }

    return items;
}

static void
font_manager_menu_provider_finalize (GObject *gobject)
{
    FontManagerMenuProvider *self = FONT_MANAGER_MENU_PROVIDER(gobject);
    g_bus_unwatch_name(self->watch_id);
    g_free(self->uri);
    g_clear_object(&self->connection);
    G_OBJECT_CLASS(font_manager_menu_provider_parent_class)->finalize(gobject);
    return;
}

static void
font_manager_menu_provider_interface_init (ThunarxMenuProviderIface *iface)
{
    iface->get_file_menu_items = font_manager_menu_provider_get_file_items;
    return;
}

static void
font_manager_menu_provider_class_init (FontManagerMenuProviderClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = font_manager_menu_provider_finalize;
    return;
}

static void
font_viewer_active_callback (GDBusConnection *connection,
                             G_GNUC_UNUSED const gchar *name,
                             G_GNUC_UNUSED const gchar *name_owner,
                             gpointer user_data)
{
    FontManagerMenuProvider *self = FONT_MANAGER_MENU_PROVIDER(user_data);
    self->active = TRUE;
    g_free(self->uri);
    self->uri = NULL;
    g_set_object(&self->connection, connection);
    return;
}

static void
font_viewer_inactive_callback (G_GNUC_UNUSED GDBusConnection *connection,
                               G_GNUC_UNUSED const gchar *name,
                               gpointer user_data)
{
    FontManagerMenuProvider *self = FONT_MANAGER_MENU_PROVIDER(user_data);
    self->active = FALSE;
    g_free(self->uri);
    self->uri = NULL;
    g_clear_object(&self->connection);
    return;
}

static void
font_manager_menu_provider_init (FontManagerMenuProvider *self)
{
    g_return_if_fail(self != NULL);
    self->active = FALSE;
    self->uri = NULL;
    self->watch_id = g_bus_watch_name(G_BUS_TYPE_SESSION,
                                      FONT_VIEWER_BUS_ID,
                                      G_BUS_NAME_WATCHER_FLAGS_NONE,
                                      (GBusNameAppearedCallback) font_viewer_active_callback,
                                      (GBusNameVanishedCallback) font_viewer_inactive_callback,
                                      self,
                                      NULL);
    return;
}

void
font_manager_menu_provider_load (ThunarxProviderPlugin *plugin)
{
    font_manager_menu_provider_register_type(plugin);
    return;
}

