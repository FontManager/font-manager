/* OrthographyList.vala
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

internal string GET_ORTH_FOR (string f, int i) {
return """SELECT json_extract(Orthography.support, '$')
FROM Orthography WHERE json_valid(Orthography.support)
AND Orthography.filepath = "%s" AND Orthography.findex = "%i"; """.printf(f, i);
}

internal string GET_BASE_ORTH_FOR (string f) {
return """SELECT json_extract(Orthography.support, '$')
FROM Orthography WHERE json_valid(Orthography.support)
AND Orthography.filepath = "%s"; """.printf(f);
}

internal const string SELECT_NON_LATIN_FONTS = """
SELECT DISTINCT description, Orthography.sample FROM Fonts
JOIN Orthography USING (filepath, findex)
WHERE Orthography.sample IS NOT NULL;
""";

internal unowned string GET_NAME (Json.Object o) { return o.get_string_member("name"); }
internal double GET_COVERAGE (Json.Object o) { return o.get_double_member("coverage"); }


namespace FontManager {

    public class OrthographyListModel : Object, ListModel {

        public Json.Object? orthography { get; set; default = null; }

        public GenericArray <unowned Json.Object>? items { get; private set; default = null; }

        construct {
            notify["orthography"].connect(() => { update_items(); });
        }

        public Type get_item_type () {
            return typeof(Orthography);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public new Object? get_item (uint position) {
            return new Orthography(items[position]);
        }

        void update_items () {
            uint n_items = get_n_items();
            items = null;
            items = new GenericArray <unowned Json.Object> ();
            items_changed(0, n_items, 0);
            if (orthography != null) {
                orthography.foreach_member((object, name, node) => {
                    // Skip anything which isn't an object representing an orthography
                    if (name == "sample")
                        return;
                    // Basic Latin is always present but can be empty
                    if (GET_COVERAGE(node.get_object()) > 0)
                        items.add(node.get_object());
                });
                items.sort((a, b) => {
                    int result = (int) GET_COVERAGE(b) - (int) GET_COVERAGE(a);
                    if (result == 0)
                        result = natural_sort(GET_NAME(a), GET_NAME(b));
                    return result;
                });
            }
            items_changed(0, 0, get_n_items());
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-orthography-list-box-row.ui")]
    class OrthographyListRow : Gtk.Grid {

        [GtkChild] unowned Gtk.Label C_name;
        [GtkChild] unowned Gtk.Label native_name;
        [GtkChild] unowned Gtk.LevelBar coverage;

        public static OrthographyListRow from_item (Object item) {
            Orthography orthography = (Orthography) item;
            OrthographyListRow row = new OrthographyListRow();
            string name = dgettext(null, orthography.name);
            row.C_name.set_text(name);
            bool have_native_name = orthography.native != null && orthography.native != "";
            row.native_name.set_text(have_native_name ? orthography.native : name);
            row.coverage.set_value(((double) orthography.coverage / 100));
            // Translators : Coverage refers to the amount of support the font provides for
            // an orthography. This will be displayed as "Coverage : XXX%" in the interface.
            row.set_tooltip_text("%s : %0.f%%".printf(_("Coverage"), orthography.coverage));
            return row;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-orthography-list.ui")]
    public class OrthographyList : Gtk.Box {

        public signal void orthography_selected (Orthography? orthography);

        public Object? selected_item { get; set; default = null; }
        public OrthographyListModel? model { get; set; default = null; }

        bool _visible_ = false;
        bool update_pending = true;

        [GtkChild] unowned Gtk.Label header;
        [GtkChild] unowned Gtk.ListBox list;
        [GtkChild] unowned Gtk.Revealer clear_revealer;

        PlaceHolder place_holder;

        public OrthographyList () {
            notify["model"].connect(() => {
                list.bind_model(model, OrthographyListRow.from_item);
            });
            model = new OrthographyListModel();
            place_holder = new PlaceHolder(null, null, null, null);
            list.set_placeholder(place_holder);
            header.set_text(_("Supported Orthographies"));
            notify["selected-item"].connect(() => {
                update_pending = true;
                update_if_needed();
            });
            update_if_needed();
        }

        [GtkCallback]
        void on_clear_clicked () {
            list.unselect_all();
            return;
        }

        [GtkCallback]
        void on_list_row_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            clear_revealer.set_reveal_child(row != null);
            Orthography? selected_orth = null;
            if (row != null)
                selected_orth = (Orthography) model.get_item(row.get_index());
            orthography_selected(selected_orth);
            return;
        }

        [GtkCallback]
        void on_map_event () {
            _visible_ = true;
            update_if_needed();
            return;
        }

        [GtkCallback]
        void on_unmap_event () {
            _visible_ = false;
            return;
        }

        Json.Object? parse_json_result (string? json) {
            return_val_if_fail(json != null, null);
            try {
                Json.Parser parser = new Json.Parser();
                parser.load_from_data(json);
                Json.Node root = parser.get_root();
                if (root.get_node_type() == Json.NodeType.OBJECT)
                    return root.get_object();
            } catch (Error e) {
                warning(e.message);
                return null;
            }
            return null;
        }

        void update_model () {
            model.orthography = null;
            place_holder.message = _("No items selected");
            place_holder.icon_name = "dialog-error-symbolic";
            if (selected_item == null)
                return;
            return_if_fail(selected_item is Font || selected_item is Family);
            place_holder.message = _("Update in progress");
            place_holder.icon_name = "emblem-synchronizing-symbolic";
            Font? font = null;
            if (selected_item is Family) {
                Json.Object source = ((Family) selected_item).get_default_variant();
                font = new Font();
                font.source_object = source;
            } else if (selected_item is Font) {
                font = ((Font) selected_item);
            }
            try {
                Database db = Database.get_default(DatabaseType.BASE);
                string query = GET_ORTH_FOR(font.filepath, (int) font.findex);
                db.execute_query(query);
                if (db.stmt.step() == Sqlite.ROW)
                    model.orthography = parse_json_result(db.stmt.column_text(0));
                else {
                    query = GET_BASE_ORTH_FOR(font.filepath);
                    db.execute_query(query);
                    if (db.stmt.step() == Sqlite.ROW)
                        model.orthography = parse_json_result(db.stmt.column_text(0));
                }
                // No error and no results means this font file is likely broken or empty
                Idle.add(() => {
                    place_holder.message = _("No valid orthographies for selection");
                    place_holder.icon_name = "action-unavailable-symbolic";
                    return GLib.Source.REMOVE;
                });
            } catch (DatabaseError e) {
                // Most likely cause of an error here is the database is currently being updated
                model.orthography = get_orthography_results(font.source_object);
            }
            return;
        }

        void update_if_needed () {
            if (_visible_ && update_pending) {
                update_model();
                update_pending = false;
                header.visible = selected_item != null;
            }
            // Show all available characters by default
            Idle.add(() => { list.unselect_all(); return GLib.Source.REMOVE; });
            return;
        }

    }

}
