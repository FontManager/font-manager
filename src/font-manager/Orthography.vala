/* OrthographyList.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    public HashTable get_non_latin_samples () {
        var result = new HashTable <string, string> (str_hash, str_equal);
        try {
            var db = get_database(DatabaseType.BASE);
            db.execute_query(SELECT_NON_LATIN_FONTS);
            foreach (unowned Sqlite.Statement row in db)
                result.insert(row.column_text(0), row.column_text(1));
        } catch (DatabaseError e) {
            message(e.message);
        }
        return result;
    }

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
                    /* Skip anything which isn't an object representing an orthography */
                    if (name == "sample")
                        return;
                    /* Basic Latin is always present but can be empty */
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
    public class OrthographyListBoxRow : Gtk.Grid {

        [GtkChild] Gtk.Label C_name;
        [GtkChild] Gtk.Label native_name;
        [GtkChild] Gtk.LevelBar coverage;

        public static OrthographyListBoxRow from_item (Object item) {
            Orthography orthography = (Orthography) item;
            OrthographyListBoxRow row = new OrthographyListBoxRow();
            string name = dgettext(null, orthography.name);
            row.C_name.set_text(name);
            bool have_native_name = orthography.native != null && orthography.native != "";
            row.native_name.set_text(have_native_name ? orthography.native : name);
            row.coverage.set_value(((double) orthography.coverage / 100));
            /* TRANSLATORS : Coverage refers to the amount of support the font provides for an
               orthography. This will be displayed as "Coverage : XXX%" in the interface. */
            row.set_tooltip_text("%s : %0.f%%".printf(_("Coverage"), orthography.coverage));
            return row;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-orthography-list.ui")]
    public class OrthographyList : Gtk.Box {

        public signal void orthography_selected (Orthography? orthography);

        public Font? selected_font { get; set; default = null; }
        public OrthographyListModel? model { get; set; default = null; }

        bool _visible_ = false;
        bool update_pending = false;

        [GtkChild] Gtk.Label header;
        [GtkChild] Gtk.ListBox list;
        [GtkChild] Gtk.Revealer clear_revealer;

        PlaceHolder place_holder;

        public OrthographyList () {
            notify["model"].connect(() => { list.bind_model(model, OrthographyListBoxRow.from_item); });
            model = new OrthographyListModel();
            place_holder = new PlaceHolder(null, null, null, null);
            place_holder.show();
            list.set_placeholder(place_holder);
            header.set_text(_("Supported Orthographies"));
            notify["selected-font"].connect(() => { update_pending = true; update_if_needed(); });
        }

        [GtkCallback]
        void on_clear_clicked () {
            list.unselect_all();
            return;
        }

        [GtkCallback]
        void on_list_row_selected (Gtk.ListBox box, Gtk.ListBoxRow? row) {
            clear_revealer.set_reveal_child(row != null);
            if (row == null) {
                orthography_selected(null);
                return;
            }
            orthography_selected((Orthography) model.get_item(row.get_index()));
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
            place_holder.message = _("Update in progress");
            place_holder.icon_name = "emblem-synchronizing-symbolic";
            if (!selected_font.is_valid())
                return;
            try {
                Database? db = get_database(DatabaseType.BASE);
                string query = GET_ORTH_FOR(selected_font.filepath, selected_font.findex);
                db.execute_query(query);
                if (db.stmt.step() == Sqlite.ROW)
                    model.orthography = parse_json_result(db.stmt.column_text(0));
                else {
                    query = GET_BASE_ORTH_FOR(selected_font.filepath);
                    db.execute_query(query);
                    if (db.stmt.step() == Sqlite.ROW)
                        model.orthography = parse_json_result(db.stmt.column_text(0));
                }
                /* No error and no results means this font file is likely broken or empty */
                Idle.add(() => {
                    place_holder.message = "";
                    place_holder.icon_name = "action-unavailable-symbolic";
                    return GLib.Source.REMOVE;
                });
            } catch (DatabaseError e) {
                /* Most likely cause of an error here is the database is currently being updated */
                model.orthography = get_orthography_results(selected_font.source_object);
            }
            return;
        }

        void update_if_needed () {
            if (_visible_ && update_pending) {
                update_model();
                update_pending = false;
            }
            /* Show all available characters by default */
            Idle.add(() => { list.unselect_all(); return GLib.Source.REMOVE; });
            return;
        }

    }

}
