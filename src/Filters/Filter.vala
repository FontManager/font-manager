/* Filter.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    int sort_on_index (Filter a, Filter b) {
        return (a.index - b.index);
    }

    public class Filter : Cacheable {

        public string name { get; set; }
        public string? icon { get; set; default = null; }
        public string comment { get; set; }
        public Gee.HashSet <string> families { get; set; }
        public int index { get; set; default = 0; }
        public bool active { get; set; default = true; }

        construct {
            comment = _("Created : %s").printf(get_local_time());
        }

        public override bool deserialize_property (string prop_name,
                                            out Value val,
                                            ParamSpec pspec,
                                            Json.Node node) {
            if (pspec.value_type == typeof(Gee.HashSet)) {
                val = Value(pspec.value_type);
                var res = new Gee.HashSet <string> ();
                node.get_array().foreach_element((array, index, node) => {
                    res.add(array.get_string_element(index));
                });
                val.set_object(res);
                return true;
            } else
                return base.deserialize_property(prop_name, out val, pspec, node);
        }

        public override Json.Node serialize_property (string prop_name,
                                               Value val,
                                               ParamSpec pspec) {
            if (pspec.value_type == typeof(Gee.HashSet)) {
                var node = new Json.Node(Json.NodeType.ARRAY);
                var array = new Json.Array.sized((uint) families.size);
                foreach (var font in families)
                    array.add_string_element(font);
                node.set_array(array);
                return node;
            } else
                return base.serialize_property(prop_name, val, pspec);
        }

    }

}
