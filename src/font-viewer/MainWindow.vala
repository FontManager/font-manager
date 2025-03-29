/* MainWindow.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

namespace FontManager.FontViewer {

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-viewer-main-window.ui")]
    public class MainWindow : FontManager.ApplicationWindow {

        public int predefined_size { get; set; }
        public bool show_line_size { get; set; default = true; }

        [GtkChild] unowned Gtk.Label title_label;
        [GtkChild] unowned Gtk.DropDown title_widget;
        [GtkChild] unowned Gtk.Stack stack;
        [GtkChild] unowned Gtk.Button action_button;
        [GtkChild] unowned Gtk.ToggleButton preference_toggle;
        [GtkChild] unowned Gtk.ListBox preference_list;
        [GtkChild] unowned PreviewPane preview_pane;

        FileStatus file_status;
        List <string> installed_files;
        Gdk.Rectangle clicked_area;
        Gtk.Switch prefer_dark_theme;
#if HAVE_ADWAITA
        Gtk.Switch use_adwaita_stylesheet;
#endif
        PreviewColors preview_colors;
        WaterfallSettings waterfall_settings;

        Font? font = null;
        Family? family = null;
        File? current_file = null;
        File? current_target = null;

        enum FileStatus {
            NOT_INSTALLED,
            INSTALLED,
            SYSTEM_FONT,
            WOULD_DOWNGRADE,
            WOULD_UPGRADE;
        }

        static construct {
            install_property_action("predefined-size", "predefined-size");
            install_property_action("show-line-size", "show-line-size");
        }

        public class MainWindow (GLib.Settings? settings) {
            // Settings instance used in base class
            Object(settings: settings);
            family = new Family();
            var target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
            target.drop.connect(on_drop);
            stack.add_controller(target);
            stack.set_visible_child_name("PlaceHolder");
            preview_pane.add_action_widget(action_button, Gtk.PackType.END);
            preview_pane.changed.connect(update);
            preview_pane.realize.connect_after(() => {
                preview_pane.restore_state(get_gsettings(BUS_ID));
            });
            clicked_area = Gdk.Rectangle();
            Gtk.Gesture right_click = new Gtk.GestureClick() {
                button = Gdk.BUTTON_SECONDARY
            };
            ((Gtk.GestureClick) right_click).pressed.connect(on_show_context_menu);
            preview_pane.add_controller(right_click);
            update_action_button();
            waterfall_settings = new WaterfallSettings(settings);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            waterfall_settings.bind_property("predefined-size", this, "predefined-size", flags);
            waterfall_settings.bind_property("show-line-size", this, "show-line-size", flags);
            bind_property("show-line-size", preview_pane, "show-line-size", flags);
            waterfall_settings.notify["predefined-size"].connect_after(() => {
                waterfall_settings.on_selection_changed();
                preview_pane.set_waterfall_size(waterfall_settings.minimum,
                                                waterfall_settings.maximum,
                                                waterfall_settings.ratio);
            });
            populate_preference_list();
            title_widget.notify["selected"].connect(on_variation_selected);
            var popup = (Gtk.Popover) title_widget.get_last_child();
            popup.set_halign(Gtk.Align.CENTER);
            popup.set_has_arrow(true);
#if HAVE_ADWAITA
            map.connect_after(() => {
                use_adwaita_stylesheet.notify["active"].connect(() => { on_restart_required(); });
            });
#endif
        }

        public void show_uri (string? uri) {
            if (uri == null) {
                family = null;
                font = null;
                current_file = null;
                current_target = null;
                return;
            }
            installed_files = list_available_font_files();
            File file = File.new_for_commandline_arg(uri);
            string path = file.get_path();
            add_application_font(path);
            clear_pango_cache(get_pango_context());
            Json.Object? source = null;
            try {
                source = get_attributes_from_filepath(path);
            } catch (Error e) {
                critical(e.message);
                return;
            }
            assert(source != null);
            family = new Family();
            font = new Font();
            family.source_object = source;
            font.source_object = family.get_default_variant();
            var model = new Gtk.StringList(null);
            family.variations.foreach_element((array, index, element) => {
                Json.Object json_object = element.get_object();
                var font_desc = json_object.get_string_member("description");
                if (family.n_variations == 1 || font_desc != family.family)
                    model.append(font_desc);
                string sample = get_sample_string(json_object);
                json_object.set_string_member("preview-text", sample);
            });
            title_widget.set_model(model);
            title_widget.set_selected(family.get_default_index());
            return;
        }

        public void open (File file) {
            show_uri(file.get_uri());
            return;
        }

        public void update () {
            if (preview_pane.font != null) {
                current_file = File.new_for_path(preview_pane.font.filepath);
            } else {
                current_file = null;
                var model = new Gtk.StringList(null);
                model.append(_("Font Viewer"));
                title_widget.set_model(model);
            }
            stack.set_visible_child_name(preview_pane.font != null ? "Preview" : "PlaceHolder");
            current_target = null;
            file_status = get_file_status();
            update_action_button();
            update_title_widget();
            return;
        }

        [GtkCallback]
        public void on_preferences_toggled () {
            if (preference_toggle.active)
                stack.set_visible_child_name("Preferences");
            else
                stack.set_visible_child_name(preview_pane.font != null ? "Preview" : "PlaceHolder");
            return;
        }

        [GtkCallback]
        public void on_action_button_clicked () {
            File font_dir = File.new_for_path(get_user_font_directory());
            switch (file_status) {
                case FileStatus.SYSTEM_FONT:
                    string directory = GLib.Path.get_dirname(current_file.get_path());
                    File file = File.new_for_path(directory);
                    var launcher = new Gtk.FileLauncher(file);
                    launcher.launch.begin(null, null);
                    break;
                case FileStatus.INSTALLED:
                    try {
                        File parent = current_target.get_parent();
                        current_target.delete(null);
                        remove_directory_tree_if_empty(parent);
                        font = null;
                        preview_pane.font = null;
                        update();
                    } catch (Error e) {
                        critical("Failed to remove %s", current_target.get_path());
                    }
                    break;
                default:
                    try {
                        install_file(current_file, font_dir);
                        update();
                    } catch (Error e) {
                        critical("Failed to install %s", current_file.get_path());
                    }
                    break;
            }
            return;
        }

        bool on_drop (Value val, double x, double y) {
            unowned SList <File> files = (SList) val.get_boxed();
            if (files.length() > 0)
                show_uri(files.nth_data(0).get_uri());
            return true;
        }

        void on_variation_selected () {
            if (family == null || font == null)
                return;
            font = new Font() {
                source_object = family.variations.get_object_element(title_widget.selected)
            };
            preview_pane.set_font(font);
            return;
        }

        void update_title_widget () {
            int64 n_items = (family != null && font != null) ? family.n_variations : 0;
            title_widget.set_show_arrow(n_items > 1);
            title_widget.set_can_target(n_items > 1);
            title_widget.set_visible(n_items > 1);
            title_label.set_visible(n_items <= 1);
            if (n_items == 1 && font != null)
                title_label.set_label(font.description);
            else
                title_label.set_label(_("Font Viewer"));
            return;
        }

        FileStatus get_file_status () {
            if (current_file == null)
                return FileStatus.NOT_INSTALLED;
            string current_path = current_file.get_path();
            if (installed_files.find_custom(current_path, strcmp) != null && get_file_owner(current_path) != 0)
                return FileStatus.SYSTEM_FONT;
            File font_dir = File.new_for_path(get_user_font_directory());
            if (current_file.get_path().contains(font_dir.get_path()))
                current_target = current_file;
            if (current_target == null) {
                try {
                    current_target = get_installation_target(current_file, font_dir, false);
                } catch (Error e) {
                    return FileStatus.NOT_INSTALLED;
                }
            }
            if (current_target.query_exists()) {
                float a = get_font_revision(current_target.get_path());
                float b = get_font_revision(current_file.get_path());
                if (a < b)
                    return FileStatus.WOULD_UPGRADE;
                else if (a > b)
                    return FileStatus.WOULD_DOWNGRADE;
                else
                    return FileStatus.INSTALLED;
            } else
                return FileStatus.NOT_INSTALLED;
        }

        void update_action_button () {
            action_button.remove_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
            action_button.remove_css_class(STYLE_CLASS_SUGGESTED_ACTION);
            action_button.remove_css_class(STYLE_CLASS_DIM_LABEL);
            action_button.set_tooltip_text(null);
            action_button.set_visible(preview_pane.font != null);
            if (preview_pane.font == null)
                return;
            switch (file_status) {
                case FileStatus.SYSTEM_FONT:
                    action_button.set_label(_("System Font"));
                    action_button.add_css_class(STYLE_CLASS_DIM_LABEL);
                    action_button.set_tooltip_text(_("Selected font file is either installed in a system directory or is not writable by the current user.\n\nIf you wish to remove this font from the list of available fonts use the system package manager to remove the package containing this font file, ask the system administrator to remove it or use a font management application to disable it."));
                    break;
                case FileStatus.WOULD_DOWNGRADE:
                    action_button.set_label(_("Newer version already installed"));
                    action_button.add_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
                    action_button.set_tooltip_text(_("Click to overwrite"));
                    break;
                case FileStatus.WOULD_UPGRADE:
                    action_button.set_label(_("Update Font"));
                    action_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
                    action_button.set_tooltip_text(_("Click to overwrite"));
                    break;
                case FileStatus.INSTALLED:
                    action_button.set_label(_("Remove Font"));
                    action_button.add_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
                    break;
                default:
                    action_button.set_label(_("Install Font"));
                    action_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
                    break;
            }
            return;
        }

        void bind_settings () {
            return_if_fail(settings != null);
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            Gtk.Settings? gtk_settings = Gtk.Settings.get_default();
            const string gtk_prefer_dark = "gtk-application-prefer-dark-theme";
            if (gtk_settings != null) {
#if HAVE_ADWAITA
                if (settings.get_boolean("use-adwaita-stylesheet")) {
                    prefer_dark_theme.notify["active"].connect(() => {
                        Adw.StyleManager style_manager = Adw.StyleManager.get_default();
                        Adw.ColorScheme color_scheme = prefer_dark_theme.active ?
                                                       Adw.ColorScheme.PREFER_DARK :
                                                       Adw.ColorScheme.PREFER_LIGHT;
                        style_manager.set_color_scheme(color_scheme);
                    });
                } else
                    settings.bind("prefer-dark-theme", gtk_settings, gtk_prefer_dark, flags);
#else
                settings.bind("prefer-dark-theme", gtk_settings, gtk_prefer_dark, flags);
#endif
            }
            warn_if_fail(gtk_settings != null);

            settings.bind("prefer-dark-theme", prefer_dark_theme, "active", flags);
#if HAVE_ADWAITA
            settings.bind("use-adwaita-stylesheet", use_adwaita_stylesheet, "active", flags);
#endif
            return;
        }

#if HAVE_ADWAITA
        void on_restart_required () {
            var title = _("Selected setting requires restart to apply");
            var body = _("Changes will take effect next time the application is started");
            var icon = new GLib.ThemedIcon(BUS_ID);
            var notification = new GLib.Notification(title);
            notification.set_body(body);
            notification.set_icon(icon);
            GLib.Application.get_default().send_notification("restart-required", notification);
            return;
        }
#endif

        void populate_preference_list () {
            preference_list.set_selection_mode(Gtk.SelectionMode.NONE);
            prefer_dark_theme = new Gtk.Switch();
            // The added margins here are due to PreviewColors widget alignment issues
            var row = new Gtk.ListBoxRow() { activatable = false, selectable = false, margin_start = 6, margin_end = 6 };
            row.set_child(new PreferenceRow(_("Prefer Dark Theme"), null, null, prefer_dark_theme));
            preference_list.insert(row, -1);
#if HAVE_ADWAITA
            use_adwaita_stylesheet = new Gtk.Switch();
            row = new Gtk.ListBoxRow() { activatable = false, selectable = false, margin_start = 6, margin_end = 6 };
            row.set_child(new PreferenceRow(_("Use Adwaita Stylesheet"), null, null, use_adwaita_stylesheet));
            preference_list.insert(row, -1);
#endif
            preview_colors = new PreviewColors();
            preview_colors.restore_state(settings);
            widget_set_margin(preview_colors, 0);
            row = new Gtk.ListBoxRow() { activatable = false, selectable = false, margin_start = 6 };
            row.set_child(new PreferenceRow(_("Preview Area Colors"), null, null, preview_colors));
            preference_list.insert(row, -1);
            var adjustment = new Gtk.Adjustment(0.0, 0.0, double.MAX, 1.0, 1.0, 1.0);
            var spacing = new Gtk.SpinButton(adjustment, 1.0, 0);
            spacing.set_value((double) waterfall_settings.line_spacing);
            row = new Gtk.ListBoxRow() { activatable = false, selectable = false, margin_start = 6, margin_end = 6 };
            row.set_child(new PreferenceRow(_("Waterfall Line Spacing"), null, null, spacing));
            row.set_tooltip_text(_("Padding in pixels to insert above and below rows"));
            preference_list.insert(row, -1);
            row = new Gtk.ListBoxRow() { activatable = false, selectable = false, margin_start = 6, margin_end = 6 };
            var show_line_size = new Gtk.Switch();
            row.set_child(new PreferenceRow(_("Display line size in Waterfall Preview"), null, null, show_line_size));
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("show-line-size", show_line_size, "active", flags);
            preference_list.insert(row, -1);
            spacing.value_changed.connect(() => {
                waterfall_settings.line_spacing = (int) spacing.value;
            });
            row = new Gtk.ListBoxRow() { activatable = false, selectable = false, margin_start = 6, margin_end = 6 };
            row.set_child(waterfall_settings.preference_row);
            waterfall_settings.preference_row.margin_end = 12;
            preference_list.insert(row, -1);
            bind_settings();
            return;
        }

        void on_show_context_menu (int n_press, double x, double y) {
            if (waterfall_settings == null)
                return;
            if (preview_pane.page != PreviewPanePage.PREVIEW || preview_pane.preview_mode != PreviewPageMode.WATERFALL)
                return;
            clicked_area.x = (int) x;
            clicked_area.y = (int) y;
            clicked_area.width = 2;
            clicked_area.height = 2;
            if (waterfall_settings.context_menu.get_parent() != null)
                waterfall_settings.context_menu.unparent();
            waterfall_settings.context_menu.set_parent(preview_pane);
            waterfall_settings.context_menu.set_pointing_to(clicked_area);
            waterfall_settings.context_menu.popup();
            return;
        }

        bool remove_directory_tree_if_empty (File dir) {
            try {
                var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,
                                                        FileQueryInfoFlags.NONE);
                if (enumerator.next_file() != null)
                    return false;
                File parent = dir.get_parent();
                dir.delete();
                if (parent != null)
                    remove_directory_tree_if_empty(parent);
                return true;
            } catch (Error e) {
                warning(e.message);
            }
            return false;
        }

    }

}

