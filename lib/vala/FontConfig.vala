/* FontConfig.vala
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

    public enum Width {

        ULTRACONDENSED = 50,
        EXTRACONDENSED = 63,
        CONDENSED = 75,
        SEMICONDENSED = 87,
        NORMAL = 100,
        SEMIEXPANDED = 113,
        EXPANDED = 125,
        EXTRAEXPANDED = 150,
        ULTRAEXPANDED = 200;

        public string? to_string () {
            switch (this) {
                case ULTRACONDENSED:
                    return _("Ultra-Condensed");
                case EXTRACONDENSED:
                    return _("Extra-Condensed");
                case CONDENSED:
                    return _("Condensed");
                case SEMICONDENSED:
                    return _("Semi-Condensed");
                case SEMIEXPANDED:
                    return _("Semi-Expanded");
                case EXPANDED:
                    return _("Expanded");
                case EXTRAEXPANDED:
                    return _("Extra-Expanded");
                case ULTRAEXPANDED:
                    return _("Ultra-Expanded");
                default:
                    return null;
            }
        }

    }

    public enum Slant {

        ROMAN = 0,
        ITALIC = 100,
        OBLIQUE = 110;

        public string? to_string () {
            switch (this) {
                case ITALIC:
                    return _("Italic");
                case OBLIQUE:
                    return _("Oblique");
                default:
                    return null;
            }
        }

    }

    public enum Weight {

        THIN = 0,
        EXTRALIGHT = 40,
        ULTRALIGHT = 40,
        LIGHT = 50,
        BOOK = 75,
        REGULAR = 80,
        NORMAL = 80,
        MEDIUM = 100,
        DEMIBOLD = 180,
        SEMIBOLD = 180,
        BOLD = 200,
        EXTRABOLD = 205,
        BLACK = 210,
        HEAVY = 210,
        EXTRABLACK = 215,
        ULTRABLACK = 215;

        public bool defined () {
            bool res;
            switch (this) {
                case THIN:
                case ULTRALIGHT:
                case LIGHT:
                case BOOK:
                case REGULAR:
                case MEDIUM:
                case SEMIBOLD:
                case BOLD:
                case EXTRABOLD:
                case BLACK:
                case ULTRABLACK:
                    res = true;
                    break;
                default:
                    res = false;
                    break;
            }
            return res;
        }

        public string? to_string () {
            switch (this) {
                case THIN:
                    return _("Thin");
                case ULTRALIGHT:
                    return _("Ultra-Light");
                case LIGHT:
                    return _("Light");
                case BOOK:
                    return _("Book");
                case MEDIUM:
                    return _("Medium");
                case SEMIBOLD:
                    return _("Semi-Bold");
                case BOLD:
                    return _("Bold");
                case EXTRABOLD:
                    return _("Ultra-Bold");
                case HEAVY:
                    return _("Heavy");
                case ULTRABLACK:
                    return _("Ultra-Heavy");
                default:
                    return null;
            }
        }

    }

    public enum Spacing {

        PROPORTIONAL = 0,
        DUAL = 90,
        MONO = 100,
        CHARCELL = 110;

        public string? to_string () {
            switch (this) {
                case PROPORTIONAL:
                    return _("Proportional");
                case DUAL:
                    return _("Dual Width");
                case MONO:
                    return _("Monospace");
                case CHARCELL:
                    return _("Charcell");
                default:
                    return null;
            }
        }

    }

    public enum HintStyle {

        NONE,
        SLIGHT,
        MEDIUM,
        FULL;

        public string to_string () {
            switch (this) {
                case SLIGHT:
                    return _("Slight");
                case MEDIUM:
                    return _("Medium");
                case FULL:
                    return _("Full");
                default:
                    return _("None");
            }
        }

    }

    public enum LCDFilter {

        NONE,
        DEFAULT,
        LIGHT,
        LEGACY;

        public string to_string () {
            switch (this) {
                case DEFAULT:
                    return _("Default");
                case LIGHT:
                    return _("Light");
                case LEGACY:
                    return _("Legacy");
                default:
                    return _("None");
            }
        }

    }

    public enum SubpixelOrder {

        UNKNOWN,
        RGB,
        BGR,
        VRGB,
        VBGR,
        NONE;

        public string to_string () {
            switch (this) {
                case UNKNOWN:
                    return _("Unknown");
                case RGB:
                    return _("RGB");
                case BGR:
                    return _("BGR");
                case VRGB:
                    return _("VRGB");
                case VBGR:
                    return _("VBGR");
                default:
                    return _("None");
            }
        }

    }

    /**
     * load_user_font_resources:
     *
     * Adds user configured font sources (directories) and rejected fonts to our
     * FcConfig so that we can render fonts which are not actually "installed".
     */
    public bool load_user_font_resources (StringHashset? files, GLib.List <weak Source> sources) {
        clear_application_fonts();
        bool res = true;
        if (!add_application_font_directory(get_user_font_directory())) {
            res = false;
            critical("Failed to add default user font directory to configuration!");
        }
        foreach (Source source in sources) {
            if (source.available && !add_application_font_directory(source.path)) {
                res = false;
                warning("Failed to register user font source! : %s", source.path);
            }
        }
        if (files != null)
            foreach (string path in files)
                add_application_font(path);
        return res;
    }

    /**
     * {@inheritDoc}
     */
    public class DefaultProperties : Properties {

        public DefaultProperties () {
            type = PropertiesType.DEFAULT;
            target_file = "19-DefaultProperties.conf";
            load();
        }

    }

    /**
     * {@inheritDoc}
     */
    public class DisplayProperties : Properties {

        public DisplayProperties () {
            type = PropertiesType.DISPLAY;
            target_file = "19-DisplayProperties.conf";
            load();
        }

    }

    /**
     * {@inheritDoc}
     */
    public class FontProperties : DefaultProperties {

        /**
         * FontProperties:changed:
         *
         * Emitted whenever family or font changes.
         */
        public signal void changed ();

        /**
         * FontProperties:family:
         *
         * Name of font family this configuration will apply to.
         * If only family is set, configuration will apply to all variations.
         */
        public string? family { get; set; default = null; }

        /**
         * FontProperties:font:
         *
         * #Font this configuration will apply to.
         * If font is set, configuration will apply only to that specific variation.
         */
        public Font? font { get; set; default = null; }

        public FontProperties () {
            type = PropertiesType.DEFAULT;
            target_file = "19-DefaultProperties.conf";
            notify["family"].connect((source, pspec) => {
                load();
                changed();
            });
            notify["font"].connect((s, p) => {
                family = is_valid_source(font) ? font.family : null;
            });
            load();
        }

        /**
         * {@inheritDoc}
         */
        public override bool load () {
            /* Load global settings */
            target_file = "19-DefaultProperties.conf";
            base.load();
            /* Load any settings that apply to entire family */
            if (family != null) {
                target_file = "29-%s.conf".printf(family);
                base.load();
            }
            /* Load font specific settings */
            if (is_valid_source(font)) {
                target_file = "29-%s.conf".printf(FontManager.to_filename(font.description));
                base.load();
            }
            return true;
        }

        /**
         * {@inheritDoc}
         */
        protected override void add_match_criteria (XmlWriter writer) {
            if (family != null)
                writer.add_test_element("family", "contains", "string", family);
            if (is_valid_source(font)) {
                writer.add_test_element("slant", "eq", "int", font.slant.to_string());
                writer.add_test_element("weight", "eq", "int", font.weight.to_string());
                writer.add_test_element("width", "eq", "int", font.width.to_string());
            }
            base.add_match_criteria(writer);
            return;
        }

    }

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
            //notify["active"].connect((s, p) => { update(); });
            //active.changed.connect(() => { update(); changed(); });
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

