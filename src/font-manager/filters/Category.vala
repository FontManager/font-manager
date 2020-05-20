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
        public StringHashset descriptions { get; set; }
        public StringHashset families { get; set; }
        public DatabaseType db_type { get; set; default = DatabaseType.BASE; }

        public GLib.List <Category> children;

        public override int size {
            get {
                return ((int) families.size);
            }
        }

        public Category (string name, string comment, string icon, string? sql) {
            Object(name: name, icon: icon, comment: comment, sql: sql);
            families = new StringHashset();
            descriptions = new StringHashset();
            children = new GLib.List <Category> ();
        }

        public new async void update () {
            descriptions.clear();
            families.clear();
            try {
                Database db = get_database(db_type);
                if (sql != null)
                    get_matching_families_and_fonts(db, families, descriptions, sql);
                foreach (Category child in children) {
                    child.update.begin((obj, res) => {
                        child.update.end(res);
                        Idle.add(update.callback);
                    });
                    yield;
                }
            } catch (DatabaseError error) {
                warning(error.message);
            }
            if (available_font_families != null)
                families.retain_all(available_font_families.list());
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

        /* Don't cache results */

        public override bool deserialize_property (string prop_name,
                                                      out Value val,
                                                      ParamSpec pspec,
                                                      Json.Node node) {
            val = Value(pspec.value_type);
            if (pspec.value_type == typeof(GLib.List)) {
                GLib.List <Category> *res = new GLib.List <Category> ();
                node.get_array().foreach_element((array, index, node) => {
                    Object child = Json.gobject_deserialize(typeof(Category), node);
                    res->append(child as Category);
                });
                val.set_pointer(res);
                return true;
            } else if (pspec.value_type == typeof(StringHashset)) {
                val.set_object(new StringHashset());
                return true;
            } else {
                return base.deserialize_property(prop_name, out val, pspec, node);
            }
        }

        public override Json.Node serialize_property (string prop_name,
                                                         Value val,
                                                         ParamSpec pspec) {
            if (pspec.value_type == typeof(GLib.List)) {
                var node = new Json.Node(Json.NodeType.ARRAY);
                var json_array = new Json.Array.sized(children.length());
                foreach (Category child in children)
                    json_array.add_element(Json.gobject_serialize(child));
                node.set_array(json_array);
                return node;
            } else if (pspec.value_type == typeof(StringHashset)) {
                return new Json.Node(Json.NodeType.OBJECT);
            } else {
                return base.serialize_property(prop_name, val, pspec);
            }
        }

    }

}
