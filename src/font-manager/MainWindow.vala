/* MainWindow.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-main-window.ui")]
    public class MainWindow : Gtk.ApplicationWindow {

        public signal void mode_changed (int new_mode);

        public bool wide_layout { get; set; default = false; }
        public bool use_csd { get; set; default = true; }

        [GtkChild] public Gtk.Stack main_stack { get; }
        [GtkChild] public Gtk.Stack content_stack { get; }
        [GtkChild] public Gtk.Stack view_stack { get; }
        [GtkChild] public Gtk.Box main_box { get; }
        [GtkChild] public Gtk.Paned main_pane { get; }
        [GtkChild] public Gtk.Paned content_pane { get; }

        [GtkChild] public Browse browse { get; }
        [GtkChild] public Compare compare { get; }
        [GtkChild] public PreviewPane preview_pane { get; }
        [GtkChild] public Preferences preference_pane { get; }
        [GtkChild] public Sidebar sidebar { get; private set; }
        [GtkChild] public FontListPane fontlist_pane { get; private set; }

        public FontModel? model { get; set; default = null; }
        public TitleBar titlebar { get; private set; }

        public FontList fontlist { get { return ((FontList) fontlist_pane.fontlist); } }

        public Mode mode {
            get {
                return _mode;
            }
            set {
                real_set_mode(value);
            }
        }

        private bool charmap_visible {
            get {
                int current_page = preview_pane.get_current_page();
                return current_page == PreviewPanePage.CHARACTER_MAP;
            }
        }

        bool sidebar_switch = false;
        bool is_horizontal = false;
        const int DEFAULT_WIDTH = 900;
        const int DEFAULT_HEIGHT = 600;

        Mode _mode;
        Disabled? disabled = null;
        Unsorted? unsorted = null;
        LanguageFilter? language_filter = null;

#if HAVE_WEBKIT
        [GtkChild] Gtk.Overlay web_pane;
#endif /* HAVE_WEBKIT */

        public MainWindow () {
            Object(title: About.DISPLAY_NAME, icon_name: About.ICON);
            initialize_preference_pane(preference_pane);

#if HAVE_WEBKIT
            web_pane.add(new GoogleFonts.Catalog());
#endif /* HAVE_WEBKIT */

            var user_action_list = ((UserActionList) preference_pane["UserActions"]);
            var user_sources_list = ((UserSourceList) preference_pane["Sources"]);
            fontlist.user_actions = user_action_list.model;
            fontlist.user_sources = user_sources_list.model;
            add_actions();
            if (settings != null)
                use_csd = settings.get_boolean("use-csd");
            if (Gdk.Screen.get_default().is_composited() && use_csd) {
                titlebar = new ClientSideDecorations();
                set_titlebar(titlebar);
            } else {
                titlebar = new ServerSideDecorations();
                main_box.pack_start(titlebar, false, true, 0);
                add_separator(main_box, Gtk.Orientation.HORIZONTAL);
            }
            main_stack.set_visible_child_name("Default");
            main_stack.sensitive = false;
            titlebar.show();
            bind_properties();
            connect_signals();
        }

        void zoom (bool zoom_in, bool zoom_out) {
            var page = (PreviewPanePage) preview_pane.get_current_page();
            if (zoom_in) {
                if (page == PreviewPanePage.CHARACTER_MAP)
                    preview_pane.character_map_preview_size += 0.5;
                else
                    preview_pane.preview_size += 0.5;
            } else if (zoom_out) {
                if (page == PreviewPanePage.CHARACTER_MAP)
                    preview_pane.character_map_preview_size -= 0.5;
                else
                    preview_pane.preview_size -= 0.5;
            } else {
                if (page == PreviewPanePage.CHARACTER_MAP)
                    preview_pane.character_map_preview_size = CHARACTER_MAP_PREVIEW_SIZE;
                else
                    preview_pane.preview_size = DEFAULT_PREVIEW_SIZE;
            }
            return;
        }

        void add_actions () {
            var action = new SimpleAction("zoom_in", null);
            action.activate.connect((a, v) => { zoom(true, false); });
            string? [] accels = { "<Ctrl>plus", "<Ctrl>equal", null };
            add_keyboard_shortcut(action, "zoom_in", accels);
            action = new SimpleAction("zoom_out", null);
            action.activate.connect((a, v) => { zoom(false, true); });
            accels = { "<Ctrl>minus", null };
            add_keyboard_shortcut(action, "zoom_out", accels);
            action = new SimpleAction("zoom_default", null);
            action.activate.connect((a, v) => { zoom(false, false); });
            accels = { "<Ctrl>0", null };
            add_keyboard_shortcut(action, "zoom_default", accels);
            action = new SimpleAction("reload", null);
            action.activate.connect((a, v) => {
                get_default_application().refresh();
            });
            accels = { "<Ctrl>r", "F5", null };
            add_keyboard_shortcut(action, "reload", accels);
            return;
        }

        void bind_properties () {
            bind_property("model", fontlist_pane, "model", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("selected-font", preview_pane, "font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("selected-font", sidebar.orthographies, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("selected-font", compare, "selected-font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("model", browse, "model", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("samples", browse, "samples", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("samples", compare, "samples", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            fontlist.bind_property("samples", preview_pane, "samples", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            var ui_prefs = (UserInterfacePreferences) preference_pane["Interface"];
            ui_prefs.wide_layout.toggle.bind_property("active", this, "wide-layout", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            main_pane.bind_property("position", preference_pane, "position", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

#if HAVE_WEBKIT
            var google_fonts_pane = (GoogleFonts.Catalog) web_pane.get_child();
            main_pane.bind_property("position", google_fonts_pane, "position", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            content_pane.bind_property("position", google_fonts_pane.content_pane, "position", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            content_pane.bind_property("orientation", google_fonts_pane.content_pane, "orientation", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
#endif /* HAVE_WEBKIT */

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
                        return GLib.Source.REMOVE;
                    });
                } else {
                    Idle.add(() => {
                        if (settings.get_boolean("wide-layout-on-maximize") && !is_maximized)
                            content_pane.set_position(settings.get_int("last-vertical-content-pane-position"));
                        return GLib.Source.REMOVE;
                    });
                }
            }
            content_pane.set_orientation(orientation);
            is_horizontal = (orientation == Gtk.Orientation.HORIZONTAL);
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
            fontlist_pane.show_controls = (mode != Mode.BROWSE);
            fontlist_pane.controls.set_remove_sensitivity((mode == Mode.MANAGE && sidebar.standard.mode == StandardSidebarMode.COLLECTION));
            fontlist.queue_draw();
            if (titlebar.prefs_toggle.active && mode != Mode.MANAGE)
                titlebar.prefs_toggle.active = false;

#if HAVE_WEBKIT
            if (titlebar.web_toggle.active && mode != Mode.MANAGE)
                titlebar.web_toggle.active = false;
#endif /* HAVE_WEBKIT */

            if (mode == Mode.BROWSE && browse.mode == BrowseMode.LIST)
                browse.treeview.queue_draw();
            mode_changed(mode);
            return;
        }

        void connect_signals () {

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
                    return GLib.Source.REMOVE;
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
                                    return GLib.Source.REMOVE;
                                });
                            }
                        } else {
                            Idle.add(() => {
                                set_layout_orientation(Gtk.Orientation.VERTICAL);
                                return GLib.Source.REMOVE;
                            });
                        }
                    }
                    return GLib.Source.REMOVE;
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
                            return GLib.Source.REMOVE;
                        });
                    }
                });
            }

            sidebar.standard.category_selected.connect((filter, index) => { fontlist_pane.filter = filter; });
            sidebar.standard.collection_selected.connect((filter) => { fontlist_pane.filter = filter; });
            sidebar.orthographies.orthography_selected.connect((o) => { preview_pane.orthography = o; });

            sidebar.standard.category_selected.connect((c, i) => {
                if (disabled == null && c is Disabled || c is Disabled && disabled != c) {
                    disabled = (c as Disabled);
                    disabled.update.begin(reject, (obj,res) => {
                        disabled.update.end(res);
                        fontlist_pane.refilter();
                    });
                }
                if (unsorted == null && c is Unsorted || c is Unsorted && unsorted != c) {
                    unsorted = (c as Unsorted);
                    var collected = sidebar.collection_model.collections.get_full_contents();
                    unsorted.update.begin(collected, (obj, res) => {
                        unsorted.update.end(res);
                        fontlist_pane.refilter();
                    });
                }
                if (language_filter == null && c is LanguageFilter || c is LanguageFilter && language_filter != c) {
                    language_filter = (c as LanguageFilter);
                    language_filter.selections_changed.connect(() => {
                        fontlist_pane.refilter();
                    });
                }
            });

            sidebar.standard.mode_selected.connect((m) => {
                /* NOTE : This indicates a drag & drop operation is in progress. */
                if (sidebar_switch)
                    return;
                if (m == StandardSidebarMode.CATEGORY)
                    fontlist_pane.filter = sidebar.standard.selected_category;
                else
                    fontlist_pane.filter = sidebar.standard.selected_collection;
                bool sensitive = (mode == Mode.MANAGE && m == StandardSidebarMode.COLLECTION);
                fontlist_pane.controls.set_remove_sensitivity(sensitive);
            });

            fontlist_pane.controls.remove_selected.connect(() => {
                if (sidebar.standard.selected_collection == null)
                    return;
                sidebar.standard.collection_tree.remove_fonts(fontlist.get_selected_families().list());
                sidebar.standard.collection_tree.queue_draw();
                fontlist_pane.refilter();
            });

            sidebar.standard.collection_tree.changed.connect(() => {
                if (unsorted != null) {
                    Idle.add(() => {
                        var collected = sidebar.collection_model.collections.get_full_contents();
                        unsorted.update.begin(collected, (obj, res) => {
                            unsorted.update.end(res);
                        });
                        return GLib.Source.REMOVE;
                    });
                }
                fontlist_pane.refilter();
                fontlist.queue_draw();
                browse.treeview.queue_draw();
            });

            Gtk.drag_dest_set(fontlist_pane, Gtk.DestDefaults.ALL, DragTargets, Gdk.DragAction.COPY);
            //fontlist.enable_model_drag_dest(AppDragTargets, AppDragActions);
            fontlist.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK | Gdk.ModifierType.RELEASE_MASK, DragTargets, Gdk.DragAction.COPY);
            var collections_tree = sidebar.standard.collection_tree;
            /* Let GTK+ handle re-ordering */
            collections_tree.set_reorderable(true);

            fontlist.drag_data_received.connect(on_drag_data_received);
            fontlist_pane.drag_data_received.connect(on_drag_data_received);
            fontlist.drag_begin.connect((w, c) => {
                /* When reorderable is set no other drag and drop is possible.
                 * Temporarily disable it and set the treeview up as a drag destination.
                 */
                collections_tree.set_reorderable(false);
                collections_tree.enable_model_drag_dest(DragTargets, Gdk.DragAction.COPY);
                if (sidebar.standard.mode == StandardSidebarMode.CATEGORY) {
                    sidebar_switch = true;
                    sidebar.standard.mode = StandardSidebarMode.COLLECTION;
                }
            });
            fontlist.drag_end.connect((w, c) => {
                if (sidebar_switch) {
                    Idle.add(() => {
                        sidebar.standard.mode = StandardSidebarMode.CATEGORY;
                        return GLib.Source.REMOVE;
                    });
                    sidebar_switch = false;
                }
                collections_tree.set_reorderable(true);
            });
            collections_tree.drag_data_received.connect(on_drag_data_received);

            titlebar.install_selected.connect(() => {
                install_fonts(FileSelector.get_selections());
            });

            titlebar.remove_selected.connect(() => {
                remove_fonts(RemoveDialog.get_selections(model));
            });

            titlebar.preferences_selected.connect((a) => {

#if HAVE_WEBKIT
                if (a && titlebar.web_toggle.active)
                    titlebar.web_toggle.active = false;
#endif /* HAVE_WEBKIT */

                if (a)
                    main_stack.set_visible_child_name("Preferences");
                else
                    main_stack.set_visible_child_name("Default");
            });

#if HAVE_WEBKIT

            titlebar.web_selected.connect((a) => {
                if (a && titlebar.prefs_toggle.active)
                    titlebar.prefs_toggle.active = false;
                if (a)
                    main_stack.set_visible_child_name("Google Fonts");
                else
                    main_stack.set_visible_child_name("Default");
            });

#endif /* HAVE_WEBKIT */

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
                        fontlist_pane.refilter();
                });

            });

            preview_pane.switch_page.connect((page, page_num) => {
                if (page_num == PreviewPanePage.CHARACTER_MAP)
                    sidebar.mode = "Orthographies";
                else
                    sidebar.mode = "Standard";
            });

        }

        public void install_fonts (StringSet selections) {
            if (selections.size > 0) {
                titlebar.installing_files = true;
                var installer = new Library.Installer();
                installer.process.begin(selections, (obj, res) => {
                    installer.process.end(res);
                    Timeout.add_seconds(3, () => {
                        get_default_application().refresh();
                        Timeout.add_seconds(3, () => {
                             titlebar.installing_files = false;
                             fontlist_pane.refilter();
                             return GLib.Source.REMOVE;
                        });
                        return GLib.Source.REMOVE;
                    });
                });
            }
            return;
        }

        public void remove_fonts (StringSet selections) {
            if (selections.size > 0) {
                titlebar.removing_files = true;
                model = null;
                Library.remove.begin(selections, (obj, res) => {
                    Library.remove.end(res);
                    Idle.add(() => {
                        get_default_application().refresh();
                        Idle.add(() => {
                            titlebar.removing_files = false;
                            fontlist_pane.refilter();
                            return GLib.Source.REMOVE;
                        });
                        return GLib.Source.REMOVE;
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
                    var selections = new StringSet();
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
            if (widget.name != "FontManagerCollectionTree")
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

        void bind_settings () {

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

            browse.mode_selected.connect((m) => {
                settings.set_enum("browse-mode", (int) m);
            });

            settings.bind("preview-text", preview_pane, "preview-text", SettingsBindFlags.DEFAULT);
            settings.bind("preview-mode", preview_pane, "preview-mode", SettingsBindFlags.DEFAULT);
            settings.bind("sidebar-size", main_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("content-pane-position", content_pane, "position", SettingsBindFlags.DEFAULT);
            settings.bind("preview-font-size", preview_pane, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("browse-font-size", browse, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("browse-preview-text", browse.entry, "text", SettingsBindFlags.DEFAULT);
            settings.bind("compare-font-size", compare, "preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("compare-preview-text", compare.entry, "text", SettingsBindFlags.DEFAULT);
            settings.bind("charmap-font-size", preview_pane, "character-map-preview-size", SettingsBindFlags.DEFAULT);
            settings.bind("selected-category", sidebar.standard.category_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-collection", sidebar.standard.collection_tree, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("selected-font", fontlist, "selected-iter", SettingsBindFlags.DEFAULT);
            settings.bind("preview-page", preview_pane, "page", SettingsBindFlags.DEFAULT);
            settings.bind("wide-layout", this, "wide-layout", SettingsBindFlags.DEFAULT);
            settings.bind("use-csd", this, "use-csd", SettingsBindFlags.DEFAULT);
            return;
        }

        [GtkCallback]
        public bool on_delete_event (Gtk.Widget widget, Gdk.EventAny event) {
            hide();
            Idle.add(() => {
                if (settings != null) {
                    settings.set_strv("compare-list", compare.list_items());
                    var language_filter = sidebar.standard.category_tree.language_filter;
                    if (language_filter != null)
                        settings.set_strv("language-filter-list", language_filter.list());
                    settings.set_string("compare-foreground-color", compare.foreground_color.to_string());
                    settings.set_string("compare-background-color", compare.background_color.to_string());
                    settings.apply();
                }
                get_default_application().quit();
                return GLib.Source.REMOVE;
            });
            return true;
        }

        [GtkCallback]
        public void on_realize (Gtk.Widget widget) {

            if (settings == null) {
                ensure_sane_defaults();
                return;
            }

            Gtk.Settings gtk = Gtk.Settings.get_default();
            gtk.gtk_application_prefer_dark_theme = settings.get_boolean("prefer-dark-theme");
            gtk.gtk_enable_animations = settings.get_boolean("enable-animations");
            gtk.gtk_dialogs_use_header = settings.get_boolean("use-csd");

            int x, y, w, h;
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);
            wide_layout = settings.get_boolean("wide-layout");
            set_default_size(w, h);
            move(x, y);
            sidebar.standard.mode = (StandardSidebarMode) settings.get_enum("sidebar-mode");
            preview_pane.preview_mode = (FontPreviewMode) settings.get_enum("preview-mode");
            preview_pane.page = settings.get_int("preview-page");

            main_pane.position = settings.get_int("sidebar-size");
            content_pane.position = settings.get_int("content-pane-position");

            preview_pane.preview_size = settings.get_double("preview-font-size");
            preview_pane.character_map_preview_size = settings.get_double("charmap-font-size");
            browse.preview_size = settings.get_double("browse-font-size");
            /* Workaround first row height bug? in browse mode */
            browse.preview_size++;
            browse.preview_size--;
            browse.entry.text = settings.get_string("browse-preview-text");
            compare.preview_size = settings.get_double("compare-font-size");
            compare.entry.text = settings.get_string("compare-preview-text");

            preview_pane.preview_text = settings.get_string("preview-text");
            fontlist_pane.controls.set_remove_sensitivity(sidebar.standard.mode == StandardSidebarMode.COLLECTION);

            mode = (FontManager.Mode) settings.get_enum("mode");
            var action = application.lookup_action("mode") as SimpleAction;
            action.set_state(mode.to_string());
            var menu_button = titlebar.main_menu;
            if (menu_button.use_popover)
                menu_button.popover.hide();
            else
                menu_button.popup.hide();

            Idle.add(() => {
                if (compare.samples == null)
                    return GLib.Source.CONTINUE;
                compare.add_from_string_array(settings.get_strv("compare-list"));
                return GLib.Source.REMOVE;
            });

            Idle.add(() => {
                var foreground = Gdk.RGBA();
                var background = Gdk.RGBA();
                bool foreground_set = foreground.parse(settings.get_string("compare-foreground-color"));
                bool background_set = background.parse(settings.get_string("compare-background-color"));
                if (foreground_set) {
                    if (foreground.alpha == 0.0)
                        foreground.alpha = 1.0;
                    ((Gtk.ColorChooser) compare.fg_color_button).set_rgba(foreground);
                }
                if (background_set) {
                    if (background.alpha == 0.0)
                        background.alpha = 1.0;
                    ((Gtk.ColorChooser) compare.bg_color_button).set_rgba(background);
                }
                return GLib.Source.REMOVE;
            });

            var font_path = settings.get_string("selected-font");
            var collection_path = settings.get_string("selected-collection");
            var category_path = settings.get_string("selected-category");

            Idle.add(() => {
                if (sidebar.standard.category_tree.update_in_progress)
                    return GLib.Source.CONTINUE;
                browse.mode = (BrowseMode) settings.get_enum("browse-mode");
                restore_selections(font_path, category_path, collection_path);
                Idle.add(() => { main_stack.sensitive = true; return GLib.Source.REMOVE; });
                return GLib.Source.REMOVE;
            });

            Idle.add(() => {
                bind_settings();
                return GLib.Source.REMOVE;
            });

            return;
        }

        public void restore_selections (string font_path,
                                        string category_path,
                                        string collection_path) {
            return_if_fail(settings != null);
            Idle.add(() => {
                BaseTreeView? tree = null;
                string? path = null;
                if (sidebar.standard.mode == StandardSidebarMode.CATEGORY) {
                    restore_last_selected_treepath(sidebar.standard.collection_tree, collection_path);
                    tree = sidebar.standard.category_tree.tree;
                    path = category_path;
                    /* Preload category contents */
                    if (path.char_count() > 1)
                        restore_last_selected_treepath(tree, path.split_set(":")[0]);
                } else if (sidebar.standard.mode == StandardSidebarMode.COLLECTION) {
                    restore_last_selected_treepath(sidebar.standard.category_tree.tree, category_path);
                    tree = sidebar.standard.collection_tree;
                    path = collection_path;
                }
                restore_last_selected_treepath(tree, path);
                Idle.add(() => {
                    if (path.char_count() > 1)
                        fontlist_pane.refilter();
                    restore_last_selected_treepath(fontlist_pane.fontlist, font_path);
                    return GLib.Source.REMOVE;
                });
                return GLib.Source.REMOVE;
            });

            return;
        }

        /* XXX : These should match the schema */
        void ensure_sane_defaults () {
            set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT);
            mode = FontManager.Mode.MANAGE;
            sidebar.standard.mode = StandardSidebarMode.CATEGORY;
            preview_pane.preview_mode = FontManager.FontPreviewMode.WATERFALL;
            main_pane.position = 275;
            content_pane.position = 200;
            preview_pane.preview_size = DEFAULT_PREVIEW_SIZE;
            browse.preview_size = DEFAULT_PREVIEW_SIZE * 1.2;
            compare.preview_size = DEFAULT_PREVIEW_SIZE * 1.2;
            preview_pane.character_map_preview_size = CHARACTER_MAP_PREVIEW_SIZE;
            preview_pane.page = 0;
            fontlist_pane.controls.set_remove_sensitivity(sidebar.standard.mode == StandardSidebarMode.COLLECTION);
            main_stack.sensitive = true;
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
            if (treepath.get_depth() > 1)
                tree.expand_to_path(treepath);
            selection.select_path(treepath);
            tree.scroll_to_cell(treepath, null, true, 0.25f, 0.25f);
            return treepath;
        }

    }

}
