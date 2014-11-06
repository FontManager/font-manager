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

    public enum Mode {
        MANAGE,
        BROWSE,
        CHARACTER_MAP,
        COMPARE,
        ORGANIZE,
        WEB,
        N_MODES;

        public static Mode parse (string mode) {
            var _mode_ = mode.down();
            if (_mode_ == "browse")
                return Mode.BROWSE;
            else if (_mode_ == "compare")
                return Mode.COMPARE;
            else if (_mode_ == "character map")
                return Mode.CHARACTER_MAP;
            else
                return Mode.MANAGE;
        }

        public string to_string () {
            switch (this) {
                case BROWSE:
                    return "Browse";
                case COMPARE:
                    return "Compare";
                case CHARACTER_MAP:
                    return "Character Map";
                default:
                    return "Manage";
            }
        }

        public string to_translatable_string () {
            switch (this) {
                case BROWSE:
                    return _("Browse");
                case COMPARE:
                    return _("Compare");
                case CHARACTER_MAP:
                    return _("Character Map");
                default:
                    return _("Manage");
            }
        }

        public int [] settings () {
            switch (this) {
                case BROWSE:
                    return { (int) this, (int) MANAGE, (int) SideBarView.STANDARD };
                case COMPARE:
                    return { (int) MANAGE, (int) this - 2,  (int) SideBarView.STANDARD};
                case CHARACTER_MAP:
                    return { (int) MANAGE, (int) this, (int) SideBarView.CHARACTER_MAP};
                default:
                    return { 0, 0, 0 };
            }
        }

    }

    public class MainWindow : Gtk.ApplicationWindow {

        public signal void mode_changed (int new_mode);

        /* XXX : TODO : Switch to Gtk.Stack */
        public Gtk.Notebook main_notebook { get; private set; }
        public Gtk.Notebook preview_notebook { get; private set; }

        public Gtk.Box main_box { get; private set; }
        public Gtk.Box content_box { get; private set; }

        public ThinPaned main_pane { get; private set; }
        public ThinPaned content_pane { get; private set; }
        public Browse browser { get; private set; }
        public Compare compare { get; private set; }
        public FontPreview preview { get; private set; }
        public CharacterMap character_map { get; private set; }
        public SideBar sidebar { get; private set; }
        public TitleBar titlebar { get; private set; }
        public FontList fontlist { get; private set; }
        public FontListTree fonttree { get; private set; }

        public Mode mode {
            get {
                return _mode;
            }
            set {
                real_set_mode(value, loading);
            }
        }

        public weak FontModel? font_model {
            get {
                return (FontModel) fontlist.model;
            }
            set {
                fontlist.model = browser.model = value;
            }
        }

        public weak CollectionModel? collections {
            get {
                return sidebar.standard.collection_tree.model;
            }
            set {
                sidebar.standard.collection_tree.model = value;
            }
        }

        public weak CategoryModel? categories {
            get {
                return sidebar.standard.category_tree.model;
            }
            set {
                sidebar.standard.category_tree.model = value;
            }
        }

        public FontConfig.Reject reject {
            get {
                return fontlist.reject;
            }
            set {
                fontlist.reject = browser.reject =
                sidebar.standard.collection_tree.reject = value;
            }
        }

        public double progress {
            get {
                return _progress;
            }
            set {
                _progress = value;
                browser.progress.set_fraction(value);
                fonttree.progress.set_fraction(value);
                if (value >= 0.99) {
                    browser.loading = false;
                    fonttree.loading = false;
                }
                ensure_ui_update();
            }
        }

        public bool loading {
            get {
                return _loading;
            }
            set {
                _loading = value;
                if (mode != Mode.CHARACTER_MAP)
                    sidebar.loading = value;
                browser.loading = value;
                fonttree.loading = value;
            }
        }

        internal bool _loading = false;
        internal bool sidebar_switch = false;
        internal double _progress = 0.0;
        internal Mode _mode;

        construct {
            title = About.NAME;
            type = Gtk.WindowType.TOPLEVEL;
            has_resize_grip = true;
        }

        public MainWindow () {
            init_components();
            pack_components();
            show_components();
            add(main_box);
            connect_signals();
        }

        internal void init_components () {
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            content_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            main_pane = new ThinPaned(Gtk.Orientation.HORIZONTAL);
            content_pane = new ThinPaned(Gtk.Orientation.VERTICAL);
            browser = new Browse();
            compare = new Compare();
            preview = new FontPreview();
            character_map = new CharacterMap();
            sidebar = new SideBar();
            sidebar.add_view(new MainSideBar(), SideBarView.STANDARD);
            sidebar.add_view(character_map.sidebar, SideBarView.CHARACTER_MAP);
            titlebar = new TitleBar();
            fonttree = new FontListTree();
            fontlist = fonttree.fontlist;

            preview_notebook = get__preview__notebook();
            main_notebook = get__main__notebook();

            return;
        }

        internal void pack_components () {
            main_pane.add1(sidebar);
            main_pane.add2(content_box);
            add_separator(content_box, Gtk.Orientation.VERTICAL);
            content_box.pack_end(main_notebook, true, true, 0);
            content_pane.add1(fonttree);
            var separator = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add_separator(separator, Gtk.Orientation.HORIZONTAL);
            separator.show();
            separator.pack_end(preview_notebook, true, true, 0);
            content_pane.add2(separator);
            main_box.pack_end(main_pane, true, true, 0);
            if (Gnome3()) {
                set_titlebar(titlebar);
            } else {
                main_box.pack_start(titlebar, false, true, 0);
                add_separator(main_box, Gtk.Orientation.HORIZONTAL);
                titlebar.use_toolbar_styling();
            }
            return;
        }

        internal void show_components () {
            main_notebook.show();
            preview_notebook.show();
            main_box.show();
            content_box.show();
            main_pane.show();
            content_pane.show();
            browser.show();
            compare.show();
            preview.show();
            character_map.show();
            sidebar.show();
            titlebar.show();
            fonttree.show();
            return;
        }

        public void unset_all_models () {
            font_model = null;
            categories = null;
            return;
        }

        public void set_all_models () {
            font_model = Main.instance.font_model;
            collections = Main.instance.collection_model;
            categories = Main.instance.category_model;
            sidebar.user_source_model = Main.instance.user_source_model;
            return;
        }

        public void queue_reload () {
            /* Note : There's a 2 second delay built into FontConfig */
            Timeout.add_seconds(3, () => {
                Main.instance.update();
                return false;
            });
            return;
        }

        internal void real_set_mode (Mode mode, bool loading) {
            _mode = mode;
            titlebar.source_toggle.set_active(false);
            titlebar.main_menu_label.set_markup("<b>%s</b>".printf(mode.to_translatable_string()));
            var settings = mode.settings();
            main_notebook.set_current_page(settings[0]);
            preview_notebook.set_current_page(settings[1]);
            sidebar.mode = (SideBarView) settings[2];
            sidebar.loading = (mode != Mode.CHARACTER_MAP) ? loading : false;
            sidebar.standard.reveal_collection_controls((mode == Mode.MANAGE));
            titlebar.reveal_controls((mode == Mode.MANAGE));
            fonttree.show_controls = (mode != Mode.BROWSE);
            fontlist.controls.set_remove_sensitivity((mode == Mode.MANAGE && sidebar.standard.mode == MainSideBarMode.COLLECTION));
            fontlist.queue_draw();
            mode_changed(_mode);
            return;
        }

        internal void update_font_model (Filter? filter) {
            if (filter == null)
                return;
            font_model = null;
            Main.instance.font_model.update(filter);
            font_model = Main.instance.font_model;
            fonttree.fontlist.select_first_row();
            browser.expand_all();
            return;
        }

        internal void set_font_desc (Pango.FontDescription font_desc) {
            preview.font_desc = font_desc;
            compare.font_desc = font_desc;
            character_map.font_desc = font_desc;
            /* XXX : Workaround zoom breakage... */
            character_map.preview_size++;
            character_map.preview_size--;
            return;
        }

        internal void update_unsorted_category () {
            Value val;
            Gtk.TreeIter iter;
            Main.instance.category_model.get_iter_from_string(out iter, "11");
            Main.instance.category_model.get_value(iter, 0, out val);
            var unsorted = (Unsorted) val.get_object();
            unsorted.update(Main.instance.database);
            var collections = Main.instance.collections;
            unsorted.families.remove_all(collections.get_full_contents());
            val.unset();
            return;
        }

        internal void connect_signals () {
            mode_changed.connect((m) => {
                var action_map = (Application) GLib.Application.get_default();
                var action = ((SimpleAction) action_map.lookup_action("mode"));
                action.set_state(((Mode) m).to_string());
            });

            sidebar.standard.collection_tree.rename_collection.connect((c, n) => {
                Main.instance.collections.rename_collection(c, n);
            });

            sidebar.standard.category_selected.connect((c, i) => {
                if (font_model == null)
                    return;
                if (c is Unsorted)
                    update_unsorted_category();
                update_font_model(c);
                }
            );
            sidebar.standard.collection_selected.connect((c) => {
                if (font_model == null)
                    return;
                update_font_model(c);
                }
            );
            sidebar.standard.mode_selected.connect((m) => {
                /* XXX */
                if (font_model == null || sidebar_switch)
                    return;
                if (m == MainSideBarMode.CATEGORY)
                    update_font_model(sidebar.standard.selected_category);
                else
                    update_font_model(sidebar.standard.selected_collection);
                fontlist.controls.set_remove_sensitivity(mode == Mode.MANAGE && m == MainSideBarMode.COLLECTION);
                }
            );

            fontlist.font_selected.connect((string_desc) => {
                set_font_desc(Pango.FontDescription.from_string(string_desc));
                }
            );

            fontlist.controls.remove_selected.connect(() => {
                sidebar.standard.collection_tree.remove_fonts(fontlist.get_selected_families());
                update_font_model(sidebar.standard.collection_tree.selected_collection);
            });

            fontlist.enable_model_drag_dest(AppDragTargets, AppDragActions);
            fontlist.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK | Gdk.ModifierType.RELEASE_MASK, AppDragTargets, AppDragActions);
            var collections = sidebar.standard.collection_tree.tree;
            /* Let GTK+ handle re-ordering */
            collections.set_reorderable(true);

            fontlist.drag_data_received.connect(on_drag_data_received);
            fontlist.drag_begin.connect((w, c) => {
                /* When reorderable is set no other drag and drop is possible.
                 * Temporarily disable it and set the treeview up as a drag destination.
                 */
                collections.set_reorderable(false);
                collections.enable_model_drag_dest(AppDragTargets, AppDragActions);
                if (sidebar.standard.mode == MainSideBarMode.CATEGORY) {
                    sidebar_switch = true;
                    sidebar.standard.mode = MainSideBarMode.COLLECTION;
                }
            });
            fontlist.drag_end.connect((w, c) => {
                if (sidebar_switch) {
                    Idle.add(() => {
                        sidebar.standard.mode = MainSideBarMode.CATEGORY;
                        return false;
                    });
                    sidebar_switch = false;
                }
                collections.set_reorderable(true);
            });
            collections.drag_data_received.connect(on_drag_data_received);

            sidebar.standard.collection_tree.update_ui.connect(() => {
                sidebar.standard.collection_tree.queue_draw();
                fontlist.queue_draw();
                browser.queue_draw();
                }
            );

            titlebar.install_selected.connect(() => {
                var selected = FileSelector.run_install((Gtk.Window) this);
                if (selected.length > 0)
                    install_fonts(selected);
            });

            titlebar.remove_selected.connect(() => {
                remove_fonts();
            });

            titlebar.manage_sources.connect((a) => {
                if (a) {
                    content_box.hide();
                    sidebar.standard.set_visible_child_name("Sources");
                } else {
                    sidebar.standard.set_visible_child_name("Default");
                    content_box.show();
                }
            });

        }

        internal Gtk.Notebook get__preview__notebook () {
            var _preview_notebook = new Gtk.Notebook();
            _preview_notebook.append_page(preview, new Gtk.Label(_("Preview")));
            _preview_notebook.append_page(compare, new Gtk.Label(_("Compare")));
            _preview_notebook.append_page(character_map.pane, new Gtk.Label(_("Character Map")));
            _preview_notebook.show_border = false;
            _preview_notebook.show_tabs = false;
            return _preview_notebook;
        }

        internal Gtk.Notebook get__main__notebook () {
            var _main_notebook = new Gtk.Notebook();
            _main_notebook.append_page(content_pane, new Gtk.Label(_("Manage")));
            _main_notebook.append_page(browser, new Gtk.Label(_("Browse")));
            _main_notebook.show_border = false;
            _main_notebook.show_tabs = false;
            return _main_notebook;
        }

        internal void remove_fonts () {
            var _model = new UserFontModel(Main.instance.fontconfig.families, Main.instance.database);
            var arr = FileSelector.run_removal((Gtk.Window) this, _model);
            if (arr != null) {
                /* Avoid empty boxes and Pango warnings when removing fonts */
                unset_all_models();
                set_font_desc(Pango.FontDescription.from_string(DEFAULT_FONT));
                fonttree.progress.set_fraction(0f);
                loading = true;
                Library.progress = (m, p, t) => {
                    fonttree.progress.set_fraction((float) p / (float) t);
                    ensure_ui_update();
                };
                Main.instance.fontconfig.cancel_monitors();
                Library.Remove.from_file_array(arr);
                queue_reload();
            }
            return;
        }

        internal void install_fonts (string [] arr) {
            fonttree.loading = true;
            font_model = null;
            fonttree.progress.set_fraction(0f);
            Library.progress = (m, p, t) => {
                fonttree.progress.set_fraction((float) p / (float) t);
                ensure_ui_update();
            };
            Main.instance.fontconfig.cancel_monitors();
            Library.Install.from_uri_array(arr);
            fonttree.loading = false;
            font_model = Main.instance.font_model;
            queue_reload();
            return;
        }

        void on_drag_data_received (Gtk.Widget widget,
                                    Gdk.DragContext context,
                                    int x,
                                    int y,
                                    Gtk.SelectionData selection_data,
                                    uint info,
                                    uint time)
        {
            switch (info) {
                case DragTargetType.FAMILY:
                    family_drop_handler(widget, x, y);
                    break;
                case DragTargetType.EXTERNAL:
                    install_fonts(selection_data.get_uris());
                    break;
                default:
                    warning("Unsupported drag target.");
                    return;
            }
            return;
        }

        void family_drop_handler (Gtk.Widget widget, int x, int y) {
            if (!(widget.name == "CollectionsTree"))
                return;
            Gtk.TreePath path;
            var tree = widget as Gtk.TreeView;
            tree.get_path_at_pos(x, y, out path, null, null, null);
            if (path == null) {
                return;
            }
            Gtk.TreeIter iter;
            var model = tree.get_model();
            if (!model.get_iter(out iter, path))
                /* Invalid drop, non-existent path */
                return;
            Value val;
            model.get_value(iter, CollectionColumn.OBJECT, out val);
            var group = (Collection) val.get_object();
            if (group != null) {
                group.families.add_all(fontlist.get_selected_families());
                group.set_active_from_fonts(Main.instance.fontconfig.reject);
                Main.instance.collections.cache();
                Idle.add(() => {
                    update_unsorted_category();
                    return false;
                });
            }
            return;
        }

        public void restore_state () {
            var settings = Main.instance.settings;
            int x, y, w, h;
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);
            set_default_size(w, h);
            move(x, y);
            mode = (FontManager.Mode) settings.get_enum("mode");
            sidebar.standard.mode = (MainSideBarMode) settings.get_enum("sidebar-mode");
            preview.mode = (PreviewMode) settings.get_enum("preview-mode");
            main_pane.position = settings.get_int("sidebar-size");
            content_pane.position = settings.get_int("content-pane-position");
            preview.preview_size = settings.get_double("preview-font-size");
            browser.preview_size = settings.get_double("browse-font-size");
            compare.preview_size = settings.get_double("compare-font-size");
            var preview_text = settings.get_string("preview-text");
            if (preview_text != "DEFAULT")
                preview.set_preview_text(preview_text);
            sidebar.character_map.selected_block = settings.get_string("selected-block");
            sidebar.character_map.selected_script = settings.get_string("selected-script");
            sidebar.character_map.mode = (CharacterMapSideBarMode) settings.get_enum("charmap-mode");
            sidebar.character_map.set_initial_selection(settings.get_string("selected-script"), settings.get_string("selected-block"));
            var foreground = Gdk.RGBA();
            var background = Gdk.RGBA();
            bool foreground_set = foreground.parse(settings.get_string("compare-foreground-color"));
            bool background_set = background.parse(settings.get_string("compare-background-color"));
            if (foreground_set)
                compare.foreground_color = foreground;
            if (background_set)
                compare.background_color = background;
            var compare_list = settings.get_strv("compare-list");
            foreach (var entry in compare_list) {
                if (entry == null)
                    break;
                compare.add_from_string(entry);
            }
            fontlist.controls.set_remove_sensitivity(sidebar.standard.mode == MainSideBarMode.COLLECTION);
            return;
        }

        public void bind_settings () {
            var settings = Main.instance.settings;
            configure_event.connect((w, /* Gdk.EventConfigure */ e) => {
                settings.set("window-size", "(ii)", e.width, e.height);
                settings.set("window-position", "(ii)", e.x, e.y);
                /* XXX : this shouldn't be needed...
                 * It's purpose is to prevent the window title from being
                 * truncated even though it would fit. (Gtk.HeaderBar)
                 */
                titlebar.queue_resize();
                return false;
                }
            );
            mode_changed.connect((i) => {
                settings.set_enum("mode", i);
                }
            );

            sidebar.standard.mode_selected.connect((m) => {
                settings.set_enum("sidebar-mode", (int) m);
                }
            );
            preview.mode_changed.connect((m) => { settings.set_enum("preview-mode", m); });
            preview.preview_changed.connect((p) => { settings.set_string("preview-text", p); });
            settings.bind("sidebar-size", main_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("content-pane-position", content_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("preview-font-size", preview, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("browse-font-size", browser, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("compare-font-size", compare, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("charmap-font-size", character_map.pane.table, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("selected-block", sidebar.character_map, "selected-block", SettingsBindFlags.DEFAULT);
            settings.bind("selected-script", sidebar.character_map, "selected-script", SettingsBindFlags.DEFAULT);
            sidebar.character_map.mode_set.connect(() => {
                settings.set_enum("charmap-mode", (int) sidebar.character_map.mode);
                }
            );
            compare.color_set.connect((p) => {
                settings.set_string("compare-foreground-color", compare.foreground_color.to_string());
                settings.set_string("compare-background-color", compare.background_color.to_string());
                }
            );
            compare.list_modified.connect(() => {
                settings.set_strv("compare-list", compare.list());
                }
            );
            settings.delay();
            /* XXX : Some settings are bound in post due to timing issues... */
            return;
        }

        public void post_activate () {

            /* Close popover on click */
            mode_changed.connect((i) => {
                titlebar.main_menu.active = !titlebar.main_menu.active;
                Idle.add(() => {
                    return Gtk.popovers_should_close_on_click(titlebar.main_menu);
                });
            });
            
            /* XXX */
            NotImplemented.parent = (Gtk.Window) this;

            delete_event.connect((w, e) => {
                ((Application) GLib.Application.get_default()).on_quit();
                return true;
                }
            );

            /* XXX : Workaround timing issue? wrong filter shown at startup */
            if (sidebar.standard.mode == MainSideBarMode.COLLECTION) {
                sidebar.standard.mode = MainSideBarMode.CATEGORY;
                sidebar.standard.mode = MainSideBarMode.COLLECTION;
            }

            /* Workaround first row height bug? in browse mode */
            Idle.add(() => {
                browser.preview_size++;
                browser.preview_size--;
                return false;
                }
            );

            /* XXX: Order matters */
            var settings = Main.instance.settings;
            var font_path = settings.get_string("selected-font");
            if (sidebar.standard.mode == MainSideBarMode.COLLECTION) {
                var tree = sidebar.standard.collection_tree.tree;
                string path = settings.get_string("selected-collection");
                restore_last_selected_treepath(tree, path);
            } else {
                var tree = sidebar.standard.category_tree.tree;
                string path = settings.get_string("selected-category");
                restore_last_selected_treepath(tree, path);
            }
            Idle.add(() => {
                var treepath = restore_last_selected_treepath(fontlist, font_path);
                if (treepath != null)
                    browser.treeview.scroll_to_cell(treepath, null, true, 0.5f, 0.5f);
                return false;
            });
            settings.bind("selected-category", sidebar.standard.category_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-collection", sidebar.standard.collection_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-font", fontlist, "selected-iter", SettingsBindFlags.DEFAULT);
        }

        internal Gtk.TreePath? restore_last_selected_treepath (Gtk.TreeView tree, string path) {
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
