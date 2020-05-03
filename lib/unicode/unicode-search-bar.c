/* unicode-search-bar.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017 - 2020 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
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

#include <stdlib.h>
#include <string.h>

#include "unicode-search-bar.h"

#define UI_RESOURCE_PATH "/ui/unicode-search-bar.ui"

typedef enum
{
    UNICODE_SEARCH_DIRECTION_BACKWARD = -1,
    UNICODE_SEARCH_DIRECTION_FORWARD = 1
}
UnicodeSearchDirection;

typedef struct _UnicodeSearchState UnicodeSearchState;

struct _UnicodeSearchState
{
    UnicodeSearchDirection direction;
    UnicodeCodepointList *codepoint_list;
    gint start_index;
    gint curr_index;
    gint match;       /* index of the found character */
    gint search_string_value;
    gint search_index_nfc;
    gint search_index_nfd;
    gint search_string_nfc_len;
    gint search_string_nfd_len;
    gboolean searching;
    /* true if there are known to be no matches,
     * or there is known to be exactly one match and it has been found */
    gboolean search_complete;
    gboolean prepped;
    gchar *search_string;
    gchar *search_string_nfd;
    gchar *search_string_nfc;
};


struct _UnicodeSearchBar
{
    GtkSearchBar parent_instance;

    GtkEntry *entry;
    GtkButton *next_button;
    GtkButton *prev_button;

    UnicodeCharacterMap *charmap;
    UnicodeSearchState  *search_state;
};

G_DEFINE_TYPE(UnicodeSearchBar, unicode_search_bar, GTK_TYPE_SEARCH_BAR)

enum
{
    PROP_RESERVED,
    PROP_CHARMAP,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = {0};

#define DEFAULT_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

static const gchar *
utf8_strcasestr (const gchar *haystack, const gchar *needle)
{
    const gchar *p, *q, *r;
    gint needle_len = strlen(needle);
    gint haystack_len = strlen(haystack);

    for (p = haystack;  p + needle_len <= haystack + haystack_len;  p = g_utf8_next_char(p)) {

        gboolean match = TRUE;

        for (q = needle, r = p;  *q && *r;  q = g_utf8_next_char(q), r = g_utf8_next_char(r)) {
            gunichar lc0 = g_unichar_tolower (g_utf8_get_char(r));
            gunichar lc1 = g_unichar_tolower (g_utf8_get_char(q));
            if (lc0 != lc1) {
                match = FALSE;
                break;
            }
        }

        if (match)
            return p;

    }

    return NULL;
}

static gboolean
found_in_array (const gchar **haystack_arr, const gchar *search_string_nfd)
{
    gboolean matched = FALSE;
    if (haystack_arr) {
        for (gint i = 0; haystack_arr[i] != NULL; i++) {
            g_autofree gchar *haystack_nfd = g_utf8_normalize(haystack_arr[i], -1, G_NORMALIZE_NFD);
            matched = utf8_strcasestr(haystack_nfd, search_string_nfd) != NULL;
            if (matched)
                break;
        }
        g_free(haystack_arr);
    }
    return matched;
}

static gboolean
matches (gunichar wc, const gchar *search_string_nfd)
{
    const gchar *haystack;
    gboolean matched = FALSE;

    haystack = unicode_get_codepoint_data_name(wc);
    if (haystack) {
        /* character names are ascii, so are nfd */
        gchar *haystack_nfd = (gchar *) haystack;
        matched = utf8_strcasestr(haystack_nfd, search_string_nfd) != NULL;
    }

    if (!matched) {
        haystack = unicode_get_unicode_kDefinition(wc);
        if (haystack) {
            g_autofree gchar *haystack_nfd = g_utf8_normalize(haystack, -1, G_NORMALIZE_NFD);
            matched = utf8_strcasestr(haystack_nfd, search_string_nfd) != NULL;
        }
    }

    if (!matched)
        matched = found_in_array(unicode_get_nameslist_equals(wc), search_string_nfd);

    if (!matched)
        matched = found_in_array(unicode_get_nameslist_stars(wc), search_string_nfd);

    if (!matched)
        matched = found_in_array(unicode_get_nameslist_colons(wc), search_string_nfd);

    if (!matched)
        matched = found_in_array(unicode_get_nameslist_pounds(wc), search_string_nfd);

    /* XXX: other strings */

    return matched;
}

static gint
check_for_explicit_codepoint (const UnicodeCodepointList *codepoint_list, const gchar *string)
{
    /* Default to hex */
    gint base = 16;
    gint index = -1, offset = 0;

    const gchar *nptr;
    gchar *endptr;
    gunichar wc;

    /* Check for explicit decimal codepoint */
    if (*string == '#') {
        offset = 1;
        base = 10;
    } else if (g_ascii_strncasecmp(string, "&#", 2) == 0) {
        offset = 2;
        base = 10;
    /* Check for explicit hex codepoint */
    } else if (g_ascii_strncasecmp(string, "&#x", 3) == 0) {
        offset = 3;
    } else if (g_ascii_strncasecmp(string, "U+", 2) == 0 || g_ascii_strncasecmp(string, "0x", 2) == 0) {
        offset = 2;
    }

    nptr = string + offset;

    if (nptr != string) {
        wc = strtoul(nptr, &endptr, base);
        if (endptr != nptr)
            index = unicode_codepoint_list_get_index((UnicodeCodepointList *) codepoint_list, wc);
    }

    /* Check for hex codepoint without any prefix. */
    if (index < 0 && base > 10) {
        wc = strtoul(string, &endptr, base);
        if (endptr-3 >= string)
            index = unicode_codepoint_list_get_index((UnicodeCodepointList *) codepoint_list, wc);
    }

    return index;
}

static gboolean
quick_checks_before (UnicodeSearchState *search_state)
{
    if (search_state->search_complete)
        return TRUE;

    if (search_state->prepped)
        return FALSE;

    search_state->prepped = TRUE;

    g_return_val_if_fail(search_state->search_string_nfd != NULL, FALSE);
    g_return_val_if_fail(search_state->search_string_nfc != NULL, FALSE);

    if (search_state->search_string_nfd[0] == '\0') {
        search_state->search_complete = TRUE;
        return TRUE;
    }

    /* if NFD of the search string is a single character, jump to that */
    if (search_state->search_string_nfd_len == 1 && search_state->search_index_nfd != -1) {
        search_state->match = search_state->curr_index = search_state->search_index_nfd;
        search_state->search_complete = TRUE;
        return TRUE;
    }

    /* if NFC of the search string is a single character, jump to that */
    if (search_state->search_string_nfc_len == 1 && search_state->search_index_nfc != -1) {
        search_state->match = search_state->curr_index = search_state->search_index_nfc;
        search_state->search_complete = TRUE;
        return TRUE;
    }

    return FALSE;
}

static gboolean
quick_checks_after (UnicodeSearchState *search_state)
{
    /* jump to the first nonspace character unless it’s plain ascii */
    if (search_state->search_string_nfd[0] < 0x20 || search_state->search_string_nfd[0] > 0x7e) {
        gint index = unicode_codepoint_list_get_index (search_state->codepoint_list, g_utf8_get_char (search_state->search_string_nfd));
        if (index != -1) {
            search_state->match = index;
            search_state->search_complete = TRUE;
            return TRUE;
        }
    }

    return FALSE;
}

static gboolean
idle_search (UnicodeSearchBar *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    gunichar wc;
    GTimer *timer;

    if (quick_checks_before (self->search_state))
        return FALSE;

    timer = g_timer_new ();

    gint n_chars = unicode_codepoint_list_get_last_index(self->search_state->codepoint_list) + 1;

    do {
        self->search_state->curr_index = (self->search_state->curr_index + self->search_state->direction + n_chars) % n_chars;
        wc = unicode_codepoint_list_get_char (self->search_state->codepoint_list, self->search_state->curr_index);

        if (!unicode_unichar_validate (wc) || !unicode_unichar_isdefined (wc))
            continue;

        /* check for explicit codepoint */
        if (self->search_state->search_string_value != -1 && self->search_state->curr_index == self->search_state->search_string_value) {
            self->search_state->match = self->search_state->curr_index;
            self->search_state->search_complete = TRUE;
            g_timer_destroy (timer);
            return FALSE;
        }

        /* check for other matches */
        if (matches(wc, self->search_state->search_string_nfd)) {
            self->search_state->match = self->search_state->curr_index;
            g_timer_destroy (timer);
            return FALSE;
        }

        if (g_timer_elapsed (timer, NULL) > 0.050) {
            g_timer_destroy (timer);
            return TRUE;
        }

    } while (self->search_state->curr_index != self->search_state->start_index);

    g_timer_destroy (timer);

    if (quick_checks_after (self->search_state))
        return FALSE;

    self->search_state->search_complete = TRUE;

    return FALSE;
}

/**
 * unicode_search_state_free:
 * @search_state:
 **/
static void
unicode_search_state_free (UnicodeSearchState *search_state)
{
    g_object_unref(search_state->codepoint_list);
    g_free(search_state->search_string);
    g_free(search_state->search_string_nfd);
    g_free(search_state->search_string_nfc);
    g_slice_free(UnicodeSearchState, search_state);
}

/**
 * unicode_search_state_new:
 * @codepoint_list: a #UnicodeCodepointList to be searched
 * @search_string: the text to search for
 * @start_index: the starting point within @codepoint_list
 * @direction: forward or backward
 *
 * Initializes a #UnicodeSearchState to search for the next character in
 * the codepoint list that matches @search_string. Assumes input is valid.
 *
 * Return value: the new #UnicodeSearchState.
 **/
static UnicodeSearchState *
unicode_search_state_new (UnicodeCodepointList *codepoint_list,
                          const gchar *search_string,
                          gint start_index,
                          UnicodeSearchDirection direction)
{
    UnicodeSearchState *search_state = g_slice_new (UnicodeSearchState);
    search_state->codepoint_list = g_object_ref (codepoint_list);
    search_state->direction = direction;
    search_state->prepped = FALSE;
    search_state->match = -1;
    search_state->search_complete = FALSE;
    search_state->start_index = start_index;
    search_state->curr_index = start_index;
    search_state->search_string = g_strstrip(g_strdup(search_string));

    /* NFD */
    search_state->search_string_nfd = g_utf8_normalize(search_string, -1, G_NORMALIZE_NFD);
    search_state->search_string_nfd_len = g_utf8_strlen(search_state->search_string_nfd, -1);

    if (search_state->search_string_nfd_len == 1)
        search_state->search_index_nfd = unicode_codepoint_list_get_index(search_state->codepoint_list, g_utf8_get_char(search_state->search_string_nfd));
    else
        search_state->search_index_nfd = -1;

    /* NFC */
    search_state->search_string_nfc = g_utf8_normalize(search_state->search_string_nfd, -1, G_NORMALIZE_NFC);
    search_state->search_string_nfc_len = g_utf8_strlen (search_state->search_string_nfc, -1);

    if (search_state->search_string_nfc_len == 1)
        search_state->search_index_nfc = unicode_codepoint_list_get_index(search_state->codepoint_list, g_utf8_get_char(search_state->search_string_nfc));
    else
        search_state->search_index_nfc = -1;

    /* INDEX */
    search_state->search_string_value = check_for_explicit_codepoint(search_state->codepoint_list, search_state->search_string_nfd);
    search_state->searching = FALSE;
    return search_state;
}

static void
set_action_visibility (UnicodeSearchBar *self, gboolean visible)
{
    g_return_if_fail(self != NULL);
    gtk_widget_set_visible(GTK_WIDGET(self->prev_button), visible);
    gtk_widget_set_visible(GTK_WIDGET(self->next_button), visible);
    return;
}

static void
search_completed (UnicodeSearchBar *self)
{
    g_return_if_fail(self != NULL && self->charmap != NULL);
    UnicodeSearchState *search_state = self->search_state;
    gunichar found_char = -1;

    if (search_state->match >= 0)
        found_char = unicode_codepoint_list_get_char(search_state->codepoint_list, search_state->match);

    search_state->searching = FALSE;
    unicode_character_map_set_active_character(self->charmap, found_char);
    set_action_visibility(self, !search_state->search_complete);
    return;
}

static void
unicode_search_start (UnicodeSearchBar *self, UnicodeSearchDirection direction)
{
    g_return_if_fail(self != NULL && self->charmap != NULL);

    gint start_index;
    gunichar start_char;
    g_autoptr(UnicodeCodepointList) codepoint_list = NULL;

    if (self->search_state && self->search_state->searching) /* Already searching */
        return;

    codepoint_list = g_object_ref(unicode_character_map_get_codepoint_list(self->charmap));
    if (!codepoint_list)
        return;

    if (self->search_state == NULL
        || codepoint_list != self->search_state->codepoint_list
        || strcmp (self->search_state->search_string, gtk_entry_get_text(GTK_ENTRY(self->entry))) != 0 ) {

        if (self->search_state) {
            unicode_search_state_free(self->search_state);
            self->search_state = NULL;
        }

        start_char = unicode_character_map_get_active_character(self->charmap);
        start_index = unicode_codepoint_list_get_index(codepoint_list, start_char);
        self->search_state = unicode_search_state_new(codepoint_list,
                                                      gtk_entry_get_text(GTK_ENTRY(self->entry)),
                                                      start_index, direction );
    } else {
        start_char = unicode_character_map_get_active_character (self->charmap);
        self->search_state->start_index = unicode_codepoint_list_get_index (codepoint_list, start_char);
        self->search_state->curr_index = self->search_state->start_index;
        self->search_state->direction = direction;
    }

    self->search_state->searching = TRUE;
    g_idle_add_full(G_PRIORITY_DEFAULT_IDLE, (GSourceFunc) idle_search, self, (GDestroyNotify) search_completed);
    return;
}

static void
on_prev_button_clicked (UnicodeSearchBar *self, G_GNUC_UNUSED GtkWidget *widget) {
    unicode_search_start(self, UNICODE_SEARCH_DIRECTION_BACKWARD);
    return;
}

static void
on_next_button_clicked (UnicodeSearchBar *self, G_GNUC_UNUSED GtkWidget *widget) {
    unicode_search_start(self, UNICODE_SEARCH_DIRECTION_FORWARD);
    return;
}

static void
on_map_event (UnicodeSearchBar *self,
              G_GNUC_UNUSED GdkEvent *event,
              G_GNUC_UNUSED GtkWidget *widget)
{
    gtk_widget_grab_focus(GTK_WIDGET(self->entry));
    return;
}

static guint search_timeout = 0;

static gboolean
_entry_changed (UnicodeSearchBar *self)
{
    unicode_search_start(self, UNICODE_SEARCH_DIRECTION_FORWARD);
    search_timeout = 0;
    return FALSE;
}

static void
entry_changed (UnicodeSearchBar *self, G_GNUC_UNUSED GtkWidget *widget)
{
    g_return_if_fail(self != NULL && self->charmap != NULL);
    set_action_visibility(self, FALSE);
    g_autofree gchar *entry_text = g_strstrip(g_strdup(gtk_entry_get_text(self->entry)));

    if (strlen(entry_text) != 0) {
        if (search_timeout > 0) {
            g_source_remove(search_timeout);
            search_timeout = 0;
        }
        search_timeout = g_timeout_add(500, (GSourceFunc) _entry_changed, self);
    } else {
        UnicodeCodepointList *codepoint_list = unicode_character_map_get_codepoint_list(self->charmap);
        gunichar first_char = unicode_codepoint_list_get_char(codepoint_list, 0);
        unicode_character_map_set_active_character(self->charmap, first_char);
    }

    return;
}

static void
unicode_search_bar_set_property (GObject *gobject,
                                 guint prop_id,
                                 const GValue *value,
                                 GParamSpec *pspec)
{
    UnicodeSearchBar *self = UNICODE_SEARCH_BAR(gobject);
    switch (prop_id) {
        case PROP_CHARMAP:
            g_set_object(&self->charmap, g_value_get_object(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
unicode_search_bar_get_property (GObject *gobject,
                                 guint prop_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
    UnicodeSearchBar *self = UNICODE_SEARCH_BAR(gobject);
    switch (prop_id) {
        case PROP_CHARMAP:
            g_value_set_object(value, self->charmap);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
unicode_search_bar_constructed (GObject *gobject)
{
    UnicodeSearchBar *self = UNICODE_SEARCH_BAR(gobject);
    set_action_visibility(self, FALSE);
    g_signal_connect_swapped(self->entry, "search-changed", G_CALLBACK(entry_changed), self);
    g_signal_connect_swapped(self->entry, "previous-match", G_CALLBACK(on_prev_button_clicked), self);
    g_signal_connect_swapped(self->entry, "next-match", G_CALLBACK(on_next_button_clicked), self);
    g_signal_connect_swapped(self->entry, "map", G_CALLBACK(on_map_event), self);
    g_signal_connect_swapped(self->prev_button, "clicked", G_CALLBACK(on_prev_button_clicked), self);
    g_signal_connect_swapped(self->next_button, "clicked", G_CALLBACK(on_next_button_clicked), self);
    G_OBJECT_CLASS(unicode_search_bar_parent_class)->constructed(gobject);
    return;
}

static void
unicode_search_bar_init (UnicodeSearchBar *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_init_template(GTK_WIDGET(self));
    self->charmap = NULL;
    return;
}

static void
unicode_search_bar_finalize (GObject *object)
{
    g_return_if_fail(object != NULL);
    UnicodeSearchBar *self = UNICODE_SEARCH_BAR(object);

    if (self->search_state) {
        unicode_search_state_free(self->search_state);
        self->search_state = NULL;
    }

    if (self->charmap)
        g_clear_object(&self->charmap);

    G_OBJECT_CLASS(unicode_search_bar_parent_class)->finalize(object);
    return;
}

static void
unicode_search_bar_class_init (UnicodeSearchBarClass *klass)
{
    g_return_if_fail(klass != NULL);
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->constructed = unicode_search_bar_constructed;
    object_class->finalize = unicode_search_bar_finalize;
    object_class->get_property = unicode_search_bar_get_property;
    object_class->set_property = unicode_search_bar_set_property;

    gtk_widget_class_set_template_from_resource(widget_class, UI_RESOURCE_PATH);
    gtk_widget_class_bind_template_child(widget_class, UnicodeSearchBar, entry);
    gtk_widget_class_bind_template_child(widget_class, UnicodeSearchBar, next_button);
    gtk_widget_class_bind_template_child(widget_class, UnicodeSearchBar, prev_button);

    obj_properties[PROP_CHARMAP] = g_param_spec_object("charmap",
                                                        NULL, NULL,
                                                        G_TYPE_OBJECT,
                                                        DEFAULT_PARAM_FLAGS);

    g_object_class_install_property(object_class, PROP_CHARMAP, obj_properties[PROP_CHARMAP]);

    return;
}

/**
 * unicode_search_bar_new:
 *
 * Returns: (transfer full): a new #UnicodeSearchBar
 */
UnicodeSearchBar *
unicode_search_bar_new (void)
{
    return g_object_new(UNICODE_TYPE_SEARCH_BAR, NULL);
}

