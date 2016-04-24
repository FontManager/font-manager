/* MainWindow.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    public enum Mode {
        MANAGE,
        BROWSE,
        COMPARE,
        N_MODES;

        public static Mode parse (string mode) {
            switch (mode.down()) {
                case "browse":
                    return Mode.BROWSE;
                case "compare":
                    return Mode.COMPARE;
                default:
                    return Mode.MANAGE;
            }
        }

        public string to_string () {
            switch (this) {
                case BROWSE:
                    return "Browse";
                case COMPARE:
                    return "Compare";
                default:
                    return "Default";
            }
        }

        public string to_translatable_string () {
            switch (this) {
                case BROWSE:
                    return _("Browse");
                case COMPARE:
                    return _("Compare");
                default:
                    return _("Manage");
            }
        }

        public string [] settings () {
            switch (this) {
                case BROWSE:
                    return { "Browse", "Default"};
                case COMPARE:
                    return { "Default", "Compare"};
                default:
                    return { "Default", "Default"};
            }
        }

    }

    public class MainWindow : Gtk.ApplicationWindow {

        public signal void mode_changed (int new_mode);

        public bool wide_layout { get; set; default = false; }
        public bool use_csd { get; set; default = true; }
        public string selected_font { get; set; default = DEFAULT_FONT; }
        public FontModel? font_model { get; set; default = null; }
        public FontConfig.Reject reject { get; set; }

        public Gtk.Stack main_stack { get; private set; }
        public Gtk.Stack content_stack { get; private set; }
        public Gtk.Stack view_stack { get; private set; }
        public Gtk.Box main_box { get; private set; }
        public Gtk.Box content_box { get; private set; }
        public Gtk.Paned main_pane { get; private set; }
        public Gtk.Paned content_pane { get; private set; }

        public Browse browser { get; private set; }
        public Compare compare { get; private set; }
        public FontPreviewPane preview { get; private set; }
        public SideBar sidebar { get; private set; }
        public TitleBar titlebar { get; private set; }
        public FontList fontlist { get; private set; }
        public FontListTree fonttree { get; private set; }
        public Preferences.Pane preference_pane { get; private set; }

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
                sidebar.loading = value;
                browser.loading = value;
                fonttree.loading = value;
            }
        }

        public FontData font_data {
            get {
                return preview.font_data;
            }
            set {
                preview.font_data = value;
            }
        }

        bool _loading = false;
        bool sidebar_switch = false;
        bool charmap_visible = false;
        bool is_horizontal = false;
        double _progress = 0.0;
        Mode _mode;
        Gtk.Box content_view;
        Gtk.Box _main_pane_;
        Gtk.Separator content_separator;
        Unsorted? unsorted = null;
        Disabled? disabled = null;
        CharacterMapSideBar charmap_sidebar;
        RenderingOptions render_opts;

        public MainWindow () {
            Object(title: About.NAME, icon_name: About.ICON, type: Gtk.WindowType.TOPLEVEL);
            application = ((Application) GLib.Application.get_default());
            use_csd = ((Application) application).use_csd;
            init_components();
            bind_properties();
            pack_components();
            add(main_box);
            set_models();
            connect_signals();
        }

        void bind_properties () {
            bind_property("font-model", browser, "model", BindingFlags.SYNC_CREATE);
            bind_property("font-model", fontlist, "model", BindingFlags.SYNC_CREATE);
            bind_property("reject", browser, "reject", BindingFlags.SYNC_CREATE);
            bind_property("reject", fontlist, "reject", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            bind_property("reject", sidebar.standard.collection_tree, "reject", BindingFlags.SYNC_CREATE);
            bind_property("selected-font", fontlist, "selected-font-desc", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("font-data", fontlist, "font-data", BindingFlags.BIDIRECTIONAL);
            bind_property("selected-font", compare, "font-desc", BindingFlags.SYNC_CREATE);
            bind_property("use-csd", ((Application) application), "use-csd", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            var ui_prefs = (Preferences.Interface) preference_pane.get_page("Interface");
            bind_property("wide-layout", ui_prefs.wide_layout.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            application.bind_property("use-csd", ui_prefs.use_csd.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            return;
        }

        void init_components () {
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            content_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            main_pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            content_pane = new Gtk.Paned(wide_layout ? Gtk.Orientation.HORIZONTAL : Gtk.Orientation.VERTICAL);
            browser = new Browse();
            compare = new Compare();
            preview = new FontPreviewPane();
            preview.charmap.show_details = true;
            sidebar = new SideBar();
            charmap_sidebar = new CharacterMapSideBar();
            sidebar.add_view(new StandardSideBar(), "Default");
            sidebar.add_view(charmap_sidebar, "Character Map");
            titlebar = new TitleBar();
            fonttree = new FontListTree();
            fontlist = fonttree.fontlist;
            main_stack = new Gtk.Stack();
            main_stack.set_transition_duration(720);
            main_stack.set_transition_type(Gtk.StackTransitionType.UNDER_UP);
            view_stack = new Gtk.Stack();
            view_stack.add_titled(preview, "Default", _("Preview"));
            view_stack.add_titled(compare, "Compare", _("Compare"));
            view_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            content_stack = new Gtk.Stack();
            content_stack.set_transition_duration(420);
            content_stack.add_titled(content_pane, "Default", _("Manage"));
            content_stack.add_titled(browser, "Browse", _("Browse"));
            content_stack.set_transition_type(Gtk.StackTransitionType.OVER_LEFT);
            unsorted = new Unsorted();
            disabled = new Disabled();
            render_opts = new RenderingOptions();
            preference_pane = construct_preference_pane();
            return;
        }

        void pack_components () {
            main_pane.add1(sidebar);
            main_pane.add2(content_box);
            add_separator(content_box, Gtk.Orientation.VERTICAL);
            content_box.pack_end(content_stack, true, true, 0);
            content_pane.add1(fonttree);
            content_view = new Gtk.Box(wide_layout ? Gtk.Orientation.HORIZONTAL : Gtk.Orientation.VERTICAL, 0);
            content_separator = add_separator(content_view, wide_layout ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL);
            content_view.pack_end(view_stack, true, true, 0);
            content_pane.add2(content_view);
            _main_pane_ = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _main_pane_.pack_start(main_pane, true, true, 0);
            add_separator(_main_pane_, Gtk.Orientation.HORIZONTAL);
            main_stack.add_named(_main_pane_, "Default");
            main_stack.add_named(preference_pane, "Preferences");
            main_box.pack_end(main_stack, true, true, 0);
            if (Gdk.Screen.get_default().is_composited() && use_csd) {
                set_titlebar(titlebar);
            } else {
                main_box.pack_start(titlebar, false, true, 0);
                add_separator(main_box, Gtk.Orientation.HORIZONTAL);
                titlebar.use_toolbar_styling();
            }
            return;
        }

        public void set_horizontal_layout () {
            var settings = Main.instance.settings;
            if (settings != null) {
                if (!is_horizontal) {
                    settings.set_int("last-vertical-content-pane-position", content_pane.position);
                }
                Idle.add(() => {
                    content_pane.set_position(settings.get_int("last-horizontal-content-pane-position"));
                    return false;
                });
            }
            content_pane.set_orientation(Gtk.Orientation.HORIZONTAL);
            content_view.set_orientation(Gtk.Orientation.HORIZONTAL);
            content_separator.set_orientation(Gtk.Orientation.VERTICAL);
            is_horizontal = true;
            return;
        }

        public void unset_horizontal_layout () {
            var settings = Main.instance.settings;
            if (settings != null) {
                if (is_horizontal) {
                    settings.set_int("last-horizontal-content-pane-position", content_pane.position);
                }
                Idle.add(() => {
                    if (settings.get_boolean("wide-layout-on-maximize") && !is_maximized)
                        content_pane.set_position(settings.get_int("last-vertical-content-pane-position"));
                    return false;
                });
            }
            content_pane.set_orientation(Gtk.Orientation.VERTICAL);
            content_view.set_orientation(Gtk.Orientation.VERTICAL);
            content_separator.set_orientation(Gtk.Orientation.HORIZONTAL);
            is_horizontal = false;
            return;
        }

        public override void show () {
            content_view.show();
            _main_pane_.show();
            content_stack.show();
            view_stack.show();
            main_box.show();
            content_box.show();
            main_pane.show();
            content_pane.show();
            browser.show();
            compare.show();
            preview.show();
            sidebar.show();
            charmap_sidebar.show();
            titlebar.show();
            fonttree.show();
            preference_pane.show();
            main_stack.show();
            base.show();
            return;
        }

        public void set_models () {
            font_model = Main.instance.font_model;
            reject = Main.instance.reject;
            return;
        }

        public void reset_selections () {
            sidebar.standard.category_tree.select_first_row();
            sidebar.standard.collection_tree.select_first_row();
            if (sidebar.standard.mode == StandardSideBarMode.CATEGORY)
                update_font_model(sidebar.standard.selected_category);
            else
                update_font_model(sidebar.standard.selected_collection);
            return;
        }

        void real_set_mode (Mode mode, bool loading) {
            _mode = mode;
            titlebar.main_menu_label.set_markup("<b>%s</b>".printf(mode.to_translatable_string()));
            var settings = mode.settings();
            /* XXX */
            content_stack.set_visible_child_name(settings[0]);
            view_stack.set_visible_child_name(settings[1]);
            if (mode == Mode.MANAGE && charmap_visible)
                sidebar.mode = "Character Map";
            else
                sidebar.mode = "Default";
            sidebar.loading = loading;
            sidebar.standard.reveal_collection_controls((mode == Mode.MANAGE));
            titlebar.reveal_controls((mode == Mode.MANAGE));
            fonttree.show_controls = (mode != Mode.BROWSE);
            fontlist.controls.set_remove_sensitivity((mode == Mode.MANAGE && sidebar.standard.mode == StandardSideBarMode.COLLECTION));
            fontlist.queue_draw();
            render_opts.visible = (render_opts.visible && mode == Mode.MANAGE);
            if (titlebar.prefs_toggle.active && mode != Mode.MANAGE)
                titlebar.prefs_toggle.active = false;
            if (mode == Mode.BROWSE)
                browser.treeview.queue_draw();
            mode_changed(_mode);
            debug("Mode changed : %s", mode.to_string());
            return;
        }

        void update_font_model (Filter? filter) {
            if (filter == null)
                return;
            font_model = null;
            Main.instance.font_model.update(filter);
            font_model = Main.instance.font_model;
            fonttree.fontlist.select_first_row();
            browser.expand_all();
            return;
        }

        void connect_signals () {

            delete_event.connect((w, e) => {
                application.quit();
                return true;
                }
            );

            var settings = Main.instance.settings;

            notify["wide-layout"].connect(() => {
                Idle.add(() => {
                    if (wide_layout && (!(settings.get_boolean("wide-layout-on-maximize")) || is_maximized)) {
                        set_horizontal_layout();
                    } else if (settings != null && wide_layout && settings.get_boolean("wide-layout-on-maximize") && !(is_maximized)) {
                        if (is_horizontal) {
                            unset_horizontal_layout();
                        }
                    } else {
                        unset_horizontal_layout();
                    }
                    return false;
                });
            });

            notify["is-maximized"].connect(() => {
                Idle.add(() => {
                    if (settings != null) {
                        if (wide_layout) {
                            if (settings.get_boolean("wide-layout-on-maximize")) {
                                Idle.add(() => {
                                    if (this.is_maximized) {
                                        set_horizontal_layout();
                                    } else {
                                        unset_horizontal_layout();
                                    }
                                    return false;
                                });
                            }
                        } else {
                            Idle.add(() => {
                                unset_horizontal_layout();
                                return false;
                            });
                        }
                    }
                    return false;
                });
            });

            if (settings != null) {
                settings.changed.connect((key) => {
                    if (key == "wide-layout-on-maximize") {
                        Idle.add(() => {
                            if (settings.get_boolean("wide-layout-on-maximize")) {
                                if (!is_maximized && is_horizontal) {
                                    unset_horizontal_layout();
                                }
                            } else {
                                if (wide_layout)
                                    set_horizontal_layout();
                                else
                                    unset_horizontal_layout();
                            }
                            return false;
                        });
                    }
                });
            }

            mode_changed.connect((m) => {
                var action = ((SimpleAction) application.lookup_action("mode"));
                action.set_state(((Mode) m).to_string());
                /* Close popover on click */
                titlebar.main_menu.active = !titlebar.main_menu.active;
            });

            sidebar.standard.category_selected.connect((c, i) => {
                if (font_model == null)
                    return;
                if (c is Unsorted) {
                    unsorted = ((Unsorted) c);
                    unsorted.update(Main.instance.database, sidebar.collection_model.collections.get_full_contents());
                } else if (c is Disabled) {
                    disabled = ((Disabled) c);
                    disabled.update(Main.instance.database, Main.instance.reject);
                }
                update_font_model(c);
            });
            sidebar.standard.collection_selected.connect((c) => {
                if (font_model == null)
                    return;
                update_font_model(c);
                }
            );
            sidebar.standard.mode_selected.connect(() => {
                if (font_model == null || sidebar_switch)
                    return;
                var m = sidebar.standard.mode;
                if (m == StandardSideBarMode.CATEGORY)
                    update_font_model(sidebar.standard.selected_category);
                else
                    update_font_model(sidebar.standard.selected_collection);
                fontlist.controls.set_remove_sensitivity(mode == Mode.MANAGE && m == StandardSideBarMode.COLLECTION);
                }
            );
            sidebar.standard.collection_tree.update_ui.connect(() => {
                sidebar.standard.collection_tree.queue_draw();
                fontlist.queue_draw();
                browser.queue_draw();
            });
            sidebar.standard.collection_tree.changed.connect(() => {
                unsorted.update(Main.instance.database, sidebar.collection_model.collections.get_full_contents());
            });

            fontlist.selection_changed.connect(() => {
                Gtk.TreeIter iter;
                fontlist.model.get_iter_from_string(out iter, fontlist.selected_iter);
                if (render_opts.visible) {
                    if (fontlist.model.iter_has_child(iter)) {
                        render_opts.properties.font = null;
                        render_opts.properties.family = fontlist.selected_family.name;
                    } else {
                        render_opts.properties.font = fontlist.selected_font;
                    }
                }
            });

            fontlist.controls.remove_selected.connect(() => {
                if (sidebar.standard.collection_tree.selected_collection == null)
                    return;
                sidebar.standard.collection_tree.remove_fonts(fontlist.get_selected_families());
                update_font_model(sidebar.standard.collection_tree.selected_collection);
            });

            fontlist.enable_model_drag_dest(AppDragTargets, AppDragActions);
            fontlist.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK | Gdk.ModifierType.RELEASE_MASK, AppDragTargets, AppDragActions);
            var collections_tree = sidebar.standard.collection_tree.tree;
            /* Let GTK+ handle re-ordering */
            collections_tree.set_reorderable(true);

            fontlist.drag_data_received.connect(on_drag_data_received);
            fontlist.drag_begin.connect((w, c) => {
                /* When reorderable is set no other drag and drop is possible.
                 * Temporarily disable it and set the treeview up as a drag destination.
                 */
                collections_tree.set_reorderable(false);
                collections_tree.enable_model_drag_dest(AppDragTargets, AppDragActions);
                if (sidebar.standard.mode == StandardSideBarMode.CATEGORY) {
                    sidebar_switch = true;
                    sidebar.standard.mode = StandardSideBarMode.COLLECTION;
                }
            });
            fontlist.drag_end.connect((w, c) => {
                if (sidebar_switch) {
                    Idle.add(() => {
                        sidebar.standard.mode = StandardSideBarMode.CATEGORY;
                        return false;
                    });
                    sidebar_switch = false;
                }
                collections_tree.set_reorderable(true);
                unsorted.update(Main.instance.database, sidebar.collection_model.collections.get_full_contents());
            });
            collections_tree.drag_data_received.connect(on_drag_data_received);

            titlebar.install_selected.connect(() => {
                var selected = FileSelector.run_install((Gtk.Window) this);
                if (selected.length > 0)
                    install_fonts(selected);
            });

            titlebar.remove_selected.connect(() => {
                remove_fonts();
            });

            titlebar.preferences_selected.connect((a) => {
                if (a)
                    main_stack.set_visible_child_name("Preferences");
                else
                    main_stack.set_visible_child_name("Default");
            });

            main_stack.notify["visible-child-name"].connect(() => {
                if (main_stack.get_visible_child_name() == "Default")
                    main_stack.set_transition_type(Gtk.StackTransitionType.UNDER_UP);
                else
                    main_stack.set_transition_type(Gtk.StackTransitionType.OVER_DOWN);
            });

            content_stack.notify["visible-child-name"].connect(() => {
                if (content_stack.get_visible_child_name() == "Default")
                    content_stack.set_transition_type(Gtk.StackTransitionType.OVER_LEFT);
                else
                    content_stack.set_transition_type(Gtk.StackTransitionType.UNDER_RIGHT);
            });

            reject.changed.connect(() => {
                disabled.update(Main.instance.database, Main.instance.reject);
                if (sidebar.standard.category_tree.selected_filter is Disabled)
                    update_font_model(sidebar.standard.category_tree.selected_filter);
                Idle.add(() => {
                    reject.load();
                    fontlist.queue_draw();
                    return false;
                });
            });

            preview.notebook.switch_page.connect((p, p_num) => {
                if (p is CharacterTable) {
                    charmap_visible = true;
                    sidebar.mode = "Character Map";
                } else {
                    charmap_visible = false;
                    sidebar.mode = "Default";
                }
            });

            charmap_sidebar.selection_changed.connect((cl) => { preview.charmap.table.codepoint_list = cl; });

        }

        void remove_fonts () {
            var _model = new UserFontModel(Main.instance.families, Main.instance.database);
            var arr = FileSelector.run_removal((Gtk.Window) this, _model);
            if (arr != null) {
                /* Avoid empty boxes and Pango warnings when removing fonts */
                font_model = null;
                fonttree.progress.set_fraction(0f);
                loading = true;
                Library.progress = (m, p, t) => {
                    Main.instance.main_window.fonttree.progress.set_fraction((float) p / (float) t);
                    ensure_ui_update();
                };
                Library.Remove.from_file_array(arr, Main.instance.database);
                foreach (var file in arr) {
                    try {
                        prune_path_from_database(Main.instance.database, file.get_path());
                    } catch (DatabaseError e) {
                        warning("Failed to remove entries from database : %s", e.message);
                    }
                }
                queue_reload();
            }
            return;
        }

        void install_fonts (string [] arr) {
            fonttree.loading = true;
            font_model = null;
            fonttree.progress.set_fraction(0f);
            Library.progress = (m, p, t) => {
                Main.instance.main_window.fonttree.progress.set_fraction((float) p / (float) t);
                ensure_ui_update();
            };
            Library.Install.from_uri_array(arr);
            fonttree.loading = false;
            font_model = Main.instance.font_model;
            if(Library.Install.installed.size > 0)
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
            if (!(widget.name == "FontManagerCollectionTree"))
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
                group.set_active_from_fonts(Main.instance.reject);
                sidebar.collection_model.collections.cache();
                Idle.add(() => {
                    disabled.update(Main.instance.database, Main.instance.reject);
                    return false;
                });
            }
            return;
        }

    }

}
