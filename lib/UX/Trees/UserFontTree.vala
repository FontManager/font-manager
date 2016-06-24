/* UserFontTree.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontManager {

    public class UserFontTree : BaseTreeView {

        Gtk.CellRendererToggle toggle;
        Gee.HashSet <FontConfig.Family> selected_families;
        Gee.HashSet <FontConfig.Font> selected_fonts;

        public UserFontTree (UserFontModel model) {
            Object(name: "UserFontTree", model: model, headers_visible: false);
            get_selection().set_mode(Gtk.SelectionMode.SINGLE);
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
            selected_families = new Gee.HashSet <FontConfig.Family> ();
            selected_fonts = new Gee.HashSet <FontConfig.Font> ();
            connect_signals();
        }

        public File [] to_file_array () {
            File? [] arr = null;
            foreach (var font in selected_fonts)
                arr += File.new_for_path(get_actual_filepath(font));
            return arr;
        }

        void connect_signals () {
            toggle.toggled.connect(on_font_toggled);
            return;
        }

        string get_actual_filepath (FontConfig.Font font) {
            File font_file = File.new_for_path(font.filepath);
            if (font_file.query_exists() && font.filepath.contains(get_user_font_dir()))
                return font_file.get_path();
            debug("Font file %s is not stored in user font directory, querying database for duplicates...", font.filepath);
            string path = font.filepath;
            try {
                var db = get_database();
                db.reset();
                db.table = "Fonts";
                db.select = "filepath";
                db.search = "family=\"%s\" AND style=\"%s\"".printf(font.family, font.style);
                db.unique = true;
                db.execute_query();
                foreach (var row in db) {
                    string res = row.column_text(0);
                    if (res.contains(get_user_font_dir())) {
                        path = res;
                        debug("Found matching font file stored in user font directory %s", path);
                        break;
                    }
                }
                db.close();
            } catch (DatabaseError e) {
                critical("Failed to query database : %s", db.db.errmsg());
            }
            return path;
        }

        void on_font_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, FontModelColumn.OBJECT, out val);
            var font = val.get_object();
            if (font is FontConfig.Family) {
                if (selected_families.contains((FontConfig.Family) font)) {
                    selected_families.remove((FontConfig.Family)font);
                    foreach (var face in ((FontConfig.Family) font).list_faces())
                        selected_fonts.remove((FontConfig.Font) face);
                } else {
                    selected_families.add((FontConfig.Family) font);
                    foreach (var face in ((FontConfig.Family) font).list_faces())
                        selected_fonts.add((FontConfig.Font) face);
                }
            } else {
                if (selected_fonts.contains((FontConfig.Font) font))
                    selected_fonts.remove((FontConfig.Font) font);
                else
                    selected_fonts.add((FontConfig.Font) font);
            }
            val.unset();
            Idle.add(() => {
                queue_draw();
                return false;
            });
            return;
        }

        void preview_cell_data_func (Gtk.TreeViewColumn layout,
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

        void toggle_cell_data_func (Gtk.TreeViewColumn layout,
                                                Gtk.CellRenderer cell,
                                                Gtk.TreeModel model,
                                                Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, FontModelColumn.OBJECT, out val);
            var obj = val.get_object();
            cell.set_property("visible", true);
            cell.set_property("sensitive", true);
            cell.set_property("inconsistent", false);
            if (obj is FontConfig.Family)
                cell.set_property("active", selected_families.contains((FontConfig.Family) obj));
            else
                cell.set_property("active", selected_fonts.contains((FontConfig.Font) obj));
            val.unset();
            return;
        }

        void text_cell_data_func (Gtk.TreeViewColumn layout,
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

        void count_cell_data_func (Gtk.TreeViewColumn layout,
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
