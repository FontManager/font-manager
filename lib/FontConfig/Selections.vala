/* Selections.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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
 * along with Font Manager.  If not, see <https://opensource.org/licenses/GPL-3.0>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    /**
     * {@inheritDoc}
     */
    public class Accept : Selections {

        public Accept () {
            target_element = "acceptfont";
            target_file = "79-Accept.conf";
        }

    }

    /**
     * {@inheritDoc}
     */
    public class Reject : Selections {

        public Reject () {
            target_element = "rejectfont";
            target_file = "78-Reject.conf";
        }

    }

    /**
     * Selections - Represents a Fontconfig configuration file.
     *
     * @config_dir      directory to store configuration file
     * @target_file     filename following the form [7][0-9]*.conf
     * @target_element  <acceptfont> or <rejectfont>
     *
     * The selectfont element is used to black/white list fonts from being
     * listed or matched against. It holds acceptfont and rejectfont elements.
     *
     * Fonts matched by an acceptfont element are "whitelisted";
     * such fonts are explicitly included in the set of fonts used to
     * resolve list and match requests; including them in this list protects
     * them from being "blacklisted" by a rejectfont element.
     * Acceptfont elements include glob and pattern elements which are used
     * to match fonts.
     *
     * Fonts matched by an rejectfont element are "blacklisted";
     * such fonts are excluded from the set of fonts used to resolve list
     * and match requests as if they didn't exist in the system.
     * Rejectfont elements include glob and pattern elements which are
     * used to match fonts.
     *
     * <selectfont>
     *     <rejectfont>
     *         <!-- FONT_PATTERN_ELEMENT_HERE -->
     *     </rejectfont>
     * </selectfont>
     * <selectfont>
     *     <acceptfont>
     *         <!-- FONT_PATTERN_ELEMENT_HERE -->
     *     </acceptfont>
     * </selectfont>
     *
     * Is actually a #Gee.HashSet holding family names.
     * Provides methods to save() / load() configuration files.
     *
     * <glob> elements are unsupported.
     */
    public abstract class Selections : Gee.HashSet <string> {

        public signal void changed ();

        /**
         * Selections:target_file:
         *
         * Should be set to a filename in the form [7][0-9]*.conf
         *
         * Default value :  "70-Selections.conf"
         */
        public string target_file { get; set; default = "70-Selections.conf"; }

        /**
         * Selections:config_dir:
         *
         * Should be set to one of the directories monitored by Fontconfig
         * for configuration files.
         *
         * Default value :   #get_config_dir()
         */
        public string config_dir { get; set; default = get_config_dir(); }

        /**
         * Selections:target_element;
         *
         * Valid values:    <acceptfont> or <rejectfont>
         */
        public string target_element { get; set; default = "<selectfont>"; }

        FileMonitor? monitor = null;

        public override bool add (string key) {
            debug("Add selection : %s : %s", target_element, key);
            return base.add(key);
        }

        public override bool remove (string key) {
            debug("Remove selection : %s : %s", target_element, key);
            return base.remove(key);
        }

        public string get_filepath () {
            return Path.build_filename(config_dir, target_file);
        }

        public virtual bool save () {
            var writer = new XmlWriter(get_filepath());
            write_node(writer);
            return (writer.close() >= 0);
        }

        public virtual bool load () {

            clear();
            if (monitor != null)
                monitor = null;

            string path = get_filepath();

            File file = File.new_for_path(path);
            if (!file.query_exists())
                return false;

            Xml.Parser.init();
            verbose("Xml.Parser : Opening : %s", path);
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

            verbose("Xml.Parser : Closing : %s", path);

            delete doc;
            Xml.Parser.cleanup();

            verbose("Adding file monitor for : %s", path);
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

        void write_patelt (XmlWriter writer,
                                 string name,
                                 string element_type,
                                 string val) {
            writer.start_element("pattern");
            writer.start_element("patelt");
            writer.write_attribute("name", name);
            writer.write_element(element_type, val);
            writer.end_element();
            writer.end_element();
            return;
        }

        protected virtual void write_node (XmlWriter writer) {
            writer.start_element("selectfont");
            writer.start_element(target_element);
            foreach (string font in this)
                write_patelt(writer, "family", "string", font.strip());
            writer.end_element();
            writer.end_element();
            return;
        }

        protected virtual void parse_node (Xml.Node * node) {
            for (Xml.Node * iter = node; iter != null; iter = iter->next) {
                /* Spaces between tags are also nodes, discard them */
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                    continue;
                string content = iter->get_content().strip();
                if (content == "")
                    continue;
                else
                    this.add(content);
            }
            return;
        }

    }

}
