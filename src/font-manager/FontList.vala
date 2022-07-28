/* FontList.vala
 *
 * Copyright (C) 2020-2022 Jerry Casiano
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

internal int64 GET_INDEX (Json.Object o) { return o.get_int_member("_index"); }

const string search_tip = _("""Case insensitive search of family names.

Start search using %s to filter based on filepath.
Start search using %s to filter based on characters.""");

namespace FontManager {

    public class BaseFontModel : Object, ListModel {

        public Type item_type { get; protected set; default = typeof(Object); }
        public Json.Array? entries { get; set; default = null; }
        public GenericArray <unowned Json.Object>? items { get; protected set; default = null; }

        public string? search_term { get; set; default = null; }
        public FontListFilter? filter { get; set; default = null; }

        construct {
            notify["entries"].connect(() => { update_items(); });
            notify["filter"].connect(() => { update_items(); });
        }

        public Type get_item_type () {
            return item_type;
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position) {
            return_val_if_fail(items[position] != null, null);
            Object retval = Object.new(item_type);
            retval.set("source-object", items[position], null);
            return retval;
        }

        string get_filepath_from_object (Json.Object item) {
            Object obj = Object.new(item_type);
            obj.set("source-object", item, null);
            return (item_type == typeof(Font)) ?
                   ((Font) obj).filepath :
                   (item_type == typeof(Family)) ?
                   ((Family) obj).get_default_variant().get_string_member("filepath") :
                   "";
        }

        bool matches_search_term (Json.Object item) {
            bool item_matches = true;
            if (search_term == null || search_term.strip() == "")
                return item_matches;
            var search = search_term.strip();
            if (search.has_prefix(Path.DIR_SEPARATOR_S)) {
                string filepath = get_filepath_from_object(item);
                item_matches = filepath.contains(search);
            } else if (search.has_prefix(Path.SEARCHPATH_SEPARATOR_S)) {
                // string needle = search.replace(Path.SEARCHPATH_SEPARATOR_S, "");
                // string family = item.get_string_member("family");
                // XXX : FIXME!
            } else {
                string family = item.get_string_member("family").casefold();
                item_matches = family.contains(search.casefold());
            }
            return item_matches;
        }

        bool matches_filter (Json.Object item) {
            if (filter == null)
                return true;
            Object? object = null;
            if (item.has_member("filepath"))
                object = new Font();
            else
                object = new Family();
            object.set(JSON_PROXY_SOURCE, item, null);
            return filter.matches(object);
        }

        public void update_items () {
            uint n_items = get_n_items();
            items = null;
            items = new GenericArray <unowned Json.Object> ();
            items_changed(0, n_items, 0);
            if (entries != null) {
                entries.foreach_element((array, index, node) => {
                    Json.Object item = node.get_object();
                    if (matches_search_term(item) && matches_filter(item)) {
                        if (item.has_member("variations")) {
                            Json.Array variants = item.get_array_member("variations");
                            int n_matches = 0;
                            variants.foreach_element((a, i, n) => {
                                Json.Object v = n.get_object();
                                if (matches_search_term(v) && matches_filter(v))
                                    n_matches++;
                            });
                            item.set_int_member("n-variations", n_matches);
                        }
                        items.add(item);
                    }
                });
                items.sort((a, b) => {
                    return (int) (GET_INDEX(a) - GET_INDEX(b));
                });
            }
            items_changed(0, 0, get_n_items());
            return;
        }

    }

    public class FontModel : BaseFontModel {

        construct {
            item_type = typeof(Family);
        }

        class VariantModel : BaseFontModel {

            construct {
                item_type = typeof(Font);
            }

        }

        public ListModel? get_child_model (Object item) {
            if (!(item is Family))
                return null;
            var child = new VariantModel();
            BindingFlags flags = BindingFlags.SYNC_CREATE;
            bind_property("filter", child, "filter", flags, null, null);
            bind_property("search-term", child, "search-term", flags, null, null);
            child.entries = ((Family) item).variations;
            return child;
        }

    }

    public class FontListBoxRow : ItemListBoxRow {

        Binding? binding = null;

        construct {
            notify["item"].connect(on_item_set);
        }

        void reset_row () {
            if (binding != null)
                binding.unbind();
            binding = null;
            item_state.set("active", true, "visible", true, "sensitive", true, null);
            item_name.set_label("");
            item_preview.set_attributes(null);
            item_preview.set_label("");
            item_count.visible = true;
            item_count.set_label("");
            return;
        }

        public void on_item_set (ParamSpec pspec) {
            reset_row();
            if (item == null)
                return;
            bool root = item is Family;
            BindingFlags flags = BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL;
            binding = item.bind_property("active", item_state, "active", flags, null, null);
            item_name.set_label(root ? ((Family) item).family : "");
            item_state.set("sensitive", root, "visible", root, null);
            item_count.visible = root;
            string desc = root ? "" : ((Font) item).description;
            Pango.FontDescription font_desc = Pango.FontDescription.from_string(desc);
            Pango.AttrList attrs = new Pango.AttrList();
            attrs.insert(new Pango.AttrFontDesc(font_desc));
            attrs.insert(Pango.attr_fallback_new(false));
            item_preview.set_attributes(attrs);
            item_preview.set_label(root ? "" : ((Font) item).description);
            if (root) {
                var count = (int) ((Family) item).n_variations;
                var label = ngettext("%i Variation ", "%i Variations", (ulong) count);
                item_count.set_label(label.printf(count));
            }
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-list-view.ui")]
    public class FontListView : Gtk.Box {

        public signal void selection_changed (Object? item);

        public Object? selected_item { get; set; default = null; }
        public FontListFilter filter { get; set; default = null; }

        public BaseFontModel model {
            get {
                return ((BaseFontModel) treemodel.model);
            }
        }

        public Json.Array? available_fonts {
            get {
                return model.entries;
            }
            set {
                model.entries = value;
            }
        }

        [GtkChild] unowned Gtk.ListView listview;
        [GtkChild] unowned Gtk.Expander expander;
        [GtkChild] unowned Gtk.SearchEntry search;

        uint search_timeout = 0;
        Gtk.TreeListModel treemodel;
        Gtk.MultiSelection selection;

        construct {
            var fontmodel = new FontModel();
            treemodel = new Gtk.TreeListModel(fontmodel,
                                              false,
                                              false,
                                              fontmodel.get_child_model);
            selection = new Gtk.MultiSelection(treemodel);
            listview.set_factory(get_factory());
            listview.set_model(selection);
            selection.selection_changed.connect(on_selection_changed);
            if (Environment.get_variable("G_MESSAGES_DEBUG") != null) {
                selection_changed.connect(() => {
                    string? description = null;
                    selected_item.get("description", out description, null);
                    debug("selection_changed : %s", description);
                });
            }
            // BindingFlags flags = BindingFlags.SYNC_CREATE;
            // bind_property("filter", fontmodel, "filter", flags, null, null);
            // XXX : Nasty? workaround for lag caused by category selection
            // See on_expander_activated for more details.
            notify["filter"].connect((pspec) => {
                bool expanded = expander.expanded;
                if (expanded)
                    expander.activate();
                fontmodel.filter = filter;
                if (expanded)
                    expander.activate();
            });
            search.search_changed.connect(queue_refilter);
            search.activate.connect(next_match);
            search.next_match.connect(next_match);
            search.previous_match.connect(previous_match);
            search.set_tooltip_text(search_tip.printf(Path.DIR_SEPARATOR_S,
                                                      Path.SEARCHPATH_SEPARATOR_S));
        }

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

        void setup_list_row (Gtk.ListItem list_item) {
            var tree_expander = new Gtk.TreeExpander();
            tree_expander.set_child(new FontListBoxRow());
            list_item.set_child(tree_expander);
            return;
        }

        void bind_list_row (Gtk.ListItem list_item) {
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.margin_start = 2;
            tree_expander.set_list_row(null);
            var row = (FontListBoxRow) tree_expander.get_child();
            Object? item = list_row.get_item();
            // Setting item triggers update to row widgets
            row.item = item;
            return_if_fail(item != null);
            bool parent = item is Family;
            tree_expander.set_list_row(parent ? list_row : null);
            return;
        }

        void queue_update () {
            Idle.add(() => {
                model.search_term = search.text.strip();
                model.update_items();
                // Try to prevent some rendering artifacts
                listview.queue_draw();
                return GLib.Source.REMOVE;
            });
            return;
        }

        public void select_item (uint position) {
            listview.activate_action("list.select-item", "(ubb)", position, false, false);
            listview.activate_action("list.scroll-to-item", "u", position);
            return;
        }

        void next_match (Gtk.SearchEntry entry) {
            select_item(selection.get_selection().get_minimum() + 1);
            return;
        }

        void previous_match (Gtk.SearchEntry entry) {
            select_item(selection.get_selection().get_minimum() - 1);
            return;
        }

        bool refilter () {
            queue_update();
            search_timeout = 0;
            return GLib.Source.REMOVE;
        }

        // Add slight delay to avoid filtering while search is still changing
        public void queue_refilter () {
            if (search_timeout != 0)
                GLib.Source.remove(search_timeout);
            search_timeout = Timeout.add(333, refilter);
            return;
        }

        // NOTE:
        // @position doesn't necessarily point to the actual selection
        // within the TreeListModel, the actual selection lies somewhere
        // between @position + @n_items. The precise location within that
        // range appears to be affected by a variety of factors i.e.
        // previous selection, multiple selections, directional changes, etc.
        void on_selection_changed (uint position, uint n_items) {
            // The minimum value present in this bitset accurately points
            // to the first currently selected row in the ListView.
            Gtk.Bitset selections = selection.get_selection();
            uint i = selections.get_minimum();
            var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
            Object? item = list_row.get_item();
            selected_item = item;
            selection_changed(item);
            return;
        }

        // XXX : FIXME : This may need to be removed...
        // Expanding all rows can cause significant lag in the interface
        // especially when all rows are expanded during category selection.
        // This is very noticeable even with categories containing as little
        // as a hundred entries, with rows collapsed switching categories
        // happens almost instantly regardless of quantity which seems to
        // indicate that the issue is likely not caused by our models ?
        [GtkCallback]
        void on_expander_activated (Gtk.Expander _expander) {
            bool expanded = expander.expanded;
            treemodel.set_autoexpand(expanded);
            expander.set_tooltip_text(expanded ? _("Collapse all") : _("Expand all"));
            queue_update();
            return;
        }

    }

}

