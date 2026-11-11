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
        uint current_position = Gtk.INVALID_LIST_POSITION;
        string current_filter = "All";

        public BrowseFilterPopover (CategoryListModel category_model,
                                    CollectionListModel collection_model) {
            widget_set_name(this, "FontManagerBrowseFilterListView");
            set_position(Gtk.PositionType.TOP);
            categories = category_model;
            collections = collection_model;
            model = new GLib.ListStore(typeof(FontListFilter));
            selection = new Gtk.SingleSelection(model);
            selection.set_can_unselect(false);
            factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            list = new Gtk.ListView(selection, factory) {
                single_click_activate = true
            };
            list.activate.connect(on_list_activated);
            set_child(list);
            map.connect(on_map);
        }

        void on_list_activated (uint position) {
            var filter = (FontListFilter) model.get_item(position);
            current_position = position;
            current_filter = filter.name;
            selection_changed(filter);
            Idle.add(() => {
                popdown();
                return GLib.Source.REMOVE;
            });
            return;
        }

        void on_map () {
            model.remove_all();
            for (int i = 0; i <= CategoryIndex.USER; i++)
                model.append(categories.get_item(i));
            foreach (var collection in collections.items)
                model.append(collection);
            if (current_position != Gtk.INVALID_LIST_POSITION) {
                var target = (FontListFilter) model.get_item(current_position);
                if (target.name != current_filter) {
                    current_position = Gtk.INVALID_LIST_POSITION;
                    current_filter = "All";
                }
            }
            selection.set_selected(current_position);
        }

        void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            list_item.set_child(new BrowseFilterListRow());
            return;
        }

        void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var row = (BrowseFilterListRow) list_item.get_child();
            row.item = list_item.get_item();
            return;
        }

    }

}

