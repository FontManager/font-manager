/* test_application.c
 *
 * Copyright (C) 2020-2023 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

#include "test-application.h"

G_GNUC_BEGIN_IGNORE_DEPRECATIONS

struct _TestApplication
{
    GtkApplication parent;
};

struct _TestApplicationWindow
{
    GtkApplicationWindow parent;

    GtkWidget *widget_list;
};

struct _TestDialog
{
    GtkDialog   parent_instance;
};

G_DEFINE_TYPE(TestApplication, test_application, GTK_TYPE_APPLICATION)
G_DEFINE_TYPE(TestApplicationWindow, test_application_window, GTK_TYPE_APPLICATION_WINDOW)
G_DEFINE_TYPE(TestDialog, test_dialog, GTK_TYPE_DIALOG);

static gint status = 0;

static void
quit (GtkDialog *dialog, gint response, gpointer user_data) {
    if (status == 0)
        status = (response == GTK_RESPONSE_ACCEPT) ? 0 : 1;
    gtk_window_destroy(GTK_WINDOW(dialog));
    return;
};

static void
test_application_init (TestApplication *self)
{
}

static gboolean
on_close_request (TestApplication *application, TestApplicationWindow *window) {
    gtk_application_remove_window(GTK_APPLICATION(application), GTK_WINDOW(window));
    gtk_window_destroy(GTK_WINDOW(window));
    g_application_quit(G_APPLICATION(application));
    return TRUE;
};

static void
test_application_activate (GApplication *self)
{
    TestApplicationWindow *window  = test_application_window_new(TEST_APPLICATION(self));
    gtk_application_add_window(GTK_APPLICATION(self), GTK_WINDOW(window));
    g_signal_connect_swapped(window, "close-request", G_CALLBACK(on_close_request), TEST_APPLICATION(self));
    gtk_window_present(GTK_WINDOW(window));
    return;
}

static void
test_application_class_init (TestApplicationClass *klass)
{
    G_APPLICATION_CLASS(klass)->activate = test_application_activate;
}

TestApplication *
test_application_new (void)
{
    return g_object_new(TEST_TYPE_APPLICATION, "application-id", "host.local.WidgetTest", NULL);
}

void
test_dialog_run (TestDialog *self)
{
    g_signal_connect(self, "response", G_CALLBACK(quit), NULL);
    gtk_widget_set_visible(GTK_WIDGET(self), TRUE);
    return;
}

static void
test_application_window_on_row_activated (TestApplicationWindow *self,
                                          GtkListBox            *list_box,
                                          GtkListBoxRow         *row)
{
    GModule *module;
    TestGetWidgetFunc get_widget;
    TestDialog *widget;
    GtkListBoxRow *_row = gtk_list_box_get_selected_row(GTK_LIST_BOX(self->widget_list));
    GtkWidget *entry = gtk_list_box_row_get_child(_row);
    const gchar *name = gtk_widget_get_name(entry);
    g_autofree gchar *module_name = g_strdup_printf("%s.so", name);
    g_autofree gchar *module_file = g_build_filename(TEST_MODULE_PATH, module_name, NULL);
    module = g_module_open(module_file, G_MODULE_BIND_LOCAL);
    g_module_symbol(module, "get_widget", (gpointer *) &get_widget);
    widget = get_widget(GTK_WINDOW(self));
    test_dialog_run(widget);
    if (status != 0)
        g_critical("Test failed : %s", name);
    return;
}

static void
test_application_window_constructed (GObject *gobject)
{
    TestApplicationWindow *self = TEST_APPLICATION_WINDOW(gobject);
    g_signal_connect_swapped(self->widget_list, "row-activated",
                             G_CALLBACK(test_application_window_on_row_activated), self);
    return;
}

static void
test_application_window_add_test (JsonArray *entries,
                                  guint  index,
                                  JsonNode *element_node,
                                  TestApplicationWindow *self)
{
    g_return_if_fail(self != NULL);
    JsonObject *entry = json_node_get_object(element_node);
    g_assert(json_object_has_member(entry, "name"));
    g_assert(json_object_has_member(entry, "label"));
    const gchar *name = json_object_get_string_member(entry, "name");
    const gchar *label = json_object_get_string_member(entry, "label");
    GtkWidget *widget = gtk_label_new(label);
    gtk_widget_set_name(widget, name);
    gtk_widget_set_margin_start(widget, 24);
    gtk_widget_set_margin_end(widget, 24);
    gtk_widget_set_margin_top(widget, 12);
    gtk_widget_set_margin_bottom(widget, 12);
    gtk_list_box_append(GTK_LIST_BOX(self->widget_list), widget);
    return;
}

static void
test_application_window_init (TestApplicationWindow *self)
{
    gtk_widget_init_template(GTK_WIDGET(self));
    gtk_widget_add_css_class(GTK_WIDGET(self), "devel");
    g_autoptr(JsonParser) parser = json_parser_new();
    json_parser_load_from_file(parser, TEST_ENTRIES, NULL);
    JsonNode *root = json_parser_get_root(parser);
    JsonArray *entries = json_node_get_array(root);
    json_array_foreach_element(entries, (JsonArrayForeach) test_application_window_add_test, self);
    return;
}

static void
test_application_window_class_init (TestApplicationWindowClass *klass)
{
    G_OBJECT_CLASS(klass)->constructed = test_application_window_constructed;

    gtk_widget_class_set_template_from_resource(GTK_WIDGET_CLASS(klass),
                                               "/host/local/WidgetTest/application/test-application.ui");
    gtk_widget_class_bind_template_child(GTK_WIDGET_CLASS(klass), TestApplicationWindow, widget_list);
    g_autoptr(GtkCssProvider) custom_css = gtk_css_provider_new();
    gtk_css_provider_load_from_resource(custom_css, "/host/local/WidgetTest/custom.css");
    gtk_style_context_add_provider_for_display(gdk_display_get_default(),
                                               GTK_STYLE_PROVIDER(custom_css),
                                               GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    return;
}

TestApplicationWindow *
test_application_window_new (TestApplication *application)
{
    return g_object_new(TEST_TYPE_APPLICATION_WINDOW, "application", application, NULL);
}


static void
test_dialog_dispose (GObject *gobject)
{
    TestDialog *self = TEST_DIALOG(gobject);
    g_return_if_fail(self != NULL);
    GtkWidget *root = gtk_dialog_get_content_area(GTK_DIALOG(gobject));
    GtkWidget *child = gtk_widget_get_first_child(root);
    while (child) {
        GtkWidget *next = gtk_widget_get_next_sibling(child);
        gtk_widget_unparent(child);
        child = next;
    }
    G_OBJECT_CLASS(test_dialog_parent_class)->dispose(gobject);
    return;
}

static void
test_dialog_class_init (TestDialogClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = test_dialog_dispose;
    return;
}

static void
test_dialog_init (TestDialog *self)
{
    g_return_if_fail(self != NULL);
    gtk_widget_add_css_class(GTK_WIDGET(self), "devel");
    gtk_window_set_deletable(GTK_WINDOW(self), FALSE);
    GtkWidget *pass = gtk_dialog_add_button(GTK_DIALOG(self), "Pass", GTK_RESPONSE_ACCEPT);
    GtkWidget *fail = gtk_dialog_add_button(GTK_DIALOG(self), "Fail", GTK_RESPONSE_REJECT);
    gtk_widget_add_css_class(pass, "suggested-action");
    gtk_widget_add_css_class(fail, "destructive-action");
    GtkWidget *header_bar = gtk_dialog_get_header_bar(GTK_DIALOG(self));
    gtk_header_bar_set_decoration_layout(GTK_HEADER_BAR(header_bar), ":");
    return;
}

void
test_dialog_append (TestDialog *self, GtkWidget *widget)
{
    GtkWidget *content_area = gtk_dialog_get_content_area(GTK_DIALOG(self));
    gtk_box_append(GTK_BOX(content_area), widget);
    return;
}

void
test_dialog_append_control (TestDialog *self, GtkWidget *widget)
{
    GtkWidget *header_bar = gtk_dialog_get_header_bar(GTK_DIALOG(self));
    gtk_header_bar_pack_start(GTK_HEADER_BAR(header_bar), widget);
    return;
}

TestDialog *
test_dialog_new (TestApplicationWindow *parent, const gchar *title, gint width, gint height)
{
    return g_object_new(TEST_TYPE_DIALOG, "use-header-bar", TRUE, "transient-for", parent,
                        "title", title, "default-width", width, "default-height", height, NULL);
}

int
main (int argc, char *argv[])
{
    g_application_run(G_APPLICATION(test_application_new()), argc, argv);
    return status;
}

G_GNUC_END_IGNORE_DEPRECATIONS

