#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Preferences", 875, 650);
    FontManagerPreferencePane *preferences = font_manager_preference_pane_new();
    test_dialog_append(dialog, GTK_WIDGET(preferences));
    return dialog;
}

