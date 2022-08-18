#include "test-application.h"
#include "vala_test.h"


static gboolean vertical = TRUE;

static void
on_control_clicked (GtkButton *button,
                    FontManagerPreviewPane *pane)
{
    gtk_orientable_set_orientation(GTK_ORIENTABLE(pane),
                                   vertical ?
                                   GTK_ORIENTATION_HORIZONTAL :
                                   GTK_ORIENTATION_VERTICAL);
    vertical = !vertical;
    gtk_button_set_icon_name(button,
                             vertical ?
                             "view-left-pane-symbolic" :
                             "view-top-pane-symbolic");
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Font Comparison", 700, 750);
    GtkWidget *fontlist = GTK_WIDGET(font_manager_font_list_view_new());
    FontManagerComparePane *widget = font_manager_compare_pane_new();
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    font_manager_update_item_preview_text(sorted_font_array);
    g_object_set(fontlist, "available-fonts", sorted_font_array, NULL);
    GtkWidget *pane = gtk_paned_new(GTK_ORIENTATION_VERTICAL);
    gtk_paned_set_start_child(GTK_PANED(pane), fontlist);
    gtk_paned_set_end_child(GTK_PANED(pane), GTK_WIDGET(widget));
    test_dialog_append(dialog, pane);
    GtkWidget *button = gtk_button_new_from_icon_name("view-left-pane-symbolic");
    gtk_widget_set_opacity(button, 0.75);
    gtk_widget_set_opacity(gtk_button_get_child(GTK_BUTTON(button)), 0.9);
    g_signal_connect(button, "clicked", G_CALLBACK(on_control_clicked), pane);
    test_dialog_append_control(dialog, button);
    g_object_bind_property(fontlist, "selected-items", widget, "selected-items", G_BINDING_SYNC_CREATE);
    g_autoptr(GSettings) settings = font_manager_get_gsettings("org.gnome.FontManager");
    font_manager_compare_pane_restore_state(widget, settings);
    g_object_ref(widget);
    return dialog;
}

