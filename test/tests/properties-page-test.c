#include "test-application.h"
#include "font-manager-properties-page.h"

const gchar *DESCRIPTION = """ \
Candara's verticals show both convex and concave curvature with entasis and ectasis on opposite \
sides of stems, high-branching arcades in the lowercase, large apertures in all open forms, and \
unique ogee curves on diagonals. Its italic includes many calligraphic and serif font influences, \
which are common in modern sans-serif typefaces. Calibri and Corbel, from the same family, have \
similar designs and spacing.""";

JsonObject *
get_test_props ()
{
    JsonObject *props = json_object_new();
    json_object_set_string_member(props, "psname", "Candara");
    json_object_set_string_member(props, "family", "Candara");
    json_object_set_string_member(props, "style", "Regular");
    json_object_set_string_member(props, "width", "Normal");
    json_object_set_string_member(props, "slant", "Normal");
    json_object_set_string_member(props, "weight", "Regular");
    json_object_set_string_member(props, "spacing", "Proportional");
    json_object_set_string_member(props, "version", "5.61");
    json_object_set_string_member(props, "vendor", "Microsoft");
    json_object_set_string_member(props, "filetype", "TrueType");
    json_object_set_string_member(props, "filepath", "/usr/share/fonts/Candara.ttf");
    json_object_set_string_member(props, "filesize", "218.5kB");
    json_object_set_string_member(props, "designer", "Gary Munch");
    json_object_set_string_member(props, "designer-url", "http://www.munchfonts.com");
    json_object_set_string_member(props, "description", DESCRIPTION);
    json_object_set_string_member(props, "copyright", "2008 Microsoft Corporation. All Rights Reserved.");
    return props;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Properties Page", 600, 450);
    GtkWidget *props = font_manager_font_properties_page_new();
    g_autoptr(JsonObject) _props = get_test_props();
    font_manager_font_properties_page_update(FONT_MANAGER_PROPERTIES_PAGE(props), _props);
    test_dialog_append(dialog, props);
    return dialog;
}

