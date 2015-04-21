/* Sources.vala
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

namespace FontConfig {

    public class Sources : Gee.HashSet <FontSource> {

        public signal void changed (File? file, FileMonitorEvent event);

        public static string get_cache_file () {
            string dirpath = Path.build_filename(Environment.get_user_config_dir(), FontManager.NAME);
            string filepath = Path.build_filename(dirpath, "Sources.xml");
            DirUtils.create_with_parents(dirpath ,0755);
            return filepath;
        }

        private string? target_file = null;
        private string? target_element = null;
        private FileMonitor? [] monitors = {};
        private VolumeMonitor volume_monitor;

        public Sources () {
            string old_path = Path.build_filename(get_config_dir(), "UserSources");
            string new_path = get_cache_file();
            {
                File old_file = File.new_for_path(old_path);
                File new_file = File.new_for_path(new_path);
                if (old_file.query_exists()) {
                    try {
                        old_file.move(new_file, FileCopyFlags.NONE);
                    } catch (Error e) {
                        warning("Failed to update file location : %s", e.message);
                        warning("Manually move %s to %s", old_path, new_path);
                    }
                }
            }
            target_element = "source";
            target_file = new_path;
            volume_monitor = VolumeMonitor.get();
            volume_monitor.mount_removed.connect((m) => {
               if (this.contains(m.get_default_location().get_path()))
                    change_detected();
            });
        }

        public new bool contains (string path) {
            foreach (var source in this)
                if (source.path.contains(path))
                    return true;
            return false;
        }

        public void update () {
            foreach (var source in this)
                source.update();
            return;
        }

        public new bool add (FontSource source) {
            source.notify["active"].connect(() => { change_detected(); });
            change_detected();
            return base.add(source);
        }

        public new bool remove (FontSource source) {
            source.available = false;
            try {
                FontManager.Database db = FontManager.get_database();
                db.table = "Fonts";
                db.remove("filepath LIKE \"%s%\"".printf(source.path));
                db.vacuum();
                db.close();
            } catch (FontManager.DatabaseError e) {
                warning(e.message);
            }
            if (base.remove(source)) {
                change_detected();
                return true;
            }
            return false;
        }

        public void cancel_monitors () {
            foreach (var mon in monitors) {
                if (mon != null)
                    mon.cancel();
                mon = null;
            }
            monitors = {};
            return;
        }

        public void enable_monitors () {
            var _dirs = list_dirs();
            foreach (var dir in _dirs)
                monitors += get_directory_monitor(dir);
            foreach (var source in this)
                if (source.path in _dirs)
                    continue;
                else
                    monitors += get_directory_monitor(source.path);
            return;
        }

        private void change_detected (File? file = null,
                                         File? other_file = null,
                                         FileMonitorEvent event = FileMonitorEvent.CHANGED) {
            cancel_monitors();
            changed(file, event);
            return;
        }

        private FileMonitor? get_directory_monitor (string dir) {
            File file = File.new_for_path(dir);
            FileMonitor? monitor = null;
            try {
                monitor = file.monitor_directory(FileMonitorFlags.NONE);
                monitor.changed.connect((f, of, ev) => {
                    change_detected(f, of, ev);
                });
            } catch (IOError e) {
                warning("Failed to create FileMonitor for %s", dir);
                critical("FileMonitor creation failed : %s", e.message);
            }
            return monitor;
        }

        public bool init ()
        requires (target_file != null && target_element != null) {

            {
                File file = File.new_for_path(target_file);
                if (!file.query_exists())
                    return false;
            }

            Xml.Parser.init();

            Xml.Doc * doc = Xml.Parser.parse_file(target_file);
            if (doc == null) {
                /* File not found */
                Xml.Parser.cleanup();
                return false;
            }

            Xml.Node * root = doc->get_root_element();
            if (root == null) {
                /* Empty doc */
                delete doc;
                Xml.Parser.cleanup();
                return false;
            }

            parse(root);

            delete doc;
            Xml.Parser.cleanup();
            return true;
        }

        public void save ()
        requires (target_file != null && target_element != null) {
            var writer = new Xml.TextWriter.filename(target_file);
            writer.set_indent(true);
            writer.set_indent_string("  ");
            writer.start_document();
            writer.write_comment(_(" Generated by Font Manager. Do NOT edit this file. "));
            writer.start_element("Sources");
            write_node(writer);
            writer.end_element();
            writer.end_document();
            writer.flush();
            return;
        }

        protected void parse (Xml.Node * root) {
            parse_node(root->children);
        }

        protected void write_node (Xml.TextWriter writer) {
            foreach (var source in this)
                writer.write_element(target_element, Markup.escape_text(source.path.strip()));
            return;
        }

        protected void parse_node (Xml.Node * node) {
            for (Xml.Node * iter = node; iter != null; iter = iter->next) {
                /* Spaces between tags are also nodes, discard them */
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                    continue;
                string content = iter->get_content();
                if (content == null)
                    continue;
                content = content.strip();
                if (content == "")
                    continue;
                else {
                    var source = new FontSource(File.new_for_path(content));
                    source.notify["active"].connect(() => { change_detected(); });
                    base.add(source);
                }
            }
            return;
        }

    }

}
