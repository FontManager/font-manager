/* Selections.vala
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

    public abstract class Selections : Gee.HashSet <string> {

        public signal void changed ();

        public string? target_file { get; set; default = null; }
        public string? target_dir { get; set; default = null; }
        public string? target_element { get; set; default = null; }

        FileMonitor? monitor = null;

        construct {
            target_dir = Path.build_filename(Environment.get_user_config_dir(), "fontconfig", "conf.d");
        }

        public override bool add (string key) {
            debug("Add selection : %s", key);
            return base.add(key);
        }

        public override bool remove (string key) {
            debug("Remove selection : %s", key);
            return base.remove(key);
        }

        public virtual void save ()
        requires (target_dir != null && target_file != null && target_element != null) {
            string path = Path.build_filename(target_dir, target_file);
            var writer = new XmlWriter(path);
            write_node(writer);
            writer.close();
            return;
        }

        public virtual bool init ()
        requires (target_dir != null && target_file != null && target_element != null) {

            clear();
            if (monitor != null)
                monitor = null;

            string path = Path.build_filename(target_dir, target_file);

            File file = File.new_for_path(path);
            if (!file.query_exists())
                return false;

            Xml.Parser.init();
            debug("Xml.Parser : Opening : %s", path);
            Xml.Doc * doc = Xml.Parser.parse_file(path);
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

            debug("Xml.Parser : Closing : %s", path);

            delete doc;
            Xml.Parser.cleanup();

            debug("Adding file monitor for : %s", path);
            try {
                monitor = file.monitor_file(FileMonitorFlags.NONE);
                monitor.changed.connect((f, of, ev) => {
                    debug("Filesystem change detected : %s", path);
                    monitor.cancel();
                    Idle.add(() => {
                        this.changed();
                        return false;
                    });
                });
            } catch (IOError e) {
                warning("Failed to create FileMonitor for %s", path);
                critical("FileMonitor creation failed : %s", e.message);
            }

            return true;
        }

        protected virtual void parse (Xml.Node * root) {
            for (Xml.Node * iter = root->children; iter != null; iter = iter->next) {
                /* Spaces between tags are also nodes, discard them */
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                    continue;
                if (iter->name == "selectfont")
                    for (Xml.Node * node = iter->children; node != null; node = node->next)
                        if (node->name == target_element)
                            parse_node(node->children);
            }
        }

        protected virtual void write_node (XmlWriter writer) {
            writer.start_selection(target_element);
            foreach (string font in this)
                writer.write_family_patelt(font.strip());
            writer.end_selection();
            return;
        }

        protected virtual void parse_node (Xml.Node * node) {
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
                else
                    this.add(content);
            }
            return;
        }

    }

}
