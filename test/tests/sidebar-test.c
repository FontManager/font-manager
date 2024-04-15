#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Sidebar Test", 875, 650);
    FontManagerMainPane *main_pane = font_manager_main_pane_new();
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    font_manager_update_item_preview_text(sorted_font_array);
    g_object_set(main_pane, "available-fonts", sorted_font_array, NULL);
    test_dialog_append(dialog, GTK_WIDGET(main_pane));
    return dialog;
}


