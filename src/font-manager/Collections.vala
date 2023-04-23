/* Collections.vala
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

    const string DEFAULT_COLLECTION_NAME = _("Enter Collection Name");

    public class CollectionListModel : FontListFilterModel {

        public static string get_cache_file () {
            string dirpath = get_package_config_directory();
            //  XXX : FIXME!
            string filepath = Path.build_filename(dirpath, "CollectionsTest.json");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        public static ListModel? get_child_model (Object item) {
            var collection = ((Collection) item);
            var child = new CollectionListModel();
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            collection.bind_property("children", child, "items", flags);
            return child;
        }

        void add_from_json_node (Json.Node node) {
            Object collection = Json.gobject_deserialize(typeof(Collection), node);
            add_item((Collection) collection);
            return;
        }

        public void load () {
            Json.Node? root = load_json_file(get_cache_file());
            if (root == null)
                return;
            Json.NodeType node_type = root.get_node_type();
            if (node_type == Json.NodeType.ARRAY) {
                Json.Array array = root.get_array();
                array.foreach_element((a, i, n) => { add_from_json_node(n); });
            } else if (node_type == Json.NodeType.OBJECT) {
                // For compatibility with previous version
                Json.Object obj = root.get_object();
                assert(obj.has_member("entries"));
                Json.Object entries = obj.get_object_member("entries");
                entries.foreach_member((o, s, n) => { add_from_json_node(n); });
            } else {
                assert_not_reached();
            }
            return;
        }

        public bool save () {
            var node = new Json.Node(Json.NodeType.ARRAY);
            var array = new Json.Array();
            foreach (var collection in items)
                array.add_element(Json.gobject_serialize(collection));
            node.set_array(array);
            return write_json_file(node, get_cache_file(), true);
        }

    }

    public class CollectionListRow : TreeListItemRow {

        public signal void changed ();

        ulong change_handler = 0;
        Binding? name_binding = null;
        Binding? state_binding = null;

        construct {
            margin_start = 0;
            item_state.visible = true;
            item_state.active = false;
            item_count.visible = true;
        }

        public override void reset () {
            if (change_handler != 0)
                item.disconnect(change_handler);
            if (state_binding != null)
                state_binding.unbind();
            if (name_binding != null)
                name_binding.unbind();
            change_handler = 0;
            state_binding = null;
            name_binding = null;
            return;
        }

        protected override void on_item_set () {
            if (item == null)
                return;
            var collection = (Collection) item;
            item_icon.visible = collection.icon != null;
            if (item_icon.visible)
                item_icon.set_from_icon_name(collection.icon);
            item_count.set_label(collection.size.to_string());
            change_handler = collection.changed.connect(() => { changed(); });
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            name_binding = collection.bind_property("name", item_label, "label", flags);
            state_binding = collection.bind_property("active", item_state, "active", flags);
            return;
        }

    }

    // TODO :
    //      - F2 shortcut to rename collections
    //      - Context menu (base class has virtual method)

    public class CollectionListView : FilterListView {

        uint update_timeout = 0;

        construct {
            widget_set_name(listview, "FontManagerCollectionListView");
            var collection_model = new CollectionListModel();
            collection_model.load();
            treemodel = new Gtk.TreeListModel(collection_model,
                                              false,
                                              true,
                                              CollectionListModel.get_child_model);
            selection = new Gtk.SingleSelection(treemodel);
            add_drop_target(listview);
        }

        ~ CollectionListView () {
            ((CollectionListModel) model).save();
        }

        bool update () {
            // Force complete update
            listview.set_model(null);
            listview.set_model(selection);
            update_timeout = 0;
            return GLib.Source.REMOVE;
        }

        public void queue_update () {
            if (update_timeout != 0)
                GLib.Source.remove(update_timeout);
            update_timeout = Timeout.add(333, update);
            return;
        }

        protected override void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tree_expander = new Gtk.TreeExpander();
            tree_expander.set_indent_for_icon(false);
            var row = new CollectionListRow();
            row.expander = tree_expander;
            row.selection = selection;
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            add_drag_source(row);
            add_drop_target(row);
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.set_list_row(list_row);
            var row = (CollectionListRow) tree_expander.get_child();
            Object? object = list_row.get_item();
            var collection = (Collection) object;
            collection.depth = (int) list_row.get_depth();
            // Setting item triggers update to row widget
            row.reset();
            row.item = object;
            // Nesting is allowed so we need the entire list refreshed if a
            // single row changes otherwise parent nodes would not update
            row.changed.connect(queue_update);
            return;
        }

        // BEGIN - COLLECTION DRAG AND DROP SUPPORT

        void add_drop_target (Gtk.Widget widget) {
            Gdk.DragAction actions = Gdk.DragAction.COPY | Gdk.DragAction.MOVE;
            var target = new Gtk.DropTarget(Type.INVALID, actions);
            target.set_gtypes({ typeof(FontListFilter), typeof(GenericArray) });
            widget.add_controller(target);
            target.accept.connect(on_accept_drop);
            target.drop.connect(on_drop);
            return;
        }

        void add_drag_source (CollectionListRow row) {
            var drag_source = new Gtk.DragSource();
            row.add_controller(drag_source);
            drag_source.prepare.connect(on_prepare_drag);
            drag_source.drag_begin.connect(on_drag_begin);
            drag_source.drag_end.connect(on_drag_end);
            drag_source.set_actions(Gdk.DragAction.MOVE);
            return;
        }

        Gdk.ContentProvider on_prepare_drag (Gtk.DragSource source, double x, double y) {
            var row = ((CollectionListRow) source.widget);
            Value selection = Value(typeof(FontListFilter));
            selection.set_object((FontListFilter) row.item);
            return new Gdk.ContentProvider.for_value(selection);
        }

        void on_drag_begin (Gtk.DragSource source, Gdk.Drag drag) {
            var row = ((CollectionListRow) source.widget);
            var drag_icon = new Gtk.Label(row.item_label.label);
            drag_icon.add_css_class("FontManagerListRowDrag");
            var gtk_drag_icon = (Gtk.DragIcon) Gtk.DragIcon.get_for_drag(drag);
            gtk_drag_icon.set_child(drag_icon);
            return;
        }

        Gtk.TreeListRow? get_list_row_for_widget (Gtk.Widget widget) {
            var e_type = typeof(Gtk.TreeExpander);
            var expander = (Gtk.TreeExpander) widget.get_ancestor(e_type);
            return (Gtk.TreeListRow) expander.get_list_row();
        }

        void on_drag_end (Gtk.DragSource source, Gdk.Drag drag, bool delete_data) {
            // Only handle move operations
            if (!delete_data)
                return;
            Gtk.TreeListRow? list_row = get_list_row_for_widget(source.widget);
            return_if_fail(list_row != null);
            FontListFilterModel target_model = model;
            Gtk.TreeListRow? parent_row = list_row.get_parent();
            Collection? dropped_collection = null;
            try {
                var content = drag.content;
                Value val = Value(typeof(FontListFilter));
                content.get_value(ref val);
                dropped_collection = (Collection) val.get_object();
            } catch (Error e) {
                warning(e.message);
                dropped_collection = ((Collection) list_row.item);
            }
            if (parent_row != null)
                target_model = ((FontListFilterModel) parent_row.get_children());
            else
                parent_row = list_row;
            target_model.remove_item(dropped_collection);
            parent_row.set_expanded((target_model.get_n_items() != 0));
            // Necessary to update parent row count label
            queue_update();
            return;
        }

        bool on_accept_drop (Gtk.DropTarget target, Gdk.Drop drop) {
            var formats = drop.drag.content.formats;
            if (formats.contain_gtype(typeof(GenericArray)))
                return (target.widget is CollectionListRow);
            if (!(formats.contain_gtype(typeof(FontListFilter))))
                return false;
            Collection? dropped_collection = null;
            try {
                var content = drop.drag.content;
                Value? val = Value(typeof(Object));
                content.get_value(ref val);
                Object object = val.get_object();
                dropped_collection = (Collection) object;
            } catch (Error e) {
                warning(e.message);
                return false;
            }
            if (target.widget is CollectionListRow) {
                Gtk.TreeListRow? list_row = get_list_row_for_widget(target.widget);
                return_val_if_fail(list_row != null, false);
                Gtk.TreeListRow? parent_row = list_row.get_parent();
                while (parent_row != null) {
                    Collection? parent = ((Collection) parent_row.item);
                    // Say no to recursive collection practices
                    if (dropped_collection == parent)
                        return false;
                    parent_row = parent_row.get_parent();
                }
                Collection target_collection = (Collection) list_row.item;
                // Reject duplicate drops
                if (target_collection.contains(dropped_collection))
                    return false;
            }
            return (target.widget is CollectionListRow ||
                    target.widget is Gtk.ListView &&
                    target.widget.name == listview.name &&
                    dropped_collection.depth > 0);
        }

        bool on_external_drop (Gtk.DropTarget target, Value val, double x, double y) {
            var objects = (GenericArray <Object>) val;
            Gtk.TreeListRow? list_row = get_list_row_for_widget(target.widget);
            return_val_if_fail(list_row != null, false);
            Collection? collection = ((Collection) list_row.item);
            foreach (var object in objects) {
                if (object is Family)
                    collection.families.add(((Family) object).family);
            }
            queue_update();
            return true;
        }

        bool on_drop (Gtk.DropTarget target, Value val, double x, double y) {
            if (val.holds(typeof(GenericArray)))
                return on_external_drop(target, val, x, y);
            return_val_if_fail(val.holds(typeof(FontListFilter)), false);
            var widget = target.widget;
            var filter = (Collection) val.get_object();
            filter.depth = 0;
            FontListFilterModel? target_model = model;
            if (widget is CollectionListRow) {
                Gtk.TreeListRow? list_row = get_list_row_for_widget(target.widget);
                return_val_if_fail(list_row != null, false);
                Collection? collection = ((Collection) list_row.item);
                return_val_if_fail(collection != null, false);
                if (collection.contains(filter))
                    return false;
                target_model = (FontListFilterModel) list_row.get_children();
                filter.depth = (int) list_row.depth + 1;
            }
            if (target_model == null)
                return false;
            target_model.add_item(filter);
            return true;
        }

        // END - COLLECTION DRAG AND DROP SUPPORT

    }

}

