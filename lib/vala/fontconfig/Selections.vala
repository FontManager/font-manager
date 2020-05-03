/* Selections.vala
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

    /**
     * {@inheritDoc}
     */
    public class Accept : Selections {

        public Accept () {
            config_dir = FontManager.get_user_fontconfig_directory();
            target_element = "acceptfont";
            target_file = "79-Accept.conf";
        }

    }

    /**
     * Directories - Represents a Fontconfig configuration file
     *
     * <dir> elements contain a directory path which will be scanned
     * for font files to include in the set of available fonts.
     */
    public class Directories : Selections {

        public Directories () {
            config_dir = FontManager.get_user_fontconfig_directory();
            target_element = "dir";
            target_file = "09-Directories.conf";
        }

        /**
         * {@inheritDoc}
         */
        public override unowned Xml.Node? get_selections (Xml.Doc * doc) {
            Xml.Node * root = doc->get_root_element();
            return (root != null) ? root->children : null;
        }

        /**
         * {@inheritDoc}
         */
        public override void write_selections (XmlWriter writer) {
            writer.add_elements(target_element, this.list());
            return;
        }

    }

    /**
     * {@inheritDoc}
     */
    public class Reject : Selections {

        public Reject () {
            config_dir = FontManager.get_user_fontconfig_directory();
            target_element = "rejectfont";
            target_file = "78-Reject.conf";
            changed.connect(() => {
                Timeout.add_seconds(3, () => {
                    load();
                    return false;
                });
            });
        }

        public StringHashset get_rejected_files () {
            StringHashset results = new StringHashset();
            try {
                Database? db = get_database(DatabaseType.FONT);
                foreach (var family in this) {
                    string sql = "SELECT DISTINCT filepath FROM Fonts WHERE family = '%s'".printf(family);
                    db.execute_query(sql);
                    foreach (unowned Sqlite.Statement stmt in db) {
                        string path = stmt.column_text(0);
                        if (File.new_for_path(path).query_exists())
                            results.add(path);
                    }
                }
            } catch (Error e) {
                warning(e.message);
            }
            return results;
        }

    }

    /**
     * Sources - Represents an application specific configuration file
     *
     * <source> elements contain the full path to a directory containing
     * font files which should be available for preview within the application
     * and easily enabled for others.
     *
     * @seealso     load_user_font_sources ()
     */
    public class Sources : Directories {

        /**
         * Sources:active:
         *
         * #Directories instance, required in order to update FontConfig
         * directory configuration whenever a #Source is activated/deactivated.
         */
        public Directories active { get; private set;}

        FileMonitors monitors;
        HashTable <string, Source> sources;

        public Sources () {
            config_dir = FontManager.get_package_config_directory();
            target_element = "source";
            target_file = "Sources.xml";
            active = new Directories();
            monitors = new FileMonitors();
            sources = new HashTable <string, Source> (str_hash, str_equal);
            monitors.changed.connect((f, of, ev) => { update(); });
        }

        public List <weak Source> list_objects () {
            return sources.get_values();
        }

        public void update () {
            foreach (Source source in sources.get_values()) {
                source.update();
                source.active = (source.path in active);
            }
            return;
        }

        public bool add_from_path (string dirpath) {
            return add(new Source(File.new_for_path(dirpath)));
        }

        public new bool add (Source source) {
            if (sources.lookup(source.path) != null)
                return true;
            sources.insert(source.path, source);
            if (sources.lookup(source.path) == null)
                return false;
            if (source.path in active)
                source.active = true;
            source.notify["active"].connect(() => { source_activated(source); });
            monitors.add(source.path);
            return base.add(source.path);
        }

        internal async void purge_entries (string path) {
            DatabaseType [] types = { DatabaseType.FONT, DatabaseType.METADATA, DatabaseType.ORTHOGRAPHY };
            try {
                Database? db = get_database(DatabaseType.BASE);
                foreach (var type in types) {
                    var name = Database.get_type_name(type);
                    db.execute_query("DELETE FROM %s WHERE filepath LIKE \"%%s%\"".printf(name, path));
                    db.stmt.step();
                }
                db = null;
                foreach (var type in types) {
                    db = get_database(type);
                    db.execute_query("VACUUM");
                    db.stmt.step();
                    Idle.add(purge_entries.callback);
                    yield;
                }
            } catch (DatabaseError e) {
                if (e.code != 1)
                    warning(e.message);
            }
            return;
        }

        public new bool remove (Source source) {
            sources.remove(source.path);
            if (sources.lookup(source.path) != null)
                return false;
            if (active.contains(source.path)) {
                active.remove(source.path);
                active.save();
            }
            monitors.remove(source.path);
            base.remove(source.path);
            purge_entries.begin(source.path, (obj, res) => { purge_entries.end(res); });
            return true;
        }

        void source_activated (Source source) {
            if (source.active)
                active.add(source.path);
            else if (source.path in active)
                active.remove(source.path);
            active.save();
            return;
        }

        /**
         * {@inheritDoc}
         */
        public new bool load () {
            base.load();
            active.load();
            foreach (var path in list())
                add_from_path(path);
            foreach (var path in active.list())
                add_from_path(path);
            return true;
        }

        internal class FileMonitors :  Object {

            /* GLib.FileMonitor:changed: for details */
            public signal void changed (File file, File? other_file, FileMonitorEvent event_type);

            public uint size {
                get {
                    return monitors.size();
                }
            }

            VolumeMonitor volume_monitor;
            HashTable <string, FileMonitor> monitors;

            /* Only notifies if the mounts default path is interesting */
            void notify_on_mount_event (Mount mount) {
                string? path = mount.get_default_location().get_path();
                if (path == null || this.size < 1)
                    return;
                foreach (var s in monitors.get_keys()) {
                    if (s.contains(path)) {
                        changed(mount.get_root(), null, FileMonitorEvent.CHANGED);
                    }
                }
                return;
            }

            construct {
                monitors = new HashTable <string, FileMonitor> (str_hash, str_equal);
                volume_monitor = VolumeMonitor.get();
                volume_monitor.mount_added.connect((m) => {
                    notify_on_mount_event(m);
                });
                volume_monitor.mount_changed.connect((m) => {
                    notify_on_mount_event(m);
                });
                volume_monitor.mount_removed.connect((m) => {
                    notify_on_mount_event(m);
                });
            }

            public bool add (string path) {
                if (monitors.contains(path))
                    return true;
                try {
                    File file = File.new_for_path(path);
                    FileMonitor monitor = file.monitor(FileMonitorFlags.WATCH_MOUNTS);
                    assert(monitor != null);
                    monitors.insert(path, monitor);
                    assert(monitors.lookup(path) != null);
                    monitor.changed.connect((f, of, ev) => { changed(f, of, ev); });
                    monitor.set_rate_limit(3000);
                } catch (Error e) {
                    warning("Failed to create FileMonitor for %s : %s", path, e.message);
                    return false;
                }
                if (!(monitors.contains(path)))
                    return false;
                return true;
            }

            public bool remove (string path) {
                FileMonitor? monitor = monitors.lookup(path);
                if (monitor != null)
                    monitor.cancel();
                return monitors.remove(path);
            }

        }

    }

}

