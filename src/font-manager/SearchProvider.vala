/* SearchProvider.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

    [DBus (name = "org.gnome.Shell.SearchProvider2")]
    public class SearchProvider : GLib.Object {

        uint dbus_id = 0;
        const string SEARCH_PROVIDER_BUS_PATH = "/com/github/FontManager/FontManager/SearchProvider";

        enum ID {
            FILEPATH,
            INDEX,
            FAMILY,
            STYLE;
        }

        const string QUERY = "SELECT filepath, findex, family, style from Fonts WHERE family LIKE \"%s%\" ORDER BY weight;";

        string get_search_term (string [] terms) {
            var search_term = new StringBuilder();
            foreach (string term in terms) {
                search_term.append(" ");
                search_term.append(term);
            }
            return search_term.str.strip();
        }

        string [] character_search (string charset) {
            string [] result_set = {};
            Json.Object fontset = get_available_fonts_for_chars(charset);
            fontset.foreach_member((obj, name, node) => {
                Json.Object fonts = node.get_object();
                fonts.foreach_member((obj, name, node) => {
                    Json.Object font = node.get_object();
                    result_set += "%s::%i::%s::%s".printf(font.get_string_member("filepath"),
                                                          (int) font.get_int_member("findex"),
                                                          font.get_string_member("family"),
                                                          font.get_string_member("style"));
                });
            });
            return result_set;
        }

        string [] database_search (string [] terms) {
            string [] result_set = {};
            var search_term = get_search_term(terms);
            try {
                Database db = DatabaseProxy.get_default_db();
                db.execute_query(QUERY.printf(search_term));
                foreach (unowned Sqlite.Statement row in db)
                    result_set += "%s::%i::%s::%s".printf(row.column_text(ID.FILEPATH),
                                                          row.column_int(ID.INDEX),
                                                          row.column_text(ID.FAMILY),
                                                          row.column_text(ID.STYLE));
                db.end_query();
            } catch (Error e) {
                warning(e.message);
            }
            return result_set;
        }

        /* This is called with the first letter of a new search. */
        /* In our case, this is not very useful so we ignore it. */
        public async string [] get_initial_result_set (string [] terms)
        throws GLib.DBusError, GLib.IOError {
            string [] result_set = {};
            return result_set;
        }

        /* Called repeatedly as user types into shell search field */
        /* TODO : Don't search while user is still typing */
        public async string [] get_subsearch_result_set (string [] previous_results, string [] terms)
        throws GLib.DBusError, GLib.IOError {
            if (terms[0].has_prefix(Path.SEARCHPATH_SEPARATOR_S))
                return character_search(terms[0].replace(Path.SEARCHPATH_SEPARATOR_S, ""));
            else
                return database_search(terms);
        }

        public HashTable <string, Variant> [] get_result_metas (string [] results)
        throws GLib.DBusError, GLib.IOError {
            var metas = new GenericArray < HashTable <string, Variant> > ();
            foreach (string entry in results) {
                string [] data = entry.split("::");
                var meta = new HashTable <string, Variant> (str_hash, str_equal);
                meta.insert("id", "%s::%s".printf(data[ID.FILEPATH], data[ID.INDEX]));
                meta.insert("name", data[ID.FAMILY]);
                meta.insert("description", data[ID.STYLE]);
                metas.add(meta);
            }
            return metas.data;
        }

        /* @result is the id assigned in GetResultMetas */
        public void activate_result (string result, string [] terms, uint32 timestamp)
        throws GLib.DBusError, GLib.IOError {
            string [] data = result.split("::");
            File file = File.new_for_path(data[ID.FILEPATH]);
            int findex = int.parse(data[ID.INDEX]);
            try {
                DBusConnection conn = Bus.get_sync(BusType.SESSION);
                conn.call_sync(FontViewer.BUS_ID,
                                FontViewer.BUS_PATH,
                                FontViewer.BUS_ID,
                                "ShowUri",
                                new Variant("(si)", file.get_uri(), findex),
                                null,
                                DBusCallFlags.NONE,
                                -1,
                                null);
            } catch (Error e) {
                critical("Method call to %s failed : %s", FontViewer.BUS_ID, e.message);
            }
            return;
        }

        public void launch_search (string [] terms, uint32 timestamp)
        throws GLib.DBusError, GLib.IOError {
            string search_term = get_search_term(terms);
            try {
                DBusConnection conn = Bus.get_sync(BusType.SESSION);
                conn.call_sync(BUS_ID,
                               BUS_PATH,
                               BUS_ID,
                               "Search",
                               new Variant("s", search_term),
                               null,
                               DBusCallFlags.NONE,
                               -1,
                               null);
            } catch (Error e) {
                critical("Method call to %s failed : %s", BUS_ID, e.message);
            }
            return;
        }

        [DBus (visible = false)]
        public void dbus_register (DBusConnection conn) {
            try {
                dbus_id = conn.register_object(SEARCH_PROVIDER_BUS_PATH, this);
            } catch (Error e) {
                warning("Failed to register gnome shell search provider : %s", e.message);
            }
            return;
        }

        [DBus (visible = false)]
        public void dbus_unregister (DBusConnection conn) {
            if (dbus_id != 0)
                conn.unregister_object(dbus_id);
            return;
        }

    }

}

