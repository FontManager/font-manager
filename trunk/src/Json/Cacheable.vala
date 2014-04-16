/* Cacheable.vala
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

public class Cacheable : Object, Json.Serializable {

    public virtual bool deserialize_property (string prop_name,
                                                    out Value val,
                                                    ParamSpec pspec,
                                                    Json.Node node) {
        val = Value(pspec.value_type);
        if (node.is_null())
            return true;
        val = node.get_value();
        return true;
    }

    public unowned ParamSpec find_property (string name) {
        return this.get_class().find_property(name);
    }

    public ParamSpec [] list_properties () {
        return this.get_class().list_properties();
    }

    public virtual Json.Node serialize_property (string prop_name,
                                                    Value val,
                                                    ParamSpec pspec) {
        Json.Node node;
        /* XXX : Value.strdup_contents() is marked unstable */
        if (val.strdup_contents() == "NULL")
            node = new Json.Node(Json.NodeType.NULL);
        else {
            node = new Json.Node(Json.NodeType.VALUE);
            node.set_value(val);
        }
        return node;
    }

}
