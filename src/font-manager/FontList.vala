/* FontList.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

    // TODO:
    //       - Enable character search

    public class BaseFontModel : Object, ListModel {

        public Type item_type { get; protected set; default = typeof(Object); }
        public Json.Array? entries { get; set; default = null; }
        public GenericArray <unowned Json.Object>? items { get; protected set; default = null; }

        public string? search_term { get; set; default = null; }
        public FontListFilter? filter { get; set; default = null; }

        construct {
            notify["entries"].connect(() => { update_items(); });
            notify["filter"].connect(() => {
                Idle.add(() => {
                    update_items();
                    return GLib.Source.REMOVE;
                });
            });
        }

        public Type get_item_type () {
            return item_type;
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position)
        requires (items != null) {
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

        bool array_matches (string [] needles, string style, string description) {
            foreach (var term in needles)
                if (style.contains(term) || description.contains(term))
                    continue;
                else
                    return false;
            return true;
        }

        bool matches_search_term (Json.Object item) {
            bool item_matches = true;
            if (search_term == null || search_term.strip() == "")
                return item_matches;
            var search = search_term.strip().casefold();
            if (search.has_prefix(Path.DIR_SEPARATOR_S)) {
                string filepath = get_filepath_from_object(item).casefold();
                item_matches = filepath.contains(search);
            } else if (search.has_prefix(Path.SEARCHPATH_SEPARATOR_S)) {
                // string needle = search.replace(Path.SEARCHPATH_SEPARATOR_S, "");
                // string family = item.get_string_member("family");
                // XXX : FIXME!
            } else {
                string family = item.get_string_member("family").casefold();
                string description = item.get_string_member("description").casefold();
                // Best case scenario, searching for a particular family
                item_matches = family.contains(search);
                // or the search term directly matches the font description
                if (!item_matches)
                    item_matches = description.contains(search);
                // possible we have multiple search terms
                if (!item_matches && item.has_member("style")) {
                    string [] needles = search.split_set(" ", -1);
                    string style = item.get_string_member("style").casefold();
                    item_matches = array_matches(needles, style, description);
                }
            }
            return item_matches;
        }

        bool matches_filter (Json.Object item) {
            if (filter == null)
                return true;
            Type type = item.has_member("filepath") ? typeof(Font) : typeof(Family);
            Object? object = Object.new(type, JSON_PROXY_SOURCE, item, null);
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
                    // Iterating through children is necessary to determine if
                    // the family should be visible at all and also to get an
                    // accurate count of currently visible variations.
                    if (item.has_member("variations")) {
                        Json.Array variants = item.get_array_member("variations");
                        int n_matches = 0;
                        variants.foreach_element((a, i, n) => {
                            Json.Object v = n.get_object();
                            if (matches_search_term(v) && matches_filter(v))
                                n_matches++;
                        });
                        item.set_int_member("n-variations", n_matches);
                        if (n_matches > 0)
                            items.add(item);
                    } else if (matches_search_term(item) && matches_filter(item)) {
                        items.add(item);
                    }
                });
                items.sort((a, b) => { return (int) (GET_INDEX(a) - GET_INDEX(b)); });
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

    public class FontListRow : ListItemRow {

        Binding? binding = null;

        protected override void reset () {
            if (binding != null)
                binding.unbind();
            binding = null;
            item_state.set("active", true, "visible", false, "sensitive", true, null);
            item_label.set("label", "", "attributes", null, null);
            item_preview.set("text", "", "attributes", null, "visible", false, null);
            item_count.visible = true;
            item_count.set_label("");
            return;
        }

        protected override void on_item_set () {
            reset();
            if (item == null)
                return;
            bool root = item is Family;
            BindingFlags flags = BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL;
            binding = item.bind_property("active", item_state, "active", flags, null, null);
            item_state.set("sensitive", root, "visible", root, null);
            item_count.visible = drag_area.sensitive = drag_handle.visible = root;
            string f; string d; string? p = null;
            item.get("family", out f, "description", out d, "preview-text", out p, null);
            string label = root ? f : p != null ? p : d;
            if (root) {
                var count = (int) ((Family) item).n_variations;
                var count_label = ngettext("%i Variation ", "%i Variations", (ulong) count);
                item_count.set_label(count_label.printf(count));
                item_label.set_text(label);
            } else {
                Pango.FontDescription font_desc = Pango.FontDescription.from_string(d);
                Pango.AttrList attrs = new Pango.AttrList();
                attrs.insert(Pango.attr_fallback_new(false));
                attrs.insert(new Pango.AttrFontDesc(font_desc));
                item_preview.set_attributes(attrs);
                item_preview.set_text(label);
                item_preview.show();
            }
            return;
        }

    }

    // TODO
    //      - Context menu
    //          - Toggle multiple fonts
    //          - Send to collection?
    //          - Export?
    //      - Drop support

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-list-view.ui")]
    public class FontListView : Gtk.Box {

        public signal void selection_changed (Object? item);

        public Json.Array? available_fonts { get; set; default = null; }
        public FontListFilter filter { get; set; default = null; }

        public BaseFontModel model {
            get {
                return ((BaseFontModel) treemodel.model);
            }
        }

        // Current selection. This is either the only item selected
        // or the first selection if multiple items are selected
        // this can be either a Family object or a Font object
        public Object? selected_item { get; set; default = null; }
        // This array contains all currently selected Family objects
        public GenericArray <Object>? selected_items { get; set; default = null; }

        [GtkChild] unowned Gtk.Button remove_button;
        [GtkChild] unowned Gtk.ListView listview;
        [GtkChild] unowned Gtk.Expander expander;
        [GtkChild] unowned Gtk.SearchEntry search;

        uint current_selection = 0;
        GenericArray <uint>? current_selections = null;
        uint search_timeout = 0;
        Gtk.TreeListModel treemodel;
        Gtk.MultiSelection selection;

        Gtk.Label menu_title;
        Gtk.PopoverMenu context_menu;

        construct {
            widget_set_name(listview, "FontManagerFontListView");
            selected_items = new GenericArray <Object> ();
            var fontmodel = new FontModel();
            treemodel = new Gtk.TreeListModel(fontmodel,
                                              false,
                                              false,
                                              fontmodel.get_child_model);
            selection = new Gtk.MultiSelection(treemodel);
            listview.set_factory(get_factory());
            listview.set_model(selection);
            selection.selection_changed.connect(on_selection_changed);
            BindingFlags flags = BindingFlags.SYNC_CREATE;
            bind_property("filter", fontmodel, "filter", flags, null, null);
            bind_property("available-fonts", model, "entries", flags, null, null);
            search.search_changed.connect(queue_refilter);
            search.activate.connect(next_match);
            search.next_match.connect(next_match);
            search.previous_match.connect(previous_match);
            search.set_tooltip_text(search_tip.printf(Path.DIR_SEPARATOR_S,
                                                      Path.SEARCHPATH_SEPARATOR_S));
            Gtk.Gesture right_click = new Gtk.GestureClick() {
                button = Gdk.BUTTON_SECONDARY
            };
            ((Gtk.GestureClick) right_click).pressed.connect(on_show_context_menu);
            listview.add_controller(right_click);
            Idle.add(() => { select_item(0); return GLib.Source.REMOVE; });
            notify["filter"].connect(() => {
                Idle.add(() => { select_item(0); return GLib.Source.REMOVE; });
                update_remove_sensitivity();
            });
            var drop_target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
            add_controller(drop_target);
            drop_target.drop.connect(on_drag_data_received);
            init_context_menu();
        }

        // Add slight delay to avoid filtering while search is still changing
        public void queue_refilter () {
            if (search_timeout != 0)
                GLib.Source.remove(search_timeout);
            search_timeout = Timeout.add(333, refilter);
            return;
        }

        public void select_item (uint position) {
            listview.activate_action("list.select-item", "(ubb)", position, false, false);
            listview.activate_action("list.scroll-to-item", "u", position);
            return;
        }

        [GtkCallback]
        void on_activate (uint position) {
            if (selected_items.length < 1)
                return;
            selected_items.foreach((i) => { var f = (Family) i; f.active = !f.active; });
            current_selections.foreach((i) => { treemodel.items_changed(i, 0, 0); });
            return;
        }

        [GtkCallback]
        void on_expander_activated (Gtk.Expander _expander) {
            bool expanded = expander.expanded;
            treemodel.set_autoexpand(expanded);
            expander.set_tooltip_text(expanded ? _("Collapse all") : _("Expand all"));
            queue_update();
            return;
        }

        [GtkCallback]
        void on_remove_clicked () requires (filter is Collection) {
            var collection = (Collection) filter;
            var families = new StringSet();
            selected_items.foreach((i) => { families.add(((Family) i).family); });
            uint i = current_selection;
            while (i > 0 && i >= treemodel.get_n_items() - 1) i--;
            collection.families.remove_all(families);
            Idle.add(() => {
                queue_update(i);
                update_remove_sensitivity();
                return GLib.Source.REMOVE;
            });
            return;
        }

        const MenuEntry [] fontlist_menu_entries = {
            {"install", N_("Install")},
            {"copy-location", N_("Copy Location")},
            {"show-in-folder",N_("Show in Folder")},
            {"enable-selected", N_("Enable selected items")},
            {"disable-selected",N_("Disable selected items")},
        };

        void init_context_menu () {
            var base_menu = new BaseContextMenu(listview);
            context_menu = base_menu.popover;
            menu_title = base_menu.menu_title;
            var menu = base_menu.menu;
            foreach (var entry in fontlist_menu_entries) {
                var item = new GLib.MenuItem(entry.display_name, entry.action_name);
                menu.append_item(item);
            }
            return;
        }

        void update_context_menu (string description, int n_items) {
            if (n_items > 1)
                // Translators : Even though singular form is not used yet, it is here
                // to make for a proper ngettext call. Still it is advisable to translate it.
                menu_title.set_label(ngettext("%i selected item",
                                              "%i selected items",
                                              (ulong) n_items).printf((int) n_items));
            else
                menu_title.set_label(description);
            return;
        }

        void on_show_context_menu (int n_press, double x, double y) {
            if (selected_item == null && selected_items.length < 1)
                return;
            var rect = Gdk.Rectangle() {x = (int) x, y = (int) y, width = 2, height = 2};
            context_menu.set_pointing_to(rect);
            context_menu.popup();
            return;
        }

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

        Gdk.ContentProvider prepare_drag (Gtk.DragSource source, double x, double y) {
            var selections = new GenericArray <Object> ();
            var e_type = typeof(Gtk.TreeExpander);
            var expander = (Gtk.TreeExpander) source.widget.get_ancestor(e_type);
            var list_row = (Gtk.TreeListRow) expander.get_list_row();
            // Dragged row is not necessarily the currently selected row
            if (list_row.item is Family)
                selections.add(list_row.item);
            // If we have multiple rows selected we need to add them here
            if (selected_items.length > 1)
                foreach (var item in selected_items)
                    if (item != list_row.item)
                        selections.add(item);
            return new Gdk.ContentProvider.for_value(selections);
        }

        void drag_begin (Gtk.DragSource drag_source, Gdk.Drag drag) {
            var drag_icon = new Gtk.Overlay();
            var icon = new Gtk.Image.from_icon_name("font-x-generic");
            icon.set_pixel_size(64);
            drag_icon.set_child(icon);
            var drag_count = new Gtk.Label(null) {
                opacity = 0.9,
                halign = Gtk.Align.END,
                valign = Gtk.Align.START,
            };
            widget_set_name(drag_count, "FontManagerListDragCount");
            drag_icon.add_overlay(drag_count);
            drag_count.set_label(selected_items.length.to_string());
            var gtk_drag_icon = (Gtk.DragIcon) Gtk.DragIcon.get_for_drag(drag);
            gtk_drag_icon.set_child(drag_icon);
            return;
        }

        bool on_drag_data_received (Value value, double x, double y) {
            if (value.holds(typeof(Gdk.FileList))) {
                GLib.SList <File>* filelist = value.get_boxed();
                for (int i = 0; i < filelist->length(); i++) {
                    File* file = filelist->nth_data(i);
                    // XXX : Install filelist
                    message(file->get_uri());
                }
            }
            return true;
        }

        void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tree_expander = new Gtk.TreeExpander();
            var row = new FontListRow();
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            var drag_source = new Gtk.DragSource();
            row.drag_area.add_controller(drag_source);
            drag_source.prepare.connect(prepare_drag);
            drag_source.drag_begin.connect(drag_begin);
            return;
        }

        void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var list_row = treemodel.get_row(list_item.get_position());
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.margin_start = 2;
            tree_expander.set_list_row(list_row);
            var row = (FontListRow) tree_expander.get_child();
            Object? _item = list_row.get_item();
            // Setting item triggers update to row widget
            row.item = _item;
            return;
        }

        void queue_update (uint position = 0) {
            Idle.add(() => {
                model.search_term = search.text.strip();
                model.update_items();
                select_item(position);
                return GLib.Source.REMOVE;
            });
            return;
        }

        void next_match (Gtk.SearchEntry entry) {
            select_item(current_selection + 1);
            return;
        }

        void previous_match (Gtk.SearchEntry entry) {
            select_item(current_selection - 1);
            return;
        }

        bool refilter () {
            queue_update();
            search_timeout = 0;
            return GLib.Source.REMOVE;
        }

        void update_remove_sensitivity () {
            bool remove_available = current_selection != uint.MAX &&
                                    filter is Collection &&
                                    ((Collection) filter).families.size > 0;
            set_control_sensitivity(remove_button, remove_available);
            return;
        }

        // NOTE:
        // @position doesn't necessarily point to the actual selection
        // within the TreeListModel, the actual selection lies somewhere
        // between @position + @n_items. The precise location within that
        // range appears to be affected by a variety of factors i.e.
        // previous selection, multiple selections, directional changes, etc.
        void on_selection_changed (uint position, uint n_items) {
            selected_items = new GenericArray <Object> ();
            selected_item = null;
            current_selection = 0;
            current_selections = new GenericArray <uint> ();
            // The minimum value present in this bitset accurately points
            // to the first currently selected row in the ListView.
            Gtk.Bitset selections = selection.get_selection();
            uint i = selections.get_minimum();
            current_selection = i;
            if (i == uint.MAX)
                return;
            assert(selection.is_selected(i));
            var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
            Object? item = list_row.get_item();
            selected_item = item;
            selection_changed(item);
            uint n = selections.get_maximum();
            if (n >= i) {
                while (i <= n) {
                    if (selection.is_selected(i)) {
                        var row = (Gtk.TreeListRow) treemodel.get_item(i);
                        item = row.get_item();
                        if (item != null && item is Family) {
                            selected_items.add(item);
                            current_selections.add(i);
                        }
                    }
                    i++;
                }
            }
            update_remove_sensitivity();
            string? description = null;
            string? family = null;
            selected_item.get("description", out description, "family", out family, null);
            string title = (selected_item is Family) ? family : description;
            update_context_menu(title, selected_items.length);
            debug("%s::selection_changed : %s", listview.name, description);
            return;
        }

    }

}

