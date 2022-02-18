#include "test-application.h"
#include "font-manager-place-holder.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Place Holder", 600, 500);
    GtkWidget *placeholder = font_manager_place_holder_new("Test", "Testing", "Testing place holder widget", "emblem-important-symbolic");
    test_dialog_append(dialog, placeholder);
    return dialog;
}
