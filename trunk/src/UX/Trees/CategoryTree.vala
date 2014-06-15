/* CategoryTree.vala
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

    public enum CategoryColumn {
        OBJECT,
        ICON,
        NAME,
        COMMENT,
        COUNT,
        HIDE_COUNT,
        N_COLUMNS
    }

    public class CategoryTree : Gtk.ScrolledWindow {

        public signal void selection_changed (Category filter, int category);

        public weak CategoryModel model {
            get {
                return _model;
            }
            set {
                _model = value;
                tree.set_model(_model);
                tree.get_selection().select_path(new Gtk.TreePath.first());
            }
        }

        public Category? selected_filter { get; protected set; default = null; }
        public Gtk.TreeView tree { get; protected set; }
        public Gtk.CellRendererText renderer { get; protected set; }
        public CellRendererCount count_renderer { get; protected set; }
        public Gtk.CellRendererPixbuf pixbuf_renderer { get; protected set; }

        private weak CategoryModel _model;

        public CategoryTree () {
            tree = new Gtk.TreeView();
            tree.level_indentation = 12;
            renderer = new Gtk.CellRendererText();
            count_renderer = new CellRendererCount();
            count_renderer.type_name = null;
            count_renderer.type_name_plural = null;
            pixbuf_renderer = new Gtk.CellRendererPixbuf();
            pixbuf_renderer.set_property("xpad", 6);
            count_renderer.xalign = 1.0f;
            renderer.set_property("ellipsize", Pango.EllipsizeMode.END);
            renderer.set_property("ellipsize-set", true);
            tree.insert_column_with_data_func(0, "", pixbuf_renderer, pixbuf_cell_data_func);
            tree.insert_column_with_attributes(1, "", renderer, "text", CategoryColumn.NAME, null);
            tree.insert_column_with_attributes(2, "", count_renderer, "count", CategoryColumn.COUNT, "fallthrough", CategoryColumn.HIDE_COUNT, null);
            tree.get_column(0).expand = false;
            tree.get_column(1).expand = true;
            tree.get_column(2).expand = false;
            tree.set_headers_visible(false);
            tree.show_expanders = false;
            tree.set_tooltip_column(CategoryColumn.COMMENT);
            tree.test_expand_row.connect((t,i,p) => { t.collapse_all(); return false; });
            tree.get_selection().changed.connect(on_selection_changed);
            tree.show();
            add(tree);
        }

        public void select_first_row () {
            tree.get_selection().select_path(new Gtk.TreePath.first());
            return;
        }

        public void on_export_category () {
            NotImplemented.run("Exporting categories");
            return;
        }


        internal void pixbuf_cell_data_func (Gtk.CellLayout layout,
                                      Gtk.CellRenderer cell,
                                      Gtk.TreeModel model,
                                      Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            var obj = val.get_object();
            if (tree.is_row_expanded(model.get_path(treeiter)))
                cell.set_property("icon-name", "folder-open");
            else
                cell.set_property("icon-name", ((Category) obj).icon);
            val.unset();
            return;
        }

        internal void on_selection_changed (Gtk.TreeSelection selection) {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            GLib.Value val;
            if (!selection.get_selected(out model, out iter))
                return;
            model.get_value(iter, 0, out val);
            var path = model.get_path(iter);
            selection_changed(((Category) val), path.get_indices()[0]);
            selected_filter = ((Category) val);
            if (path.get_depth() < 2) {
                tree.collapse_all();
                tree.expand_to_path(path);
            }
            val.unset();
            return;
        }

    }

}
