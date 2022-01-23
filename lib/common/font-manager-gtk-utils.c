/* font-manager-gtk-utils.c
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

GType
font_manager_drag_target_type_get_type (void)
{
  static gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_DRAG_TARGET_TYPE_FAMILY, "FONT_MANAGER_DRAG_TARGET_TYPE_FAMILY", "family" },
        { FONT_MANAGER_DRAG_TARGET_TYPE_COLLECTION, "FONT_MANAGER_DRAG_TARGET_TYPE_COLLECTION", "collection" },
        { FONT_MANAGER_DRAG_TARGET_TYPE_EXTERNAL, "FONT_MANAGER_DRAG_TARGET_TYPE_EXTERNAL", "external" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerDragTargetType"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}

/**
 * font_manager_set_application_style:
 *
 * Load application specific CSS and icons.
 */
void font_manager_set_application_style ()
{
    g_autofree gchar *css = g_build_path(G_DIR_SEPARATOR_S,
                                         FONT_MANAGER_BUS_PATH,
                                         "ui",
                                         "FontManager.css",
                                         NULL);

    g_autofree gchar *icons = g_build_path(G_DIR_SEPARATOR_S,
                                           FONT_MANAGER_BUS_PATH,
                                           "icons",
                                           NULL);

    GdkScreen *screen = gdk_screen_get_default();
    GtkIconTheme *icon_theme = gtk_icon_theme_get_default();
    g_autoptr(GtkCssProvider) css_provider = gtk_css_provider_new();
    gtk_icon_theme_add_resource_path(icon_theme, icons);
    gtk_css_provider_load_from_resource(css_provider, css);
    gtk_style_context_add_provider_for_screen(screen,
                                              GTK_STYLE_PROVIDER(css_provider),
                                              GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    return;
}

/**
 * font_manager_widget_set_align:
 * @widget:     #GtkWidget
 * @align:      #GtkAlign
 *
 * Set both halign and valign to the same value.
 */
void
font_manager_widget_set_align (GtkWidget *widget, GtkAlign align)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_halign(GTK_WIDGET(widget), align);
    gtk_widget_set_valign(GTK_WIDGET(widget), align);
    return;
}

/**
 * font_manager_widget_set_expand:
 * @widget:     #GtkWidget
 * @expand:     %TRUE or %FALSE
 *
 * Set both hexpand and vexpand to the same value.
 */
void
font_manager_widget_set_expand (GtkWidget *widget, gboolean expand)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_hexpand(GTK_WIDGET(widget), expand);
    gtk_widget_set_vexpand(GTK_WIDGET(widget), expand);
    return;
}

/**
 * font_manager_widget_set_margin:
 * @widget:     #GtkWidget
 * @margin:     margin in pixels
 *
 * Set all margin properties to the same value.
 */
void
font_manager_widget_set_margin (GtkWidget *widget, gint margin)
{
    g_return_if_fail(GTK_IS_WIDGET(widget));
    gtk_widget_set_margin_start(widget, margin);
    gtk_widget_set_margin_end(widget, margin);
    gtk_widget_set_margin_top(widget, margin);
    gtk_widget_set_margin_bottom(widget, margin);
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
 * font_manager_add_keyboard_shortcut:
 * @action:                                 #GSimpleAction
 * @action_name:                            name of action
 * @accels: (array zero-terminated=1):      list of accelerators
 *
 * Add the given @action and @accels to the default application.
 */
void
font_manager_add_keyboard_shortcut (GSimpleAction *action,
                                    const gchar *action_name,
                                    const gchar * const *accels)
{
    GtkApplication *application = GTK_APPLICATION(g_application_get_default());
    g_action_map_add_action(G_ACTION_MAP(application), G_ACTION(action));
    g_autofree gchar *detailed_action_name = g_strdup_printf("app.%s", action_name);
    gtk_application_set_accels_for_action(application, detailed_action_name, accels);
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
