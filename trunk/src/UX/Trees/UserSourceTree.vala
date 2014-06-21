/* UserSourceTree.vala
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

    public class UserSourceTree : Gtk.ScrolledWindow {

        public signal void selection_changed (FontConfig.FontSource filter);
        public signal void add_source ();

        public weak UserSourceModel model {
            get {
                return _model;
            }
            set {
                _model = value;
                tree.set_model(_model);
                tree.get_selection().select_path(new Gtk.TreePath.first());
            }
        }

        public BaseControls controls { get; protected set; }
        public FontConfig.FontSource? selected_filter { get; protected set; default = null; }
        public Gtk.TreeView tree { get; protected set; }

        internal Gtk.CellRendererText renderer;
        internal Gtk.CellRendererPixbuf pixbuf_renderer;

        internal weak UserSourceModel _model;
        Gtk.CellRendererToggle toggle;

        public UserSourceTree () {
            tree = new Gtk.TreeView();
            renderer = new Gtk.CellRendererText();
            pixbuf_renderer = new Gtk.CellRendererPixbuf();
            pixbuf_renderer.set_property("xpad", 6);
            renderer.set_property("ellipsize", Pango.EllipsizeMode.END);
            renderer.set_property("ellipsize-set", true);
            toggle = new Gtk.CellRendererToggle();
            tree.insert_column_with_data_func(0, "", toggle, toggle_cell_data_func);
            tree.insert_column_with_data_func(1, "", pixbuf_renderer, pixbuf_cell_data_func);
            tree.insert_column_with_attributes(2, "", renderer, "text", 1, null);
            tree.get_column(0).expand = false;
            tree.get_column(1).expand = false;
            tree.get_column(2).expand = true;
            tree.set_headers_visible(false);
            tree.show_expanders = false;
            tree.get_selection().changed.connect(on_selection_changed);
            tree.show();
            controls = new SourceControls();
            controls.show();
            add(tree);
            connect_signals();
        }

        internal void connect_signals () {
            controls.add_selected.connect(() => { on_add_source(); });
            controls.remove_selected.connect(() => { on_remove_source(); });
            toggle.toggled.connect(on_toggled);
            return;
        }

        internal void on_add_source () {
            var new_sources = FileSelector.source_selection((Gtk.Window) this.get_toplevel());
            if (new_sources.length > 0) {
                foreach (var uri in new_sources)
                    model.add_source_from_uri(uri);
                Main.instance.update();
            }
            return;
        }

        internal void on_remove_source () {
            if (selected_filter == null)
                return;
            message("Removing font source : %s", selected_filter.path);
            selected_filter.active = false;
            model.sources.remove(selected_filter);
            model.sources.save();
            model.update();
            Main.instance.update();
            return;
        }

        public void select_first_row () {
            tree.get_selection().select_path(new Gtk.TreePath.first());
            return;
        }

        public void on_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, 0, out val);
            var source = (FontConfig.FontSource) val.get_object();
            if (source == null) {
                val.unset();
                return;
            }
            if (source.available)
                source.active = !source.active;
            val.unset();
            return;
        }

        void pixbuf_cell_data_func (Gtk.CellLayout layout,
                                      Gtk.CellRenderer cell,
                                      Gtk.TreeModel model,
                                      Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            var obj = val.get_object();
            if (obj == null) {
                val.unset();
                return;
            }
            var filetype = ((FontConfig.FontSource) obj).filetype;
            if (filetype == FileType.DIRECTORY || filetype == FileType.MOUNTABLE)
                cell.set_property("icon-name", "folder");
            else
                cell.set_property("icon-name", "font-x-generic");
            val.unset();
            return;
        }

        void toggle_cell_data_func (Gtk.CellLayout layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, 0, out val);
            var obj = (FontConfig.FontSource) val.get_object();
            if (obj == null) {
                val.unset();
                return;
            }
            if (obj.available) {
                cell.set_property("inconsistent", false);
                cell.set_property("active", obj.active);
            } else
                cell.set_property("inconsistent", true);
            val.unset();
            return;
        }

        void on_selection_changed (Gtk.TreeSelection selection) {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            GLib.Value val;
            if (!selection.get_selected(out model, out iter))
                return;
            model.get_value(iter, 0, out val);
            selection_changed(((FontConfig.FontSource) val));
            selected_filter = ((FontConfig.FontSource) val);
            val.unset();
            return;
        }

    }

}
