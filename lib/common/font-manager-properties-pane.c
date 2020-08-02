/* font-manager-properties-pane.c
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

#include "font-manager-properties-pane.h"

/**
 * SECTION: font-manager-properties-pane
 * @short_description: Font properties widget
 * @title: Properties Pane
 * @include: font-manager-properties-pane.h
 *
 * Widget intended to display a message in an empty area.
 */

struct _FontManagerPropertiesPane
{
    GtkPaned   parent_instance;

    GtkWidget   *copyright;
    GtkWidget   *description;
    GtkWidget   *designer;
    GtkWidget   *designer_label;
    GtkWidget   *grid;

    FontManagerFont     *font;
    FontManagerFontInfo *metadata;
};

G_DEFINE_TYPE(FontManagerPropertiesPane, font_manager_properties_pane, GTK_TYPE_PANED)

enum
{
    FONT,
    METADATA
};

enum
{
    PSNAME,
    FAMILY,
    STYLE,
    WIDTH,
    SLANT,
    WEIGHT,
    SPACING,
    VERSION,
    VENDOR,
    FILETYPE,
    FILESIZE
};

typedef struct
{
    gint object_type;
    GType gtype;
    const gchar *member_name;
    const gchar *display_name;
}
FontPropertyRow;

static const FontPropertyRow FontPropertyRows [] =
{
    { METADATA, G_TYPE_STRING, "psname", N_("PostScript Name") },
    { METADATA, G_TYPE_STRING, "family", N_("Family") },
    { METADATA, G_TYPE_STRING, "style", N_("Style") },
    { FONT, G_TYPE_INT, "width", N_("Width") },
    { FONT, G_TYPE_INT, "slant", N_("Slant") },
    { FONT, G_TYPE_INT, "weight", N_("Weight") },
    { FONT, G_TYPE_INT, "spacing", N_("Spacing") },
    { METADATA, G_TYPE_STRING, "version", N_("Version") },
    { METADATA, G_TYPE_STRING, "vendor", N_("Vendor") },
    { METADATA, G_TYPE_STRING, "filetype", N_("FileType") },
    { METADATA, G_TYPE_STRING, "filesize", N_("Filesize") },
};

#define N_FONT_PROPERTIES G_N_ELEMENTS(FontPropertyRows)

static GtkWidget *
create_title_label (FontManagerPropertiesPane *self, gint property)
{
    GtkWidget *title = gtk_label_new(FontPropertyRows[property].display_name);
    gtk_widget_set_sensitive(title, FALSE);
    gtk_widget_set_opacity(title, 0.9);
    gtk_widget_set_halign(title, GTK_ALIGN_END);
    gtk_widget_show(title);
    font_manager_widget_set_margin(title, FONT_MANAGER_DEFAULT_MARGIN);
    return title;
}

static GtkWidget *
create_value_label (FontManagerPropertiesPane *self, gint property)
{
    GtkWidget *value = gtk_label_new(NULL);
    gtk_label_set_ellipsize(GTK_LABEL(value), PANGO_ELLIPSIZE_END);
    gtk_widget_set_halign(value, GTK_ALIGN_START);
    gtk_widget_show(value);
    font_manager_widget_set_margin(value, FONT_MANAGER_DEFAULT_MARGIN);
    return value;
}

static GtkWidget *
construct_child1 (FontManagerPropertiesPane *self)
{
    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll), GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
    self->grid = gtk_grid_new();
    for (gint i = 0; i < N_FONT_PROPERTIES; i++) {
        gtk_grid_attach(GTK_GRID(self->grid), create_title_label(self, i), 0, i, 1, 1);
        gtk_grid_attach(GTK_GRID(self->grid), create_value_label(self, i), 1, i, 1, 1);
    }
    gtk_container_add(GTK_CONTAINER(scroll), self->grid);
    gtk_widget_show(self->grid);
    gtk_widget_show(scroll);
    font_manager_widget_set_expand(self->grid, FALSE);
    font_manager_widget_set_margin(self->grid, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_widget_set_margin_start(self->grid, FONT_MANAGER_DEFAULT_MARGIN * 3);
    return scroll;
}

static GtkWidget *
construct_child2 (FontManagerPropertiesPane *self)
{
    GtkWidget *child2 = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    self->copyright = gtk_label_new(NULL);
    self->description = gtk_label_new(NULL);
    self->designer = gtk_link_button_new("");
    self->designer_label = gtk_label_new("");
    gtk_label_set_yalign(GTK_LABEL(self->copyright), 0.0);
    gtk_label_set_yalign(GTK_LABEL(self->description), 0.0);
    gtk_label_set_xalign(GTK_LABEL(self->copyright), 0.0);
    gtk_label_set_xalign(GTK_LABEL(self->description), 0.0);
    font_manager_widget_set_expand(box, TRUE);
    font_manager_widget_set_margin(self->copyright, FONT_MANAGER_DEFAULT_MARGIN * 2);
    font_manager_widget_set_margin(self->description, FONT_MANAGER_DEFAULT_MARGIN * 2);
    font_manager_widget_set_margin(self->designer, FONT_MANAGER_DEFAULT_MARGIN);
    font_manager_widget_set_margin(self->designer_label, FONT_MANAGER_DEFAULT_MARGIN * 2);
    gtk_label_set_ellipsize(GTK_LABEL(self->designer_label), PANGO_ELLIPSIZE_END);
    gtk_widget_set_margin_top(self->copyright, FONT_MANAGER_DEFAULT_MARGIN * 3);
    gtk_widget_set_margin_bottom(self->copyright, 0);
    gtk_label_set_line_wrap(GTK_LABEL(self->copyright), TRUE);
    gtk_label_set_line_wrap_mode(GTK_LABEL(self->copyright), PANGO_WRAP_WORD_CHAR);
    gtk_label_set_line_wrap(GTK_LABEL(self->description), TRUE);
    gtk_label_set_line_wrap_mode(GTK_LABEL(self->description), PANGO_WRAP_WORD_CHAR);
    gtk_box_pack_start(GTK_BOX(box), self->copyright, FALSE, FALSE, 0);
    gtk_box_pack_end(GTK_BOX(box), self->description, TRUE, TRUE, 0);
    gtk_box_pack_end(GTK_BOX(child2), self->designer, FALSE, FALSE, 0);
    gtk_box_pack_end(GTK_BOX(child2), self->designer_label, FALSE, FALSE, 0);
    gtk_container_add(GTK_CONTAINER(scroll), box);
    gtk_box_pack_start(GTK_BOX(child2), scroll, TRUE, TRUE, 0);
    gtk_widget_show_all(child2);
    return child2;
}

static void
set_row_visible (FontManagerPropertiesPane *self, gint row, gboolean visible)
{
    GtkWidget *title = gtk_grid_get_child_at(GTK_GRID(self->grid), 0, row);
    GtkWidget *value = gtk_grid_get_child_at(GTK_GRID(self->grid), 1, row);
    gtk_widget_set_visible(title, visible);
    gtk_widget_set_visible(value, visible);
    return;
}

static void
update_child1 (FontManagerPropertiesPane *self)
{
    for (gint i = 0; i < N_FONT_PROPERTIES; i++) {
        gint type = FontPropertyRows[i].object_type;
        const gchar *member = FontPropertyRows[i].member_name;
        GtkWidget *widget = gtk_grid_get_child_at(GTK_GRID(self->grid), 1, i);
        if ((type == FONT && !self->font) || (type == METADATA && !self->metadata)) {
            set_row_visible(self, i, FALSE);
            continue;
        }
        if (type == FONT) {
            const gchar *str = NULL;
            if (FontPropertyRows[i].gtype == G_TYPE_INT) {
                gint value;
                g_object_get(G_OBJECT(self->font), member, &value, NULL);
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
                gtk_label_set_label(GTK_LABEL(widget), str ? str : i == WEIGHT ? _("Regular") : _("Normal"));
            }
        } else if (type == METADATA) {
            g_autofree gchar *str = NULL;
            if (FontPropertyRows[i].gtype == G_TYPE_INT) {
                gint value;
                g_object_get(G_OBJECT(self->metadata), member, &value, NULL);
                str = g_strdup_printf("%i", value);
            } else if (FontPropertyRows[i].gtype == G_TYPE_STRING) {
                g_object_get(G_OBJECT(self->metadata), member, &str, NULL);
            }
            gtk_label_set_label(GTK_LABEL(widget), str);
            if (i == VENDOR)
                set_row_visible(self, i, g_strcmp0(str, "Unknown Vendor") != 0);
        }
    }
    return;
}

static void
update_child2 (FontManagerPropertiesPane *self)
{
    if (!self->metadata)
        return;
    g_autofree gchar *copyright = NULL;
    g_autofree gchar *description = NULL;
    g_autofree gchar *designer = NULL;
    g_autofree gchar *designer_url = NULL;
    g_object_get(G_OBJECT(self->metadata),
                 "copyright", &copyright,
                 "description", &description,
                 "designer", &designer,
                 "designer-url", &designer_url,
                 NULL);
    if (copyright)
        gtk_label_set_label(GTK_LABEL(self->copyright), copyright);
    if (description)
        gtk_label_set_label(GTK_LABEL(self->description), description);
    if (designer) {
        gtk_button_set_label(GTK_BUTTON(self->designer), designer);
        gtk_label_set_label(GTK_LABEL(self->designer_label), designer);
    }
    if (designer_url) {
        gtk_link_button_set_uri(GTK_LINK_BUTTON(self->designer), designer_url);
        gtk_widget_set_tooltip_text(self->designer, designer_url);
    }
    gtk_widget_set_visible(self->designer, (designer && designer_url));
    gtk_widget_set_visible(self->designer_label, (designer && !designer_url));
    GtkWidget *button_label = gtk_bin_get_child(GTK_BIN(self->designer));
    if (GTK_IS_LABEL(button_label))
        gtk_label_set_ellipsize(GTK_LABEL(button_label), PANGO_ELLIPSIZE_END);
    return;
}

static void
reset (FontManagerPropertiesPane *self)
{
    g_return_if_fail(self != NULL);
    for (gint i = 0; i < N_FONT_PROPERTIES; i++) {
        set_row_visible(self, i, TRUE);
        GtkWidget *widget = gtk_grid_get_child_at(GTK_GRID(self->grid), 1, i);
        gtk_label_set_label(GTK_LABEL(widget), NULL);
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
font_manager_properties_pane_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerPropertiesPane *self = FONT_MANAGER_PROPERTIES_PANE(gobject);
    g_clear_object(&self->font);
    g_clear_object(&self->metadata);
    G_OBJECT_CLASS(font_manager_properties_pane_parent_class)->dispose(gobject);
}

static void
font_manager_properties_pane_class_init (FontManagerPropertiesPaneClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = font_manager_properties_pane_dispose;
    return;
}

static void
font_manager_properties_pane_init (FontManagerPropertiesPane *self)
{
    g_return_if_fail(self != NULL);
    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(self));
    gtk_style_context_add_class(ctx, GTK_STYLE_CLASS_VIEW);
    gtk_widget_set_name(GTK_WIDGET(self), "FontManagerPropertiesPane");
    gtk_paned_add1(GTK_PANED(self), construct_child1(self));
    gtk_paned_add2(GTK_PANED(self), construct_child2(self));
    gtk_paned_set_position(GTK_PANED(self), 250);
    return;
}

/**
 * font_manager_preoperties_pane_update:
 * @font: (nullable):       #FontManagerFont or %NULL
 * @metadata: (nullable):   #FontManagerFontInfo or %NULL
 */
void
font_manager_properties_pane_update (FontManagerPropertiesPane *self,
                                     FontManagerFont *font,
                                     FontManagerFontInfo *metadata)
{
    g_return_if_fail(self != NULL);
    g_set_object(&self->font, font);
    g_set_object(&self->metadata, metadata);
    reset(self);
    update_child1(self);
    update_child2(self);
    return;
}

/**
 * font_manager_properties_pane_new:
 *
 * Returns: (transfer full): A newly created #FontManagerPropertiesPane.
 * Free the returned object using #g_object_unref().
 */
GtkWidget *
font_manager_properties_pane_new ()
{
    return g_object_new(FONT_MANAGER_TYPE_PROPERTIES_PANE, NULL);
}

