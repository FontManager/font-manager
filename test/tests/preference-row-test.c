#include "test-application.h"
#include "font-manager-preference-row.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Font Scale", 540, 480);
    GtkWidget *scroll = gtk_scrolled_window_new();
    GtkWidget *list_box = gtk_list_box_new();
    gtk_widget_add_css_class(list_box, "rich-list");
    GtkWidget *pref_row = font_manager_preference_row_new("Basic Preference Row", NULL, NULL, gtk_switch_new());
    gtk_list_box_append(GTK_LIST_BOX(list_box), pref_row);
    pref_row = font_manager_preference_row_new("Primate mode", "Enables monkey business", "face-monkey-symbolic", gtk_switch_new());
    gtk_list_box_append(GTK_LIST_BOX(list_box), pref_row);
    pref_row = font_manager_preference_row_new("Nested Preference Rows", "Enabling opens up more options", NULL, gtk_switch_new());
    GtkWidget *child = font_manager_preference_row_new("Pick A Color", "Any color", NULL, gtk_color_button_new());
    font_manager_preference_row_append_child(FONT_MANAGER_PREFERENCE_ROW(pref_row), FONT_MANAGER_PREFERENCE_ROW(child));
    GtkWidget *spin = gtk_spin_button_new_with_range(6.0, 96.0, 1.0);
    child = font_manager_preference_row_new("Spin Button Preference", NULL, NULL, spin);
    font_manager_preference_row_append_child(FONT_MANAGER_PREFERENCE_ROW(pref_row), FONT_MANAGER_PREFERENCE_ROW(child));
    gtk_list_box_append(GTK_LIST_BOX(list_box), pref_row);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), list_box);
    font_manager_widget_set_expand(scroll, TRUE);
    test_dialog_append(TEST_DIALOG(dialog), scroll);
    return dialog;
}
