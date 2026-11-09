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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-browse-filter-list-row.ui")]
    public class BrowseFilterListRow : Gtk.Box {

        public Object? item { get; set; default = null; }

        [GtkChild] unowned Gtk.Label item_label;
        [GtkChild] unowned Gtk.Label item_count;

        construct {
            notify["item"].connect((pspec) => { on_item_set(); });
        }

        public void reset () {
            item_count.set_label("");
            item_label.set_label("");
            return;
        }

        protected void on_item_set () {
            reset();
            if (item == null)
                return;
            var filter = (FontListFilter) item;
            item_count.set_label(filter.size.to_string());
            item_label.set_label(filter.name);
            return;
        }

    }

    public class BrowseFilterPopover : Gtk.Popover {

        public signal void selection_changed (FontListFilter? filter);

        public Gtk.SingleSelection selection { get; private set; }
        public CategoryListModel categories { get; private set; }
        public CollectionListModel collections { get; private set; }

        Gtk.ListView list;
        GLib.ListStore model;
        Gtk.SignalListItemFactory factory;
        FontListFilter? current_selection = null;

        public BrowseFilterPopover (CategoryListModel category_model,
                                    CollectionListModel collection_model) {
            widget_set_name(this, "FontManagerBrowseFilterListView");
            widget_set_expand(this, true);
            categories = category_model;
            collections = collection_model;
            model = new GLib.ListStore(typeof(FontListFilter));
            selection = new Gtk.SingleSelection(model);
            selection.set_can_unselect(false);
            factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            list = new Gtk.ListView(selection, factory);
            update();
            set_child(list);
            map.connect(() => { update(); });
            selection.selection_changed.connect(on_selection_changed);
        }

        public void update () {
            model.remove_all();
            for (int i = 0; i <= CategoryIndex.USER; i++)
                model.append(categories.get_item(i));
            foreach (var collection in collections.items)
                model.append(collection);
            selection.set_selected(get_current_index());
        }

        protected void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            list_item.set_child(new BrowseFilterListRow());
            return;
        }

        protected void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var row = (BrowseFilterListRow) list_item.get_child();
            row.item = list_item.get_item();
            return;
        }

        int get_current_index () {
            if (current_selection == null || model == null)
                return CategoryIndex.ALL;
            for (int i = 0; i < model.get_n_items(); i++) {
                var entry_name = ((FontListFilter) model.get_item(i)).name;
                if (current_selection.name == entry_name)
                    return i;
            }
            return CategoryIndex.ALL;
        }

        void on_selection_changed (uint position, uint n_items)
        requires (selection != null && model != null) {
            // position is not accurate, not reliably accurate anyway...
            // The minimum value present in this bitset accurately points
            // to the currently selected row in the ListView.
            Gtk.Bitset selections = selection.get_selection();
            if (selections.get_size() == 0)
                return;
            uint i = selections.get_minimum();
            Object? item = model.get_item(i);
            current_selection = (FontListFilter) item;
            selection_changed(current_selection);
            return;
        }

    }

}

