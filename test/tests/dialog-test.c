#include "vala_test.h"
#include "test-application.h"
#include "font-manager-gtk-utils.h"

void
on_about_clicked (GtkButton *button, GtkWindow *parent)
{
    font_manager_about_show_dialog(parent);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Dialog Test", 600, 400);
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    GtkWidget *about = gtk_button_new_with_label("About");
    font_manager_widget_set_align(about, GTK_ALIGN_CENTER);
    font_manager_widget_set_align(box, GTK_ALIGN_CENTER);
    font_manager_widget_set_expand(box, TRUE);
    font_manager_widget_set_margin(box, 12);
    gtk_box_append(GTK_BOX(box), about);
    g_signal_connect(GTK_BUTTON(about), "clicked", G_CALLBACK(on_about_clicked), dialog);
    test_dialog_append(dialog, box);
    return dialog;
}
