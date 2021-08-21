/* font-manager-codepoint-list.c
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

#include "font-manager-codepoint-list.h"

/**
 * SECTION: font-manager-codepoint-list
 * @short_description: UnicodeCodepointList implementation
 * @title: Codepoint List
 * @include: font-manager-codepoint-list.h
 *
 * Codepoint list which limits results to available characters in the selected font.
 */

struct _FontManagerCodepointList
{
    GObject parent_instance;

    gboolean has_regional_indicator_symbols;
    gboolean is_regional_indicator_filter;

    GList *charset;
    GList *filter;
};

static void unicode_codepoint_list_interface_init (UnicodeCodepointListInterface *iface);

G_DEFINE_TYPE_WITH_CODE(FontManagerCodepointList, font_manager_codepoint_list, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(UNICODE_TYPE_CODEPOINT_LIST, unicode_codepoint_list_interface_init))

enum
{
    PROP_0,
    PROP_FONT_OBJECT
};

static gint
get_index (UnicodeCodepointList *_self, GSList *codepoints)
{
    g_return_val_if_fail(_self != NULL, -1);
    FontManagerCodepointList *self = FONT_MANAGER_CODEPOINT_LIST(_self);
    if (!codepoints || g_slist_length(codepoints) < 1)
        return -1;
    gunichar code1 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
    if (self->filter && self->is_regional_indicator_filter) {
        if (g_slist_length(codepoints) == 2) {
            gunichar code2 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 1));
            for (int i = 0; i < G_N_ELEMENTS(FontManagerRIS); i++)
                if (FontManagerRIS[i].code1 == code1 && FontManagerRIS[i].code2 == code2)
                    return i;
        }
        return -1;
    } else if (self->filter)
        return g_list_index(self->filter, GINT_TO_POINTER(code1));
    else
        return self->charset != NULL ? (gint) g_list_index(self->charset, GINT_TO_POINTER(code1)) : -1;
}

static gint
get_last_index (UnicodeCodepointList *_self)
{
    g_return_val_if_fail(_self != NULL, -1);
    FontManagerCodepointList *self = FONT_MANAGER_CODEPOINT_LIST(_self);
    if (self->filter && self->is_regional_indicator_filter)
        return G_N_ELEMENTS(FontManagerRIS) - 1;
    else if (self->filter)
        return g_list_length(self->filter) - 1;
    if (!self->charset)
        return -1;
    if (!self->has_regional_indicator_symbols)
        return (gint) g_list_length(self->charset) - 1;
    return (((gint) g_list_length(self->charset)) + G_N_ELEMENTS(FontManagerRIS)) - 1;
}

static GSList *
get_codepoints (UnicodeCodepointList *_self, gint index)
{
    g_return_val_if_fail(_self != NULL, NULL);
    FontManagerCodepointList *self = FONT_MANAGER_CODEPOINT_LIST(_self);
    gint base_codepoints = (gint) g_list_length(self->charset);
    GSList *results = NULL;
    if (index < base_codepoints) {
        if (self->filter && self->is_regional_indicator_filter) {
            if (index < G_N_ELEMENTS(FontManagerRIS)) {
                results = g_slist_append(results, GINT_TO_POINTER(FontManagerRIS[index].code1));
                results = g_slist_append(results, GINT_TO_POINTER(FontManagerRIS[index].code2));
            }
        } else if (self->filter)
            results = g_slist_append(results, g_list_nth_data(self->filter, index));
        else
            results = g_slist_append(results, self->charset != NULL ?
                                              g_list_nth_data(self->charset, index) :
                                              GINT_TO_POINTER(-1));
    } else if (base_codepoints > 0) {
        gint _index = index - base_codepoints;
        if (_index < G_N_ELEMENTS(FontManagerRIS)) {
            results = g_slist_append(results, GINT_TO_POINTER(FontManagerRIS[_index].code1));
            results = g_slist_append(results, GINT_TO_POINTER(FontManagerRIS[_index].code2));
        }
    }
    return results;
}

static void
unicode_codepoint_list_interface_init (UnicodeCodepointListInterface *iface)
{
    iface->get_codepoints = get_codepoints;
    iface->get_index = get_index;
    iface->get_last_index = get_last_index;
    return;
}

static void
font_manager_codepoint_list_finalize (GObject *object)
{
    FontManagerCodepointList *self = FONT_MANAGER_CODEPOINT_LIST(object);
    g_clear_pointer(&self->charset, g_list_free);
    g_clear_pointer(&self->filter, g_list_free);
    G_OBJECT_CLASS(font_manager_codepoint_list_parent_class)->finalize(object);
    return;
}

static void
font_manager_codepoint_list_init (FontManagerCodepointList *self)
{
    self->charset = NULL;
    self->filter = NULL;
    self->has_regional_indicator_symbols = FALSE;
    self->is_regional_indicator_filter = FALSE;
    return;
}

static void
font_manager_codepoint_list_set_property (GObject *object,
                                           guint prop_id,
                                           const GValue *value,
                                           GParamSpec *pspec)
{
    FontManagerCodepointList *self = FONT_MANAGER_CODEPOINT_LIST(object);

    switch (prop_id) {
        case PROP_FONT_OBJECT:
            font_manager_codepoint_list_set_font(self, g_value_get_boxed(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }
}

static void
font_manager_codepoint_list_class_init (FontManagerCodepointListClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->set_property = font_manager_codepoint_list_set_property;
    object_class->finalize = font_manager_codepoint_list_finalize;

    /**
     * FontManagerCodepointList:font: (type JsonObject) (transfer none)
     *
     * Updates the codepoint list to contain only codepoints actually present in @font.
     */
    g_object_class_install_property(object_class,
                                    PROP_FONT_OBJECT,
                                    g_param_spec_boxed("font",
                                                        NULL,
                                                        "Current font",
                                                        JSON_TYPE_OBJECT,
                                                        G_PARAM_WRITABLE |
                                                        G_PARAM_STATIC_NAME |
                                                        G_PARAM_STATIC_NICK |
                                                        G_PARAM_STATIC_BLURB));

    return;
}

static void
check_for_regional_indicator_symbols (FontManagerCodepointList *self, hb_set_t *charset)
{
    self->has_regional_indicator_symbols = FALSE;
    for (guint32 i = FONT_MANAGER_RIS_START_POINT; i < FONT_MANAGER_RIS_END_POINT; i++)
        if (!hb_set_has(charset, i))
            return;
    self->has_regional_indicator_symbols = TRUE;
    return;
}

static void
populate_charset (FontManagerCodepointList *self, JsonObject *font)
{
    hb_blob_t *blob = hb_blob_create_from_file(json_object_get_string_member(font, "filepath"));
    hb_face_t *face = hb_face_create(blob, json_object_get_int_member(font, "findex"));
    hb_set_t *charset = hb_set_create();
    hb_face_collect_unicodes(face, charset);
    hb_codepoint_t codepoint = HB_SET_VALUE_INVALID;
    while (hb_set_next(charset, &codepoint))
        if (unicode_unichar_isgraph(codepoint))
            self->charset = g_list_prepend(self->charset, GINT_TO_POINTER(codepoint));
    self->charset = g_list_reverse(self->charset);
    check_for_regional_indicator_symbols(self, charset);
    hb_blob_destroy(blob);
    hb_face_destroy(face);
    hb_set_destroy(charset);
    return;
}

/**
 * font_manager_codepoint_list_set_font:
 * @self:   #FontManagerCodepointList
 * @font: (transfer none) (nullable): #JsonObject
 *
 * Updates the codepoint list to contain only codepoints actually present in @font.
 */
void
font_manager_codepoint_list_set_font (FontManagerCodepointList *self, JsonObject *font)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->charset, g_list_free);
    if (font && json_object_ref(font)) {
        populate_charset(self, font);
        json_object_unref(font);
    }
    return;
}

gboolean
_is_regional_indicator_filter (GList *filter)
{
    if (!filter || g_list_length(filter) != 26)
        return FALSE;
    return (GPOINTER_TO_INT(g_list_nth_data(filter, 0)) == FONT_MANAGER_RIS_START_POINT
            && GPOINTER_TO_INT(g_list_nth_data(filter, 25)) == FONT_MANAGER_RIS_END_POINT);
}

/**
 * font_manager_codepoint_list_set_filter:
 * @self: #FontManagerCodepointList
 * @filter: (element-type uint) (transfer full) (nullable): #GList containing codepoints
 *
 * When a filter is set only codepoints which are actually present in the filter
 * will be used.
 */
void
font_manager_codepoint_list_set_filter (FontManagerCodepointList *self, GList *filter)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->filter, g_list_free);
    self->filter = filter;
    self->is_regional_indicator_filter = _is_regional_indicator_filter(filter);
    return;
}

/**
 * font_manager_codepoint_list_new:
 *
 * Creates a new codepoint list
 *
 * Returns: (transfer full): the newly-created #FontManagerCodepointList.
 * Use g_object_unref() to free the result.
 **/
FontManagerCodepointList *
font_manager_codepoint_list_new ()
{
    return g_object_new(FONT_MANAGER_TYPE_CODEPOINT_LIST, NULL);
}

