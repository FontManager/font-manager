/* font-manager-progress-data.c
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

#include "font-manager-progress-data.h"

struct _FontManagerProgressData
{
    GObjectClass parent_class;
};

typedef struct
{
    guint processed;
    guint total;
    gchar *message;
}
FontManagerProgressDataPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (FontManagerProgressData, font_manager_progress_data, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_PROCESSED,
    PROP_TOTAL,
    PROP_MESSAGE,
    PROP_PROGRESS,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_progress_data_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerProgressData *self = FONT_MANAGER_PROGRESS_DATA(gobject);
    FontManagerProgressDataPrivate *priv = font_manager_progress_data_get_instance_private(self);
    g_clear_pointer(&priv->message, g_free);
    G_OBJECT_CLASS(font_manager_progress_data_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_progress_data_get_property (GObject *gobject,
                                         guint property_id,
                                         GValue *value,
                                         GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerProgressData *self = FONT_MANAGER_PROGRESS_DATA(gobject);
    FontManagerProgressDataPrivate *priv = font_manager_progress_data_get_instance_private(self);
    switch (property_id) {
        case PROP_PROCESSED:
            g_value_set_uint(value, priv->processed);
            break;
        case PROP_TOTAL:
            g_value_set_uint(value, priv->total);
            break;
        case PROP_MESSAGE:
            g_value_set_string(value, priv->message);
            break;
        case PROP_PROGRESS:
            ; /* Empty statement */
            gdouble fraction = ((gdouble) priv->processed / (gdouble) priv->total);
            g_value_set_double(value, fraction);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_progress_data_set_property (GObject *gobject,
                                         guint property_id,
                                         const GValue *value,
                                         GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerProgressData *self = FONT_MANAGER_PROGRESS_DATA(gobject);
    FontManagerProgressDataPrivate *priv = font_manager_progress_data_get_instance_private(self);
    switch (property_id) {
        case PROP_PROCESSED:
            priv->processed = g_value_get_uint(value);
            break;
        case PROP_TOTAL:
            priv->total = g_value_get_uint(value);
            break;
        case PROP_MESSAGE:
            if (priv->message)
                g_free(priv->message);
            priv->message = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_progress_data_class_init (FontManagerProgressDataClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = font_manager_progress_data_dispose;
    object_class->get_property = font_manager_progress_data_get_property;
    object_class->set_property = font_manager_progress_data_set_property;

    /**
     * FontManagerProgressData::processed:
     *
     * Amount processed so far
     */
    obj_properties[PROP_PROCESSED] = g_param_spec_uint("processed", NULL, NULL,
                                                        0, G_MAXUINT, 0,
                                                        G_PARAM_READWRITE);

    /**
     * FontManagerProgressData::total:
     *
     * Total amount to process
     */
    obj_properties[PROP_TOTAL] = g_param_spec_uint("total", NULL, NULL,
                                                    0, G_MAXUINT, 0,
                                                    G_PARAM_READWRITE);

    /**
     * FontManagerProgressData::message:
     *
     * String suitable for display
     */
    obj_properties[PROP_MESSAGE] = g_param_spec_string("message", NULL, NULL,
                                                        NULL,
                                                        G_PARAM_READWRITE);

    /**
     * FontManagerProgressData::progress:
     *
     * Progress as fraction between 0.0 - 1.0
     */
    obj_properties[PROP_PROGRESS] = g_param_spec_double("progress", NULL, NULL,
                                                        G_MINDOUBLE, G_MAXDOUBLE, G_MINDOUBLE,
                                                        G_PARAM_READABLE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_progress_data_init (G_GNUC_UNUSED FontManagerProgressData *self)
{
    return;
}

/**
 * font_manager_progress_data_new:
 * @message: (nullable): string suitable for display
 * @processed:  amount processed so far
 * @total:      total amount to process
 *
 * Returns: (transfer full): #FontManagerProgressData
 * Use #g_object_unref to free the result.
 */
FontManagerProgressData *
font_manager_progress_data_new (const gchar *message, guint processed, guint total)
{
    FontManagerProgressData *self = g_object_new(FONT_MANAGER_TYPE_PROGRESS_DATA, NULL);
    FontManagerProgressDataPrivate *priv = font_manager_progress_data_get_instance_private(self);
    if (message)
        priv->message = g_strdup(message);
    priv->processed = processed;
    priv->total = total;
    return self;
}

