/* MainWindow.vala
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
        public bool use_csd { get; set; default = false; }

        public Gtk.Stack main_stack { get; private set; }
        public Gtk.Stack content_stack { get; private set; }
        public Gtk.Stack view_stack { get; private set; }
        public Gtk.Box main_box { get; private set; }
        public Gtk.Box content_box { get; private set; }
        public Gtk.Paned main_pane { get; private set; }
        public Gtk.Paned content_pane { get; private set; }

        public Browse browser { get; private set; }
        public Compare compare { get; private set; }
        public FontModel? model { get; set; default = null; }
        public FontPreviewPane preview_pane { get; private set; }
        public SideBar sidebar { get; private set; }
        public TitleBar titlebar { get; private set; }
        public FontList fontlist { get; private set; }
        public FontListPane fontpane { get; private set; }
        public Preferences preference_pane { get; private set; }

        public Mode mode {
            get {
                return _mode;
            }
            set {
                real_set_mode(value);
            }
        }

        bool sidebar_switch = false;
        bool charmap_visible = false;
        bool is_horizontal = false;
        Mode _mode;
        Gtk.Box content_view;
        Gtk.Box _main_pane_;
        Gtk.Paned lock_child_position;

        Disabled? disabled = null;
        Unsorted? unsorted = null;

        const int DEFAULT_WIDTH = 900;
        const int DEFAULT_HEIGHT = 600;

        public MainWindow () {
            Object(title: About.DISPLAY_NAME, icon_name: About.ICON);
            init_components();
            pack_components();
            bind_properties();
            connect_signals();
        }

        void zoom_in () {
            preview_pane.preview_size += 0.5;
            browser.preview_size += 0.5;
            compare.preview_size += 0.5;
            preview_pane.charmap.preview_size += 0.5;
            return;
        }

        void zoom_out () {
            preview_pane.preview_size -= 0.5;
            browser.preview_size -= 0.5;
            compare.preview_size -= 0.5;
            preview_pane.charmap.preview_size -= 0.5;
            return;
        }

        void reset_zoom () {
            preview_pane.preview_size = 10.0;
            browser.preview_size = 12.0;
            compare.preview_size = 12.0;
            preview_pane.charmap.preview_size = 18;
            return;
        }

        void init_components () {
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            content_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            main_pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            content_pane = new Gtk.Paned(wide_layout ? Gtk.Orientation.HORIZONTAL : Gtk.Orientation.VERTICAL);
            browser = new Browse();
            compare = new Compare();
            preview_pane = new FontPreviewPane();
            sidebar = new SideBar();
            titlebar = new TitleBar();
            fontlist = new FontList();
            fontpane = new FontListPane(fontlist);
            main_stack = new Gtk.Stack();
            main_stack.set_transition_duration(720);
            main_stack.set_transition_type(Gtk.StackTransitionType.UNDER_UP);
            view_stack = new Gtk.Stack();
            view_stack.add_titled(preview_pane, "Default", _("Preview"));
            view_stack.add_titled(compare, "Compare", _("Compare"));
            view_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            content_stack = new Gtk.Stack();
            content_stack.set_transition_duration(420);
            content_stack.add_titled(content_pane, "Default", _("Manage"));
            content_stack.add_titled(browser, "Browse", _("Browse"));
            content_stack.set_transition_type(Gtk.StackTransitionType.OVER_LEFT);
            preference_pane = construct_preference_pane();
            /* XXX : See https://github.com/FontManager/master/issues/50 */
            lock_child_position = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            /* Prevent Gtk warning due to missing size allocation */
            lock_child_position.set_size_request(1, -1);

            insert_action_group("default", new SimpleActionGroup());

            var action = new SimpleAction("zoom_in", null);
            action.activate.connect((a, v) => { zoom_in(); });
            string? [] accels = { "<Ctrl>plus", "<Ctrl>equal", null };
            add_keyboard_shortcut(this, action, "zoom_in", accels);

            action = new SimpleAction("zoom_out", null);
            action.activate.connect((a, v) => { zoom_out(); });
            accels = { "<Ctrl>minus", null };
            add_keyboard_shortcut(this, action, "zoom_out", accels);

            action = new SimpleAction("zoom_default", null);
            action.activate.connect((a, v) => { reset_zoom(); });
            accels = { "<Ctrl>0", null };
            add_keyboard_shortcut(this, action, "zoom_default", accels);

            action = new SimpleAction("reload", null);
            action.activate.connect((a, v) => {
                ((FontManager.Application) application).refresh();
            });
            accels = { "<Ctrl>r", "F5", null };
            add_keyboard_shortcut(this, action, "reload", accels);

            return;
        }

        void pack_components () {
            lock_child_position.add1(sidebar);
            main_pane.add1(lock_child_position);
            main_pane.add2(content_box);
            main_pane.set_position(275);
            content_box.pack_end(content_stack, true, true, 0);
            content_pane.add1(fontpane);
            content_view = new Gtk.Box(wide_layout ? Gtk.Orientation.HORIZONTAL : Gtk.Orientation.VERTICAL, 0);
            content_view.pack_end(view_stack, true, true, 0);
            content_pane.add2(content_view);
            _main_pane_ = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _main_pane_.pack_start(main_pane, true, true, 0);
            main_stack.add_named(_main_pane_, "Default");
            main_stack.add_named(preference_pane, "Preferences");
            main_box.pack_end(main_stack, true, true, 0);
            use_csd = settings.get_boolean("use-csd");
            if (Gdk.Screen.get_default().is_composited() && use_csd) {
                set_titlebar(titlebar);
            } else {
                main_box.pack_start(titlebar, false, true, 0);
                titlebar.use_toolbar_styling();
            }
            add(main_box);
            return;
        }

        void bind_properties () {
            bind_property("model", fontpane, "model", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("selected-font", preview_pane, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("selected-font", sidebar.orthographies, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("selected-font", compare, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("model", browser, "model", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("samples", browser, "samples", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("samples", compare, "samples", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("samples", preview_pane.preview, "samples", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            var ui_prefs = (UserInterfacePreferences) preference_pane.get_page("Interface");
            ui_prefs.wide_layout.toggle.bind_property("active", this, "wide-layout", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            return;
        }

        public void set_layout_orientation (Gtk.Orientation orientation) {
            if (settings != null) {
                if (is_horizontal)
                    settings.set_int("last-horizontal-content-pane-position", content_pane.position);
                else
                    settings.set_int("last-vertical-content-pane-position", content_pane.position);
                if (orientation == Gtk.Orientation.HORIZONTAL) {
                    Idle.add(() => {
                        content_pane.set_position(settings.get_int("last-horizontal-content-pane-position"));
                        return false;
                    });
                } else {
                    Idle.add(() => {
                        if (settings.get_boolean("wide-layout-on-maximize") && !is_maximized)
                            content_pane.set_position(settings.get_int("last-vertical-content-pane-position"));
                        return false;
                    });
                }
            }
            content_pane.set_orientation(orientation);
            content_view.set_orientation(orientation);
            is_horizontal = (orientation == Gtk.Orientation.HORIZONTAL);
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
            preview_pane.show();
            compare.show();
            lock_child_position.show();
            sidebar.show();
            titlebar.show();
            fontpane.show();
            preference_pane.show();
            main_stack.show();
            base.show();
            return;
        }

        void real_set_mode (Mode mode) {
            _mode = mode;
            titlebar.main_menu_label.set_markup("<b>%s</b>".printf(mode.to_translatable_string()));
            var settings = mode.settings();
            content_stack.set_visible_child_name(settings[0]);
            view_stack.set_visible_child_name(settings[1]);
            if (mode == Mode.MANAGE && charmap_visible)
                sidebar.mode = "Orthographies";
            else
                sidebar.mode = "Standard";
            titlebar.reveal_controls((mode == Mode.MANAGE));
            fontpane.show_controls = (mode != Mode.BROWSE);
            fontpane.controls.set_remove_sensitivity((mode == Mode.MANAGE && sidebar.standard.mode == StandardSideBarMode.COLLECTION));
            fontlist.queue_draw();
            if (titlebar.prefs_toggle.active && mode != Mode.MANAGE)
                titlebar.prefs_toggle.active = false;
            if (mode == Mode.BROWSE)
                browser.treeview.queue_draw();
            mode_changed(mode);
            return;
        }

        void connect_signals () {

            realize.connect(() => { on_realize(); });

            delete_event.connect((w, e) => {
                save_state();
                ((FontManager.Application) application).quit();
                return true;
            });

            notify["wide-layout"].connect(() => {
                Idle.add(() => {
                    if (settings != null) {
                        if (wide_layout && (!(settings.get_boolean("wide-layout-on-maximize")) || is_maximized)) {
                            set_layout_orientation(Gtk.Orientation.HORIZONTAL);
                        } else if (wide_layout && settings.get_boolean("wide-layout-on-maximize") && !(is_maximized)) {
                            if (is_horizontal) {
                                set_layout_orientation(Gtk.Orientation.VERTICAL);
                            }
                        } else {
                            set_layout_orientation(Gtk.Orientation.VERTICAL);
                        }
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
                                        set_layout_orientation(Gtk.Orientation.HORIZONTAL);
                                    } else {
                                        set_layout_orientation(Gtk.Orientation.VERTICAL);
                                    }
                                    return false;
                                });
                            }
                        } else {
                            Idle.add(() => {
                                set_layout_orientation(Gtk.Orientation.VERTICAL);
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
                                    set_layout_orientation(Gtk.Orientation.VERTICAL);
                                }
                            } else {
                                if (wide_layout)
                                    set_layout_orientation(Gtk.Orientation.HORIZONTAL);
                                else
                                    set_layout_orientation(Gtk.Orientation.VERTICAL);
                            }
                            return false;
                        });
                    }
                });
            }

            sidebar.standard.category_selected.connect((filter, index) => { fontpane.filter = filter; });
            sidebar.standard.collection_selected.connect((filter) => { fontpane.filter = filter; });
            sidebar.orthographies.orthography_selected.connect((o) => { preview_pane.charmap.set_filter(o); });

            sidebar.standard.category_selected.connect((c, i) => {
                if (c is Disabled && disabled == null) {
                    disabled = (c as Disabled);
                    disabled.update.begin(reject, (obj,res) => {
                        disabled.update.end(res);
                        fontpane.refilter();
                    });
                }
                if (c is Unsorted && unsorted == null) {
                    unsorted = (c as Unsorted);
                    var collected = sidebar.collection_model.collections.get_full_contents();
                    unsorted.update.begin(collected, (obj, res) => {
                        unsorted.update.end(res);
                        fontpane.refilter();
                    });
                }
            });

            sidebar.standard.mode_selected.connect((m) => {
                /* NOTE : This indicates a drag & drop operation is in progress. */
                if (sidebar_switch)
                    return;
                if (m == StandardSideBarMode.CATEGORY)
                    fontpane.filter = sidebar.standard.selected_category;
                else
                    fontpane.filter = sidebar.standard.selected_collection;
                bool sensitive = (mode == Mode.MANAGE && m == StandardSideBarMode.COLLECTION);
                fontpane.controls.set_remove_sensitivity(sensitive);
            });

            fontpane.controls.remove_selected.connect(() => {
                if (sidebar.standard.selected_collection == null)
                    return;
                sidebar.standard.collection_tree.remove_fonts(fontlist.get_selected_families().list());
                sidebar.standard.collection_tree.queue_draw();
            });

            sidebar.standard.collection_tree.changed.connect(() => {
                if (unsorted != null) {
                    Idle.add(() => {
                        var collected = sidebar.collection_model.collections.get_full_contents();
                        unsorted.update.begin(collected, (obj, res) => {
                            unsorted.update.end(res);
                        });
                        return false;
                    });
                }
                fontlist.queue_draw();
                browser.treeview.queue_draw();
            });

            Gtk.drag_dest_set(fontpane, Gtk.DestDefaults.ALL, AppDragTargets, AppDragActions);
            //fontlist.enable_model_drag_dest(AppDragTargets, AppDragActions);
            fontlist.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK | Gdk.ModifierType.RELEASE_MASK, AppDragTargets, AppDragActions);
            var collections_tree = sidebar.standard.collection_tree;
            /* Let GTK+ handle re-ordering */
            collections_tree.set_reorderable(true);

            fontlist.drag_data_received.connect(on_drag_data_received);
            fontpane.drag_data_received.connect(on_drag_data_received);
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
            });
            collections_tree.drag_data_received.connect(on_drag_data_received);

            titlebar.install_selected.connect(() => {
                install_fonts(FileSelector.get_selections((Gtk.Window) this));
            });

            titlebar.remove_selected.connect(() => {
                remove_fonts(RemoveDialog.get_selections((Gtk.Window) this, model));
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
                /* Fontlist.on_family_toggled adds any newly rejected files  */
                //load_user_font_resources(reject.get_rejected_files(), sources.list_objects());

                if (disabled == null)
                    return;

                disabled.update.begin(reject, (obj,res) => {
                    disabled.update.end(res);
                    if (sidebar.standard.selected_category.index == CategoryIndex.DISABLED)
                        fontpane.refilter();
                });

            });

            preview_pane.notebook.switch_page.connect((p, p_num) => {
                if (p is CharacterTable) {
                    charmap_visible = true;
                    sidebar.mode = "Orthographies";
                } else {
                    charmap_visible = false;
                    sidebar.mode = "Standard";
                }
            });

            sources.changed.connect(() => {
                Timeout.add_seconds(3, () => {
                    ((FontManager.Application) application).refresh();
                    return false;
                });
            });

        }

        void install_fonts (StringHashset selections) {
            if (selections.size > 0) {
                titlebar.installing_files = true;
                var installer = new Library.Installer();
                installer.process.begin(selections, (obj, res) => {
                    installer.process.end(res);
                    Timeout.add_seconds(3, () => {
                        ((FontManager.Application) application).refresh();
                        Timeout.add_seconds(3, () => {
                         titlebar.installing_files = false;
                         return false;
                        });
                        return false;
                    });
                });
            }
            return;
        }

        void remove_fonts (StringHashset selections) {
            if (selections.size > 0) {
                titlebar.removing_files = true;
                model = null;
                Library.remove.begin(selections, (obj, res) => {
                    Library.remove.end(res);
                    Idle.add(() => {
                        ((FontManager.Application) application).refresh();
                        Idle.add(() => {
                            titlebar.removing_files = false;
                            return false;
                        });
                        return false;
                    });
                });
            }
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
                    var selections = new StringHashset();
                    foreach (var uri in selection_data.get_uris())
                        selections.add(File.new_for_uri(uri).get_path());
                    install_fonts(selections);
                    break;
                default:
                    warning("Unsupported drag target.");
                    return;
            }
            return;
        }

        void family_drop_handler (Gtk.Widget widget, int x, int y) {
            if (widget.name != "CollectionTree")
                return;
            Gtk.TreePath path;
            var tree = widget as Gtk.TreeView;
            tree.get_path_at_pos(x, y, out path, null, null, null);
            /* Invalid drop, non-existent path */
            if (path == null)
                return;
            Gtk.TreeIter iter;
            var model = tree.get_model();
            /* Invalid drop, non-existent path */
            if (!model.get_iter(out iter, path))
                return;
            Value val;
            model.get_value(iter, CollectionColumn.OBJECT, out val);
            var group = (Collection) val.get_object();
            if (group != null) {
                group.families.add_all(fontlist.get_selected_families().list());
                group.set_active_from_fonts(reject);
                sidebar.collection_model.collections.save();
                if (unsorted != null) {
                    var collected = sidebar.collection_model.collections.get_full_contents();
                    unsorted.update.begin(collected, (obj, res) => {
                        unsorted.update.end(res);
                    });
                }
            }
            return;
        }

        /* Window state */

        public void save_state () {
            if (settings == null)
                return;
            settings.set_strv("compare-list", compare.list());
            settings.set_string("compare-foreground-color", compare.foreground_color.to_string());
            settings.set_string("compare-background-color", compare.background_color.to_string());
            settings.apply();
            return;
        }

        public void bind_settings () {

            if (settings == null)
                return;

            settings.delay();

            configure_event.connect((_w, /* Gdk.EventConfigure */ e) => {
                /* Size and position provided by event is invalid on Wayland */
                int w, h, x, y;
                get_size(out w, out h);
                get_position(out x, out y);
                settings.set("window-size", "(ii)", w, h);
                settings.set("window-position", "(ii)", x, y);
                return false;
            });

            mode_changed.connect((i) => {
                settings.set_enum("mode", (int) i);
            });

            sidebar.standard.mode_selected.connect(() => {
                settings.set_enum("sidebar-mode", (int) sidebar.standard.mode);
            });

            preview_pane.preview_mode_changed.connect((m) => { settings.set_string("preview-mode", ((FontManager.FontPreviewMode) m).to_string()); });
            preview_pane.preview_text_changed.connect((p) => {
                if (!preview_pane.preview.restore_default_preview && p != DEFAULT_PREVIEW_TEXT)
                    settings.set_string("preview-text", p);
            });

            settings.bind("sidebar-size", main_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("content-pane-position", content_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("preview-font-size", preview_pane, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("browse-font-size", browser, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("compare-font-size", compare, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("charmap-font-size", preview_pane.charmap, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("selected-category", sidebar.standard.category_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-collection", sidebar.standard.collection_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-font", fontlist, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("preview-page", preview_pane.notebook, "page", SettingsBindFlags.DEFAULT);
            settings.bind("wide-layout", this, "wide-layout", SettingsBindFlags.DEFAULT);
            settings.bind("use-csd", this, "use-csd", SettingsBindFlags.DEFAULT);
            return;
        }

        public void on_realize () {

            if (settings == null) {
                ensure_sane_defaults();
                return;
            }

            Gtk.Settings gtk = Gtk.Settings.get_default();
            gtk.gtk_application_prefer_dark_theme = settings.get_boolean("prefer-dark-theme");
            gtk.gtk_enable_animations = settings.get_boolean("enable-animations");

            int x, y, w, h;
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);
            wide_layout = settings.get_boolean("wide-layout");
            set_default_size(w, h);
            move(x, y);
            preview_pane.mode = FontManager.FontPreviewMode.parse(settings.get_string("preview-mode"));
            preview_pane.notebook.page = settings.get_int("preview-page");
            sidebar.standard.mode = (StandardSideBarMode) settings.get_enum("sidebar-mode");

            main_pane.position = settings.get_int("sidebar-size");
            content_pane.position = settings.get_int("content-pane-position");

            preview_pane.preview_size = settings.get_double("preview-font-size");
            preview_pane.charmap.preview_size = settings.get_double("charmap-font-size");
            browser.preview_size = settings.get_double("browse-font-size");
            /* Workaround first row height bug? in browse mode */
            browser.preview_size++;
            browser.preview_size--;
            compare.preview_size = settings.get_double("compare-font-size");

            var preview_text = settings.get_string("preview-text");
            if (preview_text != "DEFAULT")
                preview_pane.set_preview_text(preview_text);
            fontpane.controls.set_remove_sensitivity(sidebar.standard.mode == StandardSideBarMode.COLLECTION);

            mode = (FontManager.Mode) settings.get_enum("mode");
            var action = application.lookup_action("mode") as SimpleAction;
            action.set_state(mode.to_string());
            var menu_button = titlebar.main_menu;
            if (menu_button.use_popover)
                menu_button.popover.hide();
            else
                menu_button.popup.hide();

            Idle.add(() => {
                var foreground = Gdk.RGBA();
                var background = Gdk.RGBA();
                bool foreground_set = foreground.parse(settings.get_string("compare-foreground-color"));
                bool background_set = background.parse(settings.get_string("compare-background-color"));
                if (foreground_set)
                    ((Gtk.ColorChooser) compare.controls.fg_color_button).set_rgba(foreground);
                if (background_set)
                    ((Gtk.ColorChooser) compare.controls.bg_color_button).set_rgba(background);
                var checklist = ((FontManager.Application) application).available_font_families.list();
                foreach (var entry in settings.get_strv("compare-list"))
                    compare.add_from_string(entry, checklist);
                return false;
            });

            var font_path = settings.get_string("selected-font");
            var collection_path = settings.get_string("selected-collection");
            var category_path = settings.get_string("selected-category");

            Idle.add(() => {
                if (sidebar.standard.category_tree.update_in_progress)
                    return true;
                restore_selections(font_path, category_path, collection_path);
                return false;
            });

            bind_settings();

            return;
        }

        public void restore_selections (string font_path,
                                        string category_path,
                                        string collection_path) {
            return_if_fail(settings != null);
            Idle.add(() => {
                BaseTreeView? tree = null;
                string? path = null;
                if (sidebar.standard.mode == StandardSideBarMode.CATEGORY) {
                    restore_last_selected_treepath(sidebar.standard.collection_tree, collection_path);
                    tree = sidebar.standard.category_tree.tree;
                    path = category_path;
                } else if (sidebar.standard.mode == StandardSideBarMode.COLLECTION) {
                    restore_last_selected_treepath(sidebar.standard.category_tree.tree, category_path);
                    tree = sidebar.standard.collection_tree;
                    path = collection_path;
                }
                restore_last_selected_treepath(tree, path);
                Idle.add(() => {
                    restore_last_selected_treepath(fontpane.fontlist, font_path);
                    return false;
                });
                return false;
            });

            return;
        }

        /* XXX : These should match the schema */
        void ensure_sane_defaults () {
            set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT);
            mode = FontManager.Mode.MANAGE;
            sidebar.standard.mode = StandardSideBarMode.CATEGORY;
            preview_pane.mode = FontManager.FontPreviewMode.WATERFALL;
            main_pane.position = 275;
            content_pane.position = 200;
            preview_pane.preview_size = 10.0;
            browser.preview_size = 12.0;
            compare.preview_size = 12.0;
            preview_pane.charmap.preview_size = 18;
            preview_pane.notebook.page = 0;
            fontpane.controls.set_remove_sensitivity(sidebar.standard.mode == StandardSideBarMode.COLLECTION);
            return;
        }

        Gtk.TreePath? restore_last_selected_treepath (Gtk.TreeView? tree, string? path) {
            return_val_if_fail(tree != null && tree.model != null && path != null, null);
            Gtk.TreeIter? iter = null;
            if (!tree.model.get_iter_first(out iter))
                return null;
            var selection = tree.get_selection();
            var treepath = new Gtk.TreePath.from_string(path);
            selection.unselect_all();
            tree.expand_to_path(treepath);
            selection.select_path(treepath);
            tree.scroll_to_cell(treepath, null, true, 0.25f, 0.25f);
            return treepath;
        }


    }

}
