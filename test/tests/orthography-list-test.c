#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Orthography List", 700, 500);
    GtkWidget *widget = GTK_WIDGET(font_manager_orthography_list_new());
    GtkWidget *fontlist = GTK_WIDGET(font_manager_font_list_view_new());
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    font_manager_update_item_preview_text(sorted_font_array);
    g_object_set(fontlist, "available-fonts", sorted_font_array, NULL);
    GtkWidget *pane = gtk_paned_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_paned_set_position(GTK_PANED(pane), 250);
    gtk_paned_set_start_child(GTK_PANED(pane), widget);
    gtk_paned_set_end_child(GTK_PANED(pane), fontlist);
    test_dialog_append(dialog, pane);
    g_object_bind_property(fontlist, "selected-item", widget, "selected-item", G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE);
    return dialog;
}

