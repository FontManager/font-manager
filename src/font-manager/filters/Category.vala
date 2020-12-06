/* Category.vala
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

namespace FontManager {

    public class Category : Filter {

        public string? sql { get; set; default = null; }
        public StringSet descriptions { get; set; }
        public StringSet families { get; set; }
        public DatabaseType db_type { get; set; default = DatabaseType.BASE; }

        public GenericArray <Category> children { get; set; }

        public override int size {
            get {
                return ((int) families.size);
            }
        }

        public Category (string name, string comment, string icon, string? sql, int index) {
            Object(name: name, icon: icon, comment: comment, sql: sql, index: index);
            families = new StringSet();
            descriptions = new StringSet();
            children = new GenericArray <Category> ();
        }

        public new async void update () {
            descriptions.clear();
            families.clear();
            try {
                Database db = get_database(db_type);
                if (sql != null)
                    get_matching_families_and_fonts(db, families, descriptions, sql);
                for (int i = 0; i < children.length; i++) {
                    var child = children[i];
                    child.update.begin((obj, res) => {
                        child.update.end(res);
                        Idle.add(update.callback);
                    });
                    yield;
                }
            } catch (DatabaseError error) {
                warning(error.message);
            }
            StringSet? available_families = get_default_application().available_families;
            return_if_fail(available_families != null);
            families.retain_all(available_families.list());
            return;
        }

        public override bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
            Value val;
            bool visible = false;
            if (model.iter_has_child(iter)) {
                model.get_value(iter, FontModelColumn.NAME, out val);
                visible = (((string) val) in families);
            } else {
                model.get_value(iter, FontModelColumn.DESCRIPTION, out val);
                visible = (((string) val) in descriptions);
            }
            val.unset();
            return visible;
        }

        public override bool deserialize_property (string prop_name,
                                                      out Value val,
                                                      ParamSpec pspec,
                                                      Json.Node node) {
            val = Value(pspec.value_type);
            if (pspec.value_type == typeof(GenericArray)) {
                GenericArray <Category> res = new GenericArray <Category> ();
                node.get_object().foreach_member((obj, name, node) => {
                    Object child = Json.gobject_deserialize(typeof(Category), node);
                    res.add((Category) child);
                });
                val.set_boxed(res);
                return true;
            } else if (pspec.value_type == typeof(StringSet)) {
                var res = new StringSet();
//                node.get_array().foreach_element((arr, index, node) => {
//                    res.add(node.get_string());
//                });
                val.set_object(res);
                return true;
            } else if (pspec.value_type == typeof(DatabaseType)) {
                val.set_enum((DatabaseType) ((int) node.get_int()));
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
//                foreach (string family in families)
//                    arr.add_string_element(family);
                node.set_array(arr);
                return node;
            } else if (pspec.value_type == typeof(DatabaseType)) {
                var node = new Json.Node(Json.NodeType.VALUE);
                node.set_int((int) val.get_enum());
                return node;
            } else {
                return base.serialize_property(prop_name, val, pspec);
            }
        }

    }

}
