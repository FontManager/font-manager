/* TitleBar.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    public class TitleBar : Gtk.HeaderBar {

        public signal void install_selected ();
        public signal void remove_selected ();
        public signal void manage_sources (bool active);

        public Gtk.MenuButton main_menu { get; private set; }
        public Gtk.Label main_menu_label { get; set; }
        public Gtk.MenuButton app_menu { get; private set; }
        public Gtk.ToggleButton source_toggle { get; private set; }

        BaseControls manage_controls;
        Gtk.Revealer revealer;

        public TitleBar () {
            title = About.NAME;
            Gtk.StyleContext ctx = get_style_context();
            ctx.add_class(Gtk.STYLE_CLASS_TITLEBAR);
            ctx.add_class(Gtk.STYLE_CLASS_MENUBAR);
            ctx.set_junction_sides(Gtk.JunctionSides.BOTTOM);
            show_close_button = false;
            main_menu = new Gtk.MenuButton();
            main_menu.border_width = 2;
            var main_menu_icon = new Gtk.Image.from_icon_name("view-more-symbolic", Gtk.IconSize.MENU);
            var main_menu_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            main_menu_container.pack_start(main_menu_icon, false, false, 0);
            main_menu_label = new Gtk.Label(null);
            main_menu_container.pack_end(main_menu_label, false, true, 0);
            main_menu.add(main_menu_container);
            main_menu.direction = Gtk.ArrowType.DOWN;
            main_menu.relief = Gtk.ReliefStyle.NONE;
            app_menu = new Gtk.MenuButton();
            app_menu.border_width = 2;
            var app_menu_icon = new Gtk.Image.from_icon_name(About.ICON, Gtk.IconSize.LARGE_TOOLBAR);
            app_menu.add(app_menu_icon);
            app_menu.direction = Gtk.ArrowType.DOWN;
            app_menu.relief = Gtk.ReliefStyle.NONE;
            revealer = new Gtk.Revealer();
            revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
            manage_controls = new BaseControls();
            manage_controls.border_width = 2;
            manage_controls.add_button.set_tooltip_text(_("Add Fonts"));
            manage_controls.remove_button.set_tooltip_text(_("Remove Fonts"));
            add_separator(manage_controls.box);
            manage_controls.box.reorder_child(manage_controls.box.get_children().nth_data(2), 0);
            source_toggle = new Gtk.ToggleButton();
            source_toggle.set_image(new Gtk.Image.from_icon_name("folder-symbolic", Gtk.IconSize.MENU));
            source_toggle.relief = Gtk.ReliefStyle.NONE;
            source_toggle.set_tooltip_text(_("Manage Sources"));
            manage_controls.box.pack_end(source_toggle, false, false, 0);
            revealer.add(manage_controls);
            pack_start(main_menu);
            pack_start(revealer);
            pack_end(app_menu);
            main_menu_icon.show();
            main_menu_container.show();
            main_menu_label.show();
            main_menu.show();
            app_menu_icon.show();
            app_menu.show();
            source_toggle.show();
            manage_controls.show();
            revealer.get_style_context().add_class(Gtk.STYLE_CLASS_TITLEBAR);
            revealer.show();
            set_menus();
            connect_signals();
        }

        internal void set_menus () {
            main_menu.set_menu_model(get_main_menu_model());
            app_menu.set_menu_model(get_app_menu_model());
            main_menu.get_popup().halign = Gtk.Align.START;
            app_menu.get_popup().halign = Gtk.Align.END;
            return;
        }

        internal void connect_signals () {
            manage_controls.add_button.clicked.connect(() => { install_selected(); });
            manage_controls.remove_button.clicked.connect(() => { remove_selected(); });
            source_toggle.toggled.connect(() => { manage_sources(source_toggle.get_active()); } );
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

        internal GLib.MenuModel get_main_menu_model () {
            var application = (Application) GLib.Application.get_default();
            var mode_section = new GLib.Menu();
            string [] modes = {"Default", "Browse", "Compare", "Character Map"};
            var mode_action = new SimpleAction.stateful("mode", VariantType.STRING, "Manage");
            mode_action.activate.connect((a, s) => {
                application.main_window.mode = Mode.parse((string) s);
                }
            );
            application.add_action(mode_action);
            int i = 0;
            foreach (var mode in modes) {
                i++;
                application.add_accelerator("<Alt>%i".printf(i), "app.mode", "%s".printf(mode));
                GLib.MenuItem item = new MenuItem(Mode.parse(mode).to_translatable_string(), "app.mode::%s".printf(mode));
                item.set_attribute("accel", "s", "<Alt>%i".printf(i));
                mode_section.append_item(item);
            }
            return (GLib.MenuModel) mode_section;
        }


        internal GLib.MenuModel get_app_menu_model () {
            var application = (Application) GLib.Application.get_default();
            MenuEntry [] app_menu_entries = {
                /* action_name, display_name, detailed_action_name, accelerator, method */
                MenuEntry("about", _("About"), "app.about", "<Alt>A", new MenuCallbackWrapper(application.on_about)),
                MenuEntry("help", _("Help"), "app.help", "F1", new MenuCallbackWrapper(application.on_help)),
                MenuEntry("quit", _("Quit"), "app.quit", "<Ctrl>Q", new MenuCallbackWrapper(application.on_quit))
            };
            var app_menu = new GLib.Menu();
            foreach (var entry in app_menu_entries) {
                add_action_from_menu_entry(application, entry);
                if (entry.accelerator != null) {
                    application.add_accelerator(entry.accelerator, entry.detailed_action_name, null);
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
