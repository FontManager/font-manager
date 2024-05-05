/* FontListFilter.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public int filter_sort (FontListFilter a, FontListFilter b) {
        return (a.index - b.index);
    }

    public class FontListFilter : Cacheable {

        public virtual string name { owned get; set; }
        public virtual string icon { owned get; set; }
        public virtual string comment { owned get; set; }
        public virtual int index { get; set; default = 0; }
        public virtual int size { get { return 0; } }
        public virtual int depth { get; set; default = 0; }

        public bool requires_update { get; set; default = true; }

        public virtual async void update (StringSet? available_fonts) {}

        public virtual bool matches (Object? item) {
            return item != null ? true : false;
        }

    }

    public class FontListFilterModel : Object, ListModel {

        public GenericArray <FontListFilter>? items { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }

        construct {
            items = new GenericArray <FontListFilter> ();
        }

        public Type get_item_type () {
            return typeof(FontListFilter);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position) {
            return_val_if_fail(items[position] != null, null);
            return items[position];
        }

        public void add_item (FontListFilter item) {
            items.add(item);
            item.index = (int) get_n_items() - 1;
            items_changed(item.index, 0, 1);
            item.changed.connect(() => {
                int n_items = (int) items.length;
                items_changed(0, n_items, n_items);
            });
            return;
        }

        public void remove_item (FontListFilter item) {
            for (uint i = 0; i < items.length; i++)
                if (items[i] == item)
                    if (items.remove(item))
                        items_changed(i, 1, 0);
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-filter-list-view.ui")]
    public class FilterListView : Gtk.Box {

        public signal void selection_changed (FontListFilter? item);

        public uint selected_position { get; set; default = 0; }
        public FontListFilter? selected_item { get; set; default = null; }
        public StringSet? available_families { get; set; default = null; }
        public Gtk.TreeListModel? treemodel { get; protected set; default = null; }
        public Gtk.SingleSelection? selection { get; protected set; default = null; }

        public FontListFilterModel? model {
            get {
                return treemodel != null ? ((FontListFilterModel) treemodel.model) : null;
            }
        }

        [GtkChild] protected unowned Gtk.ListView listview;

        construct {
            Gtk.Gesture right_click = new Gtk.GestureClick() {
                button = Gdk.BUTTON_SECONDARY
            };
            ((Gtk.GestureClick) right_click).pressed.connect(on_show_context_menu);
            listview.add_controller(right_click);
            notify["selection"].connect_after((pspec) => {
                listview.set_model(selection);
                listview.set_factory(get_factory());
                if (selection == null)
                    return;
                selection.set_autoselect(false);
                selection.set_can_unselect(true);
                selection.selection_changed.connect(on_selection_changed);
            });
            notify["available-families"].connect_after((pspec) => {
                BindingFlags flags = BindingFlags.SYNC_CREATE;
                bind_property("available-families", model, "available-families", flags, null, null);
            });
        }

        protected virtual void on_show_context_menu (int n_press, double x, double y) {}
        protected virtual void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {}
        protected virtual void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {}

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

        protected virtual void collapse_all ()
        requires (treemodel != null) {
            uint n_items = treemodel.get_n_items();
            for (uint i = 0; i < n_items; i++) {
                var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
                if (list_row != null && list_row.expanded)
                    list_row.set_expanded(false);
            }
            return;
        }

        protected virtual void on_row_selected (Gtk.TreeListRow row) {
            if (selected_item.depth > 0)
                return;
            collapse_all();
            if (row.expandable)
                row.set_expanded(true);
            return;
        }

        // NOTE:
        // @position doesn't necessarily point to the actual selection
        // within the ListView, the actual selection lies somewhere
        // between @position + @n_items. The precise location within that
        // range appears to be affected by a variety of factors i.e.
        // previous selection, multiple selections, directional changes, etc.
        protected virtual void on_selection_changed (uint position, uint n_items)
        requires (selection != null && treemodel != null) {
            // The minimum value present in this bitset accurately points
            // to the first currently selected row in the ListView.
            Gtk.Bitset selections = selection.get_selection();
            if (selections.get_size() == 0)
                return;
            uint i = selections.get_minimum();
            var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
            Object? item = list_row.get_item();
            selected_item = (FontListFilter) item;
            selected_position = i;
            selection_changed((FontListFilter) item);
            Idle.add(() => {
                on_row_selected(list_row);
                return GLib.Source.REMOVE;
            });
            debug("%s::selection_changed : %s", listview.name, selected_item.name);
            return;
        }

    }

}

