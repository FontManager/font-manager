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

namespace FontManager {

    public class BaseFontModel : Object, ListModel {

        public Type item_type { get; protected set; default = typeof(Object); }
        public Json.Array? entries { get; set; default = null; }
        public GenericArray <unowned Json.Object>? items { get; protected set; default = null; }

        public string? search_term { get; set; default = null; }

        construct {
            notify["entries"].connect(() => { update_items(); });
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
            if (search_term == null || search_term == "")
                return item_matches;
            if (search_term.has_prefix(Path.DIR_SEPARATOR_S)) {
                string filepath = get_filepath_from_object(item);
                item_matches = filepath.contains(search_term);
            } else if (search_term.has_prefix(Path.SEARCHPATH_SEPARATOR_S)) {
                // string needle = search_term.replace(Path.SEARCHPATH_SEPARATOR_S, "");
                // string family = item.get_string_member("family");
                // XXX : FIXME!
            } else {
                string family = item.get_string_member("family").casefold();
                item_matches = family.contains(search_term.casefold());
            }
            return item_matches;
        }

        bool matches_filter (Json.Object item) {
            // XXX : FIXME!
            return true;
        }

        public void update_items () {
            uint n_items = get_n_items();
            items = null;
            items = new GenericArray <unowned Json.Object> ();
            items_changed(0, n_items, 0);
            if (entries != null) {
                entries.foreach_element((array, index, node) => {
                    Json.Object item  = node.get_object();
                    if (matches_search_term(item) && matches_filter(item))
                        items.add(item);
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

        public static ListModel? get_child_model (Object item) {
            if (!(item is Family))
                return null;
            var child = new VariantModel();
            child.entries = ((Family) item).variations;
            return child;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-list-box-row.ui")]
    public class FontListBoxRow : Gtk.Box {

        public Object? item { get; set; default = null; }

        [GtkChild] public unowned Gtk.CheckButton item_state { get; }
        [GtkChild] public unowned Gtk.Label item_name { get; }
        [GtkChild] public unowned Gtk.Label item_preview { get; }
        [GtkChild] public unowned Gtk.Label item_count { get; }

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

        public Gtk.TreeListModel model { get; private set; default = null; }

        public BaseFontModel font_model {
            get {
                return ((BaseFontModel) model.model);
            }
        }

        public Json.Array? available_fonts {
            get {
                return font_model.entries;
            }
            set {
                font_model.entries = value;
            }
        }

        [GtkChild] unowned Gtk.ListView listview;
        [GtkChild] unowned Gtk.Expander expander;
        [GtkChild] unowned Gtk.SearchEntry search;

        uint? search_timeout;
        Gtk.MultiSelection selection;

        construct {
            model = new Gtk.TreeListModel(new FontModel(),
                                          false,
                                          false,
                                          FontModel.get_child_model);
            selection = new Gtk.MultiSelection(model);
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
            search.search_changed.connect(queue_refilter);
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
            var list_row = model.get_row(list_item.get_position());
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
                font_model.update_items();
                // Try to prevent some rendering artifacts
                listview.queue_draw();
                return GLib.Source.REMOVE;
            });
            return;
        }

        bool refilter () {
            font_model.search_term = search.text.strip();
            queue_update();
            search_timeout = null;
            return GLib.Source.REMOVE;
        }

        // Add slight delay to avoid filtering while search is still changing
        public void queue_refilter () {
            if (search_timeout != null)
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
            var list_row = (Gtk.TreeListRow) model.get_item(i);
            Object? item = list_row.get_item();
            selected_item = item;
            selection_changed(item);
            return;
        }

        [GtkCallback]
        void on_expander_activated (Gtk.Expander unused) {
            model.set_autoexpand(!expander.expanded);
            queue_update();
            return;
        }

    }

}

