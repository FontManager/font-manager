/* font-manager-source.c
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

#include "font-manager-source.h"

/**
 * SECTION: font-manager-source
 * @short_description: Font directory entry
 * @title: Font Source
 * @include: font-manager-source.h
 *
 * #FontManagerSource represents a user font directory.
 */

struct _FontManagerSource
{
    GObjectClass parent_class;
};

typedef struct
{
    gchar *name;
    gchar *path;
    gboolean active;
    GFile *file;
    GFileMonitor *monitor;
}
FontManagerSourcePrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerSource, font_manager_source, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_NAME,
    PROP_ICON_NAME,
    PROP_PATH,
    PROP_ACTIVE,
    PROP_AVAILABLE,
    PROP_FILE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

enum
{
    CHANGED,
    N_SIGNALS
};

static guint signals[N_SIGNALS];

#define DEFAULT_PARAM_FLAGS (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS)

static const gchar *_available = "folder-symbolic";
static const gchar *_unavailable = "action-unavailable-symbolic";

static void
font_manager_source_constructed (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    font_manager_source_update(FONT_MANAGER_SOURCE(gobject));
    G_OBJECT_CLASS(font_manager_source_parent_class)->constructed(gobject);
    return;
}

static void
font_manager_source_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerSource *self = FONT_MANAGER_SOURCE(gobject);
    FontManagerSourcePrivate *priv = font_manager_source_get_instance_private(self);
    g_clear_pointer(&priv->name, g_free);
    g_clear_pointer(&priv->path, g_free);
    g_clear_object(&priv->file);
    g_clear_object(&priv->monitor);
    G_OBJECT_CLASS(font_manager_source_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_source_get_property (GObject *gobject,
                                 guint property_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerSource *self = FONT_MANAGER_SOURCE(gobject);
    FontManagerSourcePrivate *priv = font_manager_source_get_instance_private(self);
    gboolean available = priv->file != NULL ? g_file_query_exists(priv->file, NULL) : FALSE;
    switch (property_id) {
        case PROP_NAME:
            g_value_set_string(value, priv->name);
            break;
        case PROP_ICON_NAME:
            g_value_set_string(value, available ? _available : _unavailable);
            break;
        case PROP_PATH:
            g_value_set_string(value, priv->path);
            break;
        case PROP_ACTIVE:
            g_value_set_boolean(value, priv->active);
            break;
        case PROP_AVAILABLE:
            g_value_set_boolean(value, available);
            break;
        case PROP_FILE:
            g_value_set_object(value, priv->file);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_source_set_property (GObject *gobject,
                                 guint property_id,
                                 const GValue *value,
                                 GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerSource *self = FONT_MANAGER_SOURCE(gobject);
    FontManagerSourcePrivate *priv = font_manager_source_get_instance_private(self);
    GFile *new_file = NULL;
    switch (property_id) {
        case PROP_ACTIVE:
            priv->active = g_value_get_boolean(value);
            break;
        case PROP_FILE:
            new_file = g_value_get_object(value);
            if (new_file == priv->file)
                return;
            if (priv->file)
                g_clear_object(&priv->file);
            priv->file = new_file ? g_object_ref(new_file) : NULL;
            font_manager_source_update(self);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_source_class_init (FontManagerSourceClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->constructed = font_manager_source_constructed;
    object_class->dispose = font_manager_source_dispose;
    object_class->get_property = font_manager_source_get_property;
    object_class->set_property = font_manager_source_set_property;

    /**
     * FontManagerSource::changed:
     * @self:           #FontManagerSource which changed
     * @file:           #GFile
     * @other_file:     #GFile
     * @event_type:     #GFileMonitorEvent
     *
     * Emitted when source has changed.
     *
     * See #GFileMonitor's #GFileMonitor::changed signal for parameter details.
     */
    signals[CHANGED] = g_signal_new(g_intern_static_string("changed"),
                                    G_TYPE_FROM_CLASS(object_class),
                                    G_SIGNAL_RUN_LAST,
                                    0,
                                    NULL, NULL, NULL,
                                    G_TYPE_NONE,
                                    3,
                                    G_TYPE_FILE,
                                    G_TYPE_FILE,
                                    G_TYPE_FILE_MONITOR_EVENT);

    /**
     * FontManagerSource:name:
     *
     * A string suitable for display in a user interface.
     */
    obj_properties[PROP_NAME] = g_param_spec_string("name",
                                                    NULL,
                                                    "Name",
                                                    NULL,
                                                    DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSource:icon-name:
     *
     * Name of icon which should be used to represent this source.
     */
    obj_properties[PROP_ICON_NAME] = g_param_spec_string("icon-name",
                                                         NULL,
                                                         "Icon name",
                                                         NULL,
                                                         DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSource:path:
     *
     * Full path to source.
     */
    obj_properties[PROP_PATH] = g_param_spec_string("path",
                                                    NULL,
                                                    "Filepath",
                                                    NULL,
                                                    DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSource:active:
     *
     * Whether source is currently active or not.
     */
    obj_properties[PROP_ACTIVE] = g_param_spec_boolean("active",
                                                       NULL,
                                                       "Whether source is enabled or not",
                                                       FALSE,
                                                       G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerSource:available:
     *
     * Whether source is currently available or not.
     */
    obj_properties[PROP_AVAILABLE] = g_param_spec_boolean("available",
                                                          NULL,
                                                          "Whether source is available or not",
                                                          FALSE,
                                                          DEFAULT_PARAM_FLAGS);

    /**
     * FontManagerSource:file:
     *
     * The #GFile backing this source
     */
    obj_properties[PROP_FILE] = g_param_spec_object("file",
                                                    NULL,
                                                    "#GFile backing this source",
                                                    G_TYPE_FILE,
                                                    G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_source_init (G_GNUC_UNUSED FontManagerSource *self)
{
    return;
}

static void
font_manager_source_emit_changed (G_GNUC_UNUSED GFileMonitor *monitor,
                                  GFile *file,
                                  GFile *other_file,
                                  GFileMonitorEvent  event_type,
                                  gpointer user_data)
{
    g_return_if_fail(user_data != NULL);
    FontManagerSource *self = FONT_MANAGER_SOURCE(user_data);
    FontManagerSourcePrivate *priv = font_manager_source_get_instance_private(self);
    if (other_file != NULL) {
        g_clear_object(&priv->file);
        priv->file = g_object_ref(G_FILE_MONITOR_EVENT_MOVED_IN ? file : other_file);
    }
    font_manager_source_update(self);
    g_signal_emit(self, signals[CHANGED], 0, file, other_file, event_type);
    return;
}

/**
 * font_manager_source_get_status_message:
 * @self:   #FontManagerSource
 *
 * Returns: (transfer full) (nullable): A newly allocated string suitable
 * for display in a user interface or %NULL. Free the result using #g_free().
 */
gchar *
font_manager_source_get_status_message (FontManagerSource *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    FontManagerSourcePrivate *priv = font_manager_source_get_instance_private(self);
    if (priv->path && !g_file_query_exists(priv->file, NULL))
        return g_strdup(priv->path);
    return priv->path != NULL ? g_path_get_dirname(priv->path) : g_strdup(_("Source Unavailable"));
}

/**
 * font_manager_source_update:
 * @self:   #FontManagerSource
 *
 * Update the status of source.
 */
void
font_manager_source_update (FontManagerSource *self)
{
    g_return_if_fail(self != NULL);
    FontManagerSourcePrivate *priv = font_manager_source_get_instance_private(self);
    g_free(priv->name);
    priv->name = g_strdup(_("Source Unavailable"));
    priv->active = FALSE;
    if (priv->file == NULL || !g_file_query_exists(priv->file, NULL))
        return;
    g_free(priv->path);
    priv->path = g_file_get_path(priv->file);
    g_autoptr(GFileInfo) fileinfo = g_file_query_info(priv->file,
                                                        G_FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME,
                                                        G_FILE_QUERY_INFO_NONE,
                                                        NULL, NULL);
    if (fileinfo != NULL) {
        g_free(priv->name);
        priv->name = g_markup_escape_text(g_file_info_get_display_name(fileinfo), -1);
    }
    if (priv->monitor)
        g_clear_object(&priv->monitor);
    priv->monitor = g_file_monitor_directory(priv->file, G_FILE_MONITOR_WATCH_MOUNTS | G_FILE_MONITOR_WATCH_MOVES, NULL, NULL);
    if (priv->monitor != NULL)
        g_signal_connect(priv->monitor, "changed", G_CALLBACK(font_manager_source_emit_changed), self);
    else
        g_warning(G_STRLOC ": Failed to create file monitor for %s", priv->path);
    return;
}

/**
 * font_manager_source_new:
 * @file: (nullable): A #GFile to create a new #FontManagerSource for.
 *
 * Returns: (transfer full): A newly created #FontManagerSource.
 * Free the returned object using #g_object_unref().
 */
FontManagerSource *
font_manager_source_new (GFile *file)
{
    return g_object_new(FONT_MANAGER_TYPE_SOURCE, "file", file, NULL);;
}

