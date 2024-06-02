/* FontModel.vala
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

namespace FontManager {

    public class BaseFontModel : Object, ListModel {

        public signal void items_updated ();

        public Type item_type { get; protected set; default = typeof(Object); }
        public Json.Array? entries { get; set; default = null; }
        public GenericArray <unowned Json.Object>? items { get; protected set; default = null; }

        public string? search_term { get; set; default = null; }
        public FontListFilter? filter { get; set; default = null; }

        string? char_search = null;
        Json.Object? char_support = null;

        construct {
            items = new GenericArray <unowned Json.Object> ();
            notify["entries"].connect(() => { update_items(); });
            notify["filter"].connect(() => {
                if (filter == null)
                    return;
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

        public Object? get_item (uint position) {
            if (items == null || get_n_items() < 1 || items[position] == null)
                return null;
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
                string needle = search.replace(Path.SEARCHPATH_SEPARATOR_S, "");
                if (needle == "")
                    return false;
                string family = item.get_string_member("family");
                if (char_search != needle || char_support == null) {
                    char_search = needle;
                    char_support = get_available_fonts_for_chars(char_search);
                }
                item_matches = char_support.has_member(family);
                if (item_matches && item.has_member("style")) {
                    Json.Object family_obj = char_support.get_object_member(family);
                    item_matches = family_obj.has_member(item.get_string_member("style"));
                }
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
            if (filter == null || filter is Category && filter.index == CategoryIndex.ALL)
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
            items_updated();
            return;
        }

    }

    public class VariantModel : BaseFontModel {

        public VariantModel () {
            item_type = typeof(Font);
        }

    }

    public class FontModel : BaseFontModel {

        public FontModel () {
            item_type = typeof(Family);
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

}



