#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Language Filter", 950, 550);
    GtkWidget *categories = GTK_WIDGET(font_manager_category_list_view_new());
    GList *families = font_manager_list_available_font_families();
    FontManagerStringSet *available = font_manager_string_set_new();
    for (GList *iter = families; iter != NULL; iter = iter->next)
        font_manager_string_set_add(available, iter->data);
    g_object_set(categories, "available-families", available, NULL);
    GtkWidget *pane = gtk_paned_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_paned_set_start_child(GTK_PANED(pane), categories);
    FontManagerFontListFilterModel *model;
    g_object_get(G_OBJECT(categories), "model", &model, NULL);
    FontManagerLanguageFilter *filter = g_list_model_get_item(G_LIST_MODEL(model), FONT_MANAGER_CATEGORY_INDEX_LANGUAGE);
    FontManagerLanguageFilterSettings *widget;
    g_object_get(G_OBJECT(filter), "settings", &widget, NULL);
    gtk_paned_set_end_child(GTK_PANED(pane), GTK_WIDGET(widget));
    gtk_paned_set_position(GTK_PANED(pane), 275);
    test_dialog_append(dialog, pane);
    return dialog;
}

