/* SearchProvider.vala
 *
 * Copyright (C) 2020 Jerry Casiano
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
        const string SEARCH_PROVIDER_BUS_PATH = "/org/gnome/FontManager/SearchProvider";
        const string QUERY = "SELECT filepath, findex, description from Fonts WHERE family LIKE \"%s%\" ORDER BY weight;";

        GenericArray < HashTable <string, Variant> >? current_results = null;

        /* This is called with the first letter of a new search. */
        /* In our case, this is not very useful so we ignore it. */
        public async string [] get_initial_result_set (string [] terms) throws GLib.DBusError, GLib.IOError {
            string [] result_set = {};
            return result_set;
        }

        /* Called repeatedly as user types into shell search field */
        /* TODO : Don't search while user is still typing */
        public async string [] get_subsearch_result_set (string [] previous_results, string [] terms) throws GLib.DBusError, GLib.IOError {
            string [] result_set = {};
            if (terms[0].has_prefix(Path.SEARCHPATH_SEPARATOR_S)) {
                string charset = terms[0].replace(Path.SEARCHPATH_SEPARATOR_S, "");
                Json.Object fontset = get_available_fonts_for_chars(charset);
                fontset.foreach_member((obj, name, node) => {
                    Json.Object fonts = node.get_object();
                    fonts.foreach_member((obj, name, node) => {
                        Json.Object font = node.get_object();
                        result_set += "%s::%i::%s".printf(font.get_string_member("filepath"),
                                                          (int) font.get_int_member("findex"),
                                                          font.get_string_member("description"));
                    });
                });
            } else {
                foreach (string term in terms) {
                    try {
                        Database db = get_database(DatabaseType.BASE);
                        db.execute_query(QUERY.printf(term));
                        foreach (unowned Sqlite.Statement row in db)
                            result_set += "%s::%s::%s".printf(row.column_text(0),
                                                              row.column_text(1),
                                                              row.column_text(2));
                    } catch (Error e) {
                        warning(e.message);
                    }
                }
            }
            return result_set;
        }

        public HashTable <string, Variant> [] get_result_metas (string [] results) throws GLib.DBusError, GLib.IOError {
            current_results = null;
            current_results = new GenericArray < HashTable <string, Variant> > ();
            int count = 0;
            foreach (string entry in results) {
                var meta = new HashTable <string, Variant> (str_hash, str_equal);
                meta.insert("id", count.to_string());
                meta.insert("name", " ");
                meta.insert("description", entry.split("::")[2]);
                meta.insert("data", entry);
                current_results.add(meta);
                count++;
            }
            return current_results.data;
        }

        /* @result is the id assigned in GetResultMetas as a string */
        public void activate_result (string result, string [] terms, uint32 timestamp) throws GLib.DBusError, GLib.IOError {
            string [] data = ((string) current_results[int.parse(result)]["data"]).split("::");
            File file = File.new_for_path(data[0]);
            int index = int.parse(data[1]);
            try {
                DBusConnection conn = Bus.get_sync(BusType.SESSION);
                conn.call_sync(FontViewer.BUS_ID,
                                FontViewer.BUS_PATH,
                                FontViewer.BUS_ID,
                                "ShowUri",
                                new Variant("(si)", file.get_uri(), index),
                                null,
                                DBusCallFlags.NONE,
                                -1,
                                null);
            } catch (Error e) {
                critical("Method call to %s failed : %s", FontViewer.BUS_ID, e.message);
            }
            return;
        }

        public void launch_search (string [] terms, uint32 timestamp) throws GLib.DBusError, GLib.IOError {
            var application = get_default_application();
            application.activate();
            var builder = new StringBuilder();
            foreach (string term in terms)
                builder.append(" %s".printf(term));
            string search_term = builder.str.strip();
            /* XXX : FIXME */
            Timeout.add(1000, () => {
                if (application.update_in_progress || main_window.sidebar.standard.category_tree.update_in_progress)
                    return GLib.Source.CONTINUE;
                Idle.add(() => {
                    main_window.mode = Mode.MANAGE;
                    main_window.sidebar.mode = "Standard";
                    main_window.sidebar.standard.mode = StandardSidebarMode.CATEGORY;
                    main_window.sidebar.standard.category_tree.select_first_row();
                    main_window.fontlist_pane.filter = null;
                    main_window.fontlist_pane.controls.entry.set_text(search_term);
                    if (!main_window.sidebar.standard.category_tree.tree.get_selection().path_is_selected(new Gtk.TreePath.first()))
                        return GLib.Source.CONTINUE;
                    return GLib.Source.REMOVE;
                });
                return GLib.Source.REMOVE;
            });
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

