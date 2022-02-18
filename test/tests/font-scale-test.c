#include "test-application.h"
#include "font-manager-font-scale.h"

void print_value (GtkWidget *fontscale, G_GNUC_UNUSED gpointer unused)
{
    gdouble value = font_manager_font_scale_get_value(FONT_MANAGER_FONT_SCALE(fontscale));
    g_print("Current value: %.2f\n", value);
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Font Scale", 560, -1);
    gtk_window_set_resizable(GTK_WINDOW(dialog), FALSE);
    GtkWidget *fontscale = font_manager_font_scale_new();
    g_signal_connect(FONT_MANAGER_FONT_SCALE(fontscale), "notify::value", (GCallback) print_value, NULL);
    test_dialog_append(TEST_DIALOG(dialog), fontscale);
    return dialog;
}
