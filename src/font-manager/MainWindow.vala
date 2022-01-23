/* MainWindow.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

        [GtkChild] public unowned Gtk.Stack main_stack { get; }
        [GtkChild] public unowned Gtk.Stack content_stack { get; }
        [GtkChild] public unowned Gtk.Stack view_stack { get; }
        [GtkChild] public unowned Gtk.Box main_box { get; }
        [GtkChild] public unowned Gtk.Paned main_pane { get; }
        [GtkChild] public unowned Gtk.Paned content_pane { get; }

        [GtkChild] public unowned Browse browse { get; }
        [GtkChild] public unowned Compare compare { get; }
        [GtkChild] public unowned PreviewPane preview_pane { get; }
        [GtkChild] public unowned Preferences preference_pane { get; }
        [GtkChild] public unowned Sidebar sidebar { get; }
        [GtkChild] public unowned FontListPane fontlist_pane { get; }

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

        int w = -1;
        int h = -1;
        int x = -1;
        int y = -1;
        int sidebar_size = 30;
        int content_size = 40;
        bool is_tiled = false;
        bool is_fullscreen = false;
        bool is_horizontal = false;
        const int DEFAULT_WIDTH = 900;
        const int DEFAULT_HEIGHT = 600;

        Mode _mode;
        GLib.Settings? settings = null;

#if HAVE_WEBKIT
        [GtkChild] unowned Gtk.Overlay web_pane;
#endif /* HAVE_WEBKIT */

        public MainWindow () {
            Object(title: About.DISPLAY_NAME, icon_name: About.ICON);
            settings = get_default_application().settings;
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
            fontlist.bind_property("selected-fonts", compare, "selected-fonts", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
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

        void on_sidebar_selection_changed (Filter? filter) {
            if (filter != null && filter is Unsorted)
                update_unsorted_category();
            fontlist_pane.filter = filter;
            return;
        }

        void connect_signals () {

            window_state_event.connect(on_window_state_event);
            size_allocate.connect(on_size_allocate);

            sidebar.standard.selection_changed.connect(on_sidebar_selection_changed);

            sidebar.orthographies.orthography_selected.connect((o) => { preview_pane.orthography = o; });

            sidebar.standard.category_tree.changed.connect(() => { fontlist_pane.refilter(); });

            CollectionTree collection_tree = sidebar.standard.collection_tree;
            collection_tree.selection_changed.connect_after((s) => {
                bool removable = (s != null && fontlist_pane.model_filter.iter_n_children(null) > 0);
                fontlist_pane.controls.set_remove_sensitivity(removable);
            });

            fontlist_pane.controls.remove_selected.connect(() => {
                collection_tree.remove_fonts(fontlist.get_selected_families());
                collection_tree.queue_draw();
                fontlist_pane.refilter();
                bool removable = (fontlist_pane.model_filter.iter_n_children(null) > 0);
                fontlist_pane.controls.set_remove_sensitivity(removable);
            });

            sidebar.standard.collection_tree.changed.connect(() => {
                update_unsorted_category();
                fontlist_pane.refilter();
                fontlist.queue_draw();
                browse.treeview.queue_draw();
            });

            Gtk.drag_dest_set(fontlist_pane, Gtk.DestDefaults.ALL, DragTargets, Gdk.DragAction.COPY);
            fontlist.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK | Gdk.ModifierType.RELEASE_MASK, DragTargets, Gdk.DragAction.COPY);
            var collections_tree = sidebar.standard.collection_tree;
            /* Let GTK+ handle re-ordering */
            collections_tree.set_reorderable(true);

            Gtk.TreePath drag_start_path = null;

            fontlist.drag_data_received.connect(on_drag_data_received);
            fontlist_pane.drag_data_received.connect(on_drag_data_received);
            fontlist.drag_begin.connect((w, c) => {
                if (!fontlist.get_visible_range(out drag_start_path, null))
                    drag_start_path = null;
                /* When reorderable is set no other drag and drop is possible.
                 * Temporarily disable it and set the treeview up as a drag destination. */
                collections_tree.set_reorderable(false);
                collections_tree.enable_model_drag_dest(DragTargets, Gdk.DragAction.COPY);
                if (!sidebar.standard.collection_expander.expanded)
                    sidebar.standard.collection_expander.set_expanded(true);
                sidebar.standard.category_tree.sensitive = false;
            });
            fontlist.drag_end.connect((w, c) => {
                sidebar.standard.category_tree.sensitive = true;
                collections_tree.set_reorderable(true);
                Idle.add(() => {
                    if (drag_start_path != null)
                        fontlist.scroll_to_cell(drag_start_path, null, false, 0.0f, 0.0f);
                    return GLib.Source.REMOVE;
                });
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

            preview_pane.switch_page.connect((page, page_num) => {
                if (page_num == PreviewPanePage.CHARACTER_MAP)
                    sidebar.mode = "Orthographies";
                else
                    sidebar.mode = "Standard";
            });

            return;
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

        void update_unsorted_category () {
            var category_tree = sidebar.standard.category_tree;
            var collection_tree = sidebar.standard.collection_tree;
            return_if_fail(category_tree.model != null);
            var category_model = (CategoryModel) category_tree.model;
            var unsorted = (Unsorted) category_model.categories[CategoryIndex.UNSORTED];
            var collected = collection_tree.model.collections.get_full_contents();
            unsorted.update.begin(collected, (obj, res) => {
                unsorted.update.end(res);
                fontlist_pane.refilter();
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
                group.families.add_all(fontlist.get_selected_families());
                Reject? reject = get_default_application().reject;
                group.set_active_from_fonts(reject);
                sidebar.standard.collection_tree.model.collections.save();
                update_unsorted_category();
            }
            return;
        }

        /* Window state */

        int position_to_percentage (Gtk.Paned paned, bool horizontal = true) {
            double position = (double) paned.position;
            double area = horizontal ? (double) paned.get_allocated_width() :
                                       (double) paned.get_allocated_height();
            return (int) Math.round((position / area) * 100.0);
        }

        int percentage_to_position (Gtk.Paned paned, int percent, bool horizontal = true) {
            double area = horizontal ? (double) paned.get_allocated_width() :
                                       (double) paned.get_allocated_height();
            return (int) Math.round(((double) percent / 100.0) * area);
        }

        void set_layout_orientation (Gtk.Orientation orientation) {
            Gtk.Paned pane = content_pane;

#if HAVE_WEBKIT
                var google_fonts_pane = (GoogleFonts.Catalog) web_pane.get_child();
                if (google_fonts_pane.content_pane.get_mapped())
                    pane = google_fonts_pane.content_pane;
#endif /* HAVE_WEBKIT */

            is_horizontal = (orientation == Gtk.Orientation.HORIZONTAL);
            pane.set_orientation(orientation);
            Idle.add(() => {
                int position = percentage_to_position(pane, content_size, is_horizontal);
                pane.set_position(position);
                return GLib.Source.REMOVE;
            });
            return;
        }

        void update_layout_orientation () {
            if (settings == null)
                return;
            Gtk.Orientation orientation = Gtk.Orientation.VERTICAL;
            bool only_on_maximize = settings.get_boolean("wide-layout-on-maximize");
            if (wide_layout && only_on_maximize && is_maximized || wide_layout && !only_on_maximize)
                orientation = Gtk.Orientation.HORIZONTAL;
            set_layout_orientation(orientation);
            return;
        }

        void on_size_allocate (Gtk.Widget widget, Gtk.Allocation allocation) {
            if (is_maximized || is_tiled || is_fullscreen)
                return;
            get_size(out w, out h);
            get_position(out x, out y);
            return;
        }

        bool on_window_state_event (Gtk.Widget widget, Gdk.EventWindowState event) {

            if ((event.changed_mask & Gdk.WindowState.FULLSCREEN) != 0)
                is_fullscreen = (event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0;

            if ((event.changed_mask & Gdk.WindowState.TILED) != 0)
                is_tiled = (event.new_window_state & Gdk.WindowState.TILED) != 0;

            if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
                Idle.add(() => { update_layout_orientation(); return GLib.Source.REMOVE; });

            return Gdk.EVENT_PROPAGATE;
        }

        void bind_settings () {

            if (settings == null)
                return;

            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("sidebar-size", main_pane, "position", flags);
            settings.bind("content-pane-position", content_pane, "position", flags);
            settings.bind("selected-category", sidebar.standard.category_tree, "selected-iter", flags);
            settings.bind("selected-collection", sidebar.standard.collection_tree, "selected-iter", flags);
            settings.bind("selected-font", fontlist, "selected-iter", flags);
            settings.bind("wide-layout", this, "wide-layout", flags);
            settings.bind("use-csd", this, "use-csd", flags);

            mode_changed.connect((i) => {
                settings.set_enum("mode", (int) i);
            });

            settings.changed.connect((key) => {
                if (key == "wide-layout-on-maximize")
                    Idle.add(() => { update_layout_orientation(); return GLib.Source.REMOVE; });
            });

            notify["wide-layout"].connect(() => {
                Idle.add(() => { update_layout_orientation(); return GLib.Source.REMOVE; });
            });

            main_pane.notify["position"].connect((obj, pspec) => {
                int position = position_to_percentage(main_pane);
                if (position < 2 || position > 98)
                    return;
                sidebar_size = position;
            });

            content_pane.notify["position"].connect((obj, pspec) => {
                Gtk.Paned pane = content_pane;

#if HAVE_WEBKIT
                var google_fonts_pane = (GoogleFonts.Catalog) web_pane.get_child();
                if (google_fonts_pane.content_pane.get_mapped())
                    pane = google_fonts_pane.content_pane;
#endif /* HAVE_WEBKIT */

                int position = position_to_percentage(pane, is_horizontal);
                if (position < 2 || position > 98)
                    return;
                content_size = position;
            });

            return;
        }

        [GtkCallback]
        public bool on_delete_event (Gtk.Widget widget, Gdk.EventAny event) {
            hide();
            Idle.add(() => {
                if (settings != null) {
                    settings.delay();
                    var category_tree = sidebar.standard.category_tree;
                    var category_model = (CategoryModel) category_tree.model;
                    var language_filter = category_model.categories[CategoryIndex.LANGUAGE];
                    ((LanguageFilter) language_filter).save_state(settings);
                    compare.save_state(settings);

#if HAVE_WEBKIT
                    var google_fonts_pane = (GoogleFonts.Catalog) web_pane.get_child();
                    google_fonts_pane.preview_pane.save_state(settings);
#endif /* HAVE_WEBKIT */

                    settings.set("window-size", "(ii)", w, h);
                    settings.set("window-position", "(ii)", x, y);
                    settings.set_boolean("is-maximized", is_maximized);
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

            if (settings.get_boolean("is-maximized"))
                maximize();
            settings.get("window-size", "(ii)", out w, out h);
            settings.get("window-position", "(ii)", out x, out y);

            set_default_size(w, h);
            move(x, y);

            preview_pane.set_waterfall_size(settings.get_double("min-waterfall-size"),
                                            settings.get_double("max-waterfall-size"),
                                            settings.get_double("waterfall-size-ratio"));
            preview_pane.show_line_size = settings.get_boolean("waterfall-show-line-size");
            main_pane.position = settings.get_int("sidebar-size");
            content_pane.position = settings.get_int("content-pane-position");
            wide_layout = settings.get_boolean("wide-layout");
            is_horizontal = content_pane.orientation == Gtk.Orientation.HORIZONTAL;
            Idle.add(() => { update_layout_orientation(); return GLib.Source.REMOVE; });

            mode = (FontManager.Mode) settings.get_enum("mode");
            var action = get_default_application().lookup_action("mode") as SimpleAction;
            action.set_state(mode.to_string());
            var menu_button = titlebar.main_menu;
            if (menu_button.use_popover)
                menu_button.popover.hide();
            else
                menu_button.popup.hide();

            Idle.add(() => {
                preview_pane.restore_state(settings);
                browse.restore_state(settings);
                compare.restore_state(settings);

#if HAVE_WEBKIT
                var google_fonts_pane = (GoogleFonts.Catalog) web_pane.get_child();
                google_fonts_pane.preview_pane.restore_state(settings);
#endif /* HAVE_WEBKIT */

                return GLib.Source.REMOVE;
            });

            var font_path = settings.get_string("selected-font");
            var collection_path = settings.get_string("selected-collection");
            var category_path = settings.get_string("selected-category");

            Idle.add(() => {
                if (sidebar.standard.category_tree.update_in_progress)
                    return GLib.Source.CONTINUE;
                Idle.add(() => {
                    restore_selections(font_path, category_path, collection_path);
                    Idle.add(() => {
                        /* XXX : FIXME : Ensure our content pane position is correct.
                         * It fails to restore properly intermittently. */
                        update_layout_orientation();
                        main_stack.sensitive = true;
                        return GLib.Source.REMOVE;
                    });
                    return GLib.Source.REMOVE;
                });
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
                if (category_path != "-1") {
                    tree = sidebar.standard.category_tree;
                    path = category_path;
                } else if (collection_path != "-1") {
                    tree = sidebar.standard.collection_tree;
                    path = collection_path;
                    sidebar.standard.collection_expander.set_expanded(true);
                }
                /* Preload category contents */
                if (tree is CategoryTree && path.char_count() > 1)
                    restore_last_selected_treepath(tree, path.split_set(":")[0]);
                restore_last_selected_treepath(tree, path);
                Idle.add(() => {
                    fontlist_pane.refilter();
                    restore_last_selected_treepath(fontlist_pane.fontlist, font_path);
                    fontlist_pane.begin_selection_tracking();
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
            preview_pane.preview_mode = FontManager.FontPreviewMode.WATERFALL;
            main_pane.position = 275;
            content_pane.position = 200;
            preview_pane.preview_size = DEFAULT_PREVIEW_SIZE;
            browse.preview_size = DEFAULT_PREVIEW_SIZE * 1.2;
            compare.preview_size = DEFAULT_PREVIEW_SIZE * 1.2;
            preview_pane.character_map_preview_size = CHARACTER_MAP_PREVIEW_SIZE;
            preview_pane.page = 0;
            main_stack.sensitive = true;
            return;
        }

    }

}
