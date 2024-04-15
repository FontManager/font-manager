#include <glib.h>

G_GNUC_BEGIN_IGNORE_DEPRECATIONS

#include "vala_test.h"
#include "test-application.h"
#include "font-manager-gtk-utils.h"
#include "font-manager-progress-data.h"

static guint source_id = 0;
static FontManagerProgressData *progress_data = NULL;
bool complete = FALSE;

void
on_progress_response ()
{
    if (source_id > 0)
        g_source_remove(source_id);
    complete = false;
    source_id = 0;
    g_clear_object(&progress_data);
    return;
}

bool
update_progress (FontManagerProgressDialog *dialog)
{
    const gchar *notice = "This operation will never actually complete";
    if (!progress_data)
        progress_data = font_manager_progress_data_new(notice, 0, 100);
    guint processed;
    g_object_get(progress_data, "processed", &processed, NULL);
    g_object_set(progress_data, "processed", processed > 99 ? 0 : (processed + 1), NULL);
    if (processed > 99)
        complete = TRUE;
    g_autofree gchar *message = g_strdup_printf("%i out of 100 items processed", processed);
    g_object_set(progress_data, "message", complete ? notice : message, NULL);
    font_manager_progress_dialog_update(dialog, progress_data);
    return G_SOURCE_CONTINUE;
}

/* void */
/* on_about_clicked (GtkButton *button, GtkWindow *parent) */
/* { */
/*     font_manager_show_about_dialog(parent); */
/*     return; */
/* } */

void
on_close_clicked (GtkButton* button, GtkWindow *window)
{
    gtk_window_close(window);
    return;
}

/* void */
/* on_file_selection_ready (GtkNativeDialog* dialog, int response_id) */
/* { */
/*     if (response_id != GTK_RESPONSE_ACCEPT) */
/*         return; */
/*     g_autoptr(GFile) file = gtk_file_chooser_get_file(GTK_FILE_CHOOSER(dialog)); */
/*     if (file) */
/*         g_message(g_file_get_path(file)); */
/*     return; */
/* } */

/* void */
/* on_file_selections_ready (GtkNativeDialog* dialog, int response_id) */
/* { */
/*     if (response_id != GTK_RESPONSE_ACCEPT) */
/*         return; */
/*     g_autoptr(GListModel) files = gtk_file_chooser_get_files(GTK_FILE_CHOOSER(dialog)); */
/*     for (guint i = 0; i < g_list_model_get_n_items(files); i++) { */
/*         g_autoptr(GFile) file = g_list_model_get_item(files, i); */
/*         g_message(g_file_get_uri(file)); */
/*     } */
/*     return; */
/* } */

void
on_file_selected (GObject *source, GAsyncResult *res, gpointer data) {
    g_autoptr(GFile) selected_file = gtk_file_dialog_open_finish(GTK_FILE_DIALOG(source), res, NULL);
    if (selected_file)
        g_message(g_file_get_uri(selected_file));
    return;
}

void
on_exe_clicked (GtkButton *button, GtkWindow *parent)
{
    GtkFileDialog *dialog = font_manager_file_selector_get_executable();
    gtk_file_dialog_open(dialog, parent, NULL, (GAsyncReadyCallback) on_file_selected, NULL);
    return;
}

/* void */
/* on_dir_clicked (GtkButton *button, GtkWindow *parent) */
/* { */
/*     GtkFileChooserNative *dialog = font_manager_file_selector_get_target_directory(parent); */
/*     g_signal_connect(dialog, "response", G_CALLBACK(on_file_selection_ready), NULL); */
/*     gtk_native_dialog_show(GTK_NATIVE_DIALOG(dialog)); */
/*     return; */
/* } */

/* void */
/* on_files_clicked (GtkButton *button, GtkWindow *parent) */
/* { */
/*     GtkFileChooserNative *dialog = font_manager_file_selector_get_selections(parent); */
/*     g_signal_connect(dialog, "response", G_CALLBACK(on_file_selections_ready), NULL); */
/*     gtk_native_dialog_show(GTK_NATIVE_DIALOG(dialog)); */
/*     return; */
/* } */

/* void */
/* on_folders_clicked (GtkButton *button, GtkWindow *parent) */
/* { */
/*     GtkFileChooserNative *dialog = font_manager_file_selector_get_selected_sources(parent); */
/*     g_signal_connect(dialog, "response", G_CALLBACK(on_file_selections_ready), NULL); */
/*     gtk_native_dialog_show(GTK_NATIVE_DIALOG(dialog)); */
/*     return; */
/* } */

void
on_progress_clicked (GtkButton *button, GtkWindow *parent)
{
    FontManagerProgressDialog *dialog = font_manager_progress_dialog_new("Testing Progress Dialog");
    source_id = g_timeout_add(50, G_SOURCE_FUNC(update_progress), dialog);
    GtkWidget *close_button = gtk_button_new_from_icon_name("window-close-symbolic");
    gtk_widget_set_halign(close_button, GTK_ALIGN_END);
    gtk_widget_set_valign(close_button, GTK_ALIGN_START);
    gtk_widget_set_opacity(close_button, 0.75);
    font_manager_widget_set_expand(close_button, FALSE);
    font_manager_widget_set_margin(close_button, 4);
    gtk_widget_add_css_class(GTK_WIDGET(close_button), "flat");
    gtk_widget_add_css_class(GTK_WIDGET(close_button), "rounded");
    g_autoptr(GtkOverlay) overlay = NULL;
    g_object_get(dialog, "overlay", &overlay, NULL);
    gtk_overlay_add_overlay(overlay, close_button);
    g_signal_connect(close_button, "clicked", G_CALLBACK(on_close_clicked), GTK_WINDOW(dialog));
    gtk_window_present(GTK_WINDOW(dialog));
    return;
}

void
add_dialog_entry (TestDialog  *dialog,
                  const gchar *label,
                  GtkFlowBox  *parent,
                  GCallback   callback)
{
    GtkWidget *button = gtk_button_new_with_label(label);
    font_manager_widget_set_align(button, GTK_ALIGN_CENTER);
    gtk_flow_box_append(parent, button);
    g_signal_connect(GTK_BUTTON(button), "clicked", callback, dialog);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Dialog Test", 600, 400);
    GtkWidget *box = gtk_flow_box_new();
    /* add_dialog_entry(dialog, "About", GTK_FLOW_BOX(box), G_CALLBACK(on_about_clicked)); */
    add_dialog_entry(dialog, "Progress", GTK_FLOW_BOX(box), G_CALLBACK(on_progress_clicked));
    add_dialog_entry(dialog, "Select executable", GTK_FLOW_BOX(box), G_CALLBACK(on_exe_clicked));
    /* add_dialog_entry(dialog, "Select directory", GTK_FLOW_BOX(box), G_CALLBACK(on_dir_clicked)); */
    /* add_dialog_entry(dialog, "Select files", GTK_FLOW_BOX(box), G_CALLBACK(on_files_clicked)); */
    /* add_dialog_entry(dialog, "Select sources", GTK_FLOW_BOX(box), G_CALLBACK(on_folders_clicked)); */
    font_manager_widget_set_expand(box, TRUE);
    font_manager_widget_set_margin(box, 12);
    font_manager_widget_set_align(box, GTK_ALIGN_CENTER);
    gtk_flow_box_set_selection_mode(GTK_FLOW_BOX(box), GTK_SELECTION_NONE);
    test_dialog_append(dialog, box);
    return dialog;
}

G_GNUC_END_IGNORE_DEPRECATIONS

