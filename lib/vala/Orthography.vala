/* OrthographyList.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

internal double GET_COVERAGE (Json.Object o) { return o.get_double_member("coverage"); }
internal unowned string GET_NAME (Json.Object o) { return o.get_string_member("name"); }

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

const string SELECT_NON_LATIN_FONTS = """
SELECT DISTINCT description, Orthography.sample FROM Fonts
JOIN Orthography USING (filepath, findex)
WHERE Orthography.sample IS NOT NULL;
""";


namespace FontManager {

    public Json.Object? get_non_latin_samples () {
        Json.Object? result = null;
        try {
            var db = get_database(DatabaseType.BASE);
            db.execute_query(SELECT_NON_LATIN_FONTS);
            result = new Json.Object();
            foreach (unowned Sqlite.Statement row in db)
                result.set_string_member(row.column_text(0), row.column_text(1));
        } catch (DatabaseError e) {
            message(e.message);
        }
        return result;
    }

    public class Orthography : Object {

        public string? name { get { return _get_("name"); } }
        public string? native_name { get { return _get_("native"); } }
        public string? sample { get { return _get_("sample"); } }

        public GLib.List <unichar>? filter { get { return charlist; } }

        public double coverage {
            get {
                return source_object != null ? GET_COVERAGE(source_object) : 0;
            }
        }

        GLib.List <unichar>? charlist = null;
        Json.Object? source_object = null;

        public Orthography (Json.Object orthography) {
            source_object = orthography;
            charlist = new GLib.List <unichar> ();
            if (source_object.has_member("filter")) {
                Json.Array array = source_object.get_array_member("filter");
                for (uint i = 0; i < array.get_length(); i++)
                    charlist.prepend(((unichar) array.get_int_element(i)));
                charlist.reverse();
            }
        }

        unowned string? _get_ (string member_name) {
            return_val_if_fail(source_object != null, null);
            return source_object.has_member(member_name) ?
                   source_object.get_string_member(member_name) :
                   null;
        }

    }

    public class OrthographyListModel : Object, GLib.ListModel {

        public Font? font { get; set; default = null; }
        public Json.Object? orthography { get; private set; default = null; }
        public weak OrthographyList? parent { get; set; default = null; }

        GLib.List <unowned Json.Node>? entries;
        Json.Parser? parser = null;
        PlaceHolder updating;
        PlaceHolder unavailable;
        weak PlaceHolder current_placeholder;

        construct {
            parser = new Json.Parser();
            updating = new PlaceHolder(null, "emblem-synchronizing-symbolic");
            string update_txt = _("Update in progress");
            updating.label.set_markup("<b><big>%s</big></b>".printf(update_txt));
            updating.show();
            unavailable = new PlaceHolder(null, "action-unavailable-symbolic");
            unavailable.show();
            notify["parent"].connect(() => {
                parent.placeholder = updating;
                current_placeholder = updating;
            });
        }

        public Type get_item_type () {
            return typeof(Object);
        }

        public uint get_n_items () {
            return entries != null ? entries.length() : 0;
        }

        public new Object? get_item (uint position) {
            return_val_if_fail(entries != null, null);
            return_val_if_fail(position < entries.length(), null);
            Json.Node entry = entries.nth_data(position);
            return new Orthography(entry.get_object());
        }

        public bool update_orthography () {
            entries = null;
            orthography = null;
            if (!is_valid_source(font))
                return false;
            try {
                Database? db = get_database(DatabaseType.BASE);
                string query = GET_ORTH_FOR(font.filepath, font.findex);
                db.execute_query(query);
                if (db.stmt.step() == Sqlite.ROW)
                    parse_json_result(db.stmt.column_text(0));
                else {
                    query = GET_BASE_ORTH_FOR(font.filepath);
                    db.execute_query(query);
                    if (db.stmt.step() == Sqlite.ROW)
                        parse_json_result(db.stmt.column_text(0));
                }
                Idle.add(() => {
                    if (current_placeholder == updating) {
                        parent.placeholder = unavailable;
                        current_placeholder = unavailable;
                    }
                    return false;
                });
            } catch (DatabaseError e) {
                Idle.add(() => {
                    if (current_placeholder != updating) {
                        parent.placeholder = updating;
                        current_placeholder = updating;
                    }
                    return false;
                });
            }
            update_entries();
            if (orthography == null)
                return false;
            return true;
        }

        void parse_json_result (string? json) {
            return_if_fail(json != null);
            try {
                parser.load_from_data(json);
            } catch (Error e) {
                warning(e.message);
                return;
            }
            Json.Node root = parser.get_root();
            if (root.get_node_type() == Json.NodeType.OBJECT)
                orthography = root.get_object();
            return;
        }

        void update_entries () {
            if (orthography == null)
                return;
            GLib.List <unowned Json.Node>? _entries = orthography.get_values();
            /* Basic Latin is always present but can be empty */
            foreach (var entry in _entries)
                if (GET_COVERAGE(entry.get_object()) > 0)
                    entries.prepend(entry);
            entries.sort((a, b) => {
                int result;
                Json.Object orth_a = a.get_object();
                Json.Object orth_b = b.get_object();
                result = (int) GET_COVERAGE(orth_b) - (int) GET_COVERAGE(orth_a);
                if (result == 0)
                    result =  natural_sort(GET_NAME(orth_a), GET_NAME(orth_b));
                return result;
            });
            return;
        }

    }

    public class OrthographyListBoxRow : Gtk.Grid {

        public Orthography orthography;

        Gtk.Label _name;
        Gtk.Label native_name;
        Gtk.LevelBar coverage;

        public OrthographyListBoxRow (Orthography orth) {
            orthography = orth;
            _name = new Gtk.Label(orth.name);
            _name.set("sensitive", false, "hexpand", true, "vexpand", false,
                       "margin", DEFAULT_MARGIN_SIZE / 4, null);
            bool have_native_name = orth.native_name != null && orth.native_name != "";
            string _native = have_native_name ? orth.native_name : orth.name;
            native_name = new Gtk.Label("<big>%s</big>".printf(_native));
            native_name.set("use-markup", true, "hexpand", true, "vexpand", false,
                            "margin", DEFAULT_MARGIN_SIZE / 2.5, null);
            coverage = new Gtk.LevelBar();
            coverage.set("hexpand", true, "vexpand", false, "value", orth.coverage / 100,
                          "margin", DEFAULT_MARGIN_SIZE / 4, null);
            attach(_name, 0, 0, 1, 1);
            attach(native_name, 0, 1, 1, 2);
            attach(coverage, 0, 3, 1, 1);
            string tooltip = _("Coverage");
            set_tooltip_text("%s : %0.f%%".printf(tooltip, orth.coverage));
        }

        public override void show () {
            _name.show();
            native_name.show();
            coverage.show();
            base.show();
            return;
        }

    }

    public class OrthographyList : Gtk.Box {

        public signal void orthography_selected (Orthography? orth);

        public Font? selected_font { get; set; default = null; }

        public PlaceHolder? placeholder {
            set {
                list.set_placeholder(value);
            }
        }

        bool _visible_ = false;
        bool update_pending = false;
        Gtk.Label header;
        Gtk.ListBox list;
        Gtk.EventBox blend;
        Gtk.EventBox blend1;
        Gtk.Button clear;
        Gtk.ScrolledWindow scroll;
        Gtk.Widget [] widgets;
        OrthographyListModel model;

        public OrthographyList () {
            Object(name: "OrthographyList", orientation: Gtk.Orientation.VERTICAL);
            list = new Gtk.ListBox();
            model = new OrthographyListModel();
            model.parent = this;
            var tmpl = "<b><big>%s</big></b>";
            header = new Gtk.Label(tmpl.printf(_("Supported Orthographies")));
            header.set("use-markup", true, "opacity", 0.5,
                        "margin", (DEFAULT_MARGIN_SIZE / 3) + 2,  null);
            blend = new Gtk.EventBox();
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            scroll = new Gtk.ScrolledWindow(null, null);
            blend1 = new Gtk.EventBox();
            blend1.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            clear = new Gtk.Button.with_label(_("Clear selected filter"));
            clear.set("margin", DEFAULT_MARGIN_SIZE / 4, "expand", false,
                      "relief", Gtk.ReliefStyle.NONE, "sensitive", false, null);
            blend.add(header);
            pack_start(blend, false, false, 0);
            add_separator(this);
            scroll.add(list);
            pack_start(scroll);
            add_separator(this);
            blend1.add(clear);
            pack_end(blend1, false, false, 0);
            bind_property("selected-font", model, "font",
                          BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            connect_signals();
            widgets = { list, clear, scroll, blend, header, blend1 };
        }

        public override void show () {
            foreach (var widget in widgets)
                widget.show();
            base.show();
            return;
        }

        void update_if_needed () {
            if (_visible_ && update_pending) {
                list.bind_model(null, null);
                if (!model.update_orthography())
                    return;
                list.bind_model(model, (item) => {
                    return new OrthographyListBoxRow(item as Orthography);
                });
                /* Show all available characters by default */
                Idle.add(() => {
                    list.unselect_all();
                    return false;
                });
                update_pending = false;
            }
            return;
        }

        void connect_signals () {
            clear.clicked.connect(() => { list.unselect_all(); });
            map.connect(() => { _visible_ = true; update_if_needed(); });
            unmap.connect(() => { _visible_ = false; });
            notify["selected-font"].connect(() => { update_pending = true; update_if_needed(); });
            list.row_selected.connect((r) => {
                clear.sensitive = (r != null);
                if (r == null) {
                    orthography_selected(null);
                    return;
                }
                var row = ((Gtk.Bin) r).get_child() as OrthographyListBoxRow;
                orthography_selected(row.orthography);
            });
            return;
        }

    }

}
