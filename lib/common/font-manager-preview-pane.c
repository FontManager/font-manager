/* font-manager-preview-pane.c
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

#include "font-manager-preview-pane.h"

/**
 * SECTION: font-manager-preview-pane
 * @short_description: Preview pane widget
 * @title: Preview Pane
 * @include: font-manager-preview-pane.h
 *
 * Full featured font preview widget.
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
  static volatile gsize g_define_type_id__volatile = 0;

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
    GtkNotebook   parent_instance;

    gboolean                metadata_update_required;
    gdouble                 preview_size;
    gdouble                 glyph_preview_size;
    gchar                   *preview_text;
    gchar                   *current_uri;
    GtkWidget               *preview;
    GtkWidget               *character_map;
    GtkWidget               *properties;
    GtkWidget               *license;
    GtkWidget               *search;
    GHashTable              *samples;

    FontManagerFont         *font;
    FontManagerFontInfo     *metadata;
    FontManagerFontPreviewMode  mode;
};

G_DEFINE_TYPE(FontManagerPreviewPane, font_manager_preview_pane, GTK_TYPE_NOTEBOOK)

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
    PROP_SAMPLES,
    PROP_FONT,
    PROP_METADATA,
    PROP_ORTHOGRAPHY,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void update_mode (FontManagerPreviewPane *self);
static gboolean font_manager_preview_pane_update_metadata (FontManagerPreviewPane *self);

static void
font_manager_preview_pane_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPreviewPane *self = FONT_MANAGER_PREVIEW_PANE(gobject);
    g_clear_object(&self->font);
    g_clear_object(&self->metadata);
    g_clear_object(&self->search);
    g_clear_pointer(&self->preview_text, g_free);
    g_clear_pointer(&self->current_uri, g_free);
    g_clear_pointer(&self->samples, g_hash_table_unref);
    font_manager_clear_application_fonts();
    G_OBJECT_CLASS(font_manager_preview_pane_parent_class)->dispose(gobject);
    return;
}

static void
font_manager_preview_pane_get_property (GObject *gobject,
                                        guint property_id,
                                        GValue *value,
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
        case PROP_METADATA:
            font_manager_preview_pane_update_metadata(self);
            g_value_set_object(value, self->metadata);
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
font_manager_preview_pane_set_property (GObject *gobject,
                                        guint property_id,
                                        const GValue *value,
                                        GParamSpec *pspec)
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
        case PROP_SAMPLES:
            if (self->samples)
                g_clear_pointer(&self->samples, g_hash_table_unref);
            GHashTable *samples = g_value_get_boxed(value);
            if (samples)
                self->samples = g_hash_table_ref(samples);
            break;
        case PROP_ORTHOGRAPHY:
            font_manager_preview_pane_set_orthography(self, g_value_get_object(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
    }
    return;
}

static void
font_manager_preview_pane_class_init (FontManagerPreviewPaneClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    object_class->dispose = font_manager_preview_pane_dispose;
    object_class->get_property = font_manager_preview_pane_get_property;
    object_class->set_property = font_manager_preview_pane_set_property;

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
                                                                  FONT_MANAGER_CHARACTER_MAP_PREVIEW_SIZE,
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
                                                          FONT_MANAGER_TYPE_FONT_PREVIEW_MODE,
                                                          FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL,
                                                          G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    /**
     * FontManagerPreviewPane:sample-strings:
     *
     * Dictionary of sample strings
     */
    obj_properties[PROP_SAMPLES] = g_param_spec_boxed("samples",
                                                      NULL,
                                                      "Dictionary of sample strings",
                                                      G_TYPE_HASH_TABLE,
                                                      G_PARAM_STATIC_STRINGS |
                                                      G_PARAM_READWRITE);

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
     * FontManagerPreviewPane:metadata:
     *
     * #FontManagerFontInfo for the currently displayed font.
     */
    obj_properties[PROP_METADATA] = g_param_spec_object("metadata",
                                                         NULL,
                                                         "#FontManagerFontInfo",
                                                         FONT_MANAGER_TYPE_FONT_INFO,
                                                         G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);

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

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static gboolean
font_manager_preview_pane_update_metadata (FontManagerPreviewPane *self)
{
    g_return_val_if_fail(self != NULL, G_SOURCE_REMOVE);
    if (!self->metadata_update_required || !font_manager_json_proxy_is_valid(FONT_MANAGER_JSON_PROXY(self->font)))
        return G_SOURCE_REMOVE;
    gint index = 0;
    GError *error = NULL;
    g_autofree gchar *filepath = NULL;
    JsonObject *res = NULL;
    FontManagerFontInfo *metadata = font_manager_font_info_new();
    FontManagerDatabase *db = font_manager_get_database(FONT_MANAGER_DATABASE_TYPE_BASE, &error);
    g_object_get(G_OBJECT(self->font), "filepath", &filepath, "findex", &index, NULL);
    if (error == NULL) {
        const gchar *select = "SELECT * FROM Metadata WHERE filepath='%s' AND findex='%i'";
        g_autofree gchar *query = g_strdup_printf(select, filepath, index);
        res = font_manager_database_get_object(db, query, &error);
    }
    if (error != NULL) {
        g_warning("There was an error retrieving metadata from the database for %s : %s", filepath, error->message);
        g_clear_error(&error);
    }
    if (!res) {
        res = font_manager_get_metadata(filepath, index, &error);
        if (error != NULL) {
            g_critical("Failed to get metadata for %s : %s", filepath, error->message);
            g_clear_error(&error);
        }
    }
    g_object_set(G_OBJECT(metadata), "source-object", res, NULL);
    json_object_unref(res);
    g_object_unref(db);
    g_set_object(&self->metadata, metadata);
    g_object_unref(metadata);
    self->metadata_update_required = FALSE;
    return G_SOURCE_REMOVE;
}

static gboolean
font_manager_preview_pane_update (FontManagerPreviewPane *self)
{
    g_return_val_if_fail(self != NULL, G_SOURCE_REMOVE);
    gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(self));
    GtkWidget *menu = gtk_notebook_get_action_widget(GTK_NOTEBOOK(self), GTK_PACK_START);
    GtkWidget *search = gtk_notebook_get_action_widget(GTK_NOTEBOOK(self), GTK_PACK_END);
    gboolean menu_sensitive = (page == FONT_MANAGER_PREVIEW_PANE_PAGE_PREVIEW);
    gtk_widget_set_sensitive(menu, menu_sensitive);
    GtkStyleContext *ctx = gtk_widget_get_style_context(menu);
    if (!menu_sensitive)
        gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_FLAT);
    else
        gtk_style_context_remove_class(ctx, GTK_STYLE_CLASS_FLAT);
    gtk_widget_set_visible(search, page == FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP);
    if (page == FONT_MANAGER_PREVIEW_PANE_PAGE_PREVIEW) {
        g_autofree gchar *description = NULL;
        if (self->font)
            g_object_get(G_OBJECT(self->font), "description", &description, NULL);
        if (!description)
            description = g_strdup(FONT_MANAGER_DEFAULT_FONT);
        font_manager_font_preview_set_font_description(FONT_MANAGER_FONT_PREVIEW(self->preview), description);
    } else if (page == FONT_MANAGER_PREVIEW_PANE_PAGE_CHARACTER_MAP) {
        font_manager_character_map_set_font(FONT_MANAGER_CHARACTER_MAP(self->character_map), self->font);
    } else if (page == FONT_MANAGER_PREVIEW_PANE_PAGE_PROPERTIES) {
        font_manager_preview_pane_update_metadata(self);
        font_manager_properties_pane_update(FONT_MANAGER_PROPERTIES_PANE(self->properties), self->font, self->metadata);
    } else if (page == FONT_MANAGER_PREVIEW_PANE_PAGE_LICENSE) {
        if (self->metadata) {
            font_manager_preview_pane_update_metadata(self);
            FontManagerfsType fsType;
            g_autofree gchar *license_data = NULL;
            g_autofree gchar *license_url = NULL;
            g_object_get(G_OBJECT(self->metadata), "fsType", &fsType, "license-data", &license_data, "license-url", &license_url, NULL);
            g_object_set(G_OBJECT(self->license), "fstype", fsType, "license-data", license_data, "license-url", license_url, NULL);
        } else {
            g_object_set(G_OBJECT(self->license), "fstype", FONT_MANAGER_FSTYPE_RESTRICTED_LICENSE, "license-data", NULL, "license-url", NULL, NULL);
        }
    }
    g_signal_emit(self, signals[CHANGED], 0);
    g_idle_add((GSourceFunc) font_manager_preview_pane_update_metadata, self);
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
    GtkWidget *search_icon = gtk_image_new_from_icon_name("system-search-symbolic", GTK_ICON_SIZE_SMALL_TOOLBAR);
    gtk_container_add(GTK_CONTAINER(search), search_icon);
    gtk_widget_set_tooltip_text(search, _("Search available characters"));
    g_signal_connect(search, "toggled", G_CALLBACK(on_search_toggled), self);
    gtk_widget_show(search_icon);
    gtk_widget_show(search);
    font_manager_widget_set_margin(search, 2);
    gtk_widget_set_margin_top(search, 1);
    gtk_widget_set_margin_bottom(search, 1);
    return search;
}

void
on_page_switch (GtkNotebook *notebook, GtkWidget *page, guint page_num, gpointer user_data)
{
    g_return_if_fail(notebook != NULL);
    FontManagerPreviewPane *self = FONT_MANAGER_PREVIEW_PANE(notebook);
    g_idle_add((GSourceFunc) font_manager_preview_pane_update, self);
    return;
}

static void
append_page (FontManagerPreviewPane *self, GtkWidget *widget, const gchar *title)
{
    gint page_added = gtk_notebook_append_page(GTK_NOTEBOOK(self), widget, gtk_label_new(title));
    g_warn_if_fail(page_added >= 0);
    return;
}

static void
update_mode (FontManagerPreviewPane *self)
{
    GtkWidget *widget = gtk_notebook_get_tab_label(GTK_NOTEBOOK(self), self->preview);
    gtk_label_set_text(GTK_LABEL(widget), font_manager_font_preview_mode_to_translatable_string(self->mode));
    GApplication *application = g_application_get_default();
    GAction *action = g_action_map_lookup_action(G_ACTION_MAP(application), "preview-mode");
    GVariant *variant = g_variant_new_string(font_manager_font_preview_mode_to_string(self->mode));
    g_simple_action_set_state(G_SIMPLE_ACTION(action), variant);
    return;
}

static void
on_mode_action_activated (GSimpleAction *action,
                          GVariant *parameter,
                          FontManagerPreviewPane *self)
{

    FontManagerFontPreviewMode mode = FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM;
    const gchar *name = g_variant_get_string(parameter, NULL);
    if (g_strcmp0(name, "Waterfall") == 0)
        mode = FONT_MANAGER_FONT_PREVIEW_MODE_WATERFALL;
    else if (g_strcmp0(name, "Preview") == 0)
        mode = FONT_MANAGER_FONT_PREVIEW_MODE_PREVIEW;
    font_manager_font_preview_set_preview_mode(FONT_MANAGER_FONT_PREVIEW(self->preview), mode);
    update_mode(self);
    GtkWidget *menu = gtk_notebook_get_action_widget(GTK_NOTEBOOK(self), GTK_PACK_START);
    GtkPopover *popover = gtk_menu_button_get_popover(GTK_MENU_BUTTON(menu));
    if (popover)
        gtk_popover_popdown(popover);
    return;
}

static GtkWidget *
create_menu_button (FontManagerPreviewPane *self)
{
    GApplication *application = g_application_get_default();
    GtkWidget *menu_button = gtk_menu_button_new();
    GtkWidget *menu_icon = gtk_image_new_from_icon_name("view-more-symbolic", GTK_ICON_SIZE_SMALL_TOOLBAR);
    gtk_container_add(GTK_CONTAINER(menu_button), menu_icon);
    GMenu *mode_menu = g_menu_new();
    GVariant *variant = g_variant_new_string("Waterfall");
    GSimpleAction *action = g_simple_action_new_stateful("preview-mode", G_VARIANT_TYPE_STRING, variant);
    g_simple_action_set_enabled(action, TRUE);
    g_action_map_add_action(G_ACTION_MAP(application), G_ACTION(action));
    g_signal_connect(action, "activate", G_CALLBACK(on_mode_action_activated), self);
    for (gint i = 0; i <= FONT_MANAGER_FONT_PREVIEW_MODE_LOREM_IPSUM; i++) {
        const gchar *action_state = font_manager_font_preview_mode_to_string((FontManagerFontPreviewMode) i);
        const gchar *display_name = font_manager_font_preview_mode_to_translatable_string((FontManagerFontPreviewMode) i);
        g_autofree gchar *action_name = g_strdup_printf("app.preview-mode::%s", action_state);
        g_autofree gchar *accel = g_strdup_printf("<Alt>%i", i + 1);
        const gchar *accels [] = { accel, NULL };
        gtk_application_set_accels_for_action(GTK_APPLICATION(application), action_name, accels);
        g_autoptr(GMenuItem) item = g_menu_item_new(display_name, action_name);
        g_menu_item_set_attribute(item, "accel", "s", accels[0],
                                        "action", "preview-mode",
                                        "target-value", action_name);
        g_menu_append_item(mode_menu, item);
    }
    gtk_menu_button_set_menu_model(GTK_MENU_BUTTON(menu_button), G_MENU_MODEL(mode_menu));
    gtk_widget_show(menu_icon);
    gtk_widget_show(menu_button);
    g_object_unref(action);
    font_manager_widget_set_margin(menu_button, 2);
    gtk_widget_set_margin_top(menu_button, 1);
    gtk_widget_set_margin_bottom(menu_button, 1);
    return menu_button;
}

static void
on_search_action_activated (GSimpleAction *action,
                            G_GNUC_UNUSED GVariant *parameter,
                            FontManagerPreviewPane *self)
{
    gboolean current_state = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(self->search));
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(self->search), !current_state);
    return;
}

static void
font_manager_preview_pane_init (FontManagerPreviewPane *self)
{
    g_return_if_fail(self != NULL);
    gtk_notebook_set_show_border(GTK_NOTEBOOK(self), FALSE);
    self->preview = font_manager_font_preview_new();
    self->character_map = font_manager_character_map_new();
    self->properties = font_manager_properties_pane_new();
    self->license = font_manager_license_pane_new();
    self->metadata_update_required = TRUE;
    FontManagerFontPreviewMode mode = font_manager_font_preview_get_preview_mode(FONT_MANAGER_FONT_PREVIEW(self->preview));
    append_page(self, self->preview, font_manager_font_preview_mode_to_translatable_string(mode));
    append_page(self, self->character_map, _("Characters"));
    append_page(self, self->properties, _("Properties"));
    append_page(self, self->license, _("License"));
    GSimpleAction *search = g_simple_action_new("character-search", NULL);
    g_simple_action_set_enabled(search, TRUE);
    g_signal_connect(search, "activate", G_CALLBACK(on_search_action_activated), self);
    GtkApplication *application = GTK_APPLICATION(g_application_get_default());
    g_action_map_add_action(G_ACTION_MAP(application), G_ACTION(search));
    g_object_unref(search);
    const gchar *accels [] = { "<Ctrl>f", NULL };
    gtk_application_set_accels_for_action(application, "app.character-search", accels);
    gtk_notebook_set_action_widget(GTK_NOTEBOOK(self), create_menu_button(self), GTK_PACK_START);
    self->search = g_object_ref_sink(create_search_button(self));
    gtk_notebook_set_action_widget(GTK_NOTEBOOK(self), self->search, GTK_PACK_END);
    gtk_widget_show(self->preview);
    gtk_widget_show(self->character_map);
    gtk_widget_show(self->properties);
    gtk_widget_show(self->license);
    GBindingFlags flags = (G_BINDING_BIDIRECTIONAL | G_BINDING_SYNC_CREATE);
    g_object_bind_property(self->preview, "preview-size", self, "preview-size", flags);
    g_object_bind_property(self->preview, "preview-text", self, "preview-text", flags);
    g_object_bind_property(self->preview, "preview-mode", self, "preview-mode", flags);
    g_object_bind_property(self->preview, "samples", self, "samples", flags);
    g_object_bind_property(self->character_map, "preview-size", self, "character-map-preview-size", flags);
    g_signal_connect(self, "switch-page", G_CALLBACK(on_page_switch), NULL);
    return;
}

/**
 * font_manager_preview_pane_show_uri:
 * @self:       #FontManagerPreviewPane
 * @uri:        filepath to display
 */
void
font_manager_preview_pane_show_uri (FontManagerPreviewPane *self, const gchar *uri)
{
    g_return_if_fail(self != NULL);
    if (self->current_uri && g_strcmp0(self->current_uri, uri) == 0)
        return;
    g_clear_pointer(&self->current_uri, g_free);
    g_autoptr(GFile) file = g_file_new_for_commandline_arg(uri);
    g_return_if_fail(g_file_is_native(file));
    GError *error = NULL;
    g_autoptr(GFileInfo) info = g_file_query_info(file, G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE,
                                                  G_FILE_QUERY_INFO_NONE, NULL, &error);
    if (error != NULL) {
        g_critical("Failed to query file info for %s : %s", uri, error->message);
        g_clear_error(&error);
        return;
    }
    const gchar *content_type = g_file_info_get_content_type(info);
    if (!g_strrstr(content_type, "font")) {
        g_warning("Ignoring unsupported filetype : %s", content_type);
        return;
    }
    g_autofree gchar *path = g_file_get_path(file);
    font_manager_add_application_font(path);
    FontManagerFont *font = font_manager_font_new();
    JsonObject *source = font_manager_get_attributes_from_filepath(path, 0, &error);
    if (error != NULL) {
        g_critical("%s : %s", error->message, path);
        g_clear_error(&error);
        g_object_unref(font);
        return;
    }
    JsonObject *orthography = font_manager_get_orthography_results(source);
    if (!json_object_has_member(orthography, "Basic Latin")) {
        GList *charset = font_manager_get_charset_from_filepath(path, 0);
        if (!self->samples) {
            self->samples = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, g_free);
            g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_SAMPLES]);
        }
        g_autofree gchar *sample = font_manager_get_sample_string_for_orthography(orthography, charset);
        if (sample) {
            const gchar *description = json_object_get_string_member(source, "description");
            g_hash_table_insert(self->samples, g_strdup(description), g_strdup(sample));
        }
        g_list_free(charset);
    }
    g_object_set(font, "source-object", source, NULL);
    font_manager_preview_pane_set_font(self, font);
    self->current_uri = g_strdup(uri);
    g_object_unref(font);
    json_object_unref(source);
    json_object_unref(orthography);
    return;
}

/**
 * font_msnager_preview_pane_set_font:
 * @self:       #FontManagerPreviewPane
 * @font:       #FontManagerFont
 */
void
font_manager_preview_pane_set_font (FontManagerPreviewPane *self, FontManagerFont *font)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->current_uri, g_free);
    if (g_set_object(&self->font, font))
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_FONT]);
    self->metadata_update_required = TRUE;
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
    font_manager_character_map_set_filter(FONT_MANAGER_CHARACTER_MAP(self->character_map), orthography);
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
