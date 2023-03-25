/* unicode-search-bar.c
 *
 * Originally a part of Gucharmap
 *
 * Copyright (C) 2017-2023 Jerry Casiano
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

#include "unicode-search-bar.h"

/**
 * SECTION: unicode-search-bar
 * @short_description: Search for unicode codepoints within a font
 * @title: Unicode Search Bar
 * @include: unicode-search-bar.h
 *
 * This widget provides a way to search for characters by name, value or
 * other information.
 */

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
    FontManagerUnicodeCharacterMap *character_map;
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

struct _FontManagerUnicodeSearchBar
{
    GtkWidget parent_instance;

    GtkWidget *entry;
    GtkWidget *next_button;
    GtkWidget *prev_button;

    FontManagerUnicodeCharacterMap *character_map;
    UnicodeSearchState  *search_state;
};

G_DEFINE_TYPE(FontManagerUnicodeSearchBar, font_manager_unicode_search_bar, GTK_TYPE_WIDGET)

enum
{
    PROP_RESERVED,
    PROP_CHARMAP,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = {0};

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

    haystack = font_manager_unicode_get_codepoint_data_name(wc);
    if (haystack) {
        /* character names are ascii, so are nfd */
        gchar *haystack_nfd = (gchar *) haystack;
        matched = utf8_strcasestr(haystack_nfd, search_string_nfd) != NULL;
    }

    if (!matched) {
        haystack = font_manager_unicode_get_unicode_kDefinition(wc);
        if (haystack) {
            g_autofree gchar *haystack_nfd = g_utf8_normalize(haystack, -1, G_NORMALIZE_NFD);
            matched = utf8_strcasestr(haystack_nfd, search_string_nfd) != NULL;
        }
    }

    if (!matched)
        matched = found_in_array(font_manager_unicode_get_nameslist_equals(wc), search_string_nfd);

    if (!matched)
        matched = found_in_array(font_manager_unicode_get_nameslist_stars(wc), search_string_nfd);

    if (!matched)
        matched = found_in_array(font_manager_unicode_get_nameslist_colons(wc), search_string_nfd);

    if (!matched)
        matched = found_in_array(font_manager_unicode_get_nameslist_pounds(wc), search_string_nfd);

    return matched;
}

static gint
check_for_explicit_codepoint (FontManagerUnicodeCharacterMap *character_map, const gchar *string)
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
        if (endptr != nptr) {
            GSList *codepoints = NULL;
            codepoints = g_slist_append(codepoints, GINT_TO_POINTER(wc));
            index = font_manager_unicode_character_map_get_index(character_map, codepoints);
            g_slist_free(codepoints);
        }
    }

    /* Check for hex codepoint without any prefix. */
    if (index < 0 && base > 10) {
        wc = strtoul(string, &endptr, base);
        if (endptr-3 >= string) {
            GSList *codepoints = NULL;
            codepoints = g_slist_append(codepoints, GINT_TO_POINTER(wc));
            index = font_manager_unicode_character_map_get_index(character_map, codepoints);
            g_slist_free(codepoints);
        }
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
        GSList *codepoints = NULL;
        codepoints = g_slist_append(codepoints, GINT_TO_POINTER(g_utf8_get_char(search_state->search_string_nfd)));
        gint index = font_manager_unicode_character_map_get_index (search_state->character_map, codepoints);
        g_slist_free(codepoints);
        if (index != -1) {
            search_state->match = index;
            search_state->search_complete = TRUE;
            return TRUE;
        }
    }

    return FALSE;
}

static gboolean
idle_search (FontManagerUnicodeSearchBar *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    gunichar wc;
    GTimer *timer;

    if (quick_checks_before (self->search_state))
        return FALSE;

    timer = g_timer_new ();

    gint n_chars = font_manager_unicode_character_map_get_last_index(self->search_state->character_map);

    do {
        self->search_state->curr_index = (self->search_state->curr_index + self->search_state->direction + n_chars) % n_chars;

        /* check for explicit codepoint */
        if (self->search_state->search_string_value != -1 && self->search_state->curr_index == self->search_state->search_string_value) {
            self->search_state->match = self->search_state->curr_index;
            self->search_state->search_complete = TRUE;
            g_timer_destroy (timer);
            return FALSE;
        }

        GSList *codepoints = font_manager_unicode_character_map_get_codepoints(self->search_state->character_map, self->search_state->curr_index);

        for (GSList *iter = codepoints; iter != NULL; iter = iter->next) {

            wc = (gunichar) GPOINTER_TO_INT(iter->data);

            if (!font_manager_unicode_unichar_validate (wc))
                continue;

            /* check for other matches */
            if (matches(wc, self->search_state->search_string_nfd)) {
                self->search_state->match = self->search_state->curr_index;
                g_timer_destroy (timer);
                return FALSE;
            }

        }

        g_slist_free(codepoints);

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
 * @search_state:   #UnicodeSearchState
 **/
static void
unicode_search_state_free (UnicodeSearchState *search_state)
{
    g_object_unref(search_state->character_map);
    g_free(search_state->search_string);
    g_free(search_state->search_string_nfd);
    g_free(search_state->search_string_nfc);
    g_slice_free(UnicodeSearchState, search_state);
}

/**
 * unicode_search_state_new:
 * @character_map: a #FontManagerUnicodeCodepointList to be searched
 * @search_string: the text to search for
 * @start_index: the starting point within @character_map
 * @direction: forward or backward
 *
 * Initializes a #UnicodeSearchState to search for the next character in
 * the codepoint list that matches @search_string. Assumes input is valid.
 *
 * Return value: A newly created #UnicodeSearchState.
 * Free the returned object using #unicode_search_state_free().
 **/
static UnicodeSearchState *
unicode_search_state_new (FontManagerUnicodeCharacterMap *character_map,
                          const gchar *search_string,
                          gint start_index,
                          UnicodeSearchDirection direction)
{
    UnicodeSearchState *search_state = g_slice_new(UnicodeSearchState);
    search_state->character_map = g_object_ref(character_map);
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

    if (search_state->search_string_nfd_len == 1) {
        GSList *codepoints = NULL;
        codepoints = g_slist_append(codepoints, GINT_TO_POINTER(g_utf8_get_char(search_state->search_string_nfd)));
        search_state->search_index_nfd  = font_manager_unicode_character_map_get_index (search_state->character_map, codepoints);
        g_slist_free(codepoints);
    } else
        search_state->search_index_nfd = -1;

    /* NFC */
    search_state->search_string_nfc = g_utf8_normalize(search_state->search_string_nfd, -1, G_NORMALIZE_NFC);
    search_state->search_string_nfc_len = g_utf8_strlen (search_state->search_string_nfc, -1);

    if (search_state->search_string_nfc_len == 1) {
        GSList *codepoints = NULL;
        codepoints = g_slist_append(codepoints, GINT_TO_POINTER(g_utf8_get_char(search_state->search_string_nfc)));
        search_state->search_index_nfc  = font_manager_unicode_character_map_get_index(search_state->character_map, codepoints);
        g_slist_free(codepoints);
    } else
        search_state->search_index_nfc = -1;

    /* INDEX */
    search_state->search_string_value = check_for_explicit_codepoint(search_state->character_map, search_state->search_string_nfd);
    search_state->searching = FALSE;
    return search_state;
}

static void
set_action_visibility (FontManagerUnicodeSearchBar *self, gboolean visible)
{
    g_return_if_fail(self != NULL);
    gtk_widget_set_visible(GTK_WIDGET(self->prev_button), visible);
    gtk_widget_set_visible(GTK_WIDGET(self->next_button), visible);
    return;
}

static void
search_completed (FontManagerUnicodeSearchBar *self)
{
    g_return_if_fail(self != NULL && self->character_map != NULL);
    UnicodeSearchState *search_state = self->search_state;
    gint index = search_state->match >= 0 ? search_state->match : -1;
    search_state->searching = FALSE;
    font_manager_unicode_character_map_set_active_cell(self->character_map, index);
    set_action_visibility(self, !search_state->search_complete);
    return;
}

static void
unicode_search_start (FontManagerUnicodeSearchBar *self, UnicodeSearchDirection direction)
{
    g_return_if_fail(self != NULL && self->character_map != NULL);

    gint start_index;

    if (self->search_state && self->search_state->searching) /* Already searching */
        return;

    if (self->search_state == NULL
        || self->character_map != self->search_state->character_map
        || strcmp (self->search_state->search_string, gtk_editable_get_text(GTK_EDITABLE(self->entry))) != 0 ) {

        g_clear_pointer(&self->search_state, unicode_search_state_free);

        start_index = font_manager_unicode_character_map_get_active_cell(self->character_map);
        self->search_state = unicode_search_state_new(self->character_map,
                                                      gtk_editable_get_text(GTK_EDITABLE(self->entry)),
                                                      start_index, direction );
    } else {
        self->search_state->start_index = font_manager_unicode_character_map_get_active_cell(self->character_map);
        self->search_state->curr_index = self->search_state->start_index;
        self->search_state->direction = direction;
    }

    self->search_state->searching = TRUE;
    g_idle_add_full(G_PRIORITY_DEFAULT_IDLE, (GSourceFunc) idle_search, self, (GDestroyNotify) search_completed);
    return;
}

static void
on_prev_button_clicked (FontManagerUnicodeSearchBar *self, G_GNUC_UNUSED GtkWidget *widget) {
    unicode_search_start(self, UNICODE_SEARCH_DIRECTION_BACKWARD);
    return;
}

static void
on_next_button_clicked (FontManagerUnicodeSearchBar *self, G_GNUC_UNUSED GtkWidget *widget) {
    unicode_search_start(self, UNICODE_SEARCH_DIRECTION_FORWARD);
    return;
}

static void
on_map_event (FontManagerUnicodeSearchBar *self,
              G_GNUC_UNUSED GdkEvent *event,
              G_GNUC_UNUSED GtkWidget *widget)
{
    if (gtk_widget_get_mapped(GTK_WIDGET(self)))
        gtk_widget_grab_focus(GTK_WIDGET(self->entry));
    return;
}

static guint search_timeout = 0;

static gboolean
_entry_changed (FontManagerUnicodeSearchBar *self)
{
    unicode_search_start(self, UNICODE_SEARCH_DIRECTION_FORWARD);
    search_timeout = 0;
    return FALSE;
}

static void
entry_changed (FontManagerUnicodeSearchBar *self, G_GNUC_UNUSED GtkWidget *widget)
{
    g_return_if_fail(self != NULL && self->character_map != NULL);
    set_action_visibility(self, FALSE);
    g_autofree gchar *entry_text = g_strstrip(g_strdup(gtk_editable_get_text(GTK_EDITABLE(self->entry))));

    if (strlen(entry_text) != 0) {
        if (search_timeout > 0) {
            g_source_remove(search_timeout);
            search_timeout = 0;
        }
        search_timeout = g_timeout_add(500, (GSourceFunc) _entry_changed, self);
    } else {
        font_manager_unicode_character_map_set_active_cell(self->character_map, 0);
    }

    return;
}

static void
font_manager_unicode_search_bar_set_property (GObject *gobject,
                                              guint prop_id,
                                              const GValue *value,
                                              GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeSearchBar *self = FONT_MANAGER_UNICODE_SEARCH_BAR(gobject);
    switch (prop_id) {
        case PROP_CHARMAP:
            font_manager_unicode_search_bar_set_character_map(self, g_value_get_object(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
font_manager_unicode_search_bar_get_property (GObject *gobject,
                                              guint prop_id,
                                              GValue *value,
                                              GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeSearchBar *self = FONT_MANAGER_UNICODE_SEARCH_BAR(gobject);
    switch (prop_id) {
        case PROP_CHARMAP:
            g_value_set_object(value, self->character_map);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, prop_id, pspec);
            break;
    }
    return;
}

static void
font_manager_unicode_search_bar_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeSearchBar *self = FONT_MANAGER_UNICODE_SEARCH_BAR(gobject);
    g_clear_pointer(&self->search_state, unicode_search_state_free);
    g_clear_object(&self->character_map);
    font_manager_widget_dispose(GTK_WIDGET(gobject));
    G_OBJECT_CLASS(font_manager_unicode_search_bar_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_unicode_search_bar_constructed (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerUnicodeSearchBar *self = FONT_MANAGER_UNICODE_SEARCH_BAR(gobject);
    set_action_visibility(self, FALSE);
    g_signal_connect_swapped(self->entry, "search-changed", G_CALLBACK(entry_changed), self);
    g_signal_connect_swapped(self->entry, "previous-match", G_CALLBACK(on_prev_button_clicked), self);
    g_signal_connect_swapped(self->entry, "next-match", G_CALLBACK(on_next_button_clicked), self);
    g_signal_connect_swapped(self->entry, "map", G_CALLBACK(on_map_event), self);
    g_signal_connect_swapped(self->prev_button, "clicked", G_CALLBACK(on_prev_button_clicked), self);
    g_signal_connect_swapped(self->next_button, "clicked", G_CALLBACK(on_next_button_clicked), self);
    G_OBJECT_CLASS(font_manager_unicode_search_bar_parent_class)->constructed(gobject);
    return;
}

static void
font_manager_unicode_search_bar_class_init (FontManagerUnicodeSearchBarClass *klass)
{
    g_return_if_fail(klass != NULL);

    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->constructed = font_manager_unicode_search_bar_constructed;
    object_class->dispose = font_manager_unicode_search_bar_dispose;
    object_class->get_property = font_manager_unicode_search_bar_get_property;
    object_class->set_property = font_manager_unicode_search_bar_set_property;

    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);

    obj_properties[PROP_CHARMAP] = g_param_spec_object("character-map",
                                                        NULL,
                                                        "FontManagerUnicodeCharacterMap",
                                                        G_TYPE_OBJECT,
                                                        G_PARAM_STATIC_STRINGS |
                                                        G_PARAM_READWRITE |
                                                        G_PARAM_EXPLICIT_NOTIFY);

    g_object_class_install_property(object_class, PROP_CHARMAP, obj_properties[PROP_CHARMAP]);

    return;
}

static void
font_manager_unicode_search_bar_init (FontManagerUnicodeSearchBar *self)
{
    g_return_if_fail(self != NULL);
    self->character_map = NULL;
    GtkWidget *search_bar = gtk_search_bar_new();
    GtkWidget *center_box = gtk_center_box_new();
    self->prev_button = gtk_button_new_from_icon_name("go-previous-symbolic");
    self->entry = gtk_search_entry_new();
    self->next_button = gtk_button_new_from_icon_name("go-next-symbolic");
    gtk_center_box_set_start_widget(GTK_CENTER_BOX(center_box), self->prev_button);
    gtk_widget_set_margin_start(self->prev_button, 3);
    gtk_widget_set_margin_end(self->prev_button, 3);
    gtk_center_box_set_center_widget(GTK_CENTER_BOX(center_box), self->entry);
    gtk_center_box_set_end_widget(GTK_CENTER_BOX(center_box), self->next_button);
    gtk_widget_set_margin_start(self->next_button, 3);
    gtk_widget_set_margin_end(self->next_button, 3);
    gtk_search_bar_set_child(GTK_SEARCH_BAR(search_bar), center_box);
    gtk_search_bar_set_search_mode(GTK_SEARCH_BAR(search_bar), TRUE);
    gtk_widget_set_parent(search_bar, GTK_WIDGET(self));
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerUnicodeSearchBar");
    gtk_widget_set_opacity(self->prev_button, 0.75);
    gtk_widget_set_opacity(self->next_button, 0.75);
    font_manager_widget_set_expand(GTK_WIDGET(search_bar), TRUE);
    gtk_widget_set_hexpand(GTK_WIDGET(self), TRUE);
    gtk_widget_set_vexpand(GTK_WIDGET(self), FALSE);
    return;
}

static void
reset_search (G_GNUC_UNUSED FontManagerUnicodeCharacterMap *charmap,
              G_GNUC_UNUSED const gchar *status_message,
              FontManagerUnicodeSearchBar *self)
{
    g_return_if_fail(self != NULL);
    if (gtk_widget_get_mapped(GTK_WIDGET(self->entry)) &&
        strlen(gtk_editable_get_text(GTK_EDITABLE(self->entry))) > 0) {
        g_autofree gchar *previous_text = g_strdup(gtk_editable_get_text(GTK_EDITABLE(self->entry)));
        gtk_editable_set_text(GTK_EDITABLE(self->entry), " ");
        gtk_editable_set_text(GTK_EDITABLE(self->entry), previous_text);
    }
    return;
}

/**
 * font_manager_unicode_search_bar_set_character_map:
 * @self:                                       #FontManagerUnicodeSearchBar
 * @character_map: (transfer none) (nullable):  #FontManagerUnicodeCharacterMap
 */
void
font_manager_unicode_search_bar_set_character_map (FontManagerUnicodeSearchBar *self,
                                                   FontManagerUnicodeCharacterMap *character_map)
{
    g_return_if_fail(self != NULL);
    if (self->character_map)
        g_signal_handlers_disconnect_by_func(self->character_map, G_CALLBACK(reset_search), self);
    if (g_set_object(&self->character_map, character_map))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_CHARMAP]);
    if (self->character_map) {
        g_signal_connect_after(self->character_map, "notify::font-desc", G_CALLBACK(reset_search), self);
        g_signal_connect_after(self->character_map, "notify::codepoint-list", G_CALLBACK(reset_search), self);
    }
    return;
}

/**
 * font_manager_unicode_search_bar_new:
 *
 * Returns: (transfer full): A newly created #FontManagerUnicodeSearchBar.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_unicode_search_bar_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_UNICODE_SEARCH_BAR, NULL);
}
