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

namespace FontManager.FontViewer {

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-viewer-main-window.ui")]
    public class MainWindow : FontManager.ApplicationWindow {

        File? current_file;
        File? current_target;
        FileStatus file_status;

        [GtkChild] unowned Gtk.Label title_label;
        [GtkChild] unowned Gtk.Label subtitle_label;
        [GtkChild] unowned Gtk.Stack stack;
        [GtkChild] unowned Gtk.Button action_button;
        [GtkChild] unowned Gtk.HeaderBar headerbar;
        [GtkChild] unowned PreviewPane preview_pane;

        enum FileStatus {
            NOT_INSTALLED,
            INSTALLED,
            WOULD_DOWNGRADE;
        }

        public override void constructed () {
            var target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
            target.on_drop.connect(on_drop);
            stack.add_controller(target);
            stack.set_visible_child_name("PlaceHolder");
            preview_pane.set_action_widget(action_button, Gtk.PackType.END);
            preview_pane.changed.connect(this.update);
            preview_pane.realize.connect(() => { preview_pane.restore_state(settings); });
            update_action_button();
            base.constructed();
            return;
        }

        public bool show_uri (string uri, int index = 0) {
            return preview_pane.show_uri(uri, index);
        }

        public bool open (File file, int index = 0) {
            return preview_pane.show_uri(file.get_uri(), index);
        }

        bool on_drop (Value val, double x, double y) {
            unowned SList <File> files = (SList) val.get_boxed();
            if (files.length() > 0)
                show_uri(files.nth_data(0).get_uri());
            return true;
        }

        public void update () {
            bool have_valid_source = preview_pane.font != null && preview_pane.font.is_valid();
            if (have_valid_source) {
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
            stack.set_visible_child_name(have_valid_source ? "Preview" : "PlaceHolder");
            current_target = null;
            file_status = get_file_status();
            update_action_button();
            return;
        }

        FileStatus get_file_status () {
            if (current_file == null)
                return FileStatus.NOT_INSTALLED;
            if (current_target == null) {
                File font_dir = File.new_for_path(get_user_font_directory());
                try {
                    current_target = get_installation_target(current_file, font_dir, false);
                } catch (Error e) {
                    return FileStatus.NOT_INSTALLED;
                }
            }
            if (current_target.query_exists()) {
                if (timecmp(current_target, current_file) > 0)
                    return FileStatus.WOULD_DOWNGRADE;
                else
                    return FileStatus.INSTALLED;
            } else
                return FileStatus.NOT_INSTALLED;
        }

        void update_action_button () {
            bool have_valid_source = preview_pane.font != null && preview_pane.font.is_valid();
            action_button.get_style_context().remove_class("destructive-action");
            action_button.get_style_context().remove_class("suggested-action");
            action_button.set_tooltip_text(null);
            action_button.set_visible(have_valid_source);
            if (!have_valid_source)
                return;
            switch (file_status) {
                case FileStatus.WOULD_DOWNGRADE:
                    action_button.set_label(_("Newer version already installed"));
                    action_button.get_style_context().add_class("destructive-action");
                    action_button.set_tooltip_text(_("Click to overwrite"));
                    break;
                case FileStatus.INSTALLED:
                    action_button.set_label(_("Remove Font"));
                    action_button.get_style_context().add_class("destructive-action");
                    break;
                default:
                    action_button.set_label(_("Install Font"));
                    action_button.get_style_context().add_class("suggested-action");
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
                case FileStatus.INSTALLED:
                    try {
                        File parent = current_target.get_parent();
                        current_target.delete(null);
                        remove_directory_tree_if_empty(parent);
                        update_action_button();
                    } catch (Error e) {
                        critical("Failed to remove %s", current_target.get_path());
                    }
                    break;
                default:
                    try {
                        install_file(current_file, font_dir);
                        update_action_button();
                    } catch (Error e) {
                        critical("Failed to install %s", current_file.get_path());
                    }
                    break;
            }
            return;
        }

    }

}


