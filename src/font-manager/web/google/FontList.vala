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

#if HAVE_WEBKIT

namespace FontManager.GoogleFonts {

    public async bool download_font_files (Font [] fonts) {
        var session = new Soup.Session();
        bool retval = true;
        foreach (var font in fonts) {
            string font_dir = Path.build_filename(get_font_directory(), font.family);
            if (DirUtils.create_with_parents(font_dir, 0755) != 0) {
                warning("Failed to create directory : %s", font_dir);
                return_val_if_fail(exists(font_dir), false);
            }
            string filename = font.get_filename();
            string filepath = Path.build_filename(font_dir, filename);
            var message = new Soup.Message(GET, font.url);
            try {
                Bytes? bytes = session.send_and_read(message, null);
                assert(bytes != null);
                File font_file = File.new_for_path(filepath);
                // File.create errors out if file already exists regardless of flags
                if (font_file.query_exists())
                    font_file.delete();
                FileOutputStream stream = font_file.create(FileCreateFlags.PRIVATE);
                try {
                    stream.write_bytes(bytes);
                    stream.close();
                } catch (Error e) {
                    retval = false;
                    warning("Failed to write data to file : %s : %s", filepath, e.message);
                }
            } catch (Error e) {
                retval = false;
                warning("Failed to read data for : %s :: %i :: %s",
                        filename,
                        (int) message.status_code,
                        e.message);
            }
            Idle.add(download_font_files.callback);
            yield;
        }
        return retval;
    }

    public class FontModel : Object, ListModel {

        public Json.Array? entries { get; set; default = null; }
        public GenericArray <Family>? items { get; protected set; default = null; }

        public string? search_term { get; set; default = null; }
        public FontListFilter? filter { get; set; default = null; }

        construct {
            string [] requires_update = { "entries", "filter" };
            foreach (string property in requires_update) {
                notify[property].connect(() => {
                    Idle.add(() => {
                        update_items();
                        if (property == "filter" && filter != null)
                            filter.changed.connect(update_items);
                        return GLib.Source.REMOVE;
                    });
                });
            }
        }

        public Type get_item_type () {
            return typeof(Family);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position)
        requires (items != null)
        requires (position >= 0)
        requires (position < get_n_items()) {
            return items[position];
        }

        bool variant_matches (Family item, string search) {
            var variants = new GenericArray <Font> ();
            item.variants.foreach((f) => {
                string style = f.style.casefold();
                string weight = ((Weight) f.weight).to_translatable_string();
                weight = weight.casefold();
                if (style.contains(search) || weight.contains(search))
                    variants.add(f);
            });
            item.variants = variants;
            return item.count > 0;
        }

        bool matches_search_term (Family item) {
            bool item_matches = true;
            if (search_term == null || search_term.strip().length == 0)
                return item_matches;
            var search = search_term.strip().casefold();
            // Best case scenario, searching for a particular family
            item_matches = item.family.casefold().contains(search);
            // Possible the search term matches a variant
            if (!item_matches)
                item_matches = variant_matches(item, search);
            return item_matches;
        }

        bool matches_filter (Family item) {
            if (filter == null)
                return true;
            return filter.matches(item);
        }

        void on_item_changed(Family item) {
            items_changed(item.position, 0, 0);
            return;
        }

        public void update_items () {
            uint n_items = get_n_items();
            items = null;
            items = new GenericArray <Family> ();
            items_changed(0, n_items, 0);
            if (entries != null) {
                entries.foreach_element((array, index, node) => {
                    Family item = new Family(node.get_object());
                    if (matches_filter(item) && matches_search_term(item)) {
                        items.add(item);
                        item.changed.connect(() => { on_item_changed(item); });
                        foreach (var font in item.variants)
                            font.changed.connect(() => { on_item_changed(item); });
                    }
                });
                items_changed(0, 0, get_n_items());
            }
            return;
        }

        public ListModel? get_child_model (Object item) {
            if (!(item is Family))
                return null;
            var parent = (Family) item;
            var child = new VariantModel();
            BindingFlags flags = BindingFlags.SYNC_CREATE;
            parent.bind_property("variants", child, "items", flags);
            return child;
        }

    }

    public class VariantModel : Object, ListModel {

        public GenericArray <Font>? items { get; set; default = null; }

        void on_item_changed(Font item) {
            items_changed(item.position, 0, 0);
            return;
        }

        void on_items_changed () {
            foreach (var font in items)
                font.changed.connect(on_item_changed);
        }

        construct {
            notify["items"].connect(on_items_changed);
        }

        public Type get_item_type () {
            return typeof(Font);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position)
        requires (items != null) {
            return_val_if_fail(items[position] != null, null);
            return items[position];
        }

    }

    public class FontListRow : ListItemRow {

        public uint position { get; set; default = 0; }

        ulong signal_id = 0;

        protected override void reset () {
            item_state.visible = true;
            item_label.set("label", "", "attributes", null, null);
            item_preview.visible = false;
            item_count.visible = true;
            item_count.set_label("");
            if (signal_id != 0)
                SignalHandler.disconnect(item_state, signal_id);
            signal_id = 0;
        }

        void on_family_changed (Family family) {
            foreach (var font in family.variants)
                font.changed();
            family.changed();
            return;
        }

        void on_item_state_change (Object item) {
            if (signal_id != 0)
                SignalHandler.disconnect(item_state, signal_id);
            signal_id = 0;
            if (item is Family) {
                var family = ((Family) item);
                if (item_state.active) {
                    download_font_files.begin(family.variants.data, (obj, res) => {
                        if (download_font_files.end(res))
                            on_family_changed(family);
                    });
                } else {
                    string font_dir = get_font_directory();
                    string target_dir = Path.build_filename(font_dir, family.family);
                    File file = File.new_for_path(target_dir);
                    if (remove_directory(file))
                        on_family_changed(family);
                }
            } else if (item is Font) {
                var font = ((Font) item);
                if (item_state.active) {
                    download_font_files.begin({ font }, (obj, res) => {
                        if (download_font_files.end(res))
                            font.changed();
                    });
                } else {
                    string font_dir = get_font_directory();
                    string file_name = font.get_filename();
                    string target_dir = Path.build_filename(font_dir, font.family);
                    string target_file = Path.build_filename(target_dir, file_name);
                    File dir = File.new_for_path(target_dir);
                    File file = File.new_for_path(target_file);
                    try {
                        if (file.delete())
                            remove_directory_tree_if_empty(dir);
                    } catch (Error e) {
                        if (e.code != FileError.NOENT)
                            warning(e.message);
                    }
                    font.changed();
                }
            } else
                return_if_reached();
            return;
        }

        protected override void on_item_set () {
            reset();
            if (item == null)
                return;
            bool root = item is Family;
            item_count.visible = root;
            if (root) {
                var count = ((Family) item).count;
                var count_label = ngettext("%i Variation ", "%i Variations", (ulong) count);
                item_count.set_label(count_label.printf(count));
                item_label.set_text(((Family) item).family);
                int installed = 0;
                foreach (var font in ((Family) item).variants)
                    if (font.get_installation_status() != FileStatus.NOT_INSTALLED)
                        installed++;
                item_state.active = (installed > 0);
                item_state.inconsistent = (installed > 0 && installed < count);
            } else {
                var font = ((Font) item);
                item_label.set_text(font.to_display_name());
                var installation_status = font.get_installation_status();
                item_state.active = (installation_status != FileStatus.NOT_INSTALLED);
                if (installation_status == FileStatus.REQUIRES_UPDATE)
                    download_font_files.begin({ font }, (obj, res) => {
                        if (!(download_font_files.end(res)))
                            warning("Failed to download update data for %s", font.get_filename());
                    });
            }
            signal_id = item_state.toggled.connect_after(() => { on_item_state_change(item); });
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-font-list-view.ui")]
    public class FontListView : Gtk.Box {

        public signal void selection_changed (Object? item);

        public Object? selected_item { get; set; default = null; }
        public Json.Array? available_families { get; set; default = null; }
        public FontListFilter filter { get; set; default = null; }

        public FontModel model {
            get {
                return ((FontModel) treemodel.model);
            }
        }

        [GtkChild] unowned Gtk.ListView listview;
        [GtkChild] unowned Gtk.Expander expander;
        [GtkChild] unowned Gtk.SearchEntry search;

        uint current_selection = 0;
        uint search_timeout = 0;
        Gtk.TreeListModel treemodel;
        Gtk.SingleSelection selection;

        construct {
            widget_set_name(listview, "FontManagerGoogleFontsFontListView");
            var fontmodel = new FontModel();
            treemodel = new Gtk.TreeListModel(fontmodel,
                                              false,
                                              false,
                                              fontmodel.get_child_model);
            selection = new Gtk.SingleSelection(treemodel);
            listview.set_factory(get_factory());
            listview.set_model(selection);
            selection.selection_changed.connect(on_selection_changed);
            BindingFlags flags = BindingFlags.SYNC_CREATE;
            bind_property("filter", fontmodel, "filter", flags, null, null);
            bind_property("available-families", model, "entries", flags, null, null);
            search.search_changed.connect(queue_refilter);
            search.activate.connect(next_match);
            search.next_match.connect(next_match);
            search.previous_match.connect(previous_match);
            // Not sure why this was needed but it does reset list on installation...
            // model.items_changed.connect_after(() => {
            //     Idle.add(() => {
            //         select_item(0);
            //         return GLib.Source.REMOVE;
            //     });
            // });
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
            // The above does result in selection but doesn't trigger this signal...
            selection.selection_changed(position, 1);
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

        Gtk.SignalListItemFactory get_factory () {
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup_list_row);
            factory.bind.connect(bind_list_row);
            return factory;
        }

        void setup_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            var tree_expander = new Gtk.TreeExpander();
            var row = new FontListRow();
            tree_expander.set_child(row);
            list_item.set_child(tree_expander);
            return;
        }

        void bind_list_row (Gtk.SignalListItemFactory factory, Object item) {
            Gtk.ListItem list_item = (Gtk.ListItem) item;
            uint position = list_item.get_position();
            var list_row = treemodel.get_row(position);
            var tree_expander = (Gtk.TreeExpander) list_item.get_child();
            tree_expander.margin_start = 2;
            tree_expander.set_list_row(list_row);
            var row = (FontListRow) tree_expander.get_child();
            Object? _item = list_row.get_item();
            // Setting item triggers update to row widget
            row.set("position", position, "item", _item, null);
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

        void on_selection_changed (uint position, uint n_items) {
            selected_item = null;
            current_selection = 0;
            uint i = selection.get_selected();
            current_selection = i;
            if (i == Gtk.INVALID_LIST_POSITION)
                return;
            assert(selection.is_selected(i));
            var list_row = (Gtk.TreeListRow) treemodel.get_item(i);
            Object? item = list_row.get_item();
            selected_item = item;
            selection_changed(item);
            if (Environment.get_variable("G_MESSAGES_DEBUG") != null) {
                string? description = null;
                if (selected_item is Family)
                    description = ((Family) selected_item).family;
                else
                    description = "%s %s".printf(((Font) selected_item).family,
                                                 ((Font) selected_item).style);
                debug("%s::selection_changed : %s", listview.name, description);
            }
            return;
        }

    }

}

#endif /* HAVE_WEBKIT */

