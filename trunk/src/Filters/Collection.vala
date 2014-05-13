/* Collection.vala
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

    public class Collection : Filter {

        public Gee.ArrayList <Collection> children { get; set; }

        public Collection (string name = _("New Collection")) {
            Object(name: name);
            families = new Gee.HashSet <string> ();
            children = new Gee.ArrayList <Collection> ();
        }

        public int size () {
            return get_full_contents().size;
        }

        public void clear_children () {
            foreach (var child in children)
                child.clear_children();
            children.clear();
            return;
        }

        public void set_active_from_fonts (FontConfig.Reject reject) {
            active = false;
            foreach (var family in families)
                if (!(family in reject)) {
                    active = true;
                    break;
                }
            foreach (var child in children)
                child.set_active_from_fonts(reject);
            return;
        }

        void add_child_contents (Collection child, Gee.HashSet <string> full_contents) {
            full_contents.add_all(child.families);
            foreach(var _child in child.children)
                add_child_contents(_child, full_contents);
            return;
        }

        public Gee.HashSet <string> get_full_contents () {
            var full_contents = new Gee.HashSet <string> ();
            full_contents.add_all(families);
            foreach (var child in children)
                add_child_contents(child, full_contents);
            return full_contents;
        }

        public void update (FontConfig.Reject reject) {
            if (active)
                reject.remove_all(families);
            else
                reject.add_all(families);
            reject.save();
            foreach (var child in children) {
                child.active = active;
                child.update(reject);
            }
            return;
        }

        public override bool deserialize_property (string prop_name,
                                                        out Value val,
                                                        ParamSpec pspec,
                                                        Json.Node node) {
            if (pspec.value_type == typeof(Gee.ArrayList)) {
                val = Value(pspec.value_type);
                var res = new Gee.ArrayList <Collection> ();
                node.get_object().foreach_member((obj, name, node) => {
                    res.add((Collection) Json.gobject_deserialize(typeof(Collection), node));
                });
                val.set_object(res);
                return true;
            } else
                return base.deserialize_property(prop_name, out val, pspec, node);
        }

        public override Json.Node serialize_property (string prop_name,
                                                           Value val,
                                                           ParamSpec pspec) {
            if (pspec.value_type == typeof(Gee.ArrayList)) {
                var node = new Json.Node(Json.NodeType.OBJECT);
                var obj = new Json.Object();
                foreach (var collection in children)
                    obj.set_member(collection.name.escape(""), Json.gobject_serialize(collection));
                node.set_object(obj);
                return node;
            } else
                return base.serialize_property(prop_name, val, pspec);
        }

    }

}
