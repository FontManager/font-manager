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

namespace FontManager.FontViewer {

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-viewer-main-window.ui")]
    public class MainWindow : FontManager.ApplicationWindow {

        File? current_file;
        File? current_target;
        FileStatus file_status;
        List <string> installed_files;

        [GtkChild] unowned Gtk.Label title_label;
        [GtkChild] unowned Gtk.Label subtitle_label;
        [GtkChild] unowned Gtk.Stack stack;
        [GtkChild] unowned Gtk.Button action_button;
        [GtkChild] unowned Gtk.HeaderBar headerbar;
        [GtkChild] unowned PreviewPane preview_pane;

        enum FileStatus {
            NOT_INSTALLED,
            INSTALLED,
            SYSTEM_FONT,
            WOULD_DOWNGRADE,
            WOULD_UPGRADE;
        }

        public class MainWindow (GLib.Settings? settings) {
            Object(settings: settings);
            var target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
            target.drop.connect(on_drop);
            stack.add_controller(target);
            stack.set_visible_child_name("PlaceHolder");
            preview_pane.set_action_widget(action_button, Gtk.PackType.END);
            preview_pane.changed.connect(this.update);
            preview_pane.realize.connect(() => {
                preview_pane.restore_state(get_gsettings(FontManager.BUS_ID));
            });
            update_action_button();
        }

        public bool show_uri (string uri, int index = 0) {
            installed_files = list_available_font_files();
            return preview_pane.show_uri(uri, index);
        }

        public bool open (File file, int index = 0) {
            return show_uri(file.get_uri(), index);
        }

        bool on_drop (Value val, double x, double y) {
            unowned SList <File> files = (SList) val.get_boxed();
            if (files.length() > 0)
                show_uri(files.nth_data(0).get_uri());
            return true;
        }

        public void update () {
            if (preview_pane.font != null) {
                current_file = File.new_for_path(preview_pane.font.filepath);
                string family = preview_pane.font.family;
                string style = preview_pane.font.style;
                title_label.set_label(family);
                subtitle_label.set_label(style);
                const string tt_tmpl = "<big><b>%s</b> </big><b>%s</b>";
                headerbar.set_tooltip_markup(tt_tmpl.printf(Markup.escape_text(family), style));
            } else {
                current_file = null;
                title_label.set_label(_("No file selected"));
                subtitle_label.set_label(_("Or unsupported filetype."));
                headerbar.set_tooltip_markup(null);
            }
            stack.set_visible_child_name(preview_pane.font != null ? "Preview" : "PlaceHolder");
            current_target = null;
            file_status = get_file_status();
            update_action_button();
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

    }

}

