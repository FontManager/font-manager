/* font-manager-preview-page.c
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

#include "font-manager-preview-page.h"

/**
 * SECTION: font-manager-preview-page
 * @short_description: Full featured font preview widget
 * @title: Preview Page
 * @include: font-manager-preview-page.h
 *
 * This widget has three modes to allow previewing font files in various ways.
 *
 * The first mode provides an "active" preview where the user can edit the displayed text, set the
 * size and justification. The second mode displays a standard "waterfall" preview of the selected
 * font and the third mode displays several paragraphs of "Lorem Ipsum" text.
 */

GType
font_manager_preview_page_mode_get_type (void)
{
    static gsize g_define_type_id__volatile = 0;

    if (g_once_init_enter (&g_define_type_id__volatile)) {
        static const GEnumValue values[] = {
            { FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW, "FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW", "preview" },
            { FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL, "FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL", "waterfall" },
            { FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM, "FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM", "lorem-ipsum" },
            { 0, NULL, NULL }
        };
        GType g_define_type_id = g_enum_register_static (g_intern_static_string ("FontManagerPreviewPageMode"), values);
        g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

    return g_define_type_id__volatile;
}

/**
 * font_manager_preview_page_mode_to_string:
 * @mode:   #FontManagerPreviewPageMode
 *
 * Returns: (transfer none) (nullable): @mode as a string
 */
const gchar *
font_manager_preview_page_mode_to_string (FontManagerPreviewPageMode mode)
{
    switch (mode) {
        case FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW:
            return "Preview";
        case FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL:
            return "Waterfall";
        case FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM:
            return "Lorem Ipsum";
        default:
            return NULL;
    }
}

/**
 * font_manager_preview_page_mode_to_translatable_string:
 * @mode:   #FontManagerPreviewPageMode
 *
 * Returns: (transfer none) (nullable): @mode as a localized string, if available.
 */
const gchar *
font_manager_preview_page_mode_to_translatable_string (FontManagerPreviewPageMode mode)
{
    switch (mode) {
        case FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW:
            return _("Preview");
        case FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL:
            return _("Waterfall");
        case FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM:
            return "Lorem Ipsum";
        default:
            return NULL;
    }
}


#define MIN_FONT_SIZE FONT_MANAGER_MIN_FONT_SIZE
#define MAX_FONT_SIZE FONT_MANAGER_MAX_FONT_SIZE
#define DEFAULT_PREVIEW_SIZE FONT_MANAGER_DEFAULT_PREVIEW_SIZE
#define DEFAULT_WATERFALL_MAX_SIZE MAX_FONT_SIZE / 2

static void generate_waterfall_preview (FontManagerPreviewPage *self);

struct _FontManagerPreviewPage
{
    GtkBox   parent;

    gchar       *pangram;
    gchar       *default_pangram;
    gchar       *preview;
    gchar       *default_preview;
    gchar       *restore_preview;
    GtkWidget   *controls;
    GtkWidget   *fontscale;
    GtkWidget   *textview;
    GtkWidget   *menu_button;

    gdouble             waterfall_size_ratio;
    gdouble             min_waterfall_size;
    gdouble             max_waterfall_size;
    gdouble             preview_size;
    gboolean            allow_edit;
    gboolean            show_line_size;
    GtkJustification    justification;
    FontManagerPreviewPageMode  mode;
    FontManagerFont *font;
};

G_DEFINE_TYPE(FontManagerPreviewPage, font_manager_preview_page, GTK_TYPE_BOX)

enum
{
    PROP_RESERVED,
    PROP_PREVIEW_MODE,
    PROP_PREVIEW_SIZE,
    PROP_PREVIEW_TEXT,
    PROP_FONT,
    PROP_JUSTIFICATION,
    PROP_WATERFALL_MIN,
    PROP_WATERFALL_MAX,
    PROP_WATERFALL_RATIO,
    PROP_SHOW_LINE_SIZE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void set_preview_mode_internal (FontManagerPreviewPage     *self,
                                       FontManagerPreviewPageMode  mode);

static void
font_manager_preview_page_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPage *self = FONT_MANAGER_PREVIEW_PAGE(gobject);
    g_clear_pointer(&self->pangram, g_free);
    g_clear_pointer(&self->default_pangram, g_free);
    g_clear_pointer(&self->preview, g_free);
    g_clear_pointer(&self->default_preview, g_free);
    g_clear_pointer(&self->restore_preview, g_free);
    g_clear_pointer(&self->font, g_object_unref);
    g_clear_pointer(&self->menu_button, g_object_unref);
    font_manager_widget_dispose(GTK_WIDGET(self));
    G_OBJECT_CLASS(font_manager_preview_page_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_preview_page_get_property (GObject    *gobject,
                                        guint       property_id,
                                        GValue     *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPage *self = FONT_MANAGER_PREVIEW_PAGE(gobject);
    switch (property_id) {
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, font_manager_preview_page_get_preview_size(self));
            break;
        case PROP_PREVIEW_MODE:
            g_value_set_enum(value, font_manager_preview_page_get_preview_mode(self));
            break;
        case PROP_PREVIEW_TEXT:
            g_value_set_string(value, self->preview);
            break;
        case PROP_FONT:
            g_value_set_object(value, self->font);
            break;
        case PROP_JUSTIFICATION:
            g_value_set_enum(value, (gint) font_manager_preview_page_get_justification(self));
            break;
        case PROP_WATERFALL_MIN:
            g_value_set_double(value, self->min_waterfall_size);
            break;
        case PROP_WATERFALL_MAX:
            g_value_set_double(value, self->max_waterfall_size);
            break;
        case PROP_WATERFALL_RATIO:
            g_value_set_double(value, self->waterfall_size_ratio);
            break;
        case PROP_SHOW_LINE_SIZE:
            g_value_set_boolean(value, self->show_line_size);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preview_page_set_property (GObject      *gobject,
                                        guint         property_id,
                                        const GValue *value,
                                        GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPage *self = FONT_MANAGER_PREVIEW_PAGE(gobject);
    switch (property_id) {
        case PROP_PREVIEW_SIZE:
            font_manager_preview_page_set_preview_size(self, g_value_get_double(value));
            break;
        case PROP_PREVIEW_MODE:
            font_manager_preview_page_set_preview_mode(self, g_value_get_enum(value));
            break;
        case PROP_PREVIEW_TEXT:
            font_manager_preview_page_set_preview_text(self, g_value_get_string(value));
            break;
        case PROP_FONT:
            font_manager_preview_page_set_font(self, g_value_get_object(value));
            break;
        case PROP_JUSTIFICATION:
            font_manager_preview_page_set_justification(self, (GtkJustification) g_value_get_enum(value));
            break;
        case PROP_WATERFALL_MIN:
            font_manager_preview_page_set_waterfall_size(self, g_value_get_double(value), -1.0, -1.0);
            break;
        case PROP_WATERFALL_MAX:
            font_manager_preview_page_set_waterfall_size(self, -1.0, g_value_get_double(value), -1.0);
            break;
        case PROP_WATERFALL_RATIO:
            font_manager_preview_page_set_waterfall_size(self, -1.0, -1.0, g_value_get_double(value));
            break;
        case PROP_SHOW_LINE_SIZE:
            self->show_line_size = g_value_get_boolean(value);
            if (self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL)
                generate_waterfall_preview(self);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preview_page_class_init (FontManagerPreviewPageClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->dispose = font_manager_preview_page_dispose;
    object_class->get_property = font_manager_preview_page_get_property;
    object_class->set_property = font_manager_preview_page_set_property;

    /**
     * FontManagerPreviewPage:preview-mode:
     *
     * The current font preview mode.
     */
    obj_properties[PROP_PREVIEW_MODE] = g_param_spec_enum("preview-mode",
                                                          NULL,
                                                          "Font preview mode.",
                                                          FONT_MANAGER_TYPE_PREVIEW_PAGE_MODE,
                                                          (gint) FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL,
                                                          G_PARAM_STATIC_STRINGS |
                                                          G_PARAM_READWRITE |
                                                          G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:preview-size:
     *
     * The current font preview size.
     */
    obj_properties[PROP_PREVIEW_SIZE] = g_param_spec_double("preview-size",
                                                            NULL,
                                                            "Font preview size in points.",
                                                            MIN_FONT_SIZE,
                                                            MAX_FONT_SIZE,
                                                            DEFAULT_PREVIEW_SIZE,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE |
                                                            G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:preview-text:
     *
     * Current preview text.
     */
    obj_properties[PROP_PREVIEW_TEXT] = g_param_spec_string("preview-text",
                                                             NULL,
                                                             "Current preview text.",
                                                             NULL,
                                                             G_PARAM_STATIC_STRINGS |
                                                             G_PARAM_READWRITE |
                                                             G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:font:
     *
     * #FontManagerFont
     */
    obj_properties[PROP_FONT] = g_param_spec_object("font",
                                                    NULL,
                                                    "FontManagerFont",
                                                    FONT_MANAGER_TYPE_FONT,
                                                    G_PARAM_READWRITE |
                                                    G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPage:justification:
     *
     * Preview text justification.
     */
     obj_properties[PROP_JUSTIFICATION] = g_param_spec_enum("justification",
                                                            NULL,
                                                            "Preview text justification.",
                                                            GTK_TYPE_JUSTIFICATION,
                                                            GTK_JUSTIFY_CENTER,
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_READWRITE |
                                                            G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:min-waterfall-size:
     *
     * The current minimum waterfall preview size.
     */
    obj_properties[PROP_WATERFALL_MIN] = g_param_spec_double("min-waterfall-size",
                                                             NULL,
                                                             "Minimum waterfall preview size in points.",
                                                             MIN_FONT_SIZE,
                                                             DEFAULT_WATERFALL_MAX_SIZE,
                                                             MIN_FONT_SIZE,
                                                             G_PARAM_STATIC_STRINGS |
                                                             G_PARAM_READWRITE |
                                                             G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:max-waterfall-size:
     *
     * The current maximum waterfall preview size.
     */
    obj_properties[PROP_WATERFALL_MAX] = g_param_spec_double("max-waterfall-size",
                                                             NULL,
                                                             "Maximum waterfall preview size in points.",
                                                             MIN_FONT_SIZE,
                                                             MAX_FONT_SIZE * 2,
                                                             DEFAULT_WATERFALL_MAX_SIZE,
                                                             G_PARAM_STATIC_STRINGS |
                                                             G_PARAM_READWRITE |
                                                             G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:waterfall-size-ratio:
     *
     * Waterfall point size common ratio.
     */
    obj_properties[PROP_WATERFALL_RATIO] = g_param_spec_double("mwaterfall-size-ratio",
                                                                NULL,
                                                                "Waterfall point size common ratio",
                                                                1.0,
                                                                DEFAULT_WATERFALL_MAX_SIZE / 2,
                                                                1.1,
                                                                G_PARAM_STATIC_STRINGS |
                                                                G_PARAM_READWRITE |
                                                                G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPage:show-line-size:
     *
     * Whether to display line size in Waterfall preview or not.
     */
     obj_properties[PROP_SHOW_LINE_SIZE] = g_param_spec_boolean("show-line-size",
                                                                NULL,
                                                                "Whether to display Waterfall preview line size",
                                                                TRUE,
                                                                G_PARAM_STATIC_STRINGS |
                                                                G_PARAM_READWRITE);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
update_revealer_state (FontManagerPreviewPage     *self,
                       FontManagerPreviewPageMode  mode)
{
    g_return_if_fail(self != NULL);
    gboolean controls_visible = gtk_revealer_get_child_revealed(GTK_REVEALER(self->controls));
    GtkRevealerTransitionType trans_type = controls_visible ?
                                           GTK_REVEALER_TRANSITION_TYPE_SLIDE_UP :
                                           GTK_REVEALER_TRANSITION_TYPE_SLIDE_DOWN;
    gtk_revealer_set_transition_type(GTK_REVEALER(self->controls), trans_type);
    gboolean fontscale_visible = gtk_revealer_get_child_revealed(GTK_REVEALER(self->controls));
    trans_type = fontscale_visible ? GTK_REVEALER_TRANSITION_TYPE_SLIDE_DOWN :
                                     GTK_REVEALER_TRANSITION_TYPE_SLIDE_UP;
    gtk_revealer_set_transition_type(GTK_REVEALER(self->fontscale), trans_type);
    gtk_revealer_set_reveal_child(GTK_REVEALER(self->fontscale),
                                  (mode == FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW ||
                                   mode == FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM));
    gtk_revealer_set_reveal_child(GTK_REVEALER(self->controls),
                                  (mode == FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW));
    return;
}

static gint current_line = FONT_MANAGER_MIN_FONT_SIZE;

static gboolean
generate_waterfall_line (FontManagerPreviewPage *self)
{
    GtkTextIter iter;
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    GtkTextTagTable *tag_table = gtk_text_buffer_get_tag_table(buffer);
    gint i = current_line;
    g_autofree gchar *size_point = NULL;
    g_autofree gchar *line = g_strdup_printf("%i", i);
    if (self->show_line_size)
        size_point = g_strdup_printf(i < 10 ? " %spt.  " : "%spt.  ", line);
    gtk_text_buffer_get_iter_at_line(buffer, &iter, i);
    if (self->show_line_size)
        gtk_text_buffer_insert_with_tags_by_name(buffer, &iter, size_point, -1, "SizePoint", NULL);
    if (!gtk_text_tag_table_lookup(tag_table, line))
        gtk_text_buffer_create_tag(buffer, line, "size-points", (gdouble) i, NULL);
    if (self->show_line_size)
        gtk_text_buffer_get_end_iter(buffer, &iter);
    g_autofree gchar *pangram = g_strdup_printf("%s\n", self->pangram);
    gtk_text_buffer_insert_with_tags_by_name(buffer, &iter, pangram, -1, line, "FontDescription", NULL);
    if (self->waterfall_size_ratio > 1.0) {
        gdouble next = current_line * self->waterfall_size_ratio;
        current_line = self->waterfall_size_ratio > 1.1 ? floor(next) : ceil(next);
    } else
        current_line++;
    return self->mode != FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL ||
           current_line > self->max_waterfall_size ?
           G_SOURCE_REMOVE : G_SOURCE_CONTINUE;
}

static void
generate_waterfall_preview (FontManagerPreviewPage *self)
{
    g_return_if_fail(self != NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    gtk_text_buffer_set_text(buffer, "", -1);
    g_idle_remove_by_data(self);
    current_line = self->min_waterfall_size;
    g_idle_add((GSourceFunc) generate_waterfall_line, self);
    return;
}

static void
apply_font_description (FontManagerPreviewPage *self)
{
    g_return_if_fail(self != NULL);
    if (self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL)
        return;
    GtkTextIter start, end;
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gtk_text_buffer_apply_tag_by_name(buffer, "FontDescription", &start, &end);
    return;
}

/* Prevent tofu if possible */
static void
update_sample_string (FontManagerPreviewPage *self)
{
    g_return_if_fail(self != NULL);
    if (self->font == NULL)
        return;
    g_autofree gchar *preview_text = NULL;
    g_object_get(self->font, "preview-text", &preview_text, NULL);
    if (preview_text) {
        g_clear_pointer(&self->pangram, g_free);
        self->pangram = g_strdup(preview_text);
        if (!self->restore_preview)
            self->restore_preview = g_strdup(self->preview);
        font_manager_preview_page_set_preview_text(self, preview_text);
    } else {
        if (self->restore_preview) {
            g_clear_pointer(&self->pangram, g_free);
            self->pangram = g_strdup(self->default_pangram);
            font_manager_preview_page_set_preview_text(self, self->restore_preview);
            g_clear_pointer(&self->restore_preview, g_free);
        }
    }
    if (self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL)
        generate_waterfall_preview(self);
    return;
}

static void
update_font_description (FontManagerPreviewPage *self)
{
    g_return_if_fail(self != NULL);
    if (self->font == NULL)
        return;
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    GtkTextTagTable *tag_table = gtk_text_buffer_get_tag_table(buffer);
    GtkTextTag *font_description = gtk_text_tag_table_lookup(tag_table, "FontDescription");
    g_return_if_fail(font_description != NULL);
    g_autofree gchar *description = NULL;
    g_object_get(self->font, "description", &description, NULL);
    g_return_if_fail(description != NULL);
    g_autoptr(PangoFontDescription) font_desc = pango_font_description_from_string(description);
    g_object_set(G_OBJECT(font_description),
                 "font-desc", font_desc,
                 "size-points", self->preview_size,
                 "fallback", FALSE,
                 NULL);
    return;
}

static void
on_edit_toggled (FontManagerPreviewPage *self, gboolean active)
{
    g_return_if_fail(self != NULL);
    self->allow_edit = active;
    gtk_text_view_set_editable(GTK_TEXT_VIEW(self->textview), active);
    gtk_widget_set_can_target(self->textview, active);
    return;
}

static void
on_buffer_changed (GtkTextBuffer *buffer, FontManagerPreviewPage *self)
{
    g_return_if_fail(self != NULL);
    /* Buffer may be modified by the user in preview mode */
    if (self->mode != FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW)
        return;
    gboolean undo_available = FALSE;
    GtkWidget *controls = gtk_revealer_get_child(GTK_REVEALER(self->controls));
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gchar *current_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);
    /* Restore default preview if we have an empty buffer */
    if (g_strcmp0(current_text, "") == 0) {
        g_free(current_text);
        current_text = g_strdup(self->default_preview);
    }
    undo_available = (g_strcmp0(self->default_preview, current_text) != 0);
    /* Store the buffer contents if they've been modified */
    if (undo_available && (g_strcmp0(self->preview, current_text) != 0)) {
        g_free(self->preview);
        self->preview = g_strdup(current_text);
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_TEXT]);
    }
    g_clear_pointer(&current_text, g_free);
    g_object_set(G_OBJECT(controls), "undo-available", undo_available, NULL);
    return;
}

static void
on_undo_clicked (FontManagerPreviewPage *self, FontManagerPreviewControls *controls)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW);
    font_manager_preview_page_set_preview_text(self, self->default_preview);
    return;
}

static void
on_mode_action_activated (GSimpleAction          *action,
                          GVariant               *parameter,
                          FontManagerPreviewPage *self)
{
    FontManagerPreviewPageMode mode = FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM;
    const gchar *param = g_variant_get_string(parameter, NULL);
    if (g_strcmp0(param, "Waterfall") == 0)
        mode = FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL;
    else if (g_strcmp0(param, "Preview") == 0)
        mode = FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW;
    set_preview_mode_internal(self, mode);
    g_simple_action_set_state(G_SIMPLE_ACTION(action), parameter);
    return;
}

static void
on_zoom_event (FontManagerPreviewPage *self,
               GtkGestureZoom         *controller,
               gdouble                 scale)
{
    g_return_if_fail(self != NULL);
    if (self->mode != FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL) {
        if (scale > 1.0)
            font_manager_preview_page_set_preview_size(self, self->preview_size + 0.5);
        else
            font_manager_preview_page_set_preview_size(self, self->preview_size - 0.5);
    }
    return;
}

static void
on_long_press_event (GtkWidget      *textview,
                     GtkGestureZoom *controller,
                     gdouble         x,
                     gdouble         y)
{
    g_return_if_fail(GTK_IS_TEXT_VIEW(textview));
    gtk_widget_activate_action(textview, "menu.popup", NULL);
    return;
}

static void
on_swipe_event (FontManagerPreviewPage *self,
                gdouble                 x,
                gdouble                 y,
                GtkGestureSwipe        *swipe)
{
    g_return_if_fail(self != NULL);
    gint mode = (gint) self->mode;
    mode = (x < 0) ? ((mode < 2) ? (mode + 1) : 0) : ((mode > 0) ? (mode - 1) : 2);
    font_manager_preview_page_set_preview_mode(self, mode);
    return;
}

static void
font_manager_preview_page_init (FontManagerPreviewPage *self)
{
    g_return_if_fail(self != NULL);
    self->allow_edit = FALSE;
    self->show_line_size = TRUE;
    self->restore_preview = NULL;
    self->menu_button = NULL;
    self->min_waterfall_size = MIN_FONT_SIZE + 2;
    self->max_waterfall_size = DEFAULT_WATERFALL_MAX_SIZE;
    self->waterfall_size_ratio = 1.1;
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerPreviewPage");
    gtk_orientable_set_orientation(GTK_ORIENTABLE(self), GTK_ORIENTATION_VERTICAL);
    g_autoptr(GtkTextTagTable) tag_table = font_manager_text_tag_table_new();
    self->pangram = font_manager_get_localized_pangram();
    self->default_pangram = font_manager_get_localized_pangram();
    self->preview = g_strdup_printf(FONT_MANAGER_DEFAULT_PREVIEW_TEXT, self->pangram);
    self->default_preview = g_strdup(self->preview);
    self->justification = GTK_JUSTIFY_CENTER;
    g_autoptr(GtkTextBuffer) buffer = gtk_text_buffer_new(tag_table);
    GtkWidget *scroll = gtk_scrolled_window_new();
    self->textview = gtk_text_view_new_with_buffer(buffer);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(self->textview), FALSE);
    GtkWidget *controls = font_manager_preview_controls_new();
    self->controls = gtk_revealer_new();
    GtkWidget *fontscale = font_manager_font_scale_new();
    self->fontscale = gtk_revealer_new();
    gtk_revealer_set_child(GTK_REVEALER(self->controls), controls);
    gtk_revealer_set_child(GTK_REVEALER(self->fontscale), fontscale);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), self->textview);
    font_manager_widget_set_expand(scroll, TRUE);
    gtk_box_append(GTK_BOX(self), self->controls);
    gtk_box_append(GTK_BOX(self), scroll);
    gtk_box_append(GTK_BOX(self), self->fontscale);
    font_manager_widget_set_margin(self->textview, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_top(self->textview, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    gtk_widget_set_margin_bottom(self->textview, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    font_manager_widget_set_expand(scroll, TRUE);
    font_manager_preview_page_set_preview_size(self, FONT_MANAGER_DEFAULT_PREVIEW_SIZE);
    font_manager_preview_page_set_preview_mode(self, FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL);
    GtkAdjustment *adjustment = font_manager_font_scale_get_adjustment(FONT_MANAGER_FONT_SCALE(fontscale));
    GBindingFlags flags = G_BINDING_BIDIRECTIONAL | G_BINDING_SYNC_CREATE;
    g_object_bind_property(adjustment, "value", self, "preview-size", flags);
    flags = G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE;
    g_object_bind_property(self, "font", controls, "font", flags);
    g_object_bind_property(controls, "justification", self, "justification", flags);
    font_manager_preview_page_set_justification(self, GTK_JUSTIFY_CENTER);
    g_signal_connect_swapped(controls, "edit-toggled", G_CALLBACK(on_edit_toggled), self);
    g_signal_connect_after(buffer, "changed", G_CALLBACK(on_buffer_changed), self);
    g_signal_connect_swapped(controls, "undo-clicked", G_CALLBACK(on_undo_clicked), self);
    GtkGesture *zoom = gtk_gesture_zoom_new();
    g_signal_connect_swapped(zoom, "scale-changed", G_CALLBACK(on_zoom_event), self);
    gtk_widget_add_controller(GTK_WIDGET(self), GTK_EVENT_CONTROLLER(zoom));
    GtkGesture *swipe = gtk_gesture_swipe_new();
    gtk_gesture_single_set_touch_only(GTK_GESTURE_SINGLE(swipe), TRUE);
    g_signal_connect_swapped(swipe, "swipe", G_CALLBACK(on_swipe_event), self);
    gtk_widget_add_controller(GTK_WIDGET(self), GTK_EVENT_CONTROLLER(swipe));
    GtkGesture *long_press = gtk_gesture_long_press_new();
    g_signal_connect_swapped(long_press, "pressed", G_CALLBACK(on_long_press_event), self->textview);
    gtk_widget_add_controller(GTK_WIDGET(self->textview), GTK_EVENT_CONTROLLER(long_press));
    font_manager_preview_page_set_waterfall_size(self, self->min_waterfall_size, DEFAULT_WATERFALL_MAX_SIZE, 1.0);
    self->menu_button = g_object_ref_sink(gtk_menu_button_new());
    font_manager_set_preview_page_mode_menu_and_actions(GTK_WIDGET(self), self->menu_button, G_CALLBACK(on_mode_action_activated));
    return;
}

/**
 * font_manager_preview_page_get_action_widget:
 * @self:   #FontManagerPreviewPage
 *
 * Returns: (transfer full) (nullable): A #GtkMenuButton which provides controls for preview mode.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_preview_page_get_action_widget (FontManagerPreviewPage *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return g_object_ref(self->menu_button);
}

/**
 * font_manager_preview_page_get_font:
 * @self:   #FontManagerPreviewPage
 *
 * Returns:(transfer none) (nullable):#FontManagerFont which is owned by
 * the instance and must not be modified or freed.
 */
FontManagerFont *
font_manager_preview_page_get_font (FontManagerPreviewPage *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return self->font;
}

/**
 * font_manager_preview_page_get_justification:
 * @self:   #FontManagerPreviewPage
 *
 * Returns: Current preview text justification.
 */
GtkJustification
font_manager_preview_page_get_justification (FontManagerPreviewPage *self)
{
    g_return_val_if_fail(self != NULL, 0);
    return self->justification;
}

/**
 * font_manager_preview_page_get_preview_mode:
 * @self:   #FontManagerPreviewPage
 *
 * Returns: Current preview mode.
 */
FontManagerPreviewPageMode
font_manager_preview_page_get_preview_mode (FontManagerPreviewPage *self)
{
    g_return_val_if_fail(self != NULL, 0);
    return self->mode;
}

/**
 * font_manager_preview_page_get_preview_size:
 * @self:   #FontManagerPreviewPage
 *
 * Returns: Current preview size.
 */
gdouble
font_manager_preview_page_get_preview_size (FontManagerPreviewPage *self)
{
    g_return_val_if_fail(self != NULL, 0.0);
    return self->preview_size;
}

/**
 * font_manager_preview_page_get_preview_text:
 * @self:           #FontManagerPreviewPage
 *
 * Returns:(transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_preview_page_get_preview_text (FontManagerPreviewPage *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return g_strdup(self->preview);
}

/**
 * font_manager_preview_page_set_font:
 * @self:       #FontManagerPreviewPage
 * @font:       #FontManagerFont
 */
void
font_manager_preview_page_set_font (FontManagerPreviewPage *self,
                                    FontManagerFont        *font)
{
    g_return_if_fail(self != NULL);
    if (g_set_object(&self->font, font))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_FONT]);
    update_font_description(self);
    update_sample_string(self);
    apply_font_description(self);
    return;
}

/**
 * font_manager_preview_page_set_justification:
 * @self:           #FontManagerPreviewPage
 * @justification:  #GtkJustification
 *
 * Set preview text justification.
 */
void
font_manager_preview_page_set_justification (FontManagerPreviewPage *self,
                                             GtkJustification        justification)
{
    g_return_if_fail(self != NULL);
    self->justification = justification;
    if (self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW)
        gtk_text_view_set_justification(GTK_TEXT_VIEW(self->textview), justification);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_JUSTIFICATION]);
    return;
}

static void
set_preview_mode_internal (FontManagerPreviewPage     *self,
                           FontManagerPreviewPageMode  mode)
{
    while (g_idle_remove_by_data(self))
        g_idle_remove_by_data(self);
    self->mode = mode;
    GtkTextIter start;
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    gtk_text_buffer_get_start_iter(buffer, &start);
    gtk_text_view_set_editable(GTK_TEXT_VIEW(self->textview), FALSE);
    gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(self->textview), GTK_WRAP_WORD_CHAR);
    gtk_text_view_set_justification(GTK_TEXT_VIEW(self->textview), GTK_JUSTIFY_FILL);
    gtk_text_view_scroll_to_iter(GTK_TEXT_VIEW(self->textview), &start, 0.0, TRUE, 0.0, 0.0);
    gtk_text_view_set_top_margin(GTK_TEXT_VIEW(self->textview), 0);
    gtk_widget_set_can_target(self->textview, FALSE);
    switch (mode) {
        case FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW:
            gtk_text_view_set_top_margin(GTK_TEXT_VIEW(self->textview), FONT_MANAGER_DEFAULT_MARGIN * 6);
            gtk_text_view_set_justification(GTK_TEXT_VIEW(self->textview), self->justification);
            gtk_text_view_set_editable(GTK_TEXT_VIEW(self->textview), self->allow_edit);
            gtk_widget_set_can_target(self->textview, self->allow_edit ? TRUE : FALSE);
            gchar *text = self->preview ? self->preview : self->default_preview;
            font_manager_preview_page_set_preview_text(self, text);
            break;
        case FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL:
            generate_waterfall_preview(self);
            gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(self->textview), GTK_WRAP_NONE);
            break;
        case FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM:
            gtk_text_buffer_set_text(buffer, FONT_MANAGER_LOREM_IPSUM, -1);
            break;
        default:
            g_critical("Invalid preview mode : %i", (gint) mode);
            g_return_if_reached();
    }
    apply_font_description(self);
    update_revealer_state(self, mode);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_MODE]);
}

/**
 * font_manager_preview_page_set_preview_mode:
 * @self:   #FontManagerPreviewPage
 * @mode:   Preview mode.
 */
void
font_manager_preview_page_set_preview_mode (FontManagerPreviewPage     *self,
                                            FontManagerPreviewPageMode  mode)
{
    g_return_if_fail(self != NULL);
    const gchar *mode_string = font_manager_preview_page_mode_to_string(mode);
    gtk_widget_activate_action(GTK_WIDGET(self), "preview.mode", "s", mode_string);
    return;
}

/**
 * font_manager_preview_page_set_preview_size:
 * @self:           #FontManagerPreviewPage
 * @size_points:    Preview text size.
 */
void
font_manager_preview_page_set_preview_size (FontManagerPreviewPage *self,
                                            gdouble                 size_points)
{
    g_return_if_fail(self != NULL);
    self->preview_size = CLAMP(size_points, MIN_FONT_SIZE, MAX_FONT_SIZE);
    update_font_description(self);
    apply_font_description(self);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_SIZE]);
    return;
}

/**
 * font_manager_preview_page_set_preview_text:
 * @self:           #FontManagerPreviewPage
 * @preview_text:   Preview text.
 */
void
font_manager_preview_page_set_preview_text (FontManagerPreviewPage *self,
                                            const gchar            *preview_text)
{
    g_return_if_fail(self != NULL);

    if (preview_text) {
        gchar *new_preview = g_strdup(preview_text);
        g_free(self->preview);
        self->preview = new_preview;
    }

    if (self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_PREVIEW) {
        g_return_if_fail(self->preview != NULL);
        GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
        g_autofree gchar *valid = g_utf8_make_valid(self->preview, -1);
        gtk_text_buffer_set_text(buffer, valid, -1);
    }
    apply_font_description(self);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_TEXT]);
    return;
}

/**
 * font_manager_preview_page_set_waterfall_size:
 * @self:           #FontManagerPreviewPage
 * @min_size:       Minimum point size to use for waterfall previews. (-1.0 to keep current)
 * @max_size:       Maximum size to use for waterfall previews. (-1.0 to keep current)
 * @ratio:          Waterfall point size common ratio. (-1.0 to keep current)
 */
void
font_manager_preview_page_set_waterfall_size (FontManagerPreviewPage *self,
                                              gdouble                 min_size,
                                              gdouble                 max_size,
                                              gdouble                 ratio)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(ratio == -1.0 || (ratio >= 1.0 && ratio <= DEFAULT_WATERFALL_MAX_SIZE));
    if (min_size != -1.0) {
        self->min_waterfall_size = CLAMP(min_size, MIN_FONT_SIZE, MAX_FONT_SIZE / 2);
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_WATERFALL_MIN]);
    }
    if (max_size != -1.0) {
        self->max_waterfall_size = CLAMP(max_size, MIN_FONT_SIZE * 4, MAX_FONT_SIZE * 2);
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_WATERFALL_MAX]);
    }
    if (ratio != -1.0) {
        self->waterfall_size_ratio = ratio;
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_WATERFALL_RATIO]);
    }
    if (self->mode == FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL)
        generate_waterfall_preview(self);
    return;
}

/**
 * font_manager_preview_page_restore_state:
 * @self:       #FontManagerPreviewPage
 * @settings:   #GSettings
 *
 * Applies the values in @settings to @self and also binds those settings to their
 * respective properties so that they are updated when any changes take place.
 *
 * The following keys MUST be present in @settings:
 *
 *  - preview-font-size
 *  - preview-mode
 *  - preview-text
 */
void
font_manager_preview_page_restore_state (FontManagerPreviewPage *self,
                                         GSettings              *settings)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(settings != NULL);
    GSettingsBindFlags flags = G_SETTINGS_BIND_DEFAULT;
    g_settings_bind(settings, "preview-font-size", self, "preview-size", flags);
    g_settings_bind(settings, "preview-mode", self, "preview-mode", flags);
    g_settings_bind(settings, "preview-text", self, "preview-text", flags);
    return;
}

/**
 * font_manager_preview_page_new:
 *
 * Returns: A newly created #FontManagerPreviewPage.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_preview_page_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_PREVIEW_PAGE, NULL);
}

/**
 * font_manager_set_preview_page_mode_menu_and_actions:
 * @parent:                     #GtkWidget
 * @menu_button:                #GtkMenuButton
 * @callback: (scope forever) : #GCallback for action "activate" signal
 */
void
font_manager_set_preview_page_mode_menu_and_actions (GtkWidget *parent,
                                                     GtkWidget *menu_button,
                                                     GCallback  callback)
{
    GMenu *mode_menu = g_menu_new();
    GVariant *variant = g_variant_new_string("Waterfall");
    g_autoptr(GSimpleAction) action = g_simple_action_new_stateful("mode", G_VARIANT_TYPE_STRING, variant);
    g_simple_action_set_enabled(action, TRUE);
    g_signal_connect(action, "activate", callback, parent);
    g_action_activate(G_ACTION(action), variant);
    g_autoptr(GSimpleActionGroup) action_group = g_simple_action_group_new();
    g_action_map_add_action(G_ACTION_MAP(action_group), G_ACTION(action));
    gtk_widget_insert_action_group(menu_button, "preview", G_ACTION_GROUP(action_group));
    gtk_widget_insert_action_group(parent, "preview", G_ACTION_GROUP(action_group));
    GtkEventController *shortcuts = gtk_shortcut_controller_new();
    gtk_event_controller_set_propagation_phase(shortcuts, GTK_PHASE_BUBBLE);
    gtk_widget_add_controller(parent, GTK_EVENT_CONTROLLER(shortcuts));
    gtk_shortcut_controller_set_scope(GTK_SHORTCUT_CONTROLLER(shortcuts), GTK_SHORTCUT_SCOPE_GLOBAL);
    for (gint i = 0; i <= FONT_MANAGER_PREVIEW_PAGE_MODE_LOREM_IPSUM; i++) {
        const gchar *action_state = font_manager_preview_page_mode_to_string((FontManagerPreviewPageMode) i);
        const gchar *display_name = font_manager_preview_page_mode_to_translatable_string((FontManagerPreviewPageMode) i);
        g_autofree gchar *action_name = g_strdup_printf("preview.mode::%s", action_state);
        g_autoptr(GMenuItem) item = g_menu_item_new(display_name, action_name);
        g_autofree gchar *accel = g_strdup_printf("<Alt>%i", i + 1);
        g_menu_append_item(mode_menu, item);
        GtkShortcut *shortcut = font_manager_get_shortcut_for_stateful_action("preview", "mode", action_state, accel);
        gtk_shortcut_controller_add_shortcut(GTK_SHORTCUT_CONTROLLER(shortcuts), shortcut);
    }
    gtk_menu_button_set_icon_name(GTK_MENU_BUTTON(menu_button), "view-more-symbolic");
    gtk_menu_button_set_menu_model(GTK_MENU_BUTTON(menu_button), G_MENU_MODEL(mode_menu));
    font_manager_widget_set_margin(menu_button, 2);
    g_object_unref(mode_menu);
    return;
}

