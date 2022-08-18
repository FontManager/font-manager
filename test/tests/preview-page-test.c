#include "test-application.h"
#include "font-manager-json-proxy.h"
#include "font-manager-family.h"
#include "font-manager-font.h"
#include "font-manager-fontconfig.h"
#include "font-manager-preview-page.h"
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

void
on_selection_changed (FontManagerFontListView *listview,
                      GObject *object,
                      FontManagerPreviewPage *pane)
{
    g_return_if_fail(FONT_MANAGER_IS_PREVIEW_PAGE(pane));
    g_autoptr(FontManagerFont) font = NULL;
    if (FONT_MANAGER_IS_FONT(object))
        font = FONT_MANAGER_FONT(g_object_ref(object));
    else {
        font = font_manager_font_new();
        JsonObject *variation = font_manager_family_get_default_variant(FONT_MANAGER_FAMILY(object));
        g_object_set(font, FONT_MANAGER_JSON_PROXY_SOURCE, variation, NULL);
    }
    font_manager_preview_page_set_font(pane, font);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Preview Page", 700, 750);
    GtkWidget *fontlist = GTK_WIDGET(font_manager_font_list_view_new());
    GtkWidget *preview = font_manager_preview_page_new();
    GtkWidget *mode = font_manager_preview_page_get_action_widget(FONT_MANAGER_PREVIEW_PAGE(preview));
    g_autoptr(JsonObject) available_fonts = font_manager_get_available_fonts(NULL);
    g_autoptr(JsonArray) sorted_font_array = font_manager_sort_json_font_listing(available_fonts);
    font_manager_update_item_preview_text(sorted_font_array);
    g_object_set(fontlist, "available-fonts", sorted_font_array, NULL);
    g_signal_connect(fontlist, "selection-changed", G_CALLBACK(on_selection_changed), preview);
    GtkWidget *pane = gtk_paned_new(GTK_ORIENTATION_VERTICAL);
    gtk_paned_set_start_child(GTK_PANED(pane), fontlist);
    gtk_paned_set_end_child(GTK_PANED(pane), preview);
    test_dialog_append(dialog, pane);
    GtkWidget *button = gtk_button_new_from_icon_name("view-left-pane-symbolic");
    gtk_widget_set_opacity(button, 0.75);
    gtk_widget_set_opacity(gtk_button_get_child(GTK_BUTTON(button)), 0.9);
    g_signal_connect(button, "clicked", G_CALLBACK(on_control_clicked), pane);
    test_dialog_append_control(dialog, mode);
    test_dialog_append_control(dialog, button);
    GSettings *settings = font_manager_get_gsettings("org.gnome.FontManager");
    font_manager_preview_page_restore_state(FONT_MANAGER_PREVIEW_PAGE(preview), settings);
    return dialog;
}

