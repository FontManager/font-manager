/* Collections.vala
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

    public class Collections : Cacheable {

        public Gee.HashMap <string, Collection> entries { get; set; }

        public static string get_cache_file () {
            string dirpath =Path.build_filename(Environment.get_user_config_dir(), NAME);
            string filepath = Path.build_filename(dirpath, "Collections.json");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        public Collections () {
            entries = new Gee.HashMap <string, Collection> ();
        }

        public void update (FontConfig.Reject reject) {
            return;
        }

        public void rename_collection (Collection collection, string new_name) {
            string old_name = collection.name;
            collection.name = new_name;
            if (this.entries.has_key(old_name)) {
                this.entries.set(collection.name, collection);
                this.entries.unset(old_name);
            }
            return;
        }

        public Gee.HashSet <string> get_full_contents () {
            var full_contents = new Gee.HashSet <string> ();
            foreach (var entry in entries.values)
                full_contents.add_all(entry.get_full_contents());
            return full_contents;
        }

        public override bool deserialize_property (string prop_name,
                                                        out Value val,
                                                        ParamSpec pspec,
                                                        Json.Node node) {
            if (pspec.value_type == typeof(Gee.HashMap)) {
                val = Value(pspec.value_type);
                var collections = new Gee.HashMap <string, Collection> ();
                node.get_object().foreach_member((obj, name, node) => {
                    collections[name] = (Collection) Json.gobject_deserialize(typeof(Collection), node);
                });
                val.set_object(collections);
                return true;
            } else
                return base.deserialize_property(prop_name, out val, pspec, node);
        }

        public override Json.Node serialize_property (string prop_name,
                                                            Value val,
                                                            ParamSpec pspec) {
            if (pspec.value_type == typeof(Gee.HashMap)) {
                var node = new Json.Node(Json.NodeType.OBJECT);
                var obj = new Json.Object();
                foreach (var collection in entries.values)
                    obj.set_member(collection.name.escape(""), Json.gobject_serialize(collection));
                node.set_object(obj);
                return node;
            } else
                return base.serialize_property(prop_name, val, pspec);
        }

        public bool cache () {
            if (!write_json_file(Json.gobject_serialize(this), get_cache_file(), false)) {
                warning("Failed to save collection cache file.");
                return false;
            }
            return true;
        }

    }

    Collections load_collections () {
        Collections? collections = null;
        string cache = Collections.get_cache_file();
        try {
            File group_cache = File.new_for_path(cache);
            if (group_cache.query_exists())
                collections = (Collections) Json.gobject_deserialize(typeof(Collections), load_json_file(cache));
            else
                message("No user collections found.");
        } catch (Error e) {
            warning("Failed to load file : %s : %s", cache, e.message);
        }
        if (collections != null)
            return collections;
        else
            return new Collections();
    }

}
