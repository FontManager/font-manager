#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Sidebar Test", 875, 650);
    test_dialog_append(dialog, GTK_WIDGET(font_manager_main_pane_new()));
    return dialog;
}


