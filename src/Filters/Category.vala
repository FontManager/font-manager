/* Category.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    public class Category : Filter {

        public string? condition { get; set; default = null; }
        public Gee.HashSet <string> descriptions { get; set; }
        public Gee.ArrayList <Category> children { get; set; }

        public Category (string name, string? comment = null, string? icon = null, string? condition = null) {
            Object(name: name, icon: icon, comment: comment, condition: condition);
            families = new Gee.HashSet <string> ();
            descriptions = new Gee.HashSet <string> ();
            children = new Gee.ArrayList <Category> ();
        }

        public virtual void update (Database db) {
            families.clear();
            descriptions.clear();
            try {
                get_matching_families_and_fonts(db, families, descriptions, condition);
                if (children != null)
                    foreach (var child in children)
                       child.update(db);
            } catch (DatabaseError e) {
                warning ("%s category results invalid", name);
                critical("Database error : %s", e.message);
            }
            return;
        }

        /* Don't cache any results - Categories are dynamic */
        public override bool deserialize_property (string prop_name,
                                            out Value val,
                                            ParamSpec pspec,
                                            Json.Node node) {
            if (pspec.value_type == typeof(Gee.HashSet) || pspec.value_type == typeof(Gee.ArrayList)) {
                val = Value(pspec.value_type);
                if (pspec.value_type == typeof(Gee.HashSet))
                    val.set_object(new Gee.HashSet <string> ());
                else
                    val.set_object(new Gee.ArrayList <Category> ());
                return true;
            } else
                return base.deserialize_property(prop_name, out val, pspec, node);
        }

        public override Json.Node serialize_property (string prop_name,
                                               Value val,
                                               ParamSpec pspec) {
            if (pspec.value_type == typeof(Gee.HashSet) || pspec.value_type == typeof(Gee.ArrayList)) {
                var node = new Json.Node(Json.NodeType.OBJECT);
                return node;
            } else
                return base.serialize_property(prop_name, val, pspec);
        }

    }

}

