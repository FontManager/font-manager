/* Controls.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

namespace FontManager {

    public class BaseControls : Gtk.Box {

        public signal void add_selected ();
        public signal void remove_selected ();

        public Gtk.Button add_button { get; protected set; }
        public Gtk.Button remove_button { get; protected set; }

        construct {
            spacing = DEFAULT_MARGIN;
            margin_start = margin_end = margin_top = margin_bottom = MIN_MARGIN * 2;
            add_button = new Gtk.Button.from_icon_name("list-add-symbolic") {
                opacity = 0.9,
                has_frame = false
            };
            remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic") {
                opacity = 0.9,
                has_frame = false
            };
            set_control_sensitivity(remove_button, false);
            append(add_button);
            append(remove_button);
            add_button.clicked.connect((w) => { add_selected(); });
            remove_button.clicked.connect(() => { remove_selected(); });
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-preview-entry.ui")]
    public class PreviewEntry : Gtk.Entry {

        public override void constructed () {
            on_changed_event();
            base.constructed();
            return;
        }

        [GtkCallback]
        void on_icon_press_event (Gtk.Entry entry, Gtk.EntryIconPosition position) {
            if (position == Gtk.EntryIconPosition.SECONDARY)
                set_text("");
            return;
        }

        [GtkCallback]
        void on_changed_event () {
            bool empty = (text_length == 0);
            string icon_name = !empty ? "edit-clear-symbolic" : "document-edit-symbolic";
            set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, icon_name);
            set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, !empty);
            set_icon_sensitive(Gtk.EntryIconPosition.SECONDARY, !empty);
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-preview-colors.ui")]
    public class PreviewColors : Gtk.Box {

        public signal void color_set ();

        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }

        [GtkChild] unowned Gtk.ColorDialogButton bg_color_button;
        [GtkChild] unowned Gtk.ColorDialogButton fg_color_button;

        void flatten_color_button (Gtk.ColorDialogButton button) {
            button.get_first_child().remove_css_class(STYLE_CLASS_COLOR);
            button.get_first_child().add_css_class(STYLE_CLASS_FLAT);
            return;
        }

        public override void constructed () {
            flatten_color_button(bg_color_button);
            flatten_color_button(fg_color_button);
            bg_color_button.set_dialog(new Gtk.ColorDialog() {
                title = _("Select background color")
            });
            fg_color_button.set_dialog(new Gtk.ColorDialog() {
                title = _("Select text color")
            });
            BindingFlags flags = BindingFlags.BIDIRECTIONAL;
            bind_property("background-color", bg_color_button, "rgba", flags);
            bind_property("foreground-color", fg_color_button, "rgba", flags);
            Gdk.RGBA rgba = Gdk.RGBA();
            if (rgba.parse("rgb(255,255,255)"))
                bg_color_button.set_rgba(rgba);
            if (rgba.parse("rgb(0,0,0)"))
                fg_color_button.set_rgba(rgba);
            bg_color_button.notify["rgba"].connect(() => { color_set(); });
            fg_color_button.notify["rgba"].connect(() => { color_set(); });
            base.constructed();
            return;
        }

    }

    const MenuEntry [] app_menu_entries = {
        { "win.show-help-overlay", N_("Keyboard Shortcuts") },
        { "help", N_("Help") },
        { "about",  N_("About Font Manager")}
    };

    GLib.MenuModel get_app_menu_model () {
        var section = new GLib.Menu();
        var preferences = new GLib.Menu();
        var preferences_menu_item = new GLib.MenuItem(_("Preferences"), "show-preferences");
        preferences.append_item(preferences_menu_item);
        section.prepend_section(null, preferences);
        var user_data = new GLib.Menu();
        var import_menu_item = new GLib.MenuItem(_("Import"), "import");
        var export_menu_item = new GLib.MenuItem(_("Export"), "export");
        user_data.append_item(import_menu_item);
        user_data.append_item(export_menu_item);
        var user_data_submenu = new GLib.MenuItem.submenu(_("User Data"), user_data);
        section.prepend_item(user_data_submenu);
        var standard_entries = new GLib.Menu();
        foreach (var entry in app_menu_entries) {
            GLib.MenuItem item = new MenuItem(entry.display_name, entry.action_name);
            standard_entries.append_item(item);
        }
        section.append_section(null, standard_entries);
        return (GLib.MenuModel) section;
    }

    GLib.MenuModel get_main_menu_model () {
        var section = new GLib.Menu();
        EnumClass mode_class = ((EnumClass) typeof(Mode).class_ref());
        for (int i = 0; i < Mode.N_MODES; i++) {
            string nick = mode_class.get_value(i).value_nick;
            var item = new MenuItem(((Mode) i).to_translatable_string(), null);
            item.set_action_and_target("mode", "s", nick);
            section.append_item(item);
        }
        return (GLib.MenuModel) section;
    }

    void toggle_spinner (Gtk.Spinner spinner, Gtk.Button button, string? icon_name = null) {
        if (icon_name == null) {
            spinner.start();
            button.set_child(spinner);
            button.sensitive = false;
        } else {
            spinner.stop();
            var icon = new Gtk.Image.from_icon_name(icon_name);
            button.set_child(icon);
            button.sensitive = true;
        }
        return;
    }

    public class HeaderBarWidgets : Object {

        public Gtk.MenuButton main_menu { get; protected set; }
        public Gtk.MenuButton app_menu { get; protected set; }
        public Gtk.Label main_menu_label { get; set; }
        public Gtk.Button back_button { get; protected set; }
        public GLib.Settings? settings { get; protected set; default = null; }

        public bool installing_files {
            set {
                toggle_spinner(spinner, manage_controls.add_button,
                                value ? null : "list-add-symbolic");
            }
        }

        public bool removing_files {
            set {
                toggle_spinner(spinner, manage_controls.remove_button,
                                value ? null : "list-remove-symbolic");
            }
        }

        public Gtk.Revealer revealer { get; set; }
        protected Gtk.Spinner spinner { get; set; }

        BaseControls manage_controls;

        public void reveal_manage_controls (bool reveal) {
            revealer.set_reveal_child(reveal);
            return;
        }

        public HeaderBarWidgets (GLib.Settings? settings) {
            Object(settings: settings);
            main_menu = new Gtk.MenuButton() { opacity = 0.9 };
            var main_menu_icon = new Gtk.Image.from_icon_name("view-more-symbolic");
            var main_menu_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            main_menu_container.append(main_menu_icon);
            main_menu_label = new Gtk.Label(null);
            string markup = "<b>%s</b>".printf(Mode.parse("Default").to_translatable_string());
            main_menu_label.set_markup(markup);
            main_menu_container.append(main_menu_label);
            main_menu.set_child(main_menu_container);
            main_menu.set_menu_model(get_main_menu_model());
            app_menu = new Gtk.MenuButton() { opacity = 0.9 };
            app_menu.set_menu_model(get_app_menu_model());
            app_menu.set_icon_name("open-menu-symbolic");
            revealer = new Gtk.Revealer();
            revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
            manage_controls = new BaseControls() {
                spacing = 4,
                margin_start = 0,
                margin_end = 0,
                margin_top = 0,
                margin_bottom = 0
            };
            manage_controls.add_button.has_frame = true;
            manage_controls.remove_button.has_frame = true;
            set_control_sensitivity(manage_controls.remove_button, true);
            manage_controls.add_button.set_action_name("install");
            manage_controls.remove_button.set_action_name("remove");
            manage_controls.add_button.set_tooltip_text(_("Add Fonts"));
            manage_controls.remove_button.set_tooltip_text(_("Remove Fonts"));
            var separator = new Gtk.Separator(Gtk.Orientation.VERTICAL) {
                margin_end = 4,
                margin_top = 2,
                margin_bottom = 2
            };
            separator.add_css_class("separator");
            manage_controls.prepend(separator);
            revealer.set_child(manage_controls);
            revealer.set_reveal_child(true);
            back_button = new Gtk.Button.from_icon_name("go-previous-symbolic") {
                opacity = 0.9,
                visible = false,
                tooltip_text = _("Back"),
                action_name = "show-preferences"
            };
            spinner = new Gtk.Spinner();
            if (settings != null) {
                set_button_style();
                settings.changed.connect((key) => {
                    if (key == "headerbar-button-style")
                        set_button_style();
                });
            }
            return;
        }

        void set_button_style () requires (settings != null) {
            Gtk.Widget [] buttons = { main_menu, app_menu, back_button,
                                      manage_controls.add_button,
                                      manage_controls.remove_button };
            int raised = settings.get_enum("headerbar-button-style");
            foreach (var button in buttons)
                if (button is Gtk.MenuButton)
                    ((Gtk.MenuButton) button).set_has_frame(raised == 0);
                else
                    ((Gtk.Button) button).set_has_frame(raised == 0);
            return;
        }

    }

}
