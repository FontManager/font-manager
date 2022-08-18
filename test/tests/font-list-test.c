#include "test-application.h"
#include "font-manager-fontconfig.h"
#include "vala_test.h"

void
on_selection_changed (FontManagerFontListView *listview, GObject *object)
{
    g_autofree gchar *description = NULL;
    g_object_get(object, "description", &description, NULL);
    g_message(description);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Font List", 600, 500);
    GtkWidget *fontlist = GTK_WIDGET(font_manager_font_list_view_new());
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    font_manager_update_item_preview_text(sorted_font_array);
    g_object_set(fontlist, "available-fonts", sorted_font_array, NULL);
    g_signal_connect(fontlist, "selection-changed", G_CALLBACK(on_selection_changed), NULL);
    test_dialog_append(dialog, fontlist);
    return dialog;
}
