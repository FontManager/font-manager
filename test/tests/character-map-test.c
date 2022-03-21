
#include <json-glib/json-glib.h>

#include "unicode-character-info.h"
#include "unicode-character-map.h"
#include "unicode-search-bar.h"
#include "test-application.h"

void
on_font_set (GtkFontButton *chooser, gpointer user_data)
{
    g_autoptr(PangoFontDescription) font_desc = gtk_font_chooser_get_font_desc(GTK_FONT_CHOOSER(chooser));
    font_manager_unicode_character_map_set_preview_size(FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data),
                                           (gdouble) pango_font_description_get_size(font_desc) / PANGO_SCALE);
    font_manager_unicode_character_map_set_font_desc(FONT_MANAGER_UNICODE_CHARACTER_MAP(user_data), font_desc);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Character Map", 600, 500);
    GtkWidget *cmap = font_manager_unicode_character_map_new();
    PangoFontDescription *font_desc = pango_font_description_from_string("DejauVu Sans 16");
    font_manager_unicode_character_map_set_font_desc(FONT_MANAGER_UNICODE_CHARACTER_MAP(cmap), font_desc);
    GtkWidget *search = font_manager_unicode_search_bar_new();
    font_manager_unicode_search_bar_set_character_map(FONT_MANAGER_UNICODE_SEARCH_BAR(search), FONT_MANAGER_UNICODE_CHARACTER_MAP(cmap));
    GtkWidget *scroll = gtk_scrolled_window_new();
    gtk_widget_set_can_focus(scroll, TRUE);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), cmap);
    GtkWidget *font_chooser = gtk_font_button_new_with_font("DejauVu Sans 16");
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    GtkWidget *info = font_manager_unicode_character_info_new();
    font_manager_unicode_character_info_set_character_map(FONT_MANAGER_UNICODE_CHARACTER_INFO(info), FONT_MANAGER_UNICODE_CHARACTER_MAP(cmap));
    gtk_box_append(GTK_BOX(box), info);
    gtk_box_append(GTK_BOX(box), scroll);
    gtk_box_append(GTK_BOX(box), search);
    g_signal_connect(font_chooser, "font-set", G_CALLBACK(on_font_set), cmap);
    test_dialog_append(dialog, box);
    test_dialog_append_control(dialog, font_chooser);
    return dialog;
}
