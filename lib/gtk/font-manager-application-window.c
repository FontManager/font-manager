/* font-manager-application-window.c
 *
 * Copyright (C) 2022-2024 Jerry Casiano
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

#include "font-manager-application-window.h"

/**
 * SECTION: font-manager-application-window
 * @short_description: Base class for application windows
 * @title: Application Window
 * @include: font-manager-application-window.h
 *
 * Base class for application windows. Sets up common keyboard shortcuts and
 * provides for saving and restoring state.
 */

typedef struct
{
    GSettings *settings;
}
FontManagerApplicationWindowPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerApplicationWindow,
                           font_manager_application_window,
                           GTK_TYPE_APPLICATION_WINDOW)

enum
{
    PROP_RESERVED,
    PROP_SETTINGS,
    NUM_PROPS
};

static void
font_manager_application_window_dispose (GObject *gobject)
{
    FontManagerApplicationWindow *self = FONT_MANAGER_APPLICATION_WINDOW(gobject);
    g_return_if_fail(self != NULL);
    FontManagerApplicationWindowPrivate *priv;
    priv = font_manager_application_window_get_instance_private(self);
    g_clear_object(&priv->settings);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_application_window_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_application_window_about (GtkWidget                *widget,
                                      G_GNUC_UNUSED const char *action_name,
                                      G_GNUC_UNUSED GVariant   *parameter)
{
    g_return_if_fail(widget != NULL);
    font_manager_application_window_show_about(FONT_MANAGER_APPLICATION_WINDOW(widget));
    return;
}

static void
font_manager_application_window_help (GtkWidget                *widget,
                                      G_GNUC_UNUSED const char *action_name,
                                      G_GNUC_UNUSED GVariant   *parameter)
{
    g_return_if_fail(widget != NULL);
    font_manager_application_window_show_help(FONT_MANAGER_APPLICATION_WINDOW(widget));
    return;
}

static gboolean
font_manager_application_window_on_close_request (GtkWindow *window)
{
    FontManagerApplicationWindow *self = FONT_MANAGER_APPLICATION_WINDOW(window);
    FontManagerApplicationWindowPrivate *priv;
    priv = font_manager_application_window_get_instance_private(self);
    GdkSurface *surface = gtk_native_get_surface(GTK_NATIVE(window));
    GdkToplevelState state = gdk_toplevel_get_state(GDK_TOPLEVEL(surface));
    gboolean tiled = (state & GDK_TOPLEVEL_STATE_TILED);
    if (tiled) {
        g_debug("State not saved, tiled window detected");
    } else if (priv->settings && !tiled) {
        gint width, height;
        gboolean maximized;
        g_object_get(window,
                     "default-width", &width,
                     "default-height", &height,
                     "maximized", &maximized,
                     NULL);
        g_debug("Saving state : Window size : %i x %i", width, height);
        g_debug("Saving state : Window is maximized : %s", maximized ? "TRUE" : "FALSE");
        g_settings_set(priv->settings, "window-size", "(ii)", width, height);
        g_settings_set(priv->settings, "is-maximized", "b", maximized);
        g_clear_object(&priv->settings);
    } else {
        g_debug("Settings instance unavailable, failed to save state");
    }
    return GTK_WINDOW_CLASS(font_manager_application_window_parent_class)->close_request(window);
}

static void
font_manager_application_window_quit (GtkWidget                *widget,
                                      G_GNUC_UNUSED const char *action_name,
                                      G_GNUC_UNUSED GVariant   *parameter)
{
    g_return_if_fail(widget != NULL);
    gtk_window_close(GTK_WINDOW(widget));
    return;
}

static void
font_manager_application_window_get_property (GObject    *gobject,
                                              guint       property_id,
                                              GValue     *value,
                                              GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerApplicationWindow *self = FONT_MANAGER_APPLICATION_WINDOW(gobject);
    FontManagerApplicationWindowPrivate *priv;
    priv = font_manager_application_window_get_instance_private(self);
    switch (property_id) {
        case PROP_SETTINGS:
            g_value_set_object(value, priv->settings);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_application_window_set_property (GObject      *gobject,
                                              guint         property_id,
                                              const GValue *value,
                                              GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerApplicationWindow *self = FONT_MANAGER_APPLICATION_WINDOW(gobject);
    FontManagerApplicationWindowPrivate *priv;
    priv = font_manager_application_window_get_instance_private(self);
    switch (property_id) {
        case PROP_SETTINGS:
            g_set_object(&priv->settings, G_SETTINGS(g_value_get_object(value)));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_application_window_class_init (FontManagerApplicationWindowClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);
    GtkWindowClass *window_class = GTK_WINDOW_CLASS(klass);
    window_class->close_request = font_manager_application_window_on_close_request;
    object_class->dispose = font_manager_application_window_dispose;
    object_class->get_property = font_manager_application_window_get_property;
    object_class->set_property = font_manager_application_window_set_property;

    gtk_widget_class_install_action(widget_class,
                                    "about",
                                    NULL,
                                    font_manager_application_window_about);

    gtk_widget_class_install_action(widget_class,
                                    "help",
                                    NULL,
                                    font_manager_application_window_help);

    gtk_widget_class_install_action(widget_class,
                                    "quit",
                                    NULL,
                                    font_manager_application_window_quit);

    gtk_widget_class_add_binding_action(widget_class,
                                        GDK_KEY_F1,
                                        0,
                                        "help", NULL);

    gtk_widget_class_add_binding_action(widget_class,
                                        GDK_KEY_q,
                                        GDK_CONTROL_MASK,
                                        "quit", NULL);

    gtk_widget_class_add_binding_action(widget_class,
                                        GDK_KEY_w,
                                        GDK_CONTROL_MASK,
                                        "quit", NULL);

    /**
     * FontManagerApplicationWindow:settings:
     *
     * The following keys MUST be present in @settings:
     *
     *  - window-size   : (int, int)
     *  - is-maximized  : boolean
     */
    g_object_class_install_property(object_class,
                                    PROP_SETTINGS,
                                    g_param_spec_object("settings",
                                                        NULL,
                                                        "#GSettings instance to use",
                                                        G_TYPE_SETTINGS,
                                                        G_PARAM_STATIC_STRINGS |
                                                        G_PARAM_READWRITE));

    return;
}

static void
font_manager_application_window_init (FontManagerApplicationWindow *self)
{
    font_manager_set_application_style();
    return;
}

/**
 * font_manager_application_window_restore_state:
 * @self:       #FontManagerApplicationWindow
 */
void
font_manager_application_window_restore_state (FontManagerApplicationWindow *self)
{
    FontManagerApplicationWindowPrivate *priv;
    priv = font_manager_application_window_get_instance_private(self);
    gint width, height;
    gboolean maximized;
    if (priv->settings) {
        g_settings_get(priv->settings, "window-size", "(ii)", &width, &height);
        g_settings_get(priv->settings, "is-maximized", "b", &maximized);
        g_debug("Restoring state : Window size : %i x %i", width, height);
        g_debug("Restoring state : Window is maximized : %s", maximized ? "TRUE" : "FALSE");
        gtk_window_set_default_size(GTK_WINDOW(self), width, height);
        g_object_set(self, "maximized", maximized, NULL);
    } else {
        g_debug("Settings instance unavailable, failed to restore state");
    }
    return;
}

#define PACKAGE_LICENSE \
"              This program is free software: you can redistribute it and/or modify\n" \
"              it under the terms of the GNU General Public License as published by\n" \
"              the Free Software Foundation, either version 3 of the License, or\n" \
"              (at your option) any later version.\n" \
"\n" \
"              This program is distributed in the hope that it will be useful,\n" \
"              but WITHOUT ANY WARRANTY; without even the implied warranty of\n" \
"              MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n" \
"              GNU General Public License for more details.\n" \
"\n" \
"              You should have received a copy of the GNU General Public License\n" \
"              along with this program.\n" \
"\n" \
"              If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.\n"

/**
 * font_manager_application_window_show_about:
 * @self:       #FontManagerApplicationWindow
 *
 * Show "About" dialog
 */
void
font_manager_application_window_show_about (FontManagerApplicationWindow *self)
{
    g_return_if_fail(self);

    const char *authors[] = {
        "Jerry Casiano <JerryCasiano@gmail.com>",
        NULL
    };

    gtk_show_about_dialog(GTK_WINDOW(self),
                          "program-name", _("Font Manager"),
                          "logo-icon-name", "com.github.FontManager.FontManager",
                          "version", PACKAGE_VERSION,
                          "copyright", "Copyright © 2009-2024 Jerry Casiano",
                          "comments",  _("Simple font management for GTK+ desktop environments"),
                          "website", PACKAGE_URL,
                          "authors", authors,
                          "documenters", authors,
                          "license", PACKAGE_LICENSE,
                          "translator-credits", _("translator-credits"),
                          NULL
                          );
    return;
}

/**
 * font_manager_application_window_show_help:
 * @self:       #FontManagerApplicationWindow
 *
 * Attempts to launch default help application (Yelp)
 */
void
font_manager_application_window_show_help (FontManagerApplicationWindow *self)
{
    g_return_if_fail(self);
    g_autofree gchar *uri = g_strdup_printf("help:%s", PACKAGE_NAME);
    g_autoptr(GtkUriLauncher) launcher = gtk_uri_launcher_new(uri);
    gtk_uri_launcher_launch(launcher, GTK_WINDOW(self), NULL, NULL, NULL);
    return;
}

/**
 * font_manager_application_window_new:
 * @settings:   #Gsettings instance to use or %NULL
 *
 * The following keys MUST be present in @settings:
 *
 *  - window-size   : (int, int)
 *  - is-maximized  : boolean
 *
 * Returns: (transfer full): A newly created #FontManagerApplicationWindow
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_application_window_new (GSettings *settings)
{
    return g_object_new(FONT_MANAGER_TYPE_APPLICATION_WINDOW, "settings", settings, NULL);
}


