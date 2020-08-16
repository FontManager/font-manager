/* font-manager-font-preview.c
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

#include "font-manager-font-preview.h"

/**
 * SECTION: font-manager-font-preview
 * @short_description: Full featured font preview widget
 * @title: Font Preview
 * @include: font-manager-font-preview.h
 *
 * This widget allows previewing of font files in various ways.
 */

GType
font_manager_font_preview_mode_get_type (void)
{
  static volatile gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW, "FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW", "preview" },
        { FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL, "FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL", "waterfall" },
        { FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM, "FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM", "lorem-ipsum" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerFontPreviewMode"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}

/**
 * font_manager_font_preview_mode_to_string:
 * @mode:   #FontManagerFontPreviewMode
 *
 * Returns: (transfer none) (nullable): @mode as a string
 */
const gchar *
font_manager_font_preview_mode_to_string (FontManagerFontPreviewMode mode)
{
    switch (mode) {
        case FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW:
            return "Preview";
        case FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL:
            return "Waterfall";
        case FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM:
            return "Lorem Ipsum";
        default:
            return NULL;
    }
}

/**
 * font_manager_font_preview_mode_to_translatable_string:
 * @mode:   #FontManagerFontPreviewMode
 *
 * Returns: (transfer none) (nullable): @mode as a localized string, if available.
 */
const gchar *
font_manager_font_preview_mode_to_translatable_string (FontManagerFontPreviewMode mode)
{
    switch (mode) {
        case FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW:
            return _("Preview");
        case FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL:
            return _("Waterfall");
        case FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM:
            return "Lorem Ipsum";
        default:
            return NULL;
    }
}


#define MIN_FONT_SIZE FONT_MANAGER_MIN_FONT_SIZE
#define MAX_FONT_SIZE FONT_MANAGER_MAX_FONT_SIZE
#define DEFAULT_PREVIEW_SIZE FONT_MANAGER_DEFAULT_PREVIEW_SIZE

struct _FontManagerFontPreview
{
    GtkBox   parent_instance;

    gchar       *pangram;
    gchar       *default_pangram;
    gchar       *preview;
    gchar       *default_preview;
    gchar       *restore_preview;
    GtkWidget   *controls;
    GtkWidget   *fontscale;
    GtkWidget   *textview;
    GHashTable  *samples;

    gdouble             preview_size;
    gboolean            allow_edit;
    GtkJustification    justification;
    FontManagerFontPreviewMode  mode;
    PangoFontDescription *font_desc;
};

G_DEFINE_TYPE(FontManagerFontPreview, font_manager_font_preview, GTK_TYPE_BOX)

enum
{
    PROP_RESERVED,
    PROP_PREVIEW_MODE,
    PROP_PREVIEW_SIZE,
    PROP_PREVIEW_TEXT,
    PROP_FONT_DESC,
    PROP_JUSTIFICATION,
    PROP_SAMPLES,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
font_manager_font_preview_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontPreview *self = FONT_MANAGER_FONT_PREVIEW(gobject);
    g_clear_pointer(&self->pangram, g_free);
    g_clear_pointer(&self->default_pangram, g_free);
    g_clear_pointer(&self->preview, g_free);
    g_clear_pointer(&self->default_preview, g_free);
    g_clear_pointer(&self->restore_preview, g_free);
    g_clear_pointer(&self->font_desc, pango_font_description_free);
    g_clear_pointer(&self->samples, g_hash_table_unref);
    G_OBJECT_CLASS(font_manager_font_preview_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_font_preview_get_property (GObject *gobject,
                                        guint property_id,
                                        GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontPreview *self = FONT_MANAGER_FONT_PREVIEW(gobject);
    g_autofree gchar *font = NULL;
    switch (property_id) {
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, font_manager_font_preview_get_preview_size(self));
            break;
        case PROP_PREVIEW_MODE:
            g_value_set_enum(value, font_manager_font_preview_get_preview_mode(self));
            break;
        case PROP_PREVIEW_TEXT:
            g_value_set_string(value, self->preview);
            break;
        case PROP_FONT_DESC:
            font = font_manager_font_preview_get_font_description(self);
            g_value_set_string(value, font);
            break;
        case PROP_JUSTIFICATION:
            g_value_set_enum(value, (gint) font_manager_font_preview_get_justification(self));
            break;
        case PROP_SAMPLES:
            g_value_set_boxed(value, self->samples);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_font_preview_set_property (GObject *gobject,
                                        guint property_id,
                                        const GValue *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerFontPreview *self = FONT_MANAGER_FONT_PREVIEW(gobject);
    switch (property_id) {
        case PROP_PREVIEW_SIZE:
            font_manager_font_preview_set_preview_size(self, g_value_get_double(value));
            break;
        case PROP_PREVIEW_MODE:
            font_manager_font_preview_set_preview_mode(self, g_value_get_enum(value));
            break;
        case PROP_PREVIEW_TEXT:
            font_manager_font_preview_set_preview_text(self, g_value_get_string(value));
            break;
        case PROP_FONT_DESC:
            font_manager_font_preview_set_font_description(self, g_value_get_string(value));
            break;
        case PROP_JUSTIFICATION:
            font_manager_font_preview_set_justification(self, (GtkJustification) g_value_get_enum(value));
            break;
        case PROP_SAMPLES:
            font_manager_font_preview_set_sample_strings(self, g_value_get_boxed(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_font_preview_class_init (FontManagerFontPreviewClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->dispose = font_manager_font_preview_dispose;
    object_class->get_property = font_manager_font_preview_get_property;
    object_class->set_property = font_manager_font_preview_set_property;

    /**
     * FontManagerFontPreview:preview-mode:
     *
     * The current font preview mode.
     */
    obj_properties[PROP_PREVIEW_MODE] = g_param_spec_enum("preview-mode",
                                                          NULL,
                                                          "Font preview mode.",
                                                          FONT_MANAGER_TYPE_FONT_PREVIEW_MODE,
                                                          (gint) FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL,
                                                          G_PARAM_STATIC_STRINGS |
                                                          G_PARAM_READWRITE |
                                                          G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerFontPreview:preview-size:
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
     * FontManagerFontPreview:preview-text:
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
     * FontManagerFontPreview:font-description:
     *
     * Current font dsescription as a string.
     */
    obj_properties[PROP_FONT_DESC] = g_param_spec_string("font-description",
                                                         NULL,
                                                         "Current font description as a string.",
                                                         FONT_MANAGER_DEFAULT_FONT,
                                                         G_PARAM_STATIC_STRINGS |
                                                         G_PARAM_READWRITE |
                                                         G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerFontPreview:justification:
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
     * FontManagerFontPreview:sample-strings:
     *
     * Dictionary of sample strings
     */
    obj_properties[PROP_SAMPLES] = g_param_spec_boxed("samples",
                                                      NULL,
                                                      "Dictionary of sample strings",
                                                      G_TYPE_HASH_TABLE,
                                                      G_PARAM_STATIC_STRINGS |
                                                      G_PARAM_READWRITE |
                                                      G_PARAM_EXPLICIT_NOTIFY);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
update_revealer_state (FontManagerFontPreview *self, FontManagerFontPreviewMode mode)
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
                                  (mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW ||
                                   mode == FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM));
    gtk_revealer_set_reveal_child(GTK_REVEALER(self->controls),
                                  (mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW));
    return;
}

static gint current_line = FONT_MANAGER_MIN_FONT_SIZE;

static gboolean
generate_waterfall_line (FontManagerFontPreview *self)
{
    GtkTextIter iter;
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    GtkTextTagTable *tag_table = gtk_text_buffer_get_tag_table(buffer);
    gint i = current_line;
    g_autofree gchar *size_point = NULL;
    g_autofree gchar *line = g_strdup_printf("%i", i);
    size_point = g_strdup_printf(i < 10 ? " %spt.  " : "%spt.  ", line);
    gtk_text_buffer_get_iter_at_line(buffer, &iter, i);
    gtk_text_buffer_insert_with_tags_by_name(buffer, &iter, size_point, -1, "SizePoint", NULL);
    if (!gtk_text_tag_table_lookup(tag_table, line))
        gtk_text_buffer_create_tag(buffer, line, "size-points", (gdouble) i, NULL);
    gtk_text_buffer_get_end_iter(buffer, &iter);
    g_autofree gchar *pangram = g_strdup_printf("%s\n", self->pangram);
    gtk_text_buffer_insert_with_tags_by_name(buffer, &iter, pangram, -1, line, "FontDescription", NULL);
    current_line++;
    return current_line > FONT_MANAGER_MAX_FONT_SIZE ? G_SOURCE_REMOVE : G_SOURCE_CONTINUE;
}

static void
generate_waterfall_preview (FontManagerFontPreview *self)
{
    g_return_if_fail(self != NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    gtk_text_buffer_set_text(buffer, "", -1);
    g_idle_remove_by_data(self);
    current_line = FONT_MANAGER_MIN_FONT_SIZE;
    g_idle_add((GSourceFunc) generate_waterfall_line, self);
    return;
}

static void
apply_font_description (FontManagerFontPreview *self)
{
    g_return_if_fail(self != NULL);
    if (self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL)
        return;
    GtkTextIter start, end;
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    gtk_text_buffer_get_bounds(buffer, &start, &end);
    gtk_text_buffer_apply_tag_by_name(buffer, "FontDescription", &start, &end);
    return;
}

/* Prevent tofu if possible */
static void
update_sample_string (FontManagerFontPreview *self)
{
    g_return_if_fail(self != NULL);
    g_autofree gchar *description = pango_font_description_to_string(self->font_desc);
    gboolean pangram_changed = FALSE;
    if (self->samples && g_hash_table_contains(self->samples, description)) {
        const gchar *sample = g_hash_table_lookup(self->samples, description);
        if (sample) {
            g_free(self->pangram);
            self->pangram = g_strdup(sample);
            pangram_changed = TRUE;
            if (self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW
                && g_strcmp0(self->preview, self->default_preview) == 0) {
                self->restore_preview = g_strdup(self->preview);
                font_manager_font_preview_set_preview_text(self, self->pangram);
            }
        }
    } else {
        if (g_strcmp0(self->pangram, self->default_pangram) != 0) {
            g_free(self->pangram);
            self->pangram = g_strdup(self->default_pangram);
            pangram_changed = TRUE;
        }
        if (self->restore_preview && self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW) {
            font_manager_font_preview_set_preview_text(self, self->restore_preview);
            g_clear_pointer(&self->restore_preview, g_free);
        }
    }
    if (pangram_changed && self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL)
        generate_waterfall_preview(self);
    return;
}

static void
update_font_description (FontManagerFontPreview *self)
{
    g_return_if_fail(self != NULL && self->font_desc != NULL);
    GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
    GtkTextTagTable *tag_table = gtk_text_buffer_get_tag_table(buffer);
    GtkTextTag *font_description = gtk_text_tag_table_lookup(tag_table, "FontDescription");
    g_return_if_fail(font_description != NULL);
    g_object_set(G_OBJECT(font_description),
                 "font-desc", self->font_desc,
                 "size-points", self->preview_size,
                 "fallback", FALSE,
                 NULL);
    return;
}

static void
on_edit_toggled (FontManagerFontPreview *self, gboolean active)
{
    g_return_if_fail(self != NULL);
    self->allow_edit = active;
    gtk_text_view_set_editable(GTK_TEXT_VIEW(self->textview), active);
    return;
}

static void
on_buffer_changed (FontManagerFontPreview *self, GtkTextBuffer *buffer)
{
    g_return_if_fail(self != NULL);
    gboolean undo_available = FALSE;
    GtkWidget *controls = gtk_bin_get_child(GTK_BIN(self->controls));
    if (self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW) {
        GtkTextIter start, end;
        gtk_text_buffer_get_bounds(buffer, &start, &end);
        gchar *current_text = gtk_text_buffer_get_text(buffer, &start, &end, FALSE);
        undo_available = (g_strcmp0(self->default_preview, current_text) != 0);
        g_free(self->preview);
        self->preview = current_text;
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_TEXT]);
    }
    g_object_set(G_OBJECT(controls), "undo-available", undo_available, NULL);
    return;
}

static void
on_undo_clicked (FontManagerFontPreview *self, FontManagerPreviewControls *controls)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW);
    font_manager_font_preview_set_preview_text(self, self->default_preview);
    return;
}

static gboolean
on_event (FontManagerFontPreview *self, GdkEvent *event, GtkWidget *widget)
{
    g_return_val_if_fail(self != NULL, GDK_EVENT_PROPAGATE);
    g_return_val_if_fail(event != NULL, GDK_EVENT_PROPAGATE);
    if (event->type == GDK_SCROLL)
        return GDK_EVENT_PROPAGATE;
    if (self->allow_edit && self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW)
        return GDK_EVENT_PROPAGATE;
    GdkWindow *text_window = gtk_text_view_get_window(GTK_TEXT_VIEW(self->textview), GTK_TEXT_WINDOW_TEXT);
    gdk_window_set_cursor(text_window, NULL);
    return GDK_EVENT_STOP;
}

static GtkTextTagTable *
font_manager_text_tag_table_new (void)
{
    GtkTextTagTable *tags = gtk_text_tag_table_new();
    g_autoptr(GtkTextTag) font = gtk_text_tag_new("FontDescription");
    g_object_set(font, "fallback", FALSE, NULL);
    if (!gtk_text_tag_table_add(tags, font))
        g_warning(G_STRLOC" : Failed to add text tag to table: FontDescription");
    g_autoptr(GtkTextTag) point_size = gtk_text_tag_new("SizePoint");
    g_object_set(point_size, "family", "Monospace", "rise", 1250, "size-points", 6.5, NULL);
    if (!gtk_text_tag_table_add(tags, point_size))
        g_warning(G_STRLOC" : Failed to add text tag to table: size-points");
    return tags;
}

static void
font_manager_font_preview_init (FontManagerFontPreview *self)
{
    g_return_if_fail(self != NULL);
    self->allow_edit = FALSE;
    self->samples = NULL;
    self->restore_preview = NULL;
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(self));
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerFontPreview");
    gtk_orientable_set_orientation(GTK_ORIENTABLE(self), GTK_ORIENTATION_VERTICAL);
    g_autoptr(GtkTextTagTable) tag_table = font_manager_text_tag_table_new();
    self->pangram = font_manager_get_localized_pangram();
    self->default_pangram = font_manager_get_localized_pangram();
    self->preview = g_strdup_printf(FONT_MANAGER_DEFAULT_PREVIEW_TEXT, self->pangram);
    self->default_preview = g_strdup(self->preview);
    self->justification = GTK_JUSTIFY_CENTER;
    g_autoptr(GtkTextBuffer) buffer = gtk_text_buffer_new(tag_table);
    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    self->textview = gtk_text_view_new_with_buffer(buffer);
    gtk_drag_dest_unset(self->textview);
    GtkWidget *controls = font_manager_preview_controls_new();
    self->controls = gtk_revealer_new();
    GtkWidget *fontscale = font_manager_font_scale_new();
    self->fontscale = gtk_revealer_new();
    gtk_container_add(GTK_CONTAINER(self->controls), controls);
    gtk_container_add(GTK_CONTAINER(self->fontscale), fontscale);
    gtk_container_add(GTK_CONTAINER(scroll), self->textview);
    gtk_box_pack_start(GTK_BOX(self), self->controls, FALSE, TRUE, 0);
    font_manager_widget_set_expand(scroll, TRUE);
    gtk_box_pack_start(GTK_BOX(self), scroll, TRUE, TRUE, 0);
    gtk_box_pack_end(GTK_BOX(self), self->fontscale, FALSE, TRUE, 0);
    font_manager_widget_set_margin(self->textview, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_top(self->textview, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    gtk_widget_set_margin_bottom(self->textview, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    font_manager_widget_set_expand(scroll, TRUE);
    font_manager_font_preview_set_font_description(self, FONT_MANAGER_DEFAULT_FONT);
    font_manager_font_preview_set_preview_size(self, FONT_MANAGER_DEFAULT_PREVIEW_SIZE);
    font_manager_font_preview_set_preview_mode(self, FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL);
    GtkAdjustment *adjustment = font_manager_font_scale_get_adjustment(FONT_MANAGER_FONT_SCALE(fontscale));
    GBindingFlags flags = G_BINDING_BIDIRECTIONAL | G_BINDING_SYNC_CREATE;
    g_object_bind_property(adjustment, "value", self, "preview-size", flags);
    flags = G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE;
    g_object_bind_property(self, "font-description", controls, "description", flags);
    g_object_bind_property(controls, "justification", self, "justification", flags);
    font_manager_font_preview_set_justification(self, GTK_JUSTIFY_CENTER);
    g_signal_connect_swapped(controls, "edit-toggled", G_CALLBACK(on_edit_toggled), self);
    g_signal_connect_swapped(buffer, "changed", G_CALLBACK(on_buffer_changed), self);
    g_signal_connect_swapped(controls, "undo-clicked", G_CALLBACK(on_undo_clicked), self);
    g_signal_connect_swapped(self->textview, "event", G_CALLBACK(on_event), self);
    gtk_widget_show_all(scroll);
    gtk_widget_show_all(self->controls);
    gtk_widget_show_all(self->fontscale);
    return;
}

/**
 * font_manager_font_preview_set_preview_mode:
 * @self:   #FontManagerFontPreview
 * @mode:   Preview mode.
 */
void
font_manager_font_preview_set_preview_mode (FontManagerFontPreview *self,
                                            FontManagerFontPreviewMode mode)
{
    g_return_if_fail(self != NULL);
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
    switch (mode) {
        case FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW:
            gtk_text_view_set_top_margin(GTK_TEXT_VIEW(self->textview), FONT_MANAGER_DEFAULT_MARGIN * 6);
            font_manager_font_preview_set_preview_text(self, NULL);
            gtk_text_view_set_justification(GTK_TEXT_VIEW(self->textview), self->justification);
            gtk_text_view_set_editable(GTK_TEXT_VIEW(self->textview), self->allow_edit);
            break;
        case FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL:
            generate_waterfall_preview(self);
            gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(self->textview), GTK_WRAP_NONE);
            break;
        case FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM:
            gtk_text_buffer_set_text(buffer, FONT_MANAGER_LOREM_IPSUM, -1);
            break;
        default:
            g_critical("Invalid preview mode : %i", (gint) mode);
            g_return_if_reached();
    }
    update_sample_string(self);
    apply_font_description(self);
    update_revealer_state(self, mode);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_MODE]);
    return;
}

/**
 * font_manager_font_preview_set_preview_size:
 * @self:           #FontManagerFontPreview
 * @size_points:    Preview text size.
 */
void
font_manager_font_preview_set_preview_size (FontManagerFontPreview *self,
                                            gdouble size_points)
{
    g_return_if_fail(self != NULL);
    self->preview_size = CLAMP(size_points, MIN_FONT_SIZE, MAX_FONT_SIZE);
    update_font_description(self);
    update_sample_string(self);
    apply_font_description(self);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_PREVIEW_SIZE]);
    return;
}

/**
 * font_manager_font_preview_set_preview_text:
 * @self:           #FontManagerFontPreview
 * @preview_text:   Preview text.
 */
void
font_manager_font_preview_set_preview_text (FontManagerFontPreview *self,
                                            const gchar *preview_text)
{
    g_return_if_fail(self != NULL);

    if (preview_text) {
        gchar *new_preview = g_strdup(preview_text);
        g_free(self->preview);
        self->preview = new_preview;
    }

    if (self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW) {
        g_return_if_fail(self->preview != NULL);
        GtkTextBuffer *buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(self->textview));
        g_autofree gchar *valid = g_utf8_make_valid(self->preview, -1);
        gtk_text_buffer_set_text(buffer, valid, -1);
    }
    apply_font_description(self);
    return;
}

/**
 * font_manager_font_preview_set_font_description:
 * @self:   #FontManagerFontPreview
 * @font: (nullable): string representation of a font description.
 *
 * See #pango_font_description_from_string() for details on what constitutes a
 * valid font description string.
 */
void
font_manager_font_preview_set_font_description (FontManagerFontPreview *self,
                                                const gchar *font)
{
    g_return_if_fail(self != NULL);
    pango_font_description_free(self->font_desc);
    self->font_desc = pango_font_description_from_string(font ? font : FONT_MANAGER_DEFAULT_FONT);
    update_font_description(self);
    update_sample_string(self);
    apply_font_description(self);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_FONT_DESC]);
    return;
}

/**
 * font_manager_font_preview_set_justification:
 * @self:           #FontManagerFontPreview
 * @justification:  #GtkJustification
 *
 * Set preview text justification.
 */
void
font_manager_font_preview_set_justification (FontManagerFontPreview *self,
                                             GtkJustification justification)
{
    g_return_if_fail(self != NULL);
    self->justification = justification;
    if (self->mode == FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW)
        gtk_text_view_set_justification(GTK_TEXT_VIEW(self->textview), justification);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_JUSTIFICATION]);
    return;
}

/**
 * font_manager_font_preview_set_sample_strings:
 * @self:           #FontManagerFontPreview
 * @samples:        #JsonObject containing sample strings
 *
 * @samples is expected to have a dictionary like structure,
 * with the font description as key and sample string as value.
 */
void
font_manager_font_preview_set_sample_strings (FontManagerFontPreview *self, GHashTable *samples)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->samples, g_hash_table_unref);
    if (samples)
        self->samples = g_hash_table_ref(samples);
    update_sample_string(self);
    g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_SAMPLES]);
    return;
}

/**
 * font_manager_font_preview_get_preview_size:
 * @self:   #FontManagerFontPreview
 *
 * Returns: Current preview size.
 */
gdouble
font_manager_font_preview_get_preview_size (FontManagerFontPreview *self)
{
    g_return_val_if_fail(self != NULL, 0.0);
    return self->preview_size;
}

/**
 * font_manager_font_preview_get_preview_text:
 * @self:           #FontManagerFontPreview
 *
 * Returns:(transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_font_preview_get_preview_text (FontManagerFontPreview *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return g_strdup(self->preview);
}

/**
 * font_manager_font_preview_get_font_description:
 * @self:   #FontManagerFontPreview
 *
 * Returns:(transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_font_preview_get_font_description (FontManagerFontPreview *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    return pango_font_description_to_string(self->font_desc);
}

/**
 * font_manager_font_preview_get_preview_mode:
 * @self:   #FontManagerFontPreview
 *
 * Returns: Current preview mode.
 */
FontManagerFontPreviewMode
font_manager_font_preview_get_preview_mode (FontManagerFontPreview *self)
{
    g_return_val_if_fail(self != NULL, 0);
    return self->mode;
}

/**
 * font_manager_font_preview_get_justification:
 * @self:   #FontManagerFontPreview
 *
 * Returns: Current preview text justification.
 */
GtkJustification
font_manager_font_preview_get_justification (FontManagerFontPreview *self)
{
    g_return_val_if_fail(self != NULL, 0);
    return self->justification;
}

/**
 * font_manager_font_preview_new:
 *
 * Returns: A newly created #FontManagerFontPreview.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_font_preview_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_FONT_PREVIEW, NULL);
}
