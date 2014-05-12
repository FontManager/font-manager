/* Components.vala
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

/* XXX : ugly */

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
                    return "Browse";
                case COMPARE:
                    return "Compare";
                case CHARACTER_MAP:
                    return "Character Map";
                default:
                    return "Manage";
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

    public class Core : Object {

        public signal void progress (string? message, int processed, int total);

        public Database database { get; private set; }
        public Collections collections { get; private set; }
        public FontConfig.Config fontconfig { get; private set; }

        string? progress_message = null;

        public void init () {
            collections = load_collections();
            fontconfig = new FontConfig.Config();
            fontconfig.progress.connect((m, p, t) => { progress(m, p, t); });
            fontconfig.init();
            database = get_database();
            sync_fonts_table(database, FontConfig.list_fonts(), report_progress);
        }

        public void update () {
            fontconfig.update();
            sync_fonts_table(database, FontConfig.list_fonts(), report_progress);
        }

        void report_progress (string? message, int processed, int total) {
            progress(progress_message != null ? progress_message : message, processed, total);
            return;
        }

    }

    public class Model : Object {

        public CategoryModel categories { get; set; }
        public CollectionModel collections { get; set; }
        public FontModel fonts { get; set; }

        public Model (Core core) {
            categories = new CategoryModel(core.database);
            categories.init();
            this.collections = new CollectionModel();
            this.collections.collections = core.collections; /* Yup */
            fonts = new FontModel();
            fonts.families = core.fontconfig.families;
        }

        public void update () {
            categories.update();
            fonts.update();
            return;
        }

    }

    public class Components : Object {

        public signal void mode_changed (int new_mode);

        public Core core { get; set; }
        public Model model { get; set; }
        public Main main { get; set; }
        public MainWindow main_window { get; set; }
        public ThinPaned content_pane { get; private set; }
        public Gtk.Notebook main_notebook { get; private set; }
        public Gtk.Notebook preview_notebook { get; private set; }
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

        bool _loading = false;
        bool sidebar_switch = false;
        double _progress = 0.0;

        FontModel font_model;
        FontConfig.Reject reject;
        Mode _mode;
        Gtk.Revealer font_list_controls_revealer;

        public Components () {
            titlebar = new TitleBar();
            content_pane = new ThinPaned(Gtk.Orientation.VERTICAL);
            browser = new Browse();
            compare = new Compare();
            preview = new FontPreview();
            character_map = new CharacterMap();
            sidebar = new SideBar();
            sidebar.add_view(new MainSideBar(), SideBarView.STANDARD);
            sidebar.add_view(character_map.sidebar, SideBarView.CHARACTER_MAP);
            fonttree = new FontListTree();
            fontlist = fonttree.fontlist;
            preview_notebook = get__preview__notebook();
            font_list_controls_revealer = new Gtk.Revealer();
            font_list_controls_revealer.hexpand = true;
            font_list_controls_revealer.vexpand = false;
            var fontlist_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            var _box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _box.pack_start(fontlist.controls, false, true, 0);
            add_separator(_box, Gtk.Orientation.HORIZONTAL);
            font_list_controls_revealer.add(_box);
            fontlist_box.pack_start(font_list_controls_revealer, false, true, 0);
            fontlist_box.pack_end(fonttree, true, true, 0);
            content_pane.add1(fontlist_box);
            var separator = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add_separator(separator, Gtk.Orientation.HORIZONTAL);
            separator.pack_end(preview_notebook, true, true, 0);
            content_pane.add2(separator);
            main_notebook = get__main__notebook();
            content_pane.show();
            browser.show();
            compare.show();
            preview.show();
            character_map.show();
            sidebar.show();
            fonttree.show();
            fontlist_box.show();
            _box.show();
            font_list_controls_revealer.show();
            preview_notebook.show();
            separator.show();
            main_notebook.show();
            connect_signals();
        }

        public void reveal_font_list_controls (bool reveal) {
            font_list_controls_revealer.set_reveal_child(reveal);
            return;
        }

        public void set_reject (FontConfig.Reject reject) {
            this.reject = reject;
            fontlist.reject = reject;
            browser.reject = reject;
            sidebar.standard.collection_tree.reject = reject;
            return;
        }

        public void unset_all_models () {
            font_model = null;
            fontlist.model = null;
            browser.model = null;
            return;
        }

        public void set_all_models () {
            set_font_model(model.fonts);
            set_collection_model(model.collections);
            set_category_model(model.categories);
            return;
        }

        public void set_font_model (FontModel? model) {
            font_model = model;
            fontlist.model = model;
            browser.model = model;
            return;
        }

        public void set_collection_model (CollectionModel? model) {
            sidebar.standard.collection_tree.model = model;
            return;
        }

        public void set_category_model (CategoryModel? model) {
            sidebar.standard.category_tree.model = model;
            return;
        }

        public void reload () {
            FontConfig.update_cache();
            unset_all_models();
            loading = true;
            ensure_ui_update();
            core.update();
            model.update();
            loading = false;
            set_all_models();
            ensure_ui_update();
            return;
        }

        public void queue_reload () {
            Timeout.add_seconds(3, () => {
                reload();
                return false;
            });
            return;
        }

        internal void real_set_mode (Mode mode, bool loading) {
            _mode = mode;
            titlebar.main_menu_label.set_markup("<b>%s</b>".printf(mode.to_translatable_string()));
            var settings = mode.settings();
            main_notebook.set_current_page(settings[0]);
            preview_notebook.set_current_page(settings[1]);
            sidebar.mode = (SideBarView) settings[2];
            sidebar.loading = (mode != Mode.CHARACTER_MAP) ? loading : false;
            sidebar.standard.reveal_controls((mode == Mode.MANAGE));
            titlebar.reveal_controls((mode == Mode.MANAGE));
            reveal_font_list_controls((mode != Mode.BROWSE));
            fontlist.controls.set_remove_sensitivity((mode == Mode.MANAGE && sidebar.standard.mode == MainSideBarMode.COLLECTION));
            fontlist.queue_draw();
            ensure_ui_update();
            mode_changed(mode);
            return;
        }

        internal void update_font_model (Filter? filter) {
            if (filter == null)
                return;
            fonttree.fontlist.model = null;
            font_model.update(filter);
            fonttree.fontlist.model = font_model;
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
            model.categories.get_iter_from_string(out iter, "11");
            model.categories.get_value(iter, 0, out val);
            var unsorted = (Unsorted) val.get_object();
            unsorted.update(core.database);
            unsorted.families.remove_all(core.collections.get_full_contents());
            val.unset();
            return;
        }

        internal void connect_signals () {
            sidebar.standard.collection_tree.rename_collection.connect((c, n) => {
                core.collections.rename_collection(c, n);
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

            titlebar.search_selected.connect(() => {
                NotImplemented.run("Database Search");
            });

            titlebar.install_selected.connect(() => {
                var selected = FileSelector.run_install((Gtk.Window) main_window);
                if (selected.length > 0)
                    install_fonts(selected);
            });

            titlebar.remove_selected.connect(() => {
                remove_fonts();
            });

        }

        internal Gtk.Notebook get__preview__notebook () {
            var _preview_notebook = new Gtk.Notebook();
            _preview_notebook.append_page(preview, new Gtk.Label("Preview"));
            _preview_notebook.append_page(compare, new Gtk.Label("Compare"));
            _preview_notebook.append_page(character_map.table, new Gtk.Label("Character Map"));
            _preview_notebook.show_border = false;
            _preview_notebook.show_tabs = false;
            return _preview_notebook;
        }

        internal Gtk.Notebook get__main__notebook () {
            var _main_notebook = new Gtk.Notebook();
            _main_notebook.append_page(content_pane, new Gtk.Label("Manage"));
            _main_notebook.append_page(browser, new Gtk.Label("Browse"));
            _main_notebook.show_border = false;
            _main_notebook.show_tabs = false;
            return _main_notebook;
        }

        internal void remove_fonts () {
            var _model = new UserFontModel(core.fontconfig.families, core.database);
            var arr = FileSelector.run_removal((Gtk.Window) main_window, _model);
            if (arr != null) {
                /* Avoid empty boxes and Pango warnings when removing fonts */
                unset_all_models();
                set_font_desc(Pango.FontDescription.from_string(DEFAULT_FONT));
                fonttree.progress.set_fraction(0f);
                loading = true;
                ensure_ui_update();
                Library.progress = (m, p, t) => {
                    fonttree.progress.set_fraction((float) p / (float) t);
                    ensure_ui_update();
                };
                core.fontconfig.cancel_monitors();
                Library.Remove.from_file_array(arr);
                queue_reload();
                Timeout.add_seconds(3, () => {
                    core.fontconfig.enable_monitors();
                    return false;
                });
            }
            return;
        }

        internal void install_fonts (string [] arr) {
            fonttree.loading = true;
            fontlist.model = null;
            fonttree.progress.set_fraction(0f);
            Library.progress = (m, p, t) => {
                fonttree.progress.set_fraction((float) p / (float) t);
                ensure_ui_update();
            };
            core.fontconfig.cancel_monitors();
            Library.Install.from_uri_array(arr);
            fonttree.loading = false;
            fontlist.model = model.fonts;
            queue_reload();
            Timeout.add_seconds(3, () => {
                core.fontconfig.enable_monitors();
                return false;
            });
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
                    /* XXX : need to "reload" here! */
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
                group.set_active_from_fonts(reject);
                core.collections.cache();
                Idle.add(() => {
                    update_unsorted_category();
                    return false;
                });
            }
            return;
        }


    }

}
