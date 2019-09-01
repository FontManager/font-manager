/* font-manager-menu-provider.c
 *
 * Copyright (C) 2018 Jerry Casiano
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

#define N_MIMETYPES 9

static const gchar *MIMETYPES [N_MIMETYPES] = {
    "font/ttf",
    "font/ttc",
    "font/otf",
    "font/type1",
    "font/collection",
    "application/x-font-ttf",
    "application/x-font-ttc",
    "application/x-font-otf",
    "application/x-font-type1"
};

struct _FontManagerMenuProvider
{
    GObject parent_instance;

    guint watch_id;
    gboolean active;
    gchar *uri;

    GDBusConnection *connection;
};

static void font_manager_menu_provider_interface_init (NautilusMenuProviderInterface *iface);

G_DEFINE_DYNAMIC_TYPE_EXTENDED (FontManagerMenuProvider,
                                font_manager_menu_provider,
                                G_TYPE_OBJECT,
                                0,
                                G_IMPLEMENT_INTERFACE_DYNAMIC (NAUTILUS_TYPE_MENU_PROVIDER,
                                                               font_manager_menu_provider_interface_init))

static gboolean
nautilus_file_info_is_font_file (NautilusFileInfo *fileinfo)
{
    for (gint i = 0; i < N_MIMETYPES; i++)
        if (nautilus_file_info_is_mime_type(fileinfo, MIMETYPES[i]))
            return TRUE;
    return FALSE;
}

static GList *
font_manager_menu_provider_get_file_items (G_GNUC_UNUSED NautilusMenuProvider *provider,
                                           G_GNUC_UNUSED GtkWidget *widget,
                                           GList *filelist)
{
    if (filelist == NULL)
        return NULL;

    FontManagerMenuProvider *self = FONT_MANAGER_MENU_PROVIDER(provider);

    GList *items = NULL;

    gboolean single_selection = (filelist->next == NULL);

    if (single_selection) {

        NautilusFileInfo *fileinfo = g_list_nth_data(filelist, 0);

        if (!nautilus_file_info_is_font_file(fileinfo))
            return items;

        /* TODO : Add menuitems for installation, package creation, etc */

        if (!self->active)
            return items;

        gchar *uri = nautilus_file_info_get_activation_uri(fileinfo);

        if (g_strcmp0(self->uri, uri) == 0) {
            g_free(uri);
            return items;
        }

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
        self->uri = uri;

    }

    return items;
}

static GList *
font_manager_menu_provider_get_background_items (G_GNUC_UNUSED NautilusMenuProvider *provider,
                                                 G_GNUC_UNUSED GtkWidget *widget,
                                                 G_GNUC_UNUSED NautilusFileInfo *current_folder)
{
    return NULL;
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
font_manager_menu_provider_class_finalize (G_GNUC_UNUSED FontManagerMenuProviderClass *klass)
{
    return;
}

static void
font_manager_menu_provider_interface_init (NautilusMenuProviderInterface *iface)
{
    iface->get_file_items = font_manager_menu_provider_get_file_items;
    iface->get_background_items = font_manager_menu_provider_get_background_items;
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
font_manager_menu_provider_load (GTypeModule *module)
{
    font_manager_menu_provider_register_type(module);
    return;
}

