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

namespace FontManager {

    public class Orthography : Object {

        public string? name { get { return _get_("name"); } }
        public string? native_name { get { return _get_("native"); } }
        public string? sample { get { return _get_("sample"); } }

        public GLib.List <unichar>? filter { get { return charlist; } }

        public double coverage {
            get {
                return source_object != null && source_object.has_member("coverage") ?
                        source_object.get_double_member("coverage") : 0;
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

}
