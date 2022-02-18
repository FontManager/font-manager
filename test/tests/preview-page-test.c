#include "test-application.h"
#include "font-manager-preview-page.h"

void on_font_set (GtkFontButton *chooser, gpointer user_data)
{
    g_autoptr(PangoFontDescription) font_desc = gtk_font_chooser_get_font_desc(GTK_FONT_CHOOSER(chooser));
    pango_font_description_unset_fields(font_desc, PANGO_FONT_MASK_SIZE);
    g_autofree gchar *font = pango_font_description_to_string(font_desc);
    font_manager_preview_page_set_font_description(FONT_MANAGER_PREVIEW_PAGE(user_data), font);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog  *dialog = test_dialog_new(parent, "Preview Page", 560, 420);
    GtkWidget *preview = font_manager_preview_page_new();
    GtkWidget *mode = font_manager_preview_page_get_action_widget(FONT_MANAGER_PREVIEW_PAGE(preview));
    GtkWidget *font_chooser = gtk_font_button_new();
    gtk_font_chooser_set_level(GTK_FONT_CHOOSER(font_chooser), GTK_FONT_CHOOSER_LEVEL_STYLE);
    g_signal_connect(font_chooser, "font-set", G_CALLBACK(on_font_set), preview);
    test_dialog_append(dialog, preview);
    test_dialog_append_control(dialog, mode);
    test_dialog_append_control(dialog, font_chooser);
    return dialog;
}
