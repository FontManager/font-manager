/* MainWindow.vala
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

    public class MainWindow : Gtk.ApplicationWindow {

        public Components components { get; private set; }

        ThinPaned main_pane;
        Gtk.Label mode_label;
        GLib.Settings state;

        construct {
            title = About.NAME;
            type = Gtk.WindowType.TOPLEVEL;
            has_resize_grip = true;
        }

        public MainWindow (Components components) {
            this.components = components;
            components.main_window = this;
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            main_pane = new ThinPaned(Gtk.Orientation.HORIZONTAL);
            add(main_box);
            main_box.pack_end(main_pane, true, true, 0);
            main_pane.add1(components.sidebar);
            var content_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            main_pane.add2(content_box);
            add_separator(content_box, Gtk.Orientation.VERTICAL);
            content_box.pack_end(components.main_notebook, true, true, 0);
            components.titlebar.main_menu.set_popup(new Gtk.Menu.from_model(get_main_menu_model()));
            components.titlebar.app_menu.set_menu_model(get_app_menu_model());
            components.titlebar.main_menu.get_popup().halign = Gtk.Align.START;
            components.titlebar.app_menu.get_popup().halign = Gtk.Align.END;
            components.titlebar.show();
            set_titlebar(components.titlebar);
            content_box.show();
            main_box.show();
            main_pane.show();
            state = bind_settings();
            /* Workaround first row height bug? in browse mode */
            Idle.add(() => {
                components.browser.preview_size++;
                components.browser.preview_size--;
                return false;
                }
            );
            /* XXX */
            NotImplemented.parent = (Gtk.Window) this;
        }

        GLib.MenuModel get_main_menu_model () {
            var mode_section = new GLib.Menu();
            string [] modes = {"Manage", "Browse", "Compare", "Character Map"};
            var mode_action = new SimpleAction.stateful("mode", VariantType.STRING, "Manage");
            mode_action.activate.connect((a, s) => {
                components.main.mode = Mode.parse((string) s);
                }
            );
            components.main.add_action(mode_action);
            int i = 0;
            foreach (var mode in modes) {
                i++;
                components.main.add_accelerator("<Alt>%i".printf(i), "app.mode", "%s".printf(mode));
                GLib.MenuItem item = new MenuItem(mode, "app.mode::%s".printf(mode));
                item.set_attribute("accel", "s", "<Alt>%i".printf(i));
                mode_section.append_item(item);
            }
            return (GLib.MenuModel) mode_section;
        }


        GLib.MenuModel get_app_menu_model () {
            var main = components.main;
            MenuEntry [] app_menu_entries = {
                /* action_name, display_name, detailed_action_name, accelerator, method */
                MenuEntry("about", "About", "app.about", "<Alt>A", new MenuCallbackWrapper(main.on_about)),
                MenuEntry("help", "Help", "app.help", "F1", new MenuCallbackWrapper(main.on_help)),
                MenuEntry("quit", "Quit", "app.quit", "<Ctrl>Q", new MenuCallbackWrapper(main.on_quit))
            };
            var app_menu = new GLib.Menu();
            foreach (var entry in app_menu_entries) {
                add_action_from_menu_entry(main, entry);
                if (entry.accelerator != null) {
                    main.add_accelerator(entry.accelerator, entry.detailed_action_name, null);
                    GLib.MenuItem item = new MenuItem(entry.display_name, entry.detailed_action_name);
                    item.set_attribute("accel", "s", entry.accelerator);
                    app_menu.append_item(item);
                } else {
                    app_menu.append(entry.display_name, entry.detailed_action_name);
                }
            }
            return app_menu;
        }

        GLib.Settings bind_settings () {
            var settings = new GLib.Settings(SCHEMA_ID);
            int x, y, w, h;
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);
            set_default_size(w, h);
            move(x, y);
            configure_event.connect((w, /* Gdk.EventConfigure */ e) => {
                settings.set("window-size", "(ii)", e.width, e.height);
                settings.set("window-position", "(ii)", e.x, e.y);
                return false;
                }
            );
            components.main.mode = (FontManager.Mode) settings.get_enum("mode");
            components.mode_changed.connect((i) => {
                settings.set_enum("mode", i);
                }
            );
            components.sidebar.standard.mode = (MainSideBarMode) settings.get_enum("sidebar-mode");
            components.sidebar.standard.mode_selected.connect((m) => {
                settings.set_enum("sidebar-mode", (int) m);
                }
            );
            components.preview.mode = (PreviewMode) settings.get_enum("preview-mode");
            components.preview.mode_changed.connect((m) => { settings.set_enum("preview-mode", m); });
            main_pane.position = settings.get_int("sidebar-size");
            components.content_pane.position = settings.get_int("content-pane-position");
            components.preview.preview_size = settings.get_double("preview-font-size");
            components.browser.preview_size = settings.get_double("browse-font-size");
            components.compare.preview_size = settings.get_double("compare-font-size");
            components.sidebar.character_map.selected_block = settings.get_string("selected-block");
            components.sidebar.character_map.selected_script = settings.get_string("selected-script");
            settings.bind("sidebar-size", main_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("content-pane-position", components.content_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("preview-font-size", components.preview, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("browse-font-size", components.browser, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("compare-font-size", components.compare, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("charmap-font-size", components.character_map.table, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("selected-block", components.sidebar.character_map, "selected-block", SettingsBindFlags.DEFAULT);
            settings.bind("selected-script", components.sidebar.character_map, "selected-script", SettingsBindFlags.DEFAULT);
            components.sidebar.character_map.mode_set.connect(() => {
                settings.set_enum("charmap-mode", (int) components.sidebar.character_map.mode);
                }
            );
            components.sidebar.character_map.mode = (CharacterMapSideBarMode) settings.get_enum("charmap-mode");
            components.sidebar.character_map.set_initial_selection(settings.get_string("selected-script"), settings.get_string("selected-block"));
            var foreground = Gdk.RGBA();
            var background = Gdk.RGBA();
            bool foreground_set = foreground.parse(settings.get_string("compare-foreground-color"));
            bool background_set = background.parse(settings.get_string("compare-background-color"));
            if (foreground_set)
                components.compare.foreground_color = foreground;
            if (background_set)
                components.compare.background_color = background;
            components.compare.color_set.connect((p) => {
                settings.set_string("compare-foreground-color", components.compare.foreground_color.to_string());
                settings.set_string("compare-background-color", components.compare.background_color.to_string());
                }
            );
            var compare_list = settings.get_strv("compare-list");
            foreach (var entry in compare_list) {
                if (entry == null)
                    break;
                components.compare.add_from_string(entry);
            }
            components.compare.list_modified.connect(() => {
                settings.set_strv("compare-list", components.compare.list());
                }
            );
            components.fontlist.controls.set_remove_sensitivity(components.sidebar.standard.mode == MainSideBarMode.COLLECTION);
            queue_draw();
            return settings;
        }

    }

}
