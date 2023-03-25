#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Collection Selection", 950, 550);
    GtkWidget *collections = GTK_WIDGET(font_manager_collection_list_view_new());
    GList *families = font_manager_list_available_font_families();
    FontManagerStringSet *available = font_manager_string_set_new();
    for (GList *iter = families; iter != NULL; iter = iter->next)
        font_manager_string_set_add(available, iter->data);
    g_object_set(collections, "available-families", available, NULL);
    GtkWidget *fontlist = GTK_WIDGET(font_manager_font_list_view_new());
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    font_manager_update_item_preview_text(sorted_font_array);
    g_object_set(fontlist, "available-fonts", sorted_font_array, NULL);
    GtkWidget *pane = gtk_paned_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_paned_set_start_child(GTK_PANED(pane), collections);
    gtk_paned_set_end_child(GTK_PANED(pane), fontlist);
    g_object_bind_property(collections, "selected-item", fontlist, "filter", G_BINDING_SYNC_CREATE);
    test_dialog_append(dialog, pane);
    return dialog;
}

