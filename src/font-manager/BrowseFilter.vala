/* BrowseFilter.vala
 *
 * Copyright (C) 2020-2026 Jerry Casiano
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

    public class BrowseFilterListRow : TreeListItemRow {

        construct {
            margin_start = 0;
            item_count.visible = true;
            drag_handle.visible = false;
            item_state.visible = false;
            editable = false;
        }

        public override void reset () {
            item_count.set_label(null);
            item_label.set_label(null);
            return;
        }

        protected override void on_item_set () {
            reset();
            if (item == null)
                return;
            var filter = (FontListFilter) item;
            item_count.set_label(filter.size.to_string());
            item_label.set_label(filter.name);
            return;
        }

    }

    public class BrowseFilterListView : FilterListView {

        uint update_timeout = 0;

        construct {
            widget_set_name(listview, "FontManagerBrowseFilterListView");
        }

        public static ListModel? get_null_model (Object item) {
            return null;
        }

        public void set_model (CollectionListModel? model) {
            if (model != null) {
                treemodel = new Gtk.TreeListModel(model,
                                                  false,
                                                  true,
                                                  get_null_model);
                selection = new Gtk.SingleSelection(treemodel);
                model.changed.connect(() => { queue_update(); });
            } else {
                selection = new Gtk.SingleSelection(null);
            }
            return;
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
            var row = new BrowseFilterListRow();
            row.expander = tree_expander;
            row.selection = selection;
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            return;
        }

        protected override void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            uint position = list_item.get_position();
            var list_row = treemodel.get_row(position);
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.set_list_row(list_row);
            var row = (BrowseFilterListRow) tree_expander.get_child();
            Object? object = list_row.get_item();
            var collection = (Collection) object;
            collection.depth = (int) list_row.get_depth();
            // Setting item triggers update to row widget
            row.item = object;
            return;
        }

    }

    class BrowseFilterPopover : Gtk.Popover {

        public signal void selection_changed (FontListFilter? filter);

        CollectionListModel model;
        BrowseFilterListView view;
        CollectionListModel _model;

        ulong signal_id = 0;
        FontListFilter? current_selection = null;

        public BrowseFilterPopover (CollectionListModel? collection_model) {
            _model = collection_model;
            model = new CollectionListModel();
            view = new BrowseFilterListView();
            on_map();
            set_child(view);
            map.connect(on_map);
        }

        void connect_selection_signal () {
            signal_id = view.selection_changed.connect((f) => {
                current_selection = f;
                selection_changed(f);
                Idle.add(() => {
                    popdown();
                    return GLib.Source.REMOVE;
                });
            });
            return;
        }

        int get_current_index () {
            if (current_selection == null || model == null)
                return CategoryIndex.ALL;
            for (int i = 0; i < model.items.length; i++)
                if (current_selection.name == model.items[i].name)
                    return i;
            return CategoryIndex.ALL;
        }

        void on_map () {
            view.set_model(null);
            model.items = null;
            model.items = new GenericArray <FontListFilter> ();
            foreach (var collection in _model.items)
                model.items.add(collection);
            var categories = get_base_categories();
            var category = ((Category) categories[CategoryIndex.ALL]);
            var collection = new Collection(category.name, null);
            category.update.begin(() => {
                collection.add(category.families);
                model.items.insert(CategoryIndex.ALL, collection);
                category = ((Category) categories[CategoryIndex.SYSTEM]);
                collection = new Collection(category.name, null);
                category.update.begin(() => {
                    collection.add(category.families);
                    model.items.insert(CategoryIndex.SYSTEM, collection);
                    category = ((Category) categories[CategoryIndex.USER]);
                    collection = new Collection(category.name, null);
                    category.update.begin(() => {
                        collection.add(category.families);
                        model.items.insert(CategoryIndex.USER, collection);
                        view.set_model(model);
                        if (signal_id !=  0)
                            SignalHandler.disconnect(view, signal_id);
                        view.selection.set_selected(get_current_index());
                        connect_selection_signal();
                    });
                });
            });
            return;
        }

    }

}

