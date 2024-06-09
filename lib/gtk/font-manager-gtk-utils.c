/* font-manager-gtk-utils.c
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

#include "font-manager-gtk-utils.h"

/**
 * SECTION: font-manager-gtk-utils
 * @short_description: Gtk related utility functions
 * @title: Gtk utility functions
 * @include: font-manager-gtk-utils.h
 */

/**
 * font_manager_set_application_style:
 *
 * Load application specific CSS and icons.
 */
void
font_manager_set_application_style (void)
{
    g_autofree gchar *css = g_build_path(G_DIR_SEPARATOR_S,
                                         FONT_MANAGER_BUS_PATH,
                                         "ui",
                                         "FontManager.css",
                                         NULL);

    g_autofree gchar *icons = g_build_path(G_DIR_SEPARATOR_S,
                                           FONT_MANAGER_BUS_PATH,
                                           "icons",
                                           G_DIR_SEPARATOR_S,
                                           NULL);

    GdkDisplay *default_display = gdk_display_get_default();
    GtkIconTheme *icon_theme = gtk_icon_theme_get_for_display(default_display);
    g_autoptr(GtkCssProvider) css_provider = gtk_css_provider_new();
    g_debug("Adding icons from resource path : %s", icons);
    gtk_icon_theme_add_resource_path(icon_theme, icons);
    g_debug("Loading custom css from resource path : %s", css);
    gtk_css_provider_load_from_resource(css_provider, css);
    gtk_style_context_add_provider_for_display(default_display,
                                              GTK_STYLE_PROVIDER(css_provider),
                                              GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    return;
}

/**
 * font_manager_clear_pango_cache:
 * @ctx:    #PangoContext
 *
 * Forces Pango to update the cached font configuration.
 *
 * Required to render sourced fonts on Pango > 1.47
 */
void
font_manager_clear_pango_cache (PangoContext *ctx)
{
    PangoFontMap *font_map = pango_context_get_font_map(ctx);
    pango_fc_font_map_config_changed((PangoFcFontMap *) font_map);
    return;
}

/**
 * font_manager_text_tag_table_new:
 *
 * Returns: (transfer full): A newly created #GtkTextTagTable.
 * Free the returned object using #g_object_unref().
 */
GtkTextTagTable *
font_manager_text_tag_table_new (void)
{
    GtkTextTagTable *tags = gtk_text_tag_table_new();
    g_autoptr(GtkTextTag) font = gtk_text_tag_new("FontDescription");
    g_object_set(font, "fallback", FALSE, NULL);
    if (!gtk_text_tag_table_add(tags, font))
        g_warning(G_STRLOC" : Failed to add tag to table: FontDescription");
    g_autoptr(GtkTextTag) point_size = gtk_text_tag_new("SizePoint");
    g_object_set(point_size, "family", "Monospace", "rise", 1250, "size-points", 6.5, NULL);
    if (!gtk_text_tag_table_add(tags, point_size))
        g_warning(G_STRLOC" : Failed to add tag to table: size-points");
    return tags;
}

/**
 * font_manager_widget_set_align:
 * @widget:     #GtkWidget
 * @align:      #GtkAlign
 *
 * Set both halign and valign to the same value.
 */
void
font_manager_widget_set_align (GtkWidget *widget,
                               GtkAlign   align)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_halign(GTK_WIDGET(widget), align);
    gtk_widget_set_valign(GTK_WIDGET(widget), align);
    return;
}

/**
 * font_manager_widget_set_expand:
 * @widget:     #GtkWidget
 * @expand:     #gboolean
 *
 * Set both hexpand and vexpand to the same value.
 */
void
font_manager_widget_set_expand (GtkWidget *widget,
                                gboolean   expand)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_hexpand(GTK_WIDGET(widget), expand);
    gtk_widget_set_vexpand(GTK_WIDGET(widget), expand);
    return;
}

/**
 * font_manager_widget_set_margin:
 * @widget:     #GtkWidget
 * @margin:     #gint
 *
 * Set all margin properties to the same value.
 */
void
font_manager_widget_set_margin (GtkWidget *widget,
                                gint       margin)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_margin_start(widget, margin);
    gtk_widget_set_margin_end(widget, margin);
    gtk_widget_set_margin_top(widget, margin);
    gtk_widget_set_margin_bottom(widget, margin);
    return;
}

/**
 * font_manager_widget_set_name:
 * @widget:           #GtkWidget
 * @name: (nullable): widget name
 *
 * Set widget name and css properties to the same value.
 */
void
font_manager_widget_set_name (GtkWidget   *widget,
                              const gchar *name)
{
    GtkWidgetClass *widget_class = GTK_WIDGET_GET_CLASS(widget);

    if (name)
        gtk_widget_set_name(widget, name);
    else
        name = gtk_widget_get_name(widget);

    gtk_widget_add_css_class(widget, name);
    gtk_widget_class_set_css_name(widget_class, name);
    return;
}

/**
 * font_manager_widget_dispose:
 * @widget:     #GtkWidget
 *
 * Convenience function which iterates through the children of a #GtkWidget,
 * calls #gtk_widget_unparent() on each and sets the pointer to #NULL.
 */
void
font_manager_widget_dispose (GtkWidget *widget)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    GtkWidget *child = gtk_widget_get_first_child(GTK_WIDGET(widget));
    while (child) {
        GtkWidget *next = gtk_widget_get_next_sibling(child);
        g_clear_pointer(&child, gtk_widget_unparent);
        child = next;
    }
    return;
}

/**
 * font_manager_get_localized_pangram:
 *
 * Retrieve a sample string from Pango for the default language.
 * If Pango does not have a sample string for language,
 * the classic "The quick brown fox..." is returned.
 *
 * Returns: (transfer full): A newly allocated string. Free the result using #g_free.
 */
gchar *
font_manager_get_localized_pangram (void)
{
    PangoLanguage * lang = pango_language_get_default();
    const gchar *pangram = pango_language_get_sample_string(lang);
    return g_strdup(pangram);
}

/**
 * font_manager_get_localized_preview_text:
 *
 * Returns: (transfer full): A newly allocated string. Free the result using #g_free.
 */
gchar *
font_manager_get_localized_preview_text (void)
{
    g_autofree gchar *pangram = font_manager_get_localized_pangram();
    return g_strdup_printf(FONT_MANAGER_DEFAULT_PREVIEW_TEXT, pangram);
}

/**
 * font_manager_get_shortcut_for_stateful_action:
 * @prefix: (nullable): Action prefix i.e. "app", "window", etc.
 * @name:               Action name
 * @target:             Action target
 * @accel: (nullable):  A valid accelerator string as understood by #gtk_accelerator_parse
 *
 * Returns: (transfer full) (nullable): A newly created #GtkShortcut.
 * Free the returned object using #g_object_unref.
 */
GtkShortcut *
font_manager_get_shortcut_for_stateful_action (const gchar *prefix,
                                               const gchar *name,
                                               const gchar *target,
                                               const gchar *accel)
{
    g_return_val_if_fail(name != NULL && target != NULL, NULL);
    g_autofree gchar *action_name = prefix ?
                                    g_strdup_printf("%s.%s", prefix, name) :
                                    g_strdup(name);
    GtkShortcutAction *shortcut_action = gtk_named_action_new(action_name);
    GtkShortcutTrigger *shortcut_trigger = gtk_shortcut_trigger_parse_string(accel);
    GtkShortcut *shortcut = gtk_shortcut_new(shortcut_trigger, shortcut_action);
    GVariant *arg = g_variant_new_string(target);
    gtk_shortcut_set_arguments(shortcut, arg);
    return shortcut;
}

