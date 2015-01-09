/* UserFontTree.vala
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

    public class UserFontTree : Gtk.TreeView {

        private Gtk.CellRendererToggle toggle;
        private Gee.HashSet <string> selected_paths;
        private Gee.HashMap <string, string> filemap;

        construct {
            try {
                filemap = get_user_filemap(get_database());
            } catch (DatabaseError e) {
                critical(e.message);
            }
        }

        public UserFontTree (UserFontModel model) {
            this.model = model;
            get_selection().set_mode(Gtk.SelectionMode.SINGLE);
            headers_visible = false;
            toggle = new Gtk.CellRendererToggle();
            var text = new Gtk.CellRendererText();
            var preview = new Gtk.CellRendererText();
            preview.ellipsize = Pango.EllipsizeMode.END;
            var count = new CellRendererCount();
            count.junction_side = Gtk.JunctionSides.RIGHT;
            insert_column_with_data_func(FontListColumn.TOGGLE, "", toggle, toggle_cell_data_func);
            insert_column_with_data_func(FontListColumn.TEXT, "", text, text_cell_data_func);
            insert_column_with_data_func(FontListColumn.PREVIEW, "", preview, preview_cell_data_func);
            insert_column_with_data_func(FontListColumn.COUNT, "", count, count_cell_data_func);
            get_column(FontListColumn.TOGGLE).expand = false;
            get_column(FontListColumn.TEXT).expand = false;
            get_column(FontListColumn.PREVIEW).expand = true;
            get_column(FontListColumn.COUNT).expand = false;
            selected_paths = new Gee.HashSet <string> ();
            connect_signals();
        }

        public File [] to_file_array () {
            File? [] arr = null;
            foreach (var path in selected_paths)
                arr += File.new_for_path(path);
            return arr;
        }

        private void connect_signals () {
            toggle.toggled.connect(on_font_toggled);
            return;
        }

        private int family_state (FontConfig.Family family) {
            Gee.ArrayList <FontConfig.Font> faces = family.list_faces();
            int total = faces.size;
            int active = 0;
            foreach (var face in faces)
                if (filemap.has_key(face.description))
                    if (selected_paths.contains(filemap[face.description]))
                        active++;
            if (active != 0 && active < total)
                return -1;
            else if (active == total)
                return 1;
            else
                return 0;
        }

        private void on_font_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, FontModelColumn.OBJECT, out val);
            var font = val.get_object();
            if (font is FontConfig.Family) {
                bool inconsistent = (family_state((FontConfig.Family) font) == -1);
                foreach (var face in ((FontConfig.Family) font).list_faces()) {
                    if (!filemap.has_key(face.description))
                        continue;
                    var _path = filemap[face.description];
                    if (!inconsistent && selected_paths.contains(_path))
                        selected_paths.remove(_path);
                    else
                        selected_paths.add(_path);
                }
            } else {
                var _path = filemap[((FontConfig.Font) font).description];
                if (selected_paths.contains(_path))
                    selected_paths.remove(_path);
                else
                    selected_paths.add(_path);
            }
            val.unset();
            queue_draw();
            return;
        }

        private void preview_cell_data_func (Gtk.TreeViewColumn layout,
                                                Gtk.CellRenderer cell,
                                                Gtk.TreeModel model,
                                                Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            var obj = val.get_object();
            if (obj is FontConfig.Family) {
                cell.set_property("text", ((FontConfig.Family) obj).description);
                cell.set_property("ypad", 0);
                cell.set_property("xpad", 0);
                cell.set_property("visible", false);
            } else {
                cell.set_property("text", ((FontConfig.Font) obj).description);
                cell.set_property("ypad", 3);
                cell.set_property("xpad", 6);
                cell.set_property("visible", true);
                cell.set_property("font", ((FontConfig.Font) obj).description);
            }
            val.unset();
            return;
        }

        private void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                                Gtk.CellRenderer cell,
                                                Gtk.TreeModel model,
                                                Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            var obj = val.get_object();
            cell.set_property("visible", true);
            cell.set_property("sensitive", true);
            cell.set_property("inconsistent", false);
            if (obj is FontConfig.Family) {
                int active = family_state((FontConfig.Family) obj);
                if (active == -1) {
                    cell.set_property("inconsistent", true);
                    cell.set_property("active", false);
                } else
                    cell.set_property("active", active);
            } else {
                var _path = filemap[((FontConfig.Font) obj).description];
                cell.set_property("active", selected_paths.contains(_path));
            }
            val.unset();
            return;
        }

        private void text_cell_data_func (Gtk.TreeViewColumn layout,
                                            Gtk.CellRenderer cell,
                                            Gtk.TreeModel model,
                                            Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            var obj = val.get_object();
            if (obj is FontConfig.Family) {
                cell.set_property("text", ((FontConfig.Family) obj).name);
                cell.set_property("ypad", 0);
                cell.set_property("xpad", 0);
            } else {
                cell.set_property("text", ((FontConfig.Font) obj).style);
                cell.set_property("ypad", 3);
                cell.set_property("xpad", 6);
            }
            val.unset();
            return;
        }

        private void count_cell_data_func (Gtk.TreeViewColumn layout,
                                            Gtk.CellRenderer cell,
                                            Gtk.TreeModel model,
                                            Gtk.TreeIter treeiter) {
            if (model.iter_has_child(treeiter)) {
                int count = 0;
                Gtk.TreeIter child;
                bool have_child = model.iter_children(out child, treeiter);
                while (have_child) {
                    count++;
                    have_child = model.iter_next(ref child);
                }
                cell.set_property("count", count);
                cell.set_property("visible", true);
            } else {
                cell.set_property("count", 0);
                cell.set_property("visible", false);
            }
            return;
        }

    }

}
