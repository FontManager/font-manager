/* TitleBar.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <https://opensource.org/licenses/GPL-3.0gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    public class TitleBar : Gtk.HeaderBar {

        public signal void install_selected ();
        public signal void remove_selected ();
        public signal void add_selected ();
        public signal void preferences_selected (bool active);

        public Gtk.MenuButton main_menu { get; private set; }
        public Gtk.Label main_menu_label { get; set; }
        public Gtk.MenuButton app_menu { get; private set; }
        public Gtk.ToggleButton prefs_toggle { get; private set; }

        BaseControls manage_controls;
        Gtk.Revealer revealer;
        Gtk.Image main_menu_icon;
        Gtk.Image app_menu_icon;
        Gtk.Box main_menu_container;

        public TitleBar () {
            Object(name: "TitleBar", title: About.NAME, has_subtitle: false, margin: 0);
            main_menu = new Gtk.MenuButton();
            main_menu_icon = new Gtk.Image.from_icon_name("view-more-symbolic", Gtk.IconSize.MENU);
            main_menu_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            main_menu_container.pack_start(main_menu_icon, false, false, 0);
            main_menu_label = new Gtk.Label(null);
            main_menu_container.pack_end(main_menu_label, false, true, 0);
            main_menu.add(main_menu_container);
            main_menu.direction = Gtk.ArrowType.DOWN;
            main_menu.relief = Gtk.ReliefStyle.NONE;
            app_menu = new Gtk.MenuButton();
            app_menu_icon = new Gtk.Image.from_icon_name(About.ICON, Gtk.IconSize.LARGE_TOOLBAR);
            app_menu.add(app_menu_icon);
            app_menu.direction = Gtk.ArrowType.DOWN;
            app_menu.relief = Gtk.ReliefStyle.NONE;
            revealer = new Gtk.Revealer();
            revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
            manage_controls = new BaseControls();
            manage_controls.add_button.set_tooltip_text(_("Add Fonts"));
            manage_controls.remove_button.set_tooltip_text(_("Remove Fonts"));
            var separator = add_separator(manage_controls.box);
            separator.get_style_context().add_class("separator");
            manage_controls.box.reorder_child(manage_controls.box.get_children().nth_data(2), 0);
            prefs_toggle = new Gtk.ToggleButton();
            prefs_toggle.set_image(new Gtk.Image.from_icon_name("preferences-system-symbolic", Gtk.IconSize.MENU));
            prefs_toggle.relief = Gtk.ReliefStyle.NONE;
            prefs_toggle.set_tooltip_text(_("Preferences"));
            manage_controls.box.pack_end(prefs_toggle, false, false, 1);
            revealer.add(manage_controls);
            pack_start(main_menu);
            pack_start(revealer);
            pack_end(app_menu);
            revealer.get_style_context().add_class(Gtk.STYLE_CLASS_TITLEBAR);
            get_style_context().add_class(name);
            set_menus();
            connect_signals();
        }

        public override void show () {
            main_menu_icon.show();
            main_menu_container.show();
            main_menu_label.show();
            main_menu.show();
            app_menu_icon.show();
            app_menu.show();
            prefs_toggle.show();
            manage_controls.show();
            revealer.show();
            base.show();
            return;
        }

        void set_menus () {
            main_menu.set_menu_model(get_main_menu_model());
            app_menu.set_menu_model(get_app_menu_model());
            return;
        }

        void connect_signals () {
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

        public void reveal_controls (bool reveal) {
            revealer.set_reveal_child(reveal);
            return;
        }

        public void use_toolbar_styling () {
            set_title("");
            get_style_context().remove_class("header-bar");
            get_style_context().remove_class("titlebar");
            get_style_context().remove_class("menubar");
            get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
            revealer.get_style_context().remove_class(Gtk.STYLE_CLASS_TITLEBAR);
            revealer.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
            manage_controls.get_style_context().add_class(Gtk.STYLE_CLASS_TOOLBAR);
            manage_controls.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
            return;
        }

        GLib.MenuModel get_main_menu_model () {
            var application = (Application) GLib.Application.get_default();
            var mode_section = new GLib.Menu();
            string [] modes = {"Default", "Browse", "Compare"};
            var mode_action = new SimpleAction.stateful("mode", VariantType.STRING, "Manage");
            mode_action.activate.connect((a, s) => {
                Main.instance.main_window.mode = Mode.parse((string) s);
            });
            application.add_action(mode_action);
            int i = 0;
            foreach (var mode in modes) {
                i++;
                string? accels [] = {"<Ctrl>%i".printf(i), null };
                application.set_accels_for_action("app.mode::%s".printf(mode), accels);
                GLib.MenuItem item = new MenuItem(Mode.parse(mode).to_translatable_string(), "app.mode::%s".printf(mode));
                item.set_attribute("accel", "s", "<Ctrl>%i".printf(i));
                mode_section.append_item(item);
            }
            return (GLib.MenuModel) mode_section;
        }


        GLib.MenuModel get_app_menu_model () {
            var application = (Application) GLib.Application.get_default();
            /* action_name, display_name, detailed_action_name, accelerator, method */
            MenuEntry [] app_menu_entries = {
                MenuEntry("help", _("Help"), "app.help", "F1", new MenuCallbackWrapper(application.help)),
                MenuEntry("about", _("About"), "app.about", null, new MenuCallbackWrapper(application.about)),
                MenuEntry("quit", _("Quit"), "app.quit", "<Ctrl>Q", new MenuCallbackWrapper(application.quit))
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

    }


}
