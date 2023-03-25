#include "test-application.h"
#include "font-manager-place-holder.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Place Holder", 600, 500);
    GtkWidget *placeholder = font_manager_orthography_list_new();
    test_dialog_append(dialog, placeholder);
    return dialog;
}
