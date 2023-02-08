#include "test-application.h"
#include "vala_test.h"

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Preferences", 400, 550);
    GtkWidget *preferences = GTK_WIDGET(font_manager_preferences_new());
    font_manager_initialize_preference_pane(preferences);
    test_dialog_append(dialog, preferences);
    return dialog;
}

