/* FileSelector.vala
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

    namespace FileSelector {

        public string? [] run_install (Gtk.Window? parent) {
            string? [] arr = { };
            var dialog = new Gtk.FileChooserDialog("Select files to install",
                                                        parent,
                                                        Gtk.FileChooserAction.OPEN,
                                                        "_Cancel",
                                                        Gtk.ResponseType.CANCEL,
                                                        "_Open",
                                                        Gtk.ResponseType.ACCEPT,
                                                        null);
            var filter = new Gtk.FileFilter();
            var archive_manager = new ArchiveManager();
            foreach (var mimetype in archive_manager.get_supported_types())
                if (!(mimetype in ARCHIVE_IGNORE_LIST))
                    filter.add_mime_type(mimetype);
            foreach (var mimetype in FONT_MIMETYPES)
                filter.add_mime_type(mimetype);
            dialog.set_filter(filter);
            dialog.set_select_multiple(true);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                ensure_ui_update();
                foreach (var uri in dialog.get_uris())
                    arr += uri;
            }
            dialog.destroy();
            return arr;
        }

        public File? [] run_removal (Gtk.Window? parent, UserFontModel font_model) {
            File? [] res = null;
            var dialog = new Gtk.Dialog.with_buttons("Select fonts to remove",
                                                    parent,
                                                    Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                                    "_Cancel",
                                                    Gtk.ResponseType.CANCEL,
                                                    "_Delete",
                                                    Gtk.ResponseType.ACCEPT,
                                                    null);
            var content_area = dialog.get_content_area();
            var scroll = new Gtk.ScrolledWindow(null, null);
            var tree = new RemoveTree(font_model);
            tree.hexpand = tree.vexpand = true;
            scroll.add(tree);
            add_separator(content_area, Gtk.Orientation.HORIZONTAL);
            content_area.pack_start(scroll, true, true, 0);
            add_separator(content_area, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
            scroll.show_all();
            dialog.set_size_request(420, 480);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                if (tree.files.size > 0)
                    res = tree.files.values.to_array();
            }
            dialog.destroy();
            return res;
        }

        class RemoveTree : Gtk.TreeView {

            public Gee.HashMap <string, File> files { get; private set; }

            Gtk.CellRendererToggle toggle;

            public RemoveTree (UserFontModel model) {
                set_model(model);
                headers_visible = false;
                files = new Gee.HashMap <string, File> ();
                toggle = new Gtk.CellRendererToggle();
                var text = new Gtk.CellRendererText();
                var preview = new Gtk.CellRendererText();
                insert_column_with_data_func(0, "", toggle, toggle_cell_data_func);
                insert_column_with_attributes(1, "", text, "text", 1, "font", 1, null);
                get_column(0).expand = false;
                get_column(1).expand = true;
                set_enable_search(true);
                set_search_column(1);
                toggle.toggled.connect(on_toggled);
            }

            void on_toggled (string path) {
                Gtk.TreeIter iter;
                Value val;
                model.get_iter_from_string(out iter, path);
                model.get_value(iter, 0, out val);
                var obj = (FontConfig.Font) val.get_object();
                if (files.has_key(obj.filepath))
                    files.unset(obj.filepath);
                else
                    files[obj.filepath] = File.new_for_path(obj.filepath);
                val.unset();
                return;
            }

            void toggle_cell_data_func (Gtk.CellLayout layout,
                                        Gtk.CellRenderer cell,
                                        Gtk.TreeModel model,
                                        Gtk.TreeIter treeiter) {
                Value val;
                model.get_value(treeiter, 0, out val);
                var obj = (FontConfig.Font) val.get_object();
                cell.set_property("active", files.contains(obj.filepath));
                val.unset();
                return;
            }

        }

    }

}
