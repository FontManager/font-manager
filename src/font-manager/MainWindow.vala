/* MainWindow.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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
#if HAVE_WEBKIT
        GOOGLE_FONTS,
#endif /* HAVE_WEBKIT */
        N_MODES;

        public static Mode parse (string mode) {
            switch (mode.down()) {
                case "browse":
                case "1":
                    return Mode.BROWSE;
                case "compare":
                case "2":
                    return Mode.COMPARE;
#if HAVE_WEBKIT
                case "googlefonts":
                case "3":
                    return Mode.GOOGLE_FONTS;
#endif /* HAVE_WEBKIT */
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
#if HAVE_WEBKIT
                case GOOGLE_FONTS:
                    return "GoogleFonts";
#endif /* HAVE_WEBKIT */
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
#if HAVE_WEBKIT
                case GOOGLE_FONTS:
                    return _("Google Fonts");
#endif /* HAVE_WEBKIT */
                default:
                    return _("Manage");
            }
        }

    }

    public class MainWindow : ApplicationWindow {

        public bool show_preferences { get; set; default = false; }

        public Gtk.ProgressBar progress { get; private set; }

        public Mode mode {
            get {
                return _mode;
            }
            set {
                _mode = value;
                notify_property("mode");
            }
        }

        public CategoryListModel category_model {
            get {
                return main_pane.category_model;
            }
        }

        public CollectionListModel collection_model {
            get {
                return main_pane.collection_model;
            }
        }

        public Json.Array? available_fonts { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }

        Gtk.Stack main_stack;
        MainPane main_pane;
        public BrowsePane browse_pane { get; set; default = null; }
        PreferencePane prefs_pane;
        HeaderBarWidgets header_widgets;

        Mode _mode = Mode.MANAGE;

#if HAVE_WEBKIT
        GoogleFonts.Catalog google_fonts;
#endif /* HAVE_WEBKIT */

        static construct {
            install_action("install", null, (Gtk.WidgetActionActivateFunc) install);
            install_action("remove", null, (Gtk.WidgetActionActivateFunc) remove);
            install_action("import", null, (Gtk.WidgetActionActivateFunc) import);
            install_action("export", null, (Gtk.WidgetActionActivateFunc) export);
            install_action("reload", null, (Gtk.WidgetActionActivateFunc) reload);
            install_property_action("mode", "mode");
            install_property_action("show-preferences", "show-preferences");
            uint [] mode_accels = { Gdk.Key.@1, Gdk.Key.@2, Gdk.Key.@3, Gdk.Key.@4 };
            Gdk.ModifierType mode_mask = Gdk.ModifierType.CONTROL_MASK;
            EnumClass mode_class = ((EnumClass) typeof(Mode).class_ref());
            for (int i = 0; i < Mode.N_MODES; i++) {
                string nick = mode_class.get_value(i).value_nick;
                add_binding_action(mode_accels[i], mode_mask, "mode", "s", nick);
            }
            add_binding_action(Gdk.Key.R, mode_mask, "reload", null);
        }

        public MainWindow (GLib.Settings? settings) {
            Object(settings: settings);
            var overlay = new Gtk.Overlay();
            progress = new Gtk.ProgressBar() {
                halign = Gtk.Align.FILL,
                valign = Gtk.Align.START,
                hexpand = true,
                vexpand = false
            };
            progress.add_css_class("osd");
            main_stack = new Gtk.Stack();
            overlay.set_child(main_stack);
            overlay.add_overlay(progress);
            set_child(overlay);
            var header = new Gtk.HeaderBar();
            header_widgets = new HeaderBarWidgets(settings);
            header.pack_start(header_widgets.back_button);
            header.pack_start(header_widgets.main_menu);
            header.pack_start(header_widgets.revealer);
            header.pack_end(header_widgets.app_menu);
            set_titlebar(header);
            main_stack.set_transition_type(Gtk.StackTransitionType.OVER_DOWN_UP);
            main_stack.set_transition_duration(500);
            main_pane = new MainPane(settings);
            browse_pane = new BrowsePane(settings);
            prefs_pane = new PreferencePane(settings);
            // TODO : Figure out why this happens. If it happens because we are loading widgets
            // on demand using map events, so be it. If not then what are we doing to cause it?
            // This empty stack page is a hack to force an "expose" event when mode is set.
            // Otherwise we end up with panes set to position 0 when run from launcher but panes
            // with their position set correctly when run from the command line or vice versa.
            string symbolic_icon = "com.github.FontManager.FontManager-symbolic";
            var blank = new PlaceHolder(null, null, null, symbolic_icon) { hexpand = true, vexpand = true };
            main_stack.add_named(blank, "Blank");
            main_stack.add_named(main_pane, Mode.MANAGE.to_string());
            main_stack.add_named(browse_pane, Mode.BROWSE.to_string());
#if HAVE_WEBKIT
            google_fonts = new GoogleFonts.Catalog(settings);
            main_stack.add_named(google_fonts, "GoogleFonts");
#endif /* HAVE_WEBKIT */
            main_stack.add_named(prefs_pane, "Preferences");
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("mode", main_pane, "mode", flags);
            bind_property("available-fonts", main_pane, "available-fonts", flags);
            bind_property("disabled-families", main_pane, "disabled-families", flags);
            bind_property("available-fonts", browse_pane, "available-fonts", flags);
            bind_property("disabled-families", browse_pane, "disabled-families", flags);
            prefs_pane.bind_property("user-actions", main_pane, "user-actions", flags);
            prefs_pane.bind_property("user-sources", main_pane, "user-sources", flags);
            main_pane.bind_property("sidebar-position", prefs_pane, "sidebar-position", flags);
#if HAVE_WEBKIT
            main_pane.bind_property("content-position", google_fonts, "content-position", flags);
            main_pane.bind_property("sidebar-position", google_fonts, "sidebar-position", flags);
#endif /* HAVE_WEBKIT */
            bind_settings();
            connect_signals();
            restore_state();
            update_layout_orientation();
            map.connect_after(() => {
                if (settings != null)
                    Idle.add(() => { mode = (Mode) settings.get_enum("mode"); return GLib.Source.REMOVE; });
                else
                    Idle.add(() => { mode = Mode.BROWSE; return GLib.Source.REMOVE; });
            });
        }

        public void search (string needle) {
            main_pane.search(needle);
            return;
        }

        public bool progress_update (ProgressData data) {
            progress.set_fraction(data.progress);
            return GLib.Source.REMOVE;
        }

        public void select_first_category () {
            main_pane.select_first_category();
            return;
        }

        public void select_first_font () {
            main_pane.select_first_font();
            return;
        }

        void bind_settings () {
            if (settings == null)
                return;
            settings.changed.connect((key) => {
                if (key.contains("wide-layout"))
                    Idle.add(() => { update_layout_orientation(); return GLib.Source.REMOVE; });
            });
            settings.bind("mode", this, "mode", SettingsBindFlags.DEFAULT);
            return;
        }

        void connect_signals () {
            notify["mode"].connect(on_mode_changed);
            notify["show-preferences"].connect(on_stack_page_changed);
            notify["maximized"].connect(() => { update_layout_orientation(); });
            return;
        }

        StringSet get_file_selections (Object? object, AsyncResult result) {
            var selections = new StringSet();
            return_val_if_fail(object != null, selections);
            try {
                var dialog = (Gtk.FileDialog) object;
                ListModel files = dialog.open_multiple.end(result);
                for (uint i = 0; i < files.get_n_items(); i++) {
                    var file = (File) files.get_item(i);
                    selections.add(file.get_path());
                }
            } catch (Error e) {
                if (e.code == Gtk.DialogError.FAILED)
                    warning("FileDialog : %s", e.message);
            }
            return selections;
        }

        public void install_selections (StringSet selections) {
            header_widgets.installing_files = true;
            var installer = new Library.Installer();
            installer.process.begin(selections, (obj, res) => {
                installer.process.end(res);
                header_widgets.installing_files = false;
            });
            return;
        }

        void install_selected_files (Object? object, AsyncResult result) {
            var selections = get_file_selections(object, result);
            install_selections(selections);
            return;
        }

        void reload (Gtk.Widget widget, string? action, Variant? parameter) {
            get_default_application().reload();
            return;
        }

        void install (Gtk.Widget widget, string? action, Variant? parameter) {
            var dialog = FileSelector.get_selections();
            dialog.open_multiple.begin(this, null, install_selected_files);
            return;
        }

        void remove (Gtk.Widget widget, string? action, Variant? parameter) {
            var dialog = new RemoveDialog(this);
            dialog.start_removal.connect(() => {
                header_widgets.removing_files = true;
            });
            dialog.end_removal.connect(() => {
                header_widgets.removing_files = false;
            });
            dialog.present();
            return;
        }

        void import (Gtk.Widget widget, string? action, Variant? parameter) {
            var dialog = new UserData.ImportDialog(this);
            dialog.present();
            return;
        }

        void export (Gtk.Widget widget, string? action, Variant? parameter) {
            var dialog = new UserData.ExportDialog(this);
            dialog.present();
            return;
        }

        void on_mode_changed (ParamSpec pspec) {
            string markup = "<b>%s</b>".printf(mode.to_translatable_string());
            header_widgets.main_menu_label.set_markup(markup);
            header_widgets.reveal_manage_controls(mode == Mode.MANAGE);
            if (mode == Mode.COMPARE)
                main_stack.set_visible_child_name("Default");
            else
                main_stack.set_visible_child_name(mode.to_string());
            return;
        }

        void on_stack_page_changed (ParamSpec pspec) {
            if (show_preferences)
                main_stack.set_visible_child_name("Preferences");
            else if (mode == Mode.COMPARE)
                main_stack.set_visible_child_name("Default");
            else
                main_stack.set_visible_child_name(mode.to_string());
            header_widgets.main_menu.set_visible(!show_preferences);
            header_widgets.revealer.set_visible(!show_preferences);
            header_widgets.back_button.set_visible(show_preferences);
            return;
        }

        void update_layout_orientation () {
            if (settings == null)
                return;
            Gtk.Orientation orientation = Gtk.Orientation.VERTICAL;
            bool wide_layout = settings.get_boolean("wide-layout");
            bool only_on_maximize = settings.get_boolean("wide-layout-on-maximize");
            if (wide_layout && only_on_maximize && maximized || wide_layout && !only_on_maximize)
                orientation = Gtk.Orientation.HORIZONTAL;
            main_pane.set_orientation(orientation);
#if HAVE_WEBKIT
            google_fonts.set_orientation(orientation);
#endif /* HAVE_WEBKIT */
            return;
        }

    }

}




