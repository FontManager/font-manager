/* TitleBar.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

    public class ProgressHeader : Gtk.Box {

        public Gtk.Label title { get; private set; }
        public Gtk.ProgressBar progress { get; private set; }

        construct {
            title = new Gtk.Label("");
            progress = new Gtk.ProgressBar();
            title.get_style_context().add_class("title");
            progress.get_style_context().add_class("subtitle");
        }

        public void update (string message, uint processed, uint total) {
            title.set_text(message);
            progress.set_fraction(processed/total * 100);
        }

        public override void show () {
            title.show();
            progress.show();
            base.show();
        }

    }

    public interface TitleBar : Gtk.Widget {

        public abstract signal void install_selected ();
        public abstract signal void remove_selected ();
        public abstract signal void add_selected ();
        public abstract signal void preferences_selected (bool active);

        public abstract Gtk.MenuButton main_menu { get; protected set; }
        public abstract Gtk.MenuButton app_menu { get; protected set; }
        public abstract Gtk.Label main_menu_label { get; set; }
        public abstract Gtk.ToggleButton prefs_toggle { get; protected set; }

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

        protected abstract Gtk.Revealer revealer { get; set; }
        protected abstract Gtk.Image main_menu_icon { get; set; }
        protected abstract Gtk.Image app_menu_icon { get; set; }
        protected abstract Gtk.Box main_menu_container { get; set; }
        protected abstract BaseControls manage_controls { get; set; }
        protected abstract Gtk.Spinner spinner { get; set; }

        public void reveal_controls (bool reveal) {
            revealer.set_reveal_child(reveal);
            return;
        }

        protected void connect_signals () {
            manage_controls.add_button.clicked.connect(() => {
                install_selected();
            });
            manage_controls.remove_button.clicked.connect(() => { remove_selected(); });
            prefs_toggle.toggled.connect(() => {
                var active = prefs_toggle.get_active();
                prefs_toggle.set_active(active);
                preferences_selected(prefs_toggle.get_active());
            });
            return;
        }

        protected void init_components () {
            main_menu = new Gtk.MenuButton();
            main_menu_icon = new Gtk.Image.from_icon_name("view-more-symbolic", Gtk.IconSize.MENU);
            main_menu_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            main_menu_container.pack_start(main_menu_icon, false, false, 0);
            main_menu_label = new Gtk.Label(null);
            main_menu_label.set_markup("<b>%s</b>".printf(Mode.parse("Default").to_translatable_string()));
            main_menu_label.set("margin", 0, null);
            main_menu_container.pack_end(main_menu_label, false, false, 0);
            main_menu.add(main_menu_container);
            main_menu.set("relief", Gtk.ReliefStyle.NONE, "margin", 0, null);
            main_menu.set_menu_model(get_main_menu_model(main_menu));
            revealer = new Gtk.Revealer();
            revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
            manage_controls = new BaseControls();
            manage_controls.add_button.set_tooltip_text(_("Add Fonts"));
            manage_controls.remove_button.set_tooltip_text(_("Remove Fonts"));
            var separator = add_separator(manage_controls.box);
            separator.get_style_context().add_class("separator");
            manage_controls.box.reorder_child(manage_controls.box.get_children().nth_data(2), 0);
            manage_controls.box.set("margin", 0, "border-width", 0, null);
            prefs_toggle = new Gtk.ToggleButton();
            prefs_toggle.set_image(new Gtk.Image.from_icon_name("preferences-system-symbolic", Gtk.IconSize.MENU));
            prefs_toggle.relief = Gtk.ReliefStyle.NONE;
            prefs_toggle.set_tooltip_text(_("Preferences"));
            revealer.add(manage_controls);
            revealer.set_reveal_child(true);
            app_menu = new Gtk.MenuButton();
            app_menu.set("relief", Gtk.ReliefStyle.NONE, "margin", 0, null);
            app_menu.set_menu_model(get_app_menu_model());
            app_menu_icon = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.MENU);
            app_menu.add(app_menu_icon);
            spinner = new Gtk.Spinner();
            return;
        }

    }

    GLib.MenuModel get_app_menu_model () {
        var application = (FontManager.Application) GLib.Application.get_default();
        /* action_name, display_name, detailed_action_name, accelerator, method */
        MenuEntry [] app_menu_entries = {
            MenuEntry("shortcuts", _("Keyboard Shortcuts"), "app.shortcuts", null, new MenuCallbackWrapper(application.shortcuts)),
            MenuEntry("help", _("Help"), "app.help", "F1", new MenuCallbackWrapper(application.help)),
            MenuEntry("about", _("About"), "app.about", null, new MenuCallbackWrapper(application.about)),
        };
        var app_menu = new GLib.Menu();
        foreach (var entry in app_menu_entries) {
            add_action_from_menu_entry(application, entry);
            if (entry.accelerator != null) {
                string? accels [] = {entry.accelerator, null };
                application.set_accels_for_action(entry.detailed_action_name, accels);
                GLib.MenuItem item = new MenuItem(entry.display_name, entry.detailed_action_name);
                item.set_attribute("accel", "s", entry.accelerator);
                app_menu.append_item(item);
            } else {
                app_menu.append(entry.display_name, entry.detailed_action_name);
            }
        }
        return app_menu;
    }

    GLib.MenuModel get_main_menu_model (Gtk.MenuButton parent) {
        var application = (Gtk.Application) GLib.Application.get_default();
        var mode_section = new GLib.Menu();
        string [] modes = {"Default", "Browse", "Compare"};
        var mode_action = new SimpleAction.stateful("mode", VariantType.STRING, "Manage");
        mode_action.set_state(modes[0]);
        application.add_action(mode_action);
        mode_action.activate.connect((a, s) => {
            foreach (var window in application.get_windows())
                if (window is MainWindow) {
                    ((MainWindow) window).mode = Mode.parse((string) s);
                    a.set_state((string) s);
                    parent.active = !parent.active;
                    break;
                }
        });
        int i = 0;
        foreach (var mode in modes) {
            i++;
            string? accels [] = {"<Ctrl>%i".printf(i), null };
            application.set_accels_for_action("app.mode::%s".printf(mode), accels);
            GLib.MenuItem item = new MenuItem(Mode.parse(mode).to_translatable_string(), "app.mode::%s".printf(mode));
            item.set_attribute("accel", "s", accels[0]);
            mode_section.append_item(item);
        }
        return (GLib.MenuModel) mode_section;
    }

    void toggle_spinner (Gtk.Spinner spinner, Gtk.Button button, string? icon_name = null) {
        if (icon_name == null) {
            spinner.start();
            button.set_image(spinner);
            button.sensitive = false;
        } else {
            spinner.stop();
            var icon = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.MENU);
            button.set_image(icon);
            button.sensitive = true;
        }
        return;
    }

    public class ClientSideDecorations : Gtk.HeaderBar, TitleBar {

        public Gtk.MenuButton main_menu { get; protected set; }
        public Gtk.MenuButton app_menu { get; protected set; }
        public Gtk.Label main_menu_label { get; set; }
        public Gtk.ToggleButton prefs_toggle { get; protected set; }

        protected Gtk.Revealer revealer { get; set; }
        protected Gtk.Image main_menu_icon { get; set; }
        protected Gtk.Image app_menu_icon { get; set; }
        protected Gtk.Box main_menu_container { get; set; }
        protected BaseControls manage_controls { get; set; }
        protected Gtk.Spinner spinner { get; set; }

        protected Gtk.Widget [] widgets;

        public ClientSideDecorations () {
            Object(name: "TitleBar", title: About.DISPLAY_NAME, has_subtitle: false,
                   show_close_button: true, margin: 0);
            init_components();
            pack_components();
            connect_signals();
            widgets = { main_menu_icon, main_menu_container, main_menu_label,
                        main_menu, prefs_toggle, manage_controls, revealer,
                        app_menu, app_menu_icon, spinner };
        }

        public override void show () {
            foreach (var widget in widgets)
                widget.show();
            base.show();
            return;
        }

        void pack_components () {
            pack_start(main_menu);
            pack_start(revealer);
            pack_end(app_menu);
            pack_end(prefs_toggle);
            return;
        }

    }

    public class ServerSideDecorations : Gtk.ActionBar, TitleBar {

        public Gtk.MenuButton main_menu { get; protected set; }
        public Gtk.MenuButton app_menu { get; protected set; }
        public Gtk.Label main_menu_label { get; set; }
        public Gtk.ToggleButton prefs_toggle { get; protected set; }

        protected Gtk.Revealer revealer { get; set; }
        protected Gtk.Image main_menu_icon { get; set; }
        protected Gtk.Image app_menu_icon { get; set; }
        protected Gtk.Box main_menu_container { get; set; }
        protected BaseControls manage_controls { get; set; }
        protected Gtk.Spinner spinner { get; set; }

        protected Gtk.Widget [] widgets;

        public ServerSideDecorations () {
            Object(name: "TitleBar", margin: 0);
            init_components();
            pack_components();
            connect_signals();
            widgets = { main_menu_icon, main_menu_container, main_menu_label,
                        main_menu, prefs_toggle, manage_controls, revealer,
                        app_menu, app_menu_icon, spinner };
        }

        public override void show () {
            foreach (var widget in widgets)
                widget.show();
            base.show();
            return;
        }

        void pack_components () {
            pack_start(main_menu);
            pack_start(revealer);
            pack_end(app_menu);
            pack_end(prefs_toggle);
            return;
        }

    }

}
