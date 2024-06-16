/* Collection.vala
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

    public class Collection : FontListFilter {

        public signal void activated (bool active, StringSet families);

        public StringSet? available_families { get; set; default = null; }
        public Reject? disabled_families { get; set; default = null; }
        public bool active { get; set; default = true; }
        public GenericArray <Collection> children { get; set; }
        public StringSet families { get; set; }

        public override int size {
            get {
                return get_collection_total();
            }
        }

        construct {
            children = new GenericArray <Collection> ();
            families = new StringSet();
            notify["available-families"].connect(() => {
                foreach (var child in children) {
                    BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                    bind_property("available-families", child, "available-families", flags);
                }
            });
            notify["disabled-families"].connect(() => {
                foreach (var child in children) {
                    BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                    bind_property("disabled-families", child, "disabled-families", flags);
                }
            });
            notify["active"].connect(() => { activated(active, families); });
        }

        public Collection (string? name, string? comment) {
            string default_name = _("New Collection");
            string default_comment = _("Created : %s").printf(get_local_time());
            this.name = name != null ? name : default_name;
            this.comment = comment != null ? comment : default_comment;
        }

        public void clear_children () {
            children.foreach((child) => { child.clear_children(); });
            children = null;
            children = new GenericArray <Collection> ();
            return;
        }

        public void remove (string family) {
            families.remove(family);
            set_active_from_fonts();
            changed();
            return;
        }

        public void add (StringSet new_families) {
            families.add_all(new_families);
            set_active_from_fonts();
            changed();
            return;
        }

        public bool contains (Collection collection) {
            for (uint i = 0; i < children.length; i++)
                if (children[i].name == collection.name)
                    return true;
            return false;
        }

        public void set_active_from_fonts () {
            active = (families.size > 0);
            children.foreach((child) => { child.set_active_from_fonts(); });
            return;
        }

        int get_collection_total () {
            int total = (int) families.size;
            if (available_families != null) {
                foreach (var family in families)
                    if (!(family in available_families))
                        total--;
            }
            children.foreach((child) => { total += child.get_collection_total(); });
            return total;
        }

        void add_child_contents (Collection child, StringSet full_contents) {
            full_contents.add_all(child.families);
            child.children.foreach((_child) => { add_child_contents(_child, full_contents); });
            return;
        }

        public StringSet get_full_contents () {
            var full_contents = new StringSet();
            full_contents.add_all(families);
            children.foreach((_child) => { add_child_contents(_child, full_contents); });
            return full_contents;
        }

        public StringSet get_filelist () {
            var results = new StringSet();
            try {
                Database db = DatabaseProxy.get_default_db();
                var contents = get_full_contents();
                foreach (var family in contents) {
                    string sql = "SELECT filepath FROM Fonts WHERE family = \"%s\"";
                    db.execute_query(sql.printf(family));
                    foreach (unowned Sqlite.Statement row in db)
                        results.add(row.column_text(0));
                    db.end_query();
                }
            } catch (Error e) {
                warning(e.message);
            }
            return results;
        }

        public override bool matches (Object? item) {
            bool visible = false;
            string family;
            item.get("family", out family, null);
            visible = (family in get_full_contents());
            return visible;
        }

        public override bool deserialize_property (string prop_name,
                                                   out Value val,
                                                   ParamSpec pspec,
                                                   Json.Node node) {
            val = Value(pspec.value_type);
            if (pspec.value_type == typeof(GenericArray)) {
                GenericArray <Collection> res = new GenericArray <Collection> ();
                node.get_object().foreach_member((obj, name, node) => {
                    Object child = Json.gobject_deserialize(typeof(Collection), node);
                    res.add((Collection) child);
                });
                val.set_boxed(res);
                return true;
            } else if (pspec.value_type == typeof(StringSet)) {
                var res = new StringSet();
                node.get_array().foreach_element((arr, index, node) => {
                    res.add(node.get_string());
                });
                val.set_object(res);
                return true;
            } else if (pspec.value_type == typeof(Reject)) {
                var res = new Reject();
                val.set_object(res);
                return true;
            } else {
                return base.deserialize_property(prop_name, out val, pspec, node);
            }
        }

        public override Json.Node serialize_property (string prop_name,
                                                      Value val,
                                                      ParamSpec pspec) {
            if (pspec.value_type == typeof(GenericArray)) {
                var node = new Json.Node(Json.NodeType.OBJECT);
                var obj = new Json.Object();
                children.foreach((child) => {
                    obj.set_member(child.name.escape(""), Json.gobject_serialize(child));
                });
                node.set_object(obj);
                return node;
            } else if (pspec.value_type == typeof(StringSet)) {
                var node = new Json.Node(Json.NodeType.ARRAY);
                var arr = new Json.Array();
                if (prop_name == "families")
                    foreach (string family in families)
                        arr.add_string_element(family);
                node.set_array(arr);
                return node;
            } else if (pspec.value_type == typeof(Reject)) {
                var node = new Json.Node(Json.NodeType.ARRAY);
                var arr = new Json.Array();
                node.set_array(arr);
                return node;
            } else {
                return base.serialize_property(prop_name, val, pspec);
            }
        }

    }

}


