/* font-manager-preview-pane.c
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

#include "font-manager-preview-pane.h"

/**
 * SECTION: font-manager-preview-pane
 * @short_description: Preview pane widget
 * @title: Preview Pane
 * @include: font-manager-preview-pane.h
 *
 * Full featured font preview widget.
 *
 * This widget combines several other widgets to provide as much information
 * about a particular font file as possible, previews, provided characters,
 * basic file properties and license information (if available).
 */

/**
 * font_manager_preview_pane_page_to_string:
 * @page:  #FontManagerPreviewPanePage
 *
 * Returns: (transfer none) (nullable): @page as a string
 */
const gchar *
font_manager_preview_pane_page_to_string (FontManagerPreviewPanePage page)
{
    switch (page) {
        case FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP:
            return _("Characters");
        case FONT_MANAGER_PREVIEW_PANE_PAGE_PROPERTIES:
            return _("Properties");
        case FONT_MANAGER_PREVIEW_PANE_PAGE_LICENSE:
            return _("License");
        default:
            return NULL;
    }
}

GType
font_manager_preview_pane_page_get_type (void)
{
  static gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_PREVIEW_PANE_PAGE_PREVIEW, "FONT_MANAGER_PREVIEW_PANE_PAGE_PREVIEW", "preview" },
        { FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP, "FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP", "character-map" },
        { FONT_MANAGER_PREVIEW_PANE_PAGE_PROPERTIES, "FONT_MANAGER_PREVIEW_PANE_PAGE_PROPERTIES", "properties" },
        { FONT_MANAGER_PREVIEW_PANE_PAGE_LICENSE, "FONT_MANAGER_PREVIEW_PANE_PAGE_LICENSE", "license" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerPreviewPanePage"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}

struct _FontManagerPreviewPane
{
    GtkWidget parent;

    gint                    page;
    gint                    line_spacing;
    gboolean                update_required;
    gboolean                show_line_size;
    gdouble                 preview_size;
    gdouble                 glyph_preview_size;
    gchar                   *preview_text;
    gchar                   *current_uri;
    GtkWidget               *preview;
    GtkWidget               *character_map;
    GtkWidget               *properties;
    GtkWidget               *license;
    GtkWidget               *search;
    GtkNotebook             *notebook;

    FontManagerFont             *font;
    FontManagerDatabase         *db;
    FontManagerPreviewPageMode  mode;
};

G_DEFINE_TYPE(FontManagerPreviewPane, font_manager_preview_pane, GTK_TYPE_WIDGET)

enum
{
    CHANGED,
    NUM_SIGNALS
};

static guint signals[NUM_SIGNALS];

enum
{
    PROP_RESERVED,
    PROP_PREVIEW_SIZE,
    PROP_GLYPH_PREVIEW_SIZE,
    PROP_PREVIEW_TEXT,
    PROP_PREVIEW_MODE,
    PROP_FONT,
    PROP_ORTHOGRAPHY,
    PROP_SHOW_LINE_SIZE,
    PROP_LINE_SPACING,
    PROP_PAGE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void update_mode (FontManagerPreviewPane *self);

static void
font_manager_preview_pane_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPane *self = FONT_MANAGER_PREVIEW_PANE(gobject);
    g_clear_object(&self->font);
    g_clear_object(&self->db);
    g_clear_pointer(&self->preview_text, g_free);
    g_clear_pointer(&self->current_uri, g_free);
    font_manager_clear_application_fonts();
    font_manager_widget_dispose(GTK_WIDGET(self));
    G_OBJECT_CLASS(font_manager_preview_pane_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_preview_pane_get_property (GObject    *gobject,
                                        guint       property_id,
                                        GValue     *value,
                                        GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPane *self = FONT_MANAGER_PREVIEW_PANE(gobject);
    switch (property_id) {
        case PROP_PREVIEW_SIZE:
            g_value_set_double(value, self->preview_size);
            break;
        case PROP_GLYPH_PREVIEW_SIZE:
            g_value_set_double(value, self->glyph_preview_size);
            break;
        case PROP_PREVIEW_MODE:
            g_value_set_enum(value, self->mode);
            break;
        case PROP_PREVIEW_TEXT:
            g_value_set_string(value, self->preview_text);
            break;
        case PROP_FONT:
            g_value_set_object(value, self->font);
            break;
        case PROP_SHOW_LINE_SIZE:
            g_value_set_boolean(value, self->show_line_size);
            break;
        case PROP_LINE_SPACING:
            g_value_set_int(value, self->line_spacing);
            break;
        case PROP_PAGE:
            g_value_set_int(value, self->page);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preview_pane_set_property (GObject      *gobject,
                                        guint         property_id,
                                        const GValue *value,
                                        GParamSpec   *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPane *self = FONT_MANAGER_PREVIEW_PANE(gobject);
    switch (property_id) {
        case PROP_PREVIEW_SIZE:
            self->preview_size = g_value_get_double(value);
            break;
        case PROP_GLYPH_PREVIEW_SIZE:
            self->glyph_preview_size = g_value_get_double(value);
            break;
        case PROP_PREVIEW_MODE:
            self->mode = g_value_get_enum(value);
            update_mode(self);
            break;
        case PROP_PREVIEW_TEXT:
            g_clear_pointer(&self->preview_text, g_free);
            self->preview_text = g_value_dup_string(value);
            break;
        case PROP_FONT:
            font_manager_preview_pane_set_font(self, g_value_get_object(value));
            break;
        case PROP_ORTHOGRAPHY:
            font_manager_preview_pane_set_orthography(self, g_value_get_object(value));
            break;
        case PROP_SHOW_LINE_SIZE:
            self->show_line_size = g_value_get_boolean(value);
            break;
        case PROP_LINE_SPACING:
            self->line_spacing = g_value_get_int(value);
            break;
        case PROP_PAGE:
            self->page = g_value_get_int(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
on_search_action_activated (GtkWidget                *widget,
                            G_GNUC_UNUSED const char *action_name,
                            G_GNUC_UNUSED GVariant   *parameter)
{
    g_return_if_fail(widget != NULL);
    FontManagerPreviewPane *self = FONT_MANAGER_PREVIEW_PANE(widget);
    gboolean current_state = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(self->search));
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(self->search), !current_state);
    return;
}

static void
font_manager_preview_pane_class_init (FontManagerPreviewPaneClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);

    object_class->dispose = font_manager_preview_pane_dispose;
    object_class->get_property = font_manager_preview_pane_get_property;
    object_class->set_property = font_manager_preview_pane_set_property;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BIN_LAYOUT);

    gtk_widget_class_install_action(widget_class,
                                    "character-search",
                                    NULL,
                                    on_search_action_activated);

    gtk_widget_class_add_binding_action(widget_class,
                                        GDK_KEY_f,
                                        GDK_CONTROL_MASK,
                                        "character-search", NULL);

    /**
     * FontManagerPreviewPane::changed:
     *
     * Emitted whenever the the preview is updated.
     */
    signals[CHANGED] = g_signal_new("changed",
                                    FONT_MANAGER_TYPE_PREVIEW_PANE,
                                    G_SIGNAL_RUN_FIRST,
                                    0, NULL, NULL, NULL, G_TYPE_NONE, 0);

    /**
     * FontManagerPreviewPane:preview-size:
     *
     * Size to use for font in preview mode.
     */
    obj_properties[PROP_PREVIEW_SIZE] = g_param_spec_double("preview-size",
                                                            NULL,
                                                            "Font preview size",
                                                            FONT_MANAGER_MIN_FONT_SIZE,
                                                            FONT_MANAGER_MAX_FONT_SIZE,
                                                            FONT_MANAGER_DEFAULT_PREVIEW_SIZE,
                                                            G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPane:character-map-preview-size:
     *
     * Size to use for font in character map.
     */
    obj_properties[PROP_GLYPH_PREVIEW_SIZE] = g_param_spec_double("character-map-preview-size",
                                                                  NULL,
                                                                  "Font preview size",
                                                                  FONT_MANAGER_MIN_FONT_SIZE,
                                                                  FONT_MANAGER_MAX_FONT_SIZE,
                                                                  FONT_MANAGER_LARGE_PREVIEW_SIZE,
                                                                  G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPane:preview-text:
     *
     * Text to display in interactive preview mode.
     */
    obj_properties[PROP_PREVIEW_TEXT] = g_param_spec_string("preview-text",
                                                            NULL,
                                                            "Preview text",
                                                            NULL,
                                                            G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPane:preview-mode:
     */
    obj_properties[PROP_PREVIEW_MODE] = g_param_spec_enum("preview-mode",
                                                          NULL,
                                                          "Preview mode",
                                                          FONT_MANAGER_TYPE_PREVIEW_PAGE_MODE,
                                                          FONT_MANAGER_PREVIEW_PAGE_MODE_WATERFALL,
                                                          G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPane:font:
     *
     * #FontManagerFont to display.
     */
    obj_properties[PROP_FONT] = g_param_spec_object("font",
                                                    NULL,
                                                    "#FontManagerFont to display",
                                                    FONT_MANAGER_TYPE_FONT,
                                                    G_PARAM_READWRITE |
                                                    G_PARAM_STATIC_STRINGS |
                                                    G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerPreviewPane:orthography:
     *
     * #FontManagerOrthography to display in character map.
     */
    obj_properties[PROP_ORTHOGRAPHY] = g_param_spec_object("orthography",
                                                            NULL,
                                                            "#FontManagerOrthography to display",
                                                            FONT_MANAGER_TYPE_ORTHOGRAPHY,
                                                            G_PARAM_WRITABLE |
                                                            G_PARAM_STATIC_STRINGS |
                                                            G_PARAM_EXPLICIT_NOTIFY);

    /**
     * FontManagerFontPreviewPane:show-line-size:
     *
     * Whether to display line size in Waterfall preview or not.
     */
     obj_properties[PROP_SHOW_LINE_SIZE] = g_param_spec_boolean("show-line-size",
                                                                NULL,
                                                                "Whether to display Waterfall preview line size",
                                                                TRUE,
                                                                G_PARAM_STATIC_STRINGS |
                                                                G_PARAM_READWRITE);

    /**
     * FontManagerPreviewPane:line-spacing:
     *
     * Pixels between lines in Waterfall preview.
     */
    obj_properties[PROP_LINE_SPACING] = g_param_spec_int("line-spacing",
                                                          NULL,
                                                          "Waterfall preview line spacing",
                                                          0,
                                                          G_MAXINT,
                                                          0,
                                                          G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPane:page:
     *
     * Current page number.
     */
    obj_properties[PROP_PAGE] = g_param_spec_int("page",
                                                 NULL,
                                                 "Current page",
                                                 0,
                                                 3,
                                                 0,
                                                 G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

enum { WIDTH, WEIGHT, SLANT, SPACING, NUM_STYLE_DETAILS };
static const gchar *style_detail [NUM_STYLE_DETAILS] = { "width", "weight", "slant", "spacing" };

static gboolean
font_manager_preview_pane_update_metadata (FontManagerPreviewPane *self)
{
    g_return_val_if_fail(self != NULL, G_SOURCE_REMOVE);
    if (!self->font)
        return G_SOURCE_CONTINUE;
    if (!self->update_required)
        return G_SOURCE_REMOVE;
    gint index = 0;
    GError *error = NULL;
    // XXX: ???
    // g_autofree gchar *filepath = NULL;
    gchar *filepath = NULL;
    g_autoptr(JsonObject) res = NULL;
    if (!self->db)
        self->db = font_manager_database_new();
    g_object_get(G_OBJECT(self->font), "filepath", &filepath, "findex", &index, NULL);
    if (error == NULL) {
        const gchar *select = "SELECT * FROM Metadata WHERE filepath = %s AND findex = '%i'";
        char *path = sqlite3_mprintf("%Q", filepath);
        g_autofree gchar *query = g_strdup_printf(select, path, index);
        res = font_manager_database_get_object(self->db, query, &error);
        sqlite3_free(path);
    }
    if (error != NULL) {
        g_clear_error(&error);
    }
    if (!res) {
        res = font_manager_get_metadata(filepath, index, &error);
        if (error != NULL) {
            g_critical("Failed to get metadata for %s : %s", filepath, error->message);
            g_clear_error(&error);
        }
    }
    g_free(filepath);
    if (res) {
        for (gint i = 0; i < NUM_STYLE_DETAILS; i++) {
            gint value;
            const gchar *str = NULL;
            g_object_get(G_OBJECT(self->font), style_detail[i], &value, NULL);
            switch (i) {
                case WIDTH:
                    str = font_manager_width_to_string((FontManagerWidth) value);
                    break;
                case WEIGHT:
                    str = font_manager_weight_to_string((FontManagerWeight) value);
                    break;
                case SLANT:
                    str = font_manager_slant_to_string((FontManagerSlant) value);
                    break;
                case SPACING:
                    str = font_manager_spacing_to_string((FontManagerSpacing) value);
                    break;
            }
            json_object_set_string_member(res, style_detail[i],
                                          str ? str : i == WEIGHT ? _("Regular") : _("Normal"));
        }
        gint64 fsType = json_object_get_int_member(res, "fsType");
        const gchar *license_data = json_object_get_string_member(res, "license-data");
        const gchar *license_url = json_object_get_string_member(res, "license-url");
        g_object_set(G_OBJECT(self->license), "fstype", (FontManagerfsType) fsType,
                                              "license-data", license_data,
                                              "license-url", license_url, NULL);
    } else {
        g_object_set(G_OBJECT(self->license), "fstype", FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE,
                                              "license-data", NULL, "license-url", NULL, NULL);
    }
    font_manager_font_properties_page_update(FONT_MANAGER_PROPERTIES_PAGE(self->properties), res);
    //g_debug("PreviewPane.update_metadata : %s", font_manager_print_json_object(res, true));
    self->update_required = FALSE;
    return G_SOURCE_REMOVE;
}

static gboolean
font_manager_preview_pane_update (FontManagerPreviewPane *self)
{
    g_return_val_if_fail(self != NULL, G_SOURCE_REMOVE);
    /* XXX : How is this a thing that happens intermittently ?! */
    if (!GTK_IS_NOTEBOOK(self->notebook))
        return G_SOURCE_REMOVE;
    gint page = gtk_notebook_get_current_page(self->notebook);
    GtkWidget *action_widget_box = gtk_notebook_get_action_widget(self->notebook, GTK_PACK_START);
    GtkWidget *menu = gtk_widget_get_first_child(action_widget_box);
    GtkWidget *search = gtk_notebook_get_action_widget(self->notebook, GTK_PACK_END);
    gtk_widget_set_visible(search, page == FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP);
    gboolean menu_sensitive = (page == FONT_MANAGER_PREVIEW_PANE_PAGE_PREVIEW);
    gtk_widget_add_css_class(menu, menu_sensitive ? "image-button" : FONT_MANAGER_STYLE_CLASS_FLAT);
    gtk_widget_remove_css_class(menu, menu_sensitive ? FONT_MANAGER_STYLE_CLASS_FLAT : "image-button");
    gtk_widget_set_sensitive(menu, menu_sensitive);
    g_idle_add((GSourceFunc) font_manager_preview_pane_update_metadata, self);
    g_signal_emit(self, signals[CHANGED], 0);
    gtk_widget_queue_draw(self->preview);
    return G_SOURCE_REMOVE;
}

static void
on_search_toggled (GtkToggleButton *button, FontManagerPreviewPane *self)
{
    g_return_if_fail(self != NULL && button != NULL);
    g_object_set(G_OBJECT(self->character_map), "search-mode", gtk_toggle_button_get_active(button), NULL);
    return;
}

GtkWidget *
create_search_button (FontManagerPreviewPane *self)
{
    GtkWidget *search = gtk_toggle_button_new();
    GtkWidget *search_icon = gtk_image_new_from_icon_name("system-search-symbolic");
    gtk_button_set_child(GTK_BUTTON(search), search_icon);
    gtk_widget_set_tooltip_text(search, _("Search available characters"));
    g_signal_connect(search, "toggled", G_CALLBACK(on_search_toggled), self);
    font_manager_widget_set_margin(search, 2);
    gtk_widget_set_margin_top(search, 1);
    gtk_widget_set_margin_bottom(search, 1);
    gtk_widget_set_visible(search, FALSE);
    return search;
}

void
on_page_switch (FontManagerPreviewPane *self,
                GtkNotebook            *notebook,
                GtkWidget              *page,
                guint                   page_num)
{
    g_return_if_fail(self != NULL);
    g_idle_add((GSourceFunc) font_manager_preview_pane_update, self);
    return;
}

static void
append_page (GtkNotebook *notebook,
             GtkWidget   *widget,
             const gchar *title)
{
    gint page_added = gtk_notebook_append_page(notebook, widget, gtk_label_new(title));
    g_warn_if_fail(page_added >= 0);
    return;
}

static void
update_mode (FontManagerPreviewPane *self)
{
    g_return_if_fail(self != NULL);
    GtkWidget *widget = gtk_notebook_get_tab_label(self->notebook, self->preview);
    gtk_label_set_text(GTK_LABEL(widget), font_manager_preview_page_mode_to_translatable_string(self->mode));
    return;
}

static gboolean
on_drop (GtkDropTarget          *target,
         const GValue           *value,
         double                  x,
         double                  y,
         FontManagerPreviewPane *self)
{
    if (G_VALUE_HOLDS(value, GDK_TYPE_FILE_LIST)) {
        GSList *files = g_value_get_boxed(value);
        /* We only handle the first face in the first file at this level */
        if (g_slist_length(files) > 0) {
            GFile *file = g_slist_nth_data(files, 0);
            g_autofree gchar *uri = g_file_get_uri(file);
            font_manager_preview_pane_show_uri(self, uri, 0);
        }
    }
    return TRUE;
}

static void
font_manager_preview_pane_init (FontManagerPreviewPane *self)
{
    g_return_if_fail(self != NULL);
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerPreviewPane");
    self->notebook = GTK_NOTEBOOK(gtk_notebook_new());
    GtkWidget *box = gtk_widget_get_first_child(GTK_WIDGET(self->notebook));
    gtk_widget_add_css_class(box, FONT_MANAGER_STYLE_CLASS_BACKGROUND);
    gtk_notebook_set_show_border(self->notebook, FALSE);
    gtk_widget_set_parent(GTK_WIDGET(self->notebook), GTK_WIDGET(self));
    self->preview = font_manager_preview_page_new();
    self->character_map = font_manager_character_map_new();
    self->properties = font_manager_font_properties_page_new();
    self->license = font_manager_license_page_new();
    self->update_required = TRUE;
    self->show_line_size = TRUE;
    FontManagerPreviewPageMode mode = font_manager_preview_page_get_preview_mode(FONT_MANAGER_PREVIEW_PAGE(self->preview));
    append_page(self->notebook, self->preview, font_manager_preview_page_mode_to_translatable_string(mode));
    append_page(self->notebook, self->character_map, _("Characters"));
    append_page(self->notebook, self->properties, _("Properties"));
    append_page(self->notebook, self->license, _("License"));
    self->page = gtk_notebook_get_current_page(self->notebook);
    GtkWidget *menu_button = font_manager_preview_page_get_action_widget(FONT_MANAGER_PREVIEW_PAGE(self->preview));
    gtk_notebook_set_action_widget(self->notebook, menu_button, GTK_PACK_START);
    self->search = create_search_button(self);
    gtk_notebook_set_action_widget(self->notebook, self->search, GTK_PACK_END);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    GBindingFlags flags = (G_BINDING_BIDIRECTIONAL | G_BINDING_SYNC_CREATE);
    g_object_bind_property(self->notebook, "page", self, "page", flags);
    g_object_bind_property(self->preview, "font", self, "font", flags);
    g_object_bind_property(self->preview, "preview-size", self, "preview-size", flags);
    g_object_bind_property(self->preview, "preview-text", self, "preview-text", flags);
    g_object_bind_property(self->preview, "preview-mode", self, "preview-mode", flags);
    g_object_bind_property(self->preview, "show-line-size", self, "show-line-size", flags);
    g_object_bind_property(self->preview, "line-spacing", self, "line-spacing", flags);
    g_object_bind_property(self->character_map, "font", self, "font", flags);
    g_object_bind_property(self->character_map, "preview-size", self, "character-map-preview-size", flags);
    g_signal_connect_swapped(self->notebook, "switch-page", G_CALLBACK(on_page_switch), self);
    g_signal_connect(self, "notify::preview-mode", G_CALLBACK(update_mode), NULL);
    GtkDropTarget *target = gtk_drop_target_new(GDK_TYPE_FILE_LIST, GDK_ACTION_COPY);
    g_signal_connect(target, "drop", G_CALLBACK(on_drop), self);
    gtk_widget_add_controller(GTK_WIDGET(self), GTK_EVENT_CONTROLLER(target));
    return;
}

/**
 * font_manager_preview_pane_show_uri:
 * @self:       #FontManagerPreviewPane
 * @uri:        filepath to display
 * @index:      index of face within file
 *
 * Returns:     %TRUE on success
 */
gboolean
font_manager_preview_pane_show_uri (FontManagerPreviewPane *self,
                                    const gchar            *uri,
                                    int                     index)
{
    g_return_val_if_fail(self != NULL, FALSE);
    if (self->current_uri && g_strcmp0(self->current_uri, uri) == 0)
        return FALSE;
    g_clear_pointer(&self->current_uri, g_free);
    g_autoptr(GFile) file = g_file_new_for_commandline_arg(uri);
    g_return_val_if_fail(g_file_is_native(file), FALSE);
    GError *error = NULL;
    g_autoptr(GFileInfo) info = g_file_query_info(file,
                                                  G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE,
                                                  G_FILE_QUERY_INFO_NONE,
                                                  NULL,
                                                  &error);
    if (error != NULL) {
        g_critical("Failed to query file info for %s : %s", uri, error->message);
        g_clear_error(&error);
        return FALSE;
    }
    const gchar *content_type = g_file_info_get_content_type(info);
    if (!g_strrstr(content_type, "font")) {
        g_warning("Ignoring unsupported filetype : %s", content_type);
        return FALSE;
    }
    g_autofree gchar *path = g_file_get_path(file);
    font_manager_add_application_font(path);
    font_manager_clear_pango_cache(gtk_widget_get_pango_context((GtkWidget *) self));
    g_autoptr(FontManagerFont) font = font_manager_font_new();
    g_autoptr(JsonObject) source = font_manager_get_attributes_from_filepath(path, index, &error);
    if (error != NULL) {
        g_critical("%s : %s", error->message, path);
        g_clear_error(&error);
        return FALSE;
    }
    g_autofree gchar *sample = font_manager_get_sample_string(source);
    json_object_set_string_member(source, "preview-text", sample);
    g_object_set(font, "source-object", source, NULL);
    font_manager_preview_pane_set_font(self, font);
    self->current_uri = g_strdup(uri);
    return TRUE;
}

/**
 * font_manager_preview_pane_set_font:
 * @self:       #FontManagerPreviewPane
 * @font:       #FontManagerFont
 */
void
font_manager_preview_pane_set_font (FontManagerPreviewPane *self,
                                    FontManagerFont        *font)
{
    g_return_if_fail(FONT_MANAGER_IS_PREVIEW_PANE(self));
    g_clear_pointer(&self->current_uri, g_free);
    if (g_set_object(&self->font, font))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_FONT]);
    self->update_required = TRUE;
    font_manager_preview_pane_update(self);
    return;
}

/**
 * font_manager_preview_pane_set_orthography:
 * @self:                                       #FontManagerPreviewPane
 * @orthography: (transfer none) (nullable):    #FontManagerOrthography
 *
 * Filter character map using provided @orthography
 */
void
font_manager_preview_pane_set_orthography (FontManagerPreviewPane *self,
                                           FontManagerOrthography *orthography)
{
    g_return_if_fail(self != NULL);
    font_manager_character_map_set_filter(FONT_MANAGER_CHARACTER_MAP(self->character_map),
                                          font_manager_orthography_get_filter(orthography));
    return;
}

/**
 * font_manager_preview_pane_restore_state:
 * @self:       #FontManagerPreviewPage
 * @settings:   #GSettings
 *
 * Applies the values in @settings to @self and also binds those settings to their
 * respective properties so that they are updated when any changes take place.
 *
 * The following keys MUST be present in @settings:
 *
 *  - preview-text
 *  - preview-mode
 *  - preview-page
 *  - preview-font-size
 *  - charmap-font-size
 *  - preview-font-size
 *  - preview-mode
 *  - preview-text
 *  - show-line-size
 *  - min-waterfall-size
 *  - max-waterfall-size
 *  - waterfall-size-ratio
 *  - charmap-font-size
 *  - waterfall-line-spacing
 */
void
font_manager_preview_pane_restore_state (FontManagerPreviewPane *self,
                                         GSettings              *settings)
{
    g_return_if_fail(self != NULL);
    g_return_if_fail(settings != NULL);
    g_settings_bind(settings, "preview-page", self, "page", G_SETTINGS_BIND_DEFAULT);
    font_manager_preview_page_restore_state(FONT_MANAGER_PREVIEW_PAGE(self->preview), settings);
    font_manager_character_map_restore_state(FONT_MANAGER_CHARACTER_MAP(self->character_map), settings);
    return;
}

/**
 * font_manager_preview_pane_set_waterfall_size:
 * @self:           #FontManagerFontPreview
 * @min_size:       Minimum point size to use for waterfall previews. (-1.0 to keep current)
 * @max_size:       Maximum size to use for waterfall previews. (-1.0 to keep current)
 * @ratio:          Waterfall point size common ratio. (-1.0 to keep current)
 */
void
font_manager_preview_pane_set_waterfall_size (FontManagerPreviewPane *self,
                                              gdouble                 min_size,
                                              gdouble                 max_size,
                                              gdouble                 ratio)
{
    g_return_if_fail(self != NULL);
    FontManagerPreviewPage *preview = FONT_MANAGER_PREVIEW_PAGE(self->preview);
    font_manager_preview_page_set_waterfall_size(preview,
                                                 min_size,
                                                 max_size,
                                                 ratio);
    return;
}

/**
 * font_manager_preview_pane_set_action_widget:
 * @self:           #FontManagerFontPreview
 * @widget:         #GtkWidget to set as action widget
 * @pack_type:      #GtkPackType
 */
void
font_manager_preview_pane_set_action_widget (FontManagerPreviewPane *self,
                                             GtkWidget              *widget,
                                             GtkPackType             pack_type)
{
    gtk_notebook_set_action_widget(GTK_NOTEBOOK(self->notebook), widget, pack_type);
    return;
}

/**
 * font_manager_preview_pane_new:
 *
 * Returns: (transfer full): A newly created #FontManagerPreviewPane.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_preview_pane_new ()
{
    return g_object_new(FONT_MANAGER_TYPE_PREVIEW_PANE, NULL);
}

