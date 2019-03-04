/* Collection.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    int get_collection_total (Collection root) {
        int total = (int) root.families.size;
        foreach (Collection child in root.children)
            total += get_collection_total(child);
        return total;
    }

    public class Collection : FontListFilter {

        public bool active { get; set; default = true; }
        public GLib.List <Collection> children { get; owned set; }
        public StringHashset families { get; set; }

        public override int size {
            get {
                return get_collection_total(this);
            }
        }

        public Collection (string? name, string? comment) {
            Object(name: name, comment: comment);
            requires_update = false;
            children = new GLib.List <Collection> ();
            families = new StringHashset();
            /* XXX : Translatable string as default argument generates broken vapi ? */
            if (name == null)
                name = _("New Collection");
            if (comment == null) {
                string default_comment = _("Created : %s").printf(get_local_time());
                comment = default_comment;
            }
        }

        public void clear_children () {
            foreach (Collection child in children)
                child.clear_children();
            children = null;
            children = new GLib.List <Collection> ();
            return;
        }

        public void set_active_from_fonts (Reject? reject) {
            if (reject == null)
                return;
            active = false;
            foreach (string family in families) {
                if (!(family in reject)) {
                    active = true;
                    break;
                }
            }
            foreach (Collection child in children)
                child.set_active_from_fonts(reject);
            return;
        }

        void add_child_contents (Collection child, StringHashset full_contents) {
            full_contents.add_all(child.families.list());
            foreach(Collection _child in child.children)
                add_child_contents(_child, full_contents);
            return;
        }

        public StringHashset get_full_contents () {
            var full_contents = new StringHashset();
            full_contents.add_all(families.list());
            foreach (Collection child in children)
                add_child_contents(child, full_contents);
            return full_contents;
        }

        public StringHashset get_filelist () {
            var results = new StringHashset();
            try {
                Database db = get_database(DatabaseType.BASE);
                var contents = get_full_contents();
                foreach (var family in contents) {
                    db.execute_query("SELECT filepath FROM Fonts WHERE family = \"%s\"".printf(family));
                    foreach (unowned Sqlite.Statement row in db)
                        results.add(row.column_text(0));
                }
            } catch (Error e) {
                warning(e.message);
            }
            return results;
        }

        public new void update (Reject? reject) {
            if (reject == null)
                return;
            GLib.List <weak string> _families = families.list();
            if (active)
                reject.remove_all(_families);
            else
                reject.add_all(_families);
            reject.save();
            foreach (Collection child in children) {
                child.active = active;
                child.update(reject);
            }
            return;
        }

        public override bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
            Value? val = null;
            bool visible = false;
            model.get_value(iter, FontModelColumn.OBJECT, out val);
            Object object = val.get_object();
            string family = (object is Family) ?
                            ((Family) object).family :
                            ((Font) object).family;
            visible = (family in families);
            val.unset();
            return visible;
        }

        public override bool deserialize_property (string prop_name,
                                                      out Value val,
                                                      ParamSpec pspec,
                                                      Json.Node node) {
            val = Value(pspec.value_type);
            if (pspec.value_type == typeof(GLib.List)) {
                GLib.List <Collection> *res = new GLib.List <Collection> ();
                node.get_object().foreach_member((obj, name, node) => {
                    Object child = Json.gobject_deserialize(typeof(Collection), node);
                    res->append(child as Collection);
                });
                val.set_pointer(res);
                return true;
            } else if (pspec.value_type == typeof(StringHashset)) {
                var res = new StringHashset();
                node.get_array().foreach_element((arr, index, node) => {
                    res.add(node.get_string());
                });
                val.set_object(res);
                return true;
            } else {
                return base.deserialize_property(prop_name, out val, pspec, node);
            }
        }

        public override Json.Node serialize_property (string prop_name,
                                                         Value val,
                                                         ParamSpec pspec) {
            if (pspec.value_type == typeof(GLib.List)) {
                var node = new Json.Node(Json.NodeType.OBJECT);
                var obj = new Json.Object();
                foreach (Collection child in children)
                    obj.set_member(child.name.escape(""), Json.gobject_serialize(child));
                node.set_object(obj);
                return node;
            } else if (pspec.value_type == typeof(StringHashset)) {
                var node = new Json.Node(Json.NodeType.ARRAY);
                var arr = new Json.Array();
                foreach (string family in families)
                    arr.add_string_element(family);
                node.set_array(arr);
                return node;
            } else {
                return base.serialize_property(prop_name, val, pspec);
            }
        }

    }

}
