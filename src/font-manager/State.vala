/* State.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    public class State : Object {

        public Settings? settings { get; set; default = null; }
        public weak MainWindow? main_window { get; set; default = null; }

        public State (MainWindow main_window, string schema_id) {
            Object(main_window: main_window, settings: get_settings(schema_id));
        }

        public void save () {
            if (settings == null)
                return;
            settings.apply();
            return;
        }

        public void restore () {

            if (settings == null) {
                ensure_sane_defaults();
                return;
            }

            int x, y, w, h;
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);
            main_window.set_default_size(w, h);
            main_window.move(x, y);
            main_window.mode = (FontManager.Mode) settings.get_enum("mode");
            main_window.titlebar.main_menu.active = false;
            main_window.sidebar.standard.mode = (StandardSideBarMode) settings.get_enum("sidebar-mode");
            main_window.preview.mode = FontManager.FontPreviewMode.parse(settings.get_string("preview-mode"));
            main_window.main_pane.position = settings.get_int("sidebar-size");
            main_window.content_pane.position = settings.get_int("content-pane-position");
            main_window.preview.preview_size = settings.get_double("preview-font-size");
            main_window.browser.preview_size = settings.get_double("browse-font-size");
            main_window.compare.preview_size = settings.get_double("compare-font-size");
            main_window.preview.notebook.page = settings.get_int("preview-page");
            var preview_text = settings.get_string("preview-text");
            if (preview_text != "DEFAULT")
                main_window.preview.set_preview_text(preview_text);
            main_window.sidebar.character_map.mode = (CharacterMapSideBarMode) settings.get_enum("charmap-mode");
            main_window.sidebar.character_map.selected_block = settings.get_string("selected-block");
            main_window.sidebar.character_map.selected_script = settings.get_string("selected-script");
            main_window.sidebar.character_map.set_initial_selection(settings.get_string("selected-script"), settings.get_string("selected-block"));
            main_window.fontlist.controls.set_remove_sensitivity(main_window.sidebar.standard.mode == StandardSideBarMode.COLLECTION);
            return;
        }

        public void bind_settings () {

            if (settings == null)
                return;

            main_window.configure_event.connect((w, /* Gdk.EventConfigure */ e) => {
                settings.set("window-size", "(ii)", e.width, e.height);
                settings.set("window-position", "(ii)", e.x, e.y);
                /* XXX : this shouldn't be needed...
                 * It's purpose is to prevent the window title from being
                 * truncated even though it would fit. (Gtk.HeaderBar)
                 */
                main_window.titlebar.queue_resize();
                return false;
                }
            );
            main_window.mode_changed.connect((i) => {
                settings.set_enum("mode", (int) i);
                }
            );

            main_window.sidebar.standard.mode_selected.connect(() => {
                settings.set_enum("sidebar-mode", (int) main_window.sidebar.standard.mode);
                }
            );
            main_window.preview.preview_mode_changed.connect((m) => { settings.set_string("preview-mode", ((FontManager.FontPreviewMode) m).to_string()); });
            main_window.preview.preview_text_changed.connect((p) => { settings.set_string("preview-text", p); });
            settings.bind("sidebar-size", main_window.main_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("content-pane-position", main_window.content_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("preview-font-size", main_window.preview, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("browse-font-size", main_window.browser, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("compare-font-size", main_window.compare, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("charmap-font-size", main_window.preview.charmap, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("selected-block", main_window.sidebar.character_map, "selected-block", SettingsBindFlags.DEFAULT);
            settings.bind("selected-script", main_window.sidebar.character_map, "selected-script", SettingsBindFlags.DEFAULT);
            settings.bind("selected-category", main_window.sidebar.standard.category_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-collection", main_window.sidebar.standard.collection_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-font", main_window.fontlist, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("preview-page", main_window.preview.notebook, "page", SettingsBindFlags.DEFAULT);
            main_window.sidebar.character_map.mode_set.connect(() => {
                settings.set_enum("charmap-mode", (int) main_window.sidebar.character_map.mode);
                }
            );
            main_window.compare.color_set.connect((p) => {
                settings.set_string("compare-foreground-color", main_window.compare.foreground_color.to_string());
                settings.set_string("compare-background-color", main_window.compare.background_color.to_string());
                }
            );
            main_window.compare.list_modified.connect(() => {
                settings.set_strv("compare-list", main_window.compare.list());
                }
            );
            settings.delay();
            return;
        }

        public void post_activate () {

            if (settings == null)
                return;

            /* XXX : Workaround timing issue? wrong filter shown at startup */
            if (main_window.sidebar.standard.mode == StandardSideBarMode.COLLECTION) {
                main_window.sidebar.standard.mode = StandardSideBarMode.CATEGORY;
                main_window.sidebar.standard.mode = StandardSideBarMode.COLLECTION;
            }

            /* Workaround first row height bug? in browse mode */
            main_window.browser.preview_size++;
            main_window.browser.preview_size--;

            Idle.add(() => {
                var foreground = Gdk.RGBA();
                var background = Gdk.RGBA();
                bool foreground_set = foreground.parse(settings.get_string("compare-foreground-color"));
                bool background_set = background.parse(settings.get_string("compare-background-color"));
                if (foreground_set)
                    ((Gtk.ColorChooser) main_window.compare.controls.fg_color_button).set_rgba(foreground);
                if (background_set)
                    ((Gtk.ColorChooser) main_window.compare.controls.bg_color_button).set_rgba(background);
                var compare_list = settings.get_strv("compare-list");
                /* XXX */
                var available_fonts = Main.instance.families.list_font_descriptions();
                foreach (var entry in compare_list) {
                    if (entry in available_fonts)
                        main_window.compare.add_from_string(entry);
                }
                return false;
            });

        }

        public void restore_selections () {

            if (settings == null)
                return;

            /* XXX: Order matters */
            var font_path = settings.get_string("selected-font");
            if (main_window.sidebar.standard.mode == StandardSideBarMode.COLLECTION) {
                var tree = main_window.sidebar.standard.collection_tree.tree;
                string path = settings.get_string("selected-collection");
                restore_last_selected_treepath(tree, path);
            } else {
                var tree = main_window.sidebar.standard.category_tree.tree;
                string path = settings.get_string("selected-category");
                restore_last_selected_treepath(tree, path);
            }
            var treepath = restore_last_selected_treepath(main_window.fontlist, font_path);
            if (treepath != null)
                main_window.browser.treeview.scroll_to_cell(treepath, null, true, 0.5f, 0.5f);
            return;
        }

        /* These should match the schema */
        void ensure_sane_defaults () {
            main_window.set_default_size(700, 480);
            main_window.mode = FontManager.Mode.BROWSE;
            main_window.sidebar.standard.mode = StandardSideBarMode.CATEGORY;
            main_window.preview.mode = FontManager.FontPreviewMode.PREVIEW;
            main_window.main_pane.position = 200;
            main_window.content_pane.position = 150;
            main_window.preview.preview_size = 10.0;
            main_window.browser.preview_size = 12.0;
            main_window.compare.preview_size = 12.0;
            main_window.preview.notebook.page = 0;
            main_window.fontlist.controls.set_remove_sensitivity(main_window.sidebar.standard.mode == StandardSideBarMode.COLLECTION);
            return;
        }

        Gtk.TreePath? restore_last_selected_treepath (Gtk.TreeView tree, string path) {
            Gtk.TreeIter iter;
            var model = (Gtk.TreeStore) tree.get_model();
            var selection = tree.get_selection();
            model.get_iter_from_string(out iter, path);
            if (!model.iter_is_valid(iter)) {
                selection.select_path(new Gtk.TreePath.first());
                return null;
            }
            var treepath = new Gtk.TreePath.from_string(path);
            selection.unselect_all();
            if (treepath.get_depth() > 1)
                tree.expand_to_path(treepath);
            tree.scroll_to_cell(treepath, null, true, 0.5f, 0.5f);
            selection.select_path(treepath);
            return treepath;
        }

    }

}
