#include "vala_test.h"
#include "test-application.h"
#include "font-manager-gtk-utils.h"
#include "font-manager-progress-data.h"

static guint source_id = 0;
static FontManagerProgressData *progress_data = NULL;

void
on_progress_response ()
{
    if (source_id > 0)
        g_source_remove(source_id);
    return;
}

void
update_progress (GtkMessageDialog *dialog)
{
    if (!progress_data)
        progress_data = font_manager_progress_data_new("This operation will never actually complete", 0, 100);
    guint processed;
    g_object_get(progress_data, "processed", &processed, NULL);
    g_object_set(progress_data, "processed", processed > 99 ? 0 : (processed + 1), NULL);
    font_manager_progress_dialog_update(dialog, progress_data);
    return;
}

void
on_about_clicked (GtkButton *button, GtkWindow *parent)
{
    font_manager_show_about_dialog(parent);
    return;
}

void
on_close_clicked (GtkButton* button, GtkWindow *window)
{
    gtk_window_destroy(window);
    return;
}

void
on_progress_clicked (GtkButton *button, GtkWindow *parent)
{
    GtkMessageDialog *dialog = font_manager_progress_dialog_create(parent, "ProgressDialog test");
    source_id = g_timeout_add(50, G_SOURCE_FUNC(update_progress), dialog);
    g_signal_connect(dialog, "response", G_CALLBACK(on_progress_response), NULL);
    GtkWidget *close_button = gtk_button_new_with_label("Close");
    font_manager_widget_set_align(close_button, GTK_ALIGN_CENTER);
    font_manager_widget_set_expand(close_button, FALSE);
    font_manager_widget_set_margin(close_button, 4);
    gtk_widget_add_css_class(GTK_WIDGET(close_button), "flat");
    gtk_dialog_add_action_widget(GTK_DIALOG(dialog), close_button, GTK_RESPONSE_CLOSE);
    GtkWidget *button_parent = gtk_widget_get_parent(close_button);
    gtk_widget_remove_css_class(button_parent, "dialog-action-area");
    g_signal_connect(close_button, "clicked", G_CALLBACK(on_close_clicked), GTK_WINDOW(dialog));
    gtk_window_present(GTK_WINDOW(dialog));
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Dialog Test", 600, 400);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    GtkWidget *about = gtk_button_new_with_label("About");
    GtkWidget *progress = gtk_button_new_with_label("Progress");
    font_manager_widget_set_align(about, GTK_ALIGN_CENTER);
    font_manager_widget_set_align(progress, GTK_ALIGN_CENTER);
    font_manager_widget_set_align(box, GTK_ALIGN_CENTER);
    font_manager_widget_set_expand(box, TRUE);
    font_manager_widget_set_margin(box, 12);
    gtk_box_append(GTK_BOX(box), about);
    gtk_box_append(GTK_BOX(box), progress);
    g_signal_connect(GTK_BUTTON(about), "clicked", G_CALLBACK(on_about_clicked), dialog);
    g_signal_connect(GTK_BUTTON(progress), "clicked", G_CALLBACK(on_progress_clicked), dialog);
    test_dialog_append(dialog, box);
    return dialog;
}
