#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Google Fonts Selection Test", 800, 600);
    test_dialog_append(dialog, GTK_WIDGET(font_manager_google_fonts_catalog_new()));
    return dialog;
}
