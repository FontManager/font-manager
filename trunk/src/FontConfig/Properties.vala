/* Properties.vala
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

    public class Properties : Object {

        public int hintstyle { get; set; default = 0; }
        public int rgba { get; set; default = 5; }
        public int lcdfilter { get; set; default = 0; }
        public double scale { get; set; default = 1.0; }
        public double dpi { get; set; default = 96; }
        public double smaller_than { get; set; default = 0.0; }
        public double larger_than { get; set; default = 0.0; }
        public bool antialias { get; set; default = false; }
        public bool hinting { get; set; default = false; }
        public bool autohint { get; set; default = false; }

        public Font? font {
            get {
                return _font;
            }
            set {
                _font = value;
                init();
            }
        }

        Font? _font = null;

        public Properties () {
            font = null;
        }

        public bool discard () {
            var target = get_config_file();
            if (FileUtils.test(target, FileTest.EXISTS) && FileUtils.remove(target) != 0)
                return false;
            else {
                /* Force update */
                var writer = new XmlWriter(target);
                writer.close();
                return true;
            }
        }

        public bool save () {
            var writer = new XmlWriter(get_config_file());
            writer.start_element("match");
            writer.write_attribute("target", "font");
            if (font != null) {
                write_match_criteria(writer);
            }
            write_assignments(writer);
            writer.end_element();
            writer.close();
            return true;
        }

        void reset_properties () {
            antialias = false;
            hinting = false;
            hintstyle = 0;
            autohint = false;
            scale = 1.0;
            dpi = 96;
            rgba = 5;
            lcdfilter = 0;
            smaller_than = 0.0;
            larger_than = 0.0;
        }

        string get_config_file () {
            if (font == null)
                return Path.build_filename(get_config_dir(), "28-Properties.conf");
            else
                return Path.build_filename(get_config_dir(), "29-%s-Properties.conf".printf(font.to_filename()));
        }

        public bool init () {
            reset_properties();
            var target = get_config_file();
            if (FileUtils.test(target, FileTest.EXISTS)) {
                load_assignments(target);
                return true;
            }
            /* File not found */
            return false;
        }

        void load_assignments (string target_file) {
            Xml.Parser.init();

            Xml.Doc * doc = Xml.Parser.parse_file(target_file);
            if (doc == null) {
                /* File not found */
                Xml.Parser.cleanup();
                return;
            }

            Xml.Node * root = doc->get_root_element();
            if (root == null) {
                /* Empty doc */
                delete doc;
                Xml.Parser.cleanup();
                return;
            }

            for (Xml.Node * iter = root->children; iter != null; iter=iter->next) {
                string name = iter->name;
                if (name == "match") {
                    parse_node(iter);
                    break;
                }
            }

            delete doc;
            Xml.Parser.cleanup();
            return;
        }

        void parse_node (Xml.Node * node) {
            for (Xml.Node * iter = node->children; iter != null; iter=iter->next) {
                /* Spaces between tags are also nodes, discard them */
                if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                    continue;
                }

                string name = iter->name;

                if (name == "edit") {

                    string? pname = null;
                    string? pval = null;

                    for (Xml.Attr * prop = iter->properties; prop != null; prop = prop->next) {
                        if (prop->name == "name") {
                            pname = prop->children->content;
                            break;
                        }
                    }

                    for (Xml.Node * val = iter->children; val != null; val = val->next) {
                        if (val->name == "bool" || val->name == "int" || val->name == "double") {
                            pval = val->get_content();
                            break;
                        }
                    }

                    if (pval != null) {
                        if (pname == "autohint")
                            autohint = bool.parse(pval);
                        else if (pname == "antialias")
                            antialias = bool.parse(pval);
                        else if (pname == "hinting")
                            hinting = bool.parse(pval);
                        else if (pname == "lcdfilter")
                            lcdfilter = int.parse(pval);
                        else if (pname == "hintstyle")
                            hintstyle = int.parse(pval);
                        else if (pname == "rgba")
                            rgba = int.parse(pval);
                        else if (pname == "scale")
                            scale = double.parse(pval);
                        else if (pname == "dpi")
                            dpi = double.parse(pval);
                    }

                } else if (name == "test") {

                    string? ptype = null;
                    string? pval = null;

                    for (Xml.Attr * prop = iter->properties; prop != null; prop = prop->next) {
                        if (prop->name == "name" && prop->children->content == "size")
                            continue;
                        else if (prop->name == "compare"
                                  && prop->children->content == "less"
                                  || prop->children->content == "more") {
                            for (Xml.Node * val = iter->children; val != null; val = val->next) {
                                if (val->name == "double") {
                                    ptype = prop->children->content;
                                    pval = val->get_content();
                                    break;
                                }
                            }
                        } else
                            break;
                    }
                    if (pval != null) {
                        if (ptype == "less")
                            smaller_than = double.parse(pval);
                        else if (ptype == "more")
                            larger_than = double.parse(pval);
                    }
                } else {
                    warning("Properties : Error parsing : %s", get_config_file());
                    message("Ignoring unknown element");
                }
            }

            return;
        }

        void write_assignments (XmlWriter writer) {
            writer.write_assignment("autohint", "bool", autohint.to_string());
            writer.write_assignment("antialias", "bool", antialias.to_string());
            writer.write_assignment("hinting", "bool", hinting.to_string());
            writer.write_assignment("lcdfilter", "int", lcdfilter.to_string());
            writer.write_assignment("hintstyle", "int", hintstyle.to_string());
            writer.write_assignment("rgba", "int", rgba.to_string());
            writer.write_assignment("scale", "double", scale.to_string());
            writer.write_assignment("dpi", "double", dpi.to_string());
            return;
        }

        void write_match_criteria (XmlWriter writer) requires (font != null) {
            writer.start_element("test");
            writer.write_attribute("name", "family");
            writer.write_element("string", font.family);
            writer.end_element();

            writer.write_comparison("slant", "eq", "int", font.slant.to_string());
            writer.write_comparison("weight", "eq", "int", font.weight.to_string());
            writer.write_comparison("width", "eq", "int", font.width.to_string());

            if (smaller_than != 0.0)
                writer.write_comparison("size", "less", "double", smaller_than.to_string());
            if (larger_than != 0.0)
                writer.write_comparison("size", "more", "double", larger_than.to_string());

            return;

        }
    }

}
