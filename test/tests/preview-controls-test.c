#include "test-application.h"
#include "font-manager-preview-controls.h"

static const gchar *justify[4] = { "Left", "Right", "Center", "Fill" };

void
print_justification (GtkWidget *controls, G_GNUC_UNUSED gpointer unused)
{
    GtkJustification justification;
    g_object_get(FONT_MANAGER_PREVIEW_CONTROLS(controls), "justification", &justification, NULL);
    g_print("Justification set : %s\n", justify[(int) justification]);
    return;
}

void
on_edit_toggled (GtkWidget *controls, gpointer active)
{
    g_print("Editing %s\n", active ? "enabled" : "disabled");
    g_object_set(FONT_MANAGER_PREVIEW_CONTROLS(controls), "undo-available", active ? TRUE : FALSE, NULL);
    return;
}

void
on_undo_clicked (GtkWidget *controls, G_GNUC_UNUSED gpointer unused)
{
    g_print("Undo requested\n");
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Preview Controls", 560, -1);
    GtkWidget *controls = font_manager_preview_controls_new();

    g_signal_connect(FONT_MANAGER_PREVIEW_CONTROLS(controls),
                     "notify::justification",
                     (GCallback) print_justification,
                     NULL);

    g_signal_connect(FONT_MANAGER_PREVIEW_CONTROLS(controls),
                     "edit-toggled",
                     (GCallback) on_edit_toggled,
                     NULL);

    g_signal_connect(FONT_MANAGER_PREVIEW_CONTROLS(controls),
                     "undo-clicked",
                     (GCallback) on_undo_clicked,
                     NULL);

    test_dialog_append(dialog, controls);
    return dialog;
}
