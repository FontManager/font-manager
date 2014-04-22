/* CollectionTree.vala
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

    public enum CollectionColumn {
        OBJECT,
        NAME,
        COMMENT,
        N_COLUMNS
    }

    public class CollectionTree : Gtk.ScrolledWindow {

        public signal void update_ui ();
        public signal void selection_changed (Collection group);
        public signal void rename_collection (Collection group, string new_name);

        public Collection? selected_collection { get; protected set; default = null; }

        public CollectionModel model {
            get {
                return _model;
            }
            set {
                _model = value;
                tree.set_model(value);
                tree.get_selection().select_path(new Gtk.TreePath.first());
                value.row_deleted.connect((t, p) => { update_and_cache_collections(); });
                value.row_inserted.connect((t, p, i) => { update_and_cache_collections(); });
                value.rows_reordered.connect((t, p, i) => { update_and_cache_collections(); });
                value.row_changed.connect((t, p, i) => { update_and_cache_collections(); });
            }
        }

        public FontConfig.Reject reject {
            get {
                return _reject;
            }
            set {
                _reject = value;
            }
        }

        public CollectionControls controls { get; protected set; }
        public Gtk.TreeView tree { get; protected set; }
        public Gtk.CellRendererText renderer { get; protected set; }
        public CellRendererCount count_renderer { get; protected set; }
        public Gtk.CellRendererPixbuf pixbuf_renderer { get; protected set; }

        Gtk.TreeIter selected_iter;
        CollectionModel _model;
        FontConfig.Reject _reject;

        public CollectionTree () {
            tree = new Gtk.TreeView();
            tree.name = "CollectionsTree";
            renderer = new Gtk.CellRendererText();
            count_renderer = new CellRendererCount();
            var toggle = new Gtk.CellRendererToggle();
            toggle.toggled.connect(on_collection_toggled);
            count_renderer.type_name = null;
            count_renderer.type_name_plural = null;
            count_renderer.xalign = 1.0f;
            renderer.set_property("ellipsize", Pango.EllipsizeMode.END);
            renderer.set_property("ellipsize-set", true);
            renderer.editable = true;
            tree.insert_column_with_data_func(0, "", toggle, toggle_cell_data_func);
            tree.insert_column_with_data_func(1, "", renderer, text_cell_data_func);
            tree.insert_column_with_data_func(2, "", count_renderer, count_cell_data_func);
            tree.get_column(0).expand = false;
            tree.get_column(1).expand = true;
            tree.get_column(2).expand = false;
            tree.set_headers_visible(false);
            controls = new CollectionControls();
            controls.show();
            tree.reorderable = true;
            tree.set_tooltip_column(CollectionColumn.COMMENT);
            tree.show();
            add(tree);
            connect_signals();
        }

        internal void connect_signals () {
            tree.get_selection().changed.connect(on_selection_changed);
            renderer.edited.connect(on_edited);
            controls.add_selected.connect(() => { on_add_collection(); });
            controls.remove_selected.connect(() => { on_remove_collection(); });
            return;
        }

        public void select_first_row () {
            tree.get_selection().select_path(new Gtk.TreePath.first());
            return;
        }

        public bool remove_fonts (Gee.ArrayList <string> fonts) {
            bool res = selected_collection.families.remove_all(fonts);
            Idle.add(() => {
                model.collections.cache();
                return false;
            });
            selected_collection.set_active_from_fonts(reject);
            return res;
        }

        public void on_add_collection (Gee.ArrayList <string>? families = null) {
            string default_collection_name = DEFAULT_COLLECTION_NAME;
            int i = 1;
            while (model.collections.entries.has_key(default_collection_name))
                default_collection_name = "%s %i".printf(DEFAULT_COLLECTION_NAME, i);
            var group = new Collection(default_collection_name);
            if (families != null) {
                group.families.add_all(families);
                group.set_active_from_fonts(reject);
            }
            model.collections.entries[default_collection_name] = group;
            Gtk.TreeIter iter;
            model.append(out iter, null);
            model.set(iter, 0, group, 1, group.comment, -1);
            tree.grab_focus();
            tree.set_cursor(model.get_path(iter), tree.get_column(CollectionColumn.NAME), true);
            return;
        }

        public void on_remove_collection () {
            if (!model.iter_is_valid(selected_iter))
                return;
            var collections = model.collections.entries;
            if (collections.has_key(selected_collection.name))
                collections.unset(selected_collection.name);
            ((Gtk.TreeStore) model).remove(ref selected_iter);
            return;
        }

        public void on_export_collection () {
            NotImplemented.run("Exporting collections");
            return;
        }

        void on_edited (Gtk.CellRendererText renderer, string path, string new_text) {
            string new_name = new_text.strip();
            if (new_name == selected_collection.name || new_name == "" || model.collections.entries.has_key(new_name)) {
                return;
            } else if (new_name == DEFAULT_COLLECTION_NAME) {
                Idle.add(() => {
                    tree.grab_focus();
                    tree.set_cursor(new Gtk.TreePath.from_string(path), tree.get_column(CollectionColumn.NAME), true);
                    return false;
                });
                return;
            }
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, CollectionColumn.OBJECT, out val);
            var group = (Collection) val.get_object();
            rename_collection(group, new_name);
            val.unset();
            Idle.add(() => {
                model.collections.cache();
                return false;
            });
            return;
        }

        void on_collection_toggled (string path) {
            Gtk.TreeIter iter;
            Value val;
            model.get_iter_from_string(out iter, path);
            model.get_value(iter, CollectionColumn.OBJECT, out val);
            var group = (Collection) val.get_object();
            group.active = !(group.active);
            group.update(reject);
            group.set_active_from_fonts(reject);
            val.unset();
            update_ui();
            Idle.add(() => {
                model.collections.cache();
                return false;
            });
            return;
        }

        void on_selection_changed (Gtk.TreeSelection selection) {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            GLib.Value val;
            if (!selection.get_selected(out model, out iter))
                return;
            model.get_value(iter, 0, out val);
            selection_changed(((Collection) val));
            selected_collection = ((Collection) val);
            selected_iter = iter;
            val.unset();
            return;
        }

        void text_cell_data_func (Gtk.CellLayout layout,
                                   Gtk.CellRenderer cell,
                                   Gtk.TreeModel model,
                                   Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, CollectionColumn.OBJECT, out val);
            var obj = (Collection) val.get_object();
            cell.set_property("text", obj.name);
            val.unset();
            return;
        }

        void toggle_cell_data_func (Gtk.CellLayout layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, CollectionColumn.OBJECT, out val);
            var obj = (Collection) val.get_object();
            cell.set_property("active", obj.active);
            val.unset();
            return;
        }

        void count_cell_data_func (Gtk.CellLayout layout,
                                    Gtk.CellRenderer cell,
                                    Gtk.TreeModel model,
                                    Gtk.TreeIter treeiter) {
            Value val;
            model.get_value(treeiter, CollectionColumn.OBJECT, out val);
            var obj = (Collection) val.get_object();
            cell.set_property("count", obj.size());
            val.unset();
            return;
        }

        void update_and_cache_collections () {
            model.update_group_index();
            Idle.add(() => {
                model.collections.cache();
                return false;
            });
            return;
        }

    }

}
