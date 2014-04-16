/* Selections.vala
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

namespace FontConfig {

    public abstract class Selections : Gee.HashSet <string> {

        public string? target_file {
            get {
                return _target_file;
            }
            set {
                _target_file = Path.build_filename(get_config_dir(), value);
            }
        }

        public string? target_element { get; set; default = null; }

        string? _target_file = null;

        public virtual void save ()
        requires (target_file != null && target_element != null) {
            var writer = new XmlWriter(target_file);
            write_node(writer);
            writer.close();
            return;
        }

        public virtual bool init ()
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
