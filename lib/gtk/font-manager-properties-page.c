/* font-manager-properties-page.c
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

#include "font-manager-properties-page.h"

/**
 * SECTION: font-manager-properties-page
 * @short_description: Font properties widget
 * @title: Properties Pane
 * @include: font-manager-properties-page.h
 *
 * This widget displays extended information about the selected font file,
 * including any embedded designer details, copyright and design description.
 */

struct _FontManagerPropertiesPageClass
{
    GtkWidgetClass  parent_instance;

    GtkWidget   *copyright;
    GtkWidget   *description;
    GtkWidget   *designer;
    GtkWidget   *designer_label;
    GtkWidget   *grid;

    JsonObject  *properties;
};

G_DEFINE_TYPE(FontManagerPropertiesPage, font_manager_font_properties_page, GTK_TYPE_WIDGET)

static const struct
{
    const gchar *member_name;
    const gchar *display_name;
}
FontPropertyRow [] =
{
    { "psname", N_("PostScript Name") },
    { "family", N_("Family") },
    { "style", N_("Style") },
    { "width", N_("Width") },
    { "slant", N_("Slant") },
    { "weight", N_("Weight") },
    { "spacing", N_("Spacing") },
    { "version", N_("Version") },
    /* Translators : For context see https://docs.microsoft.com/en-us/typography/opentype/spec/os2#achvendid */
    { "vendor", N_("Vendor") },
    { "filetype", N_("FileType") },
    /* Keep this entry last */
    { "filesize", N_("Filesize") },
};

#define N_FONT_PROPERTIES G_N_ELEMENTS(FontPropertyRow)
#define FILESIZE_PROPERTY (N_FONT_PROPERTIES - 1)

static GtkWidget *
create_title_label (FontManagerPropertiesPage *self, gint property)
{

    GtkWidget *title = gtk_label_new(g_dgettext(NULL, FontPropertyRow[property].display_name));
    gtk_widget_set_sensitive(title, FALSE);
    gtk_widget_set_opacity(title, 0.9);
    gtk_widget_set_halign(title, GTK_ALIGN_END);
    font_manager_widget_set_margin(title, FONT_MANAGER_DEFAULT_MARGIN);
    return title;
}

static GtkWidget *
create_value_label (FontManagerPropertiesPage *self, gint property)
{
    GtkWidget *value = gtk_label_new(NULL);
    gtk_label_set_ellipsize(GTK_LABEL(value), PANGO_ELLIPSIZE_END);
    gtk_widget_set_halign(value, GTK_ALIGN_START);
    font_manager_widget_set_margin(value, FONT_MANAGER_DEFAULT_MARGIN);
    return value;
}

static GtkWidget *
construct_start_child (FontManagerPropertiesPage *self)
{
    GtkWidget *scroll = gtk_scrolled_window_new();
    self->grid = gtk_grid_new();
    for (gint i = 0; i < N_FONT_PROPERTIES; i++) {
        gtk_grid_attach(GTK_GRID(self->grid), create_title_label(self, i), 0, i, 1, 1);
        if (i == FILESIZE_PROPERTY) {
            GtkWidget *value = gtk_link_button_new_with_label("", NULL);
            GtkWidget *label = gtk_button_get_child(GTK_BUTTON(value));
            gtk_widget_set_halign(label, GTK_ALIGN_START);
            gtk_widget_set_halign(value, GTK_ALIGN_START);
            gtk_widget_remove_css_class(value, "text-button");
            gtk_widget_remove_css_class(value, "link");
            gtk_grid_attach(GTK_GRID(self->grid), value, 1, i, 1, 1);
        } else {
            gtk_grid_attach(GTK_GRID(self->grid), create_value_label(self, i), 1, i, 1, 1);
        }
    }
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), self->grid);
    font_manager_widget_set_expand(self->grid, FALSE);
    font_manager_widget_set_margin(self->grid, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_start(self->grid, FONT_MANAGER_DEFAULT_MARGIN * 3);
    return scroll;
}

static GtkWidget *
construct_end_child (FontManagerPropertiesPage *self)
{
    GtkWidget *child2 = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    GtkWidget *scroll = gtk_scrolled_window_new();
    self->copyright = gtk_label_new(NULL);
    self->description = gtk_label_new(NULL);
    self->designer = gtk_link_button_new("");
    self->designer_label = gtk_label_new("");
    gtk_label_set_ellipsize(GTK_LABEL(self->designer_label), PANGO_ELLIPSIZE_END);
    gtk_widget_set_margin_top(self->copyright, FONT_MANAGER_DEFAULT_MARGIN * 3);
    gtk_widget_set_margin_bottom(self->copyright, 0);
    gtk_label_set_wrap(GTK_LABEL(self->copyright), TRUE);
    gtk_label_set_wrap_mode(GTK_LABEL(self->copyright), PANGO_WRAP_WORD_CHAR);
    gtk_label_set_wrap(GTK_LABEL(self->description), TRUE);
    gtk_label_set_wrap_mode(GTK_LABEL(self->description), PANGO_WRAP_WORD_CHAR);
    gtk_box_append(GTK_BOX(box), self->copyright);
    gtk_box_append(GTK_BOX(box), self->description);
    gtk_widget_set_size_request(box, 0, 0);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), box);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll),
                                   GTK_POLICY_NEVER,
                                   GTK_POLICY_AUTOMATIC);
    gtk_box_append(GTK_BOX(child2), scroll);
    gtk_box_append(GTK_BOX(child2), self->designer);
    gtk_box_append(GTK_BOX(child2), self->designer_label);
    gtk_label_set_yalign(GTK_LABEL(self->copyright), 0.0);
    gtk_label_set_yalign(GTK_LABEL(self->description), 0.0);
    gtk_label_set_xalign(GTK_LABEL(self->copyright), 0.0);
    gtk_label_set_xalign(GTK_LABEL(self->description), 0.0);
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    font_manager_widget_set_expand(box, TRUE);
    font_manager_widget_set_expand(scroll, TRUE);
    font_manager_widget_set_expand(self->copyright, FALSE);
    font_manager_widget_set_expand(self->description, TRUE);
    font_manager_widget_set_expand(self->designer, FALSE);
    font_manager_widget_set_expand(self->designer_label, FALSE);
    font_manager_widget_set_margin(self->copyright, FONT_MANAGER_DEFAULT_MARGIN * 2);
    font_manager_widget_set_margin(self->description, FONT_MANAGER_DEFAULT_MARGIN * 2);
    /* Affected by the margin set on our pane separator */
    gtk_widget_set_margin_start(self->copyright, 0);
    gtk_widget_set_margin_start(self->description, 0);
    font_manager_widget_set_margin(self->designer, FONT_MANAGER_DEFAULT_MARGIN);
    font_manager_widget_set_margin(self->designer_label, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_start(child2, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    gtk_widget_set_margin_end(child2, FONT_MANAGER_DEFAULT_MARGIN * 1.5);
    return child2;
}

static void
set_row_visible (FontManagerPropertiesPage *self,
                 gint                       row,
                 gboolean                   visible)
{
    GtkWidget *title = gtk_grid_get_child_at(GTK_GRID(self->grid), 0, row);
    GtkWidget *value = gtk_grid_get_child_at(GTK_GRID(self->grid), 1, row);
    gtk_widget_set_visible(title, visible);
    gtk_widget_set_visible(value, visible);
    return;
}

static void
reset (FontManagerPropertiesPage *self)
{
    g_return_if_fail(self != NULL);
    for (gint i = 0; i < N_FONT_PROPERTIES; i++) {
        set_row_visible(self, i, TRUE);
        GtkWidget *widget = gtk_grid_get_child_at(GTK_GRID(self->grid), 1, i);
        if (i == FILESIZE_PROPERTY) {
            gtk_link_button_set_uri(GTK_LINK_BUTTON(widget), "");
            gtk_button_set_label(GTK_BUTTON(widget), NULL);
        } else {
            gtk_label_set_label(GTK_LABEL(widget), NULL);
        }
    }
    gtk_label_set_text(GTK_LABEL(self->copyright), NULL);
    gtk_label_set_text(GTK_LABEL(self->description), NULL);
    gtk_button_set_label(GTK_BUTTON(self->designer), "");
    gtk_link_button_set_uri(GTK_LINK_BUTTON(self->designer), "");
    gtk_widget_set_tooltip_text(self->designer, "");
    gtk_label_set_label(GTK_LABEL(self->designer_label), "");
    return;
}

static void
update (FontManagerPropertiesPage *self)
{
    reset(self);

    for (gint i = 0; i < N_FONT_PROPERTIES; i++) {

        const gchar *member = FontPropertyRow[i].member_name;
        if (!json_object_has_member(self->properties, member)) {
            set_row_visible(self, i, FALSE);
            continue;
        }
        const gchar *value = json_object_get_string_member(self->properties, member);
        if (!value) {
            set_row_visible(self, i, FALSE);
            continue;
        }

        GtkWidget *widget = gtk_grid_get_child_at(GTK_GRID(self->grid), 1, i);

        if (i == FILESIZE_PROPERTY) {
            g_autofree gchar *uri = NULL;
            if (json_object_has_member(self->properties, "filepath")) {
                const gchar *filepath = json_object_get_string_member(self->properties, "filepath");
                gtk_widget_set_tooltip_text(GTK_WIDGET(widget), filepath);
                g_autofree gchar *dirpath = g_path_get_dirname(filepath);
                uri = g_strdup_printf("file://%s", dirpath);
            }
            gtk_link_button_set_uri(GTK_LINK_BUTTON(widget), uri ? uri : "");
            gtk_button_set_label(GTK_BUTTON(widget), value);
        } else {
            gtk_label_set_label(GTK_LABEL(widget), value);
        }

    }

    const gchar *copyright = NULL;
    const gchar *description = NULL;
    const gchar *designer = NULL;
    const gchar *designer_url = NULL;

    if (json_object_has_member(self->properties, "copyright"))
        copyright = json_object_get_string_member(self->properties, "copyright");

    if (json_object_has_member(self->properties, "description"))
        description = json_object_get_string_member(self->properties, "description");

    if (json_object_has_member(self->properties, "designer"))
        designer = json_object_get_string_member(self->properties, "designer");

    if (json_object_has_member(self->properties, "designer-url"))
        designer_url = json_object_get_string_member(self->properties, "designer-url");

    gtk_label_set_label(GTK_LABEL(self->copyright), copyright);
    gtk_label_set_label(GTK_LABEL(self->description), description);
    gtk_button_set_label(GTK_BUTTON(self->designer), designer ? designer : "");
    gtk_label_set_label(GTK_LABEL(self->designer_label), designer ? designer : "");
    gtk_link_button_set_uri(GTK_LINK_BUTTON(self->designer), designer_url ? designer_url : "");
    gtk_widget_set_tooltip_text(self->designer, designer_url ? designer_url : "");
    gtk_widget_set_visible(self->designer, (designer && designer_url));
    gtk_widget_set_visible(self->designer_label, (designer && !designer_url));
    GtkWidget *button_label = gtk_button_get_child(GTK_BUTTON(self->designer));
    if (GTK_IS_LABEL(button_label))
        gtk_label_set_ellipsize(GTK_LABEL(button_label), PANGO_ELLIPSIZE_END);
    return;
}

static void
font_manager_font_properties_page_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPropertiesPage *self = FONT_MANAGER_PROPERTIES_PAGE(gobject);
    g_clear_pointer(&self->properties, json_object_unref);
    font_manager_widget_dispose(GTK_WIDGET(self));
    G_OBJECT_CLASS(font_manager_font_properties_page_parent_class)->dispose(gobject);
}

static void
font_manager_font_properties_page_class_init (FontManagerPropertiesPageClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);
    object_class->dispose = font_manager_font_properties_page_dispose;
    gtk_widget_class_set_layout_manager_type(widget_class, GTK_TYPE_BOX_LAYOUT);
    gtk_widget_class_set_css_name(widget_class, "FontManagerPropertiesPage");
    return;
}

static void
font_manager_font_properties_page_init (FontManagerPropertiesPage *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_add_css_class(GTK_WIDGET(self), FONT_MANAGER_STYLE_CLASS_VIEW);
    font_manager_widget_set_name(GTK_WIDGET(self), "FontManagerPropertiesPage");
    GtkWidget *pane = gtk_paned_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_widget_set_parent(pane, GTK_WIDGET(self));
    font_manager_widget_set_expand(pane, TRUE);
    gtk_paned_set_start_child(GTK_PANED(pane), construct_start_child(self));
    gtk_paned_set_end_child(GTK_PANED(pane), construct_end_child(self));
    font_manager_widget_set_expand(GTK_WIDGET(self), TRUE);
    return;
}

/**
 * font_manager_preoperties_pane_update:
 * @properties: (nullable):     #JsonObject or %NULL
 *
 * The following are valid members for @properties
 *
 * {
 *      "psname"        :   string,
 *      "family"        :   string,
 *      "style"         :   string,
 *      "width"         :   string,
 *      "slant"         :   string,
 *      "weight"        :   string,
 *      "spacing"       :   string,
 *      "version"       :   string,
 *      "vendor"        :   string,
 *      "filetype"      :   string,
 *      "filepath"      :   string,
 *      "filesize"      :   string,
 *      "copyright"     :   string,
 *      "description"   :   string,
 *      "designer"      :   string,
 *      "designer-url"  :   string
 * }
 *
 * Missing members and %NULL values are allowed.
 * Members not listed above are ignored.
 */
void
font_manager_font_properties_page_update (FontManagerPropertiesPage *self,
                                          JsonObject                *properties)
{
    g_return_if_fail(self != NULL);
    g_clear_pointer(&self->properties, json_object_unref);
    self->properties = properties ? json_object_ref(properties) : NULL;
    update(self);
    return;
}

/**
 * font_manager_font_properties_page_new:
 *
 * Returns: (transfer full): A newly created #FontManagerPropertiesPage.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_font_properties_page_new ()
{
    return g_object_new(FONT_MANAGER_TYPE_PROPERTIES_PAGE, NULL);
}

