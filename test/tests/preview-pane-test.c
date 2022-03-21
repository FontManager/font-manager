
#include <json-glib/json-glib.h>

#include "font-manager-json-proxy.h"
#include "font-manager-family.h"
#include "font-manager-font.h"
#include "font-manager-orthography.h"
#include "font-manager-preview-pane.h"
#include "test-application.h"

static gboolean paused = FALSE;
static JsonArray *available_fonts;

static void
on_control_clicked (GtkButton *button,
                    gpointer   user_data)
{
    paused = !paused;
    gtk_button_set_icon_name(button,
                             paused ?
                             "media-playback-start-symbolic" :
                             "media-playback-pause-symbolic");
    return;
}

static gboolean
set_random_font (FontManagerPreviewPane *pane)
{
    if (paused)
        return G_SOURCE_CONTINUE;
    guint entry = g_random_int_range(0, json_array_get_length(available_fonts));
    g_autoptr(FontManagerFamily) family = font_manager_family_new();
    g_autoptr(FontManagerFont) font = font_manager_font_new();
    JsonObject *source = json_array_get_object_element(available_fonts, entry);
    g_object_set(family, FONT_MANAGER_JSON_PROXY_SOURCE, source, NULL);
    JsonObject *variation = font_manager_family_get_default_variant(family);
    g_object_set(font, FONT_MANAGER_JSON_PROXY_SOURCE, variation, NULL);
    font_manager_preview_pane_set_font(pane, font);
    return G_SOURCE_CONTINUE;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    g_autoptr(JsonObject) fonts = font_manager_get_available_fonts(NULL);
    available_fonts = font_manager_sort_json_font_listing(fonts);
    TestDialog *dialog = test_dialog_new(parent, "Preview Pane", 600, 500);
    GtkWidget *pane = font_manager_preview_pane_new();
    test_dialog_append(dialog, pane);
    GtkWidget *button = gtk_button_new_from_icon_name("media-playback-pause-symbolic");
    gtk_widget_set_opacity(button, 0.75);
    gtk_widget_set_opacity(gtk_button_get_child(GTK_BUTTON(button)), 0.9);
    g_signal_connect(button, "clicked", G_CALLBACK(on_control_clicked), NULL);
    test_dialog_append_control(dialog, button);
    set_random_font(FONT_MANAGER_PREVIEW_PANE(pane));
    GSettings *settings = font_manager_get_gsettings("org.gnome.FontManager");
    font_manager_preview_pane_restore_state(FONT_MANAGER_PREVIEW_PANE(pane), settings);
    // Select a random font from installed files every 5 seconds
    g_timeout_add_seconds(5, (GSourceFunc) set_random_font, pane);
    return dialog;
}

