/* unicode-script-codepoint-list.c
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
#include "unicode-scripts.h"
#include "unicode-codepoint-list.h"
#include "unicode-script-codepoint-list.h"


struct _UnicodeScriptCodepointList
{
    GObject parent_instance;
    GPtrArray *ranges;
};

static void unicode_script_codepoint_list_interface_init (UnicodeCodepointListInterface *iface);

G_DEFINE_TYPE_WITH_CODE(UnicodeScriptCodepointList, unicode_script_codepoint_list, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(UNICODE_TYPE_CODEPOINT_LIST, unicode_script_codepoint_list_interface_init))


typedef struct
{
    gint index;   /* index of @start in the codepoint list */
    gunichar start;
    gunichar end;
}
UnicodeRange;

static void
ensure_initialized (UnicodeScriptCodepointList *self)
{
    if (self->ranges == NULL)
        g_assert(unicode_script_codepoint_list_set_script(self, "Latin"));
    return;
}

static gunichar
get_char (UnicodeScriptCodepointList *self, gint index)
{
    UnicodeScriptCodepointList *_self = UNICODE_SCRIPT_CODEPOINT_LIST(self);

    gint min, mid, max;

    ensure_initialized(_self);

    min = 0;
    max = _self->ranges->len - 1;

    while (max >= min) {

        UnicodeRange *range;

        mid = (min + max) / 2;
        range = (UnicodeRange *) (_self->ranges->pdata[mid]);

        if (index > (gint) (range->index + range->end - range->start))
            min = mid + 1;
        else if (index < range->index)
            max = mid - 1;
        else
            return range->start + index - range->index;
    }

    return (gunichar)(-1);
}

/* XXX: linear search */
static gint
get_index (UnicodeScriptCodepointList *self, gunichar wc)
{
    UnicodeScriptCodepointList *_self = UNICODE_SCRIPT_CODEPOINT_LIST(self);

    ensure_initialized(_self);

    for (guint i = 0;  i < _self->ranges->len;  i++) {
        UnicodeRange *range = (UnicodeRange *) _self->ranges->pdata[i];
        if (wc >= range->start && wc <= range->end)
            return range->index + wc - range->start;
    }

    return -1;
}

static gint
get_last_index (UnicodeScriptCodepointList *self)
{
    UnicodeScriptCodepointList *_self = UNICODE_SCRIPT_CODEPOINT_LIST(self);

    ensure_initialized(_self);
    UnicodeRange *last_range = (UnicodeRange *) (_self->ranges->pdata[_self->ranges->len-1]);
    return last_range->index + last_range->end - last_range->start;
}

static void
unicode_script_codepoint_list_interface_init (UnicodeCodepointListInterface *iface)
{
    iface->get_char = get_char;
    iface->get_index = get_index;
    iface->get_last_index = get_last_index;
    return;
}

static gint
find_script (const gchar *script)
{
    gint min, mid, max;

    min = 0;
    max = G_N_ELEMENTS(unicode_script_list_offsets) - 1;

    while (max >= min) {

        mid = (min + max) / 2;

        if (g_strcmp0(script, unicode_script_list_strings + unicode_script_list_offsets[mid]) > 0)
            min = mid + 1;
        else if (g_strcmp0(script, unicode_script_list_strings + unicode_script_list_offsets[mid]) < 0)
            max = mid - 1;
        else
            return mid;

    }

    return -1;
}

/* XXX: *ranges should be freed by caller */
static gboolean
get_chars_for_script (const gchar *script, UnicodeRange **ranges, gint *size)
{
    guint i, prev_end;
    gint j, index, script_index, common_script_index;

    script_index = find_script(script);
    /* Unlisted characters are added to "Common" script */
    common_script_index = find_script("Common");

    if (script_index == -1)
        return FALSE;

    j = 0;

    if (script_index == common_script_index) {
        prev_end = -1;
        for (i = 0;  i < G_N_ELEMENTS(unicode_scripts);  i++) {
            if (unicode_scripts[i].start > prev_end + 1)
                j++;
            prev_end = unicode_scripts[i].end;
        }
        if (unicode_scripts[i-1].end < UNICHAR_MAX)
            j++;
    }

    for (i = 0;  i < G_N_ELEMENTS (unicode_scripts);  i++)
        if (unicode_scripts[i].script_index == script_index)
            j++;

    *size = j;
    *ranges = g_new(UnicodeRange, *size);

    j = 0, index = 0, prev_end = -1;

    for (i = 0;  i < G_N_ELEMENTS(unicode_scripts);  i++) {
        if (script_index == common_script_index) {
            if (unicode_scripts[i].start > prev_end + 1) {
                (*ranges)[j].start = prev_end + 1;
                (*ranges)[j].end = unicode_scripts[i].start - 1;
                (*ranges)[j].index = index;
                index += (*ranges)[j].end - (*ranges)[j].start + 1;
                j++;
            }

            prev_end = unicode_scripts[i].end;
        }

        if (unicode_scripts[i].script_index == script_index) {
            (*ranges)[j].start = unicode_scripts[i].start;
            (*ranges)[j].end = unicode_scripts[i].end;
            (*ranges)[j].index = index;
            index += (*ranges)[j].end - (*ranges)[j].start + 1;
            j++;
        }
    }

    if (script_index == common_script_index) {
        if (unicode_scripts[i-1].end < UNICHAR_MAX) {
            (*ranges)[j].start = unicode_scripts[i-1].end + 1;
            (*ranges)[j].end = UNICHAR_MAX;
            (*ranges)[j].index = index;
            j++;
        }
    }


    g_assert (j == *size);

    return TRUE;
}

static void
clear_ranges (GPtrArray *ranges)
{
    guint n = ranges->len;
    for (guint i = 0; i < n; ++i)
        g_free(g_ptr_array_index(ranges, i));
    g_ptr_array_set_size(ranges, 0);
    return;
}

static void
unicode_script_codepoint_list_finalize (GObject *object)
{
    UnicodeScriptCodepointList *self = UNICODE_SCRIPT_CODEPOINT_LIST(object);

    if (self->ranges) {
        clear_ranges(self->ranges);
        g_ptr_array_free(self->ranges, TRUE);
    }

    G_OBJECT_CLASS(unicode_script_codepoint_list_parent_class)->finalize(object);
    return;
}

static void
unicode_script_codepoint_list_class_init (UnicodeScriptCodepointListClass *klass)
{
    G_OBJECT_CLASS(klass)->finalize = unicode_script_codepoint_list_finalize;
    return;
}

static void
unicode_script_codepoint_list_init (UnicodeScriptCodepointList *self)
{
    return;
}

/**
 * unicode_script_codepoint_list_new:
 *
 * Creates a new script codepoint list. The default script is Latin.
 *
 * Return value: the newly-created #UnicodeScriptCodepointList. Use
 * g_object_unref() to free the result.
 **/
UnicodeScriptCodepointList *
unicode_script_codepoint_list_new (void)
{
    return UNICODE_SCRIPT_CODEPOINT_LIST(g_object_new(unicode_script_codepoint_list_get_type(), NULL));
}

/**
 * unicode_script_codepoint_list_set_script:
 * @self: a UnicodeScriptCodepointList
 * @script: the script name
 *
 * Sets the script for the codepoint list.
 *
 * Return value: %TRUE on success, %FALSE if there is no such script, in
 * which case the script is not changed.
 **/
gboolean
unicode_script_codepoint_list_set_script (UnicodeScriptCodepointList *self,
                                          const gchar *script)
{
    gint size;
    UnicodeRange *ranges;

    if (self->ranges)
        clear_ranges(self->ranges);
    else
        self->ranges = g_ptr_array_new();

    if (get_chars_for_script(script, &ranges, &size)) {
        for (gint j = 0; j < size; j++)
            g_ptr_array_add(self->ranges, g_memdup(ranges + j, sizeof(ranges[j])));
        g_free(ranges);
    } else {
        g_ptr_array_free(self->ranges, TRUE);
        return FALSE;
    }

    return TRUE;
}


