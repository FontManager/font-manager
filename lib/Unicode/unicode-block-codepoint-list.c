/* unicode-block-codepoint-list.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright © 2017 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02110-1301  USA
 */

#include <glib.h>

#include "unicode.h"
#include "unicode-codepoint-list.h"
#include "unicode-block-codepoint-list.h"


struct _UnicodeBlockCodepointList
{
    GObject parent_instance;

    gunichar start;
    gunichar end;
};

static void unicode_block_codepoint_list_interface_init (UnicodeCodepointListInterface *iface);

G_DEFINE_TYPE_WITH_CODE(UnicodeBlockCodepointList, unicode_block_codepoint_list, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(UNICODE_TYPE_CODEPOINT_LIST, unicode_block_codepoint_list_interface_init))


enum
{
    PROP_0,
    PROP_FIRST_CODEPOINT,
    PROP_LAST_CODEPOINT
};

static gunichar
get_char (UnicodeBlockCodepointList *_self, gint index)
{
    UnicodeBlockCodepointList *self = UNICODE_BLOCK_CODEPOINT_LIST(_self);
    return (index > (gint) (self->end - self->start)) ? (gunichar)(-1) : (gunichar) self->start + index;
}

static gint
get_index (UnicodeBlockCodepointList *_self, gunichar wc)
{
    UnicodeBlockCodepointList *self = UNICODE_BLOCK_CODEPOINT_LIST(_self);
    return (wc < self->start || wc > self->end) ? -1 : wc - self->start;
}

static gint
get_last_index (UnicodeBlockCodepointList *_self)
{
    UnicodeBlockCodepointList *self = UNICODE_BLOCK_CODEPOINT_LIST(_self);
    return self->end - self->start;
}

static void
unicode_block_codepoint_list_interface_init (UnicodeCodepointListInterface *iface)
{
    iface->get_char = get_char;
    iface->get_index = get_index;
    iface->get_last_index = get_last_index;
    return;
}

static void
unicode_block_codepoint_list_init (UnicodeBlockCodepointList *list)
{
    return;
}

static GObject *
unicode_block_codepoint_list_constructor (GType type,
                                          guint n_props,
                                          GObjectConstructParam *params)
{
    GObject *object = G_OBJECT_CLASS(unicode_block_codepoint_list_parent_class)->constructor(type, n_props, params);
    UnicodeBlockCodepointList *self = UNICODE_BLOCK_CODEPOINT_LIST(object);
    g_assert (self->start <= self->end);
    return object;
}

static void
unicode_block_codepoint_list_set_property (GObject *object,
                                           guint prop_id,
                                           const GValue *value,
                                           GParamSpec *pspec)
{
    UnicodeBlockCodepointList *self = UNICODE_BLOCK_CODEPOINT_LIST(object);

    switch (prop_id) {
        case PROP_FIRST_CODEPOINT:
            self->start = g_value_get_uint(value);
            break;
        case PROP_LAST_CODEPOINT:
            self->end = g_value_get_uint(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }
}

static void
unicode_block_codepoint_list_get_property (GObject *object,
                                           guint prop_id,
                                           GValue *value,
                                           GParamSpec *pspec)
{
    UnicodeBlockCodepointList *self = UNICODE_BLOCK_CODEPOINT_LIST(object);

    switch (prop_id) {
        case PROP_FIRST_CODEPOINT:
            g_value_set_uint(value, self->start);
            break;
        case PROP_LAST_CODEPOINT:
            g_value_set_uint(value, self->end);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }
}

static void
unicode_block_codepoint_list_class_init (UnicodeBlockCodepointListClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->constructor = unicode_block_codepoint_list_constructor;
    object_class->get_property = unicode_block_codepoint_list_get_property;
    object_class->set_property = unicode_block_codepoint_list_set_property;

    /* Not using g_param_spec_unichar on purpose, since it disallows certain
     * values we want (it's performing a g_unichar_validate).
     */
    g_object_class_install_property(object_class,
                                    PROP_FIRST_CODEPOINT,
                                    g_param_spec_uint("first-codepoint",
                                                        NULL, NULL,
                                                        0,
                                                        UNICHAR_MAX,
                                                        0,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_CONSTRUCT_ONLY |
                                                        G_PARAM_STATIC_NAME |
                                                        G_PARAM_STATIC_NICK |
                                                        G_PARAM_STATIC_BLURB));

    g_object_class_install_property(object_class,
                                    PROP_LAST_CODEPOINT,
                                    g_param_spec_uint("last-codepoint",
                                                        NULL, NULL,
                                                        0,
                                                        UNICHAR_MAX,
                                                        0,
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_CONSTRUCT_ONLY |
                                                        G_PARAM_STATIC_NAME |
                                                        G_PARAM_STATIC_NICK |
                                                        G_PARAM_STATIC_BLURB));
    return;
}

/**
 * unicode_block_codepoint_list_new:
 * @start: the first codepoint
 * @end: the last codepoint
 *
 * Creates a new codepoint list for the range @start..@end.
 *
 * Return value: the newly-created #UnicodeBlockCodepointList. Use
 * g_object_unref() to free the result.
 **/
UnicodeBlockCodepointList *
unicode_block_codepoint_list_new (gunichar start, gunichar end)
{
    g_return_val_if_fail(start <= end, NULL);
    GObject *obj = g_object_new(unicode_block_codepoint_list_get_type(),
                                 "first-codepoint", (guint) start,
                                 "last-codepoint", (guint) end,
                                 NULL);
    return UNICODE_BLOCK_CODEPOINT_LIST(obj);
}

