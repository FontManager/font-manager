#include "test-application.h"
#include "font-manager-place-holder.h"
#include "font-manager-fontconfig.h"
#include "font-manager-gtk-utils.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Font List", 600, 500);
    GtkWidget *fontlist = GTK_WIDGET(font_manager_font_list_view_new());
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    g_object_set(fontlist, "available-fonts", sorted_font_array, NULL);
    test_dialog_append(dialog, fontlist);
    return dialog;
}
