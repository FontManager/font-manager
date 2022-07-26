#include "test-application.h"
#include "font-manager-fontconfig.h"
#include "vala_test.h"

void
on_selection_changed (FontManagerFontListView *listview, GObject *object)
{
    gint size;
    g_autofree gchar *name = NULL;
    g_object_get(object, "name", &name, "size", &size, NULL);
    g_message("%s : %i", name, size);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Category List", 400, 550);
    GtkWidget *categories = GTK_WIDGET(font_manager_category_list_view_new());
    GList *families = font_manager_list_available_font_families();
    FontManagerStringSet *available = font_manager_string_set_new();
    for (GList *iter = families; iter != NULL; iter = iter->next)
        font_manager_string_set_add(available, iter->data);
    g_object_set(categories, "available-families", available, NULL);
    g_signal_connect(categories, "selection-changed", G_CALLBACK(on_selection_changed), NULL);
    g_list_free_full(families, g_free);
    test_dialog_append(dialog, categories);
    return dialog;
}
