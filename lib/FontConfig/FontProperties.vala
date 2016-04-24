/* FontProperties.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    public class FontProperties : DefaultProperties {

        public signal void changed ();

        public double less { get; set; default = 0.0; }
        public double more { get; set; default = 0.0; }

        public string? family {
            get {
                return _family;
            }
            set {
                _family = value;
                reset_properties();
                load();
                changed();
                Idle.add(() => { this.modified = false; return this.modified; });
            }
        }

        public Font? font {
            get {
                return _font;
            }
            set {
                _font = value;
                if (_font != null)
                    _family = _font.family;
                else
                    _family = null;
                reset_properties();
                load();
                changed();
                Idle.add(() => { this.modified = false; return this.modified; });
            }
        }

        string? _family = null;
        Font? _font = null;

        public FontProperties () {
            skip_property_assignment.add("family");
            skip_property_assignment.add("font");
            skip_property_assignment.add("less");
            skip_property_assignment.add("more");
        }

        public override void reset_properties () {
            less = 0.0;
            more = 0.0;
            base.reset_properties();
            return;
        }

        public new string get_config_file (bool get_default = false) {
            if (font != null && !get_default)
                return Path.build_filename(get_config_dir(), "29-%s.conf".printf(font.to_filename()));
            else if (family != null)
                return Path.build_filename(get_config_dir(), "29-%s.conf".printf(family));
            else
                return base.get_config_file();
        }

        public override bool load () {
            target_file = "19-DefaultProperties.conf";
            base.load();
            if (family != null) {
                target_file = "29-%s.conf".printf(family);
                base.load();
            }
            if (font != null) {
                target_file = "29-%s.conf".printf(font.to_filename());
                base.load();
            }
            return true;
        }


        protected override void parse_test_node (Xml.Node * iter) {
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
            if (pval != null)
                if (ptype == "less")
                    less = double.parse(pval);
                else if (ptype == "more")
                    more = double.parse(pval);
            return;
        }

        void write_comparison (XmlWriter writer,
                                     string name,
                                     string test,
                                     string type,
                                     string val) {
            writer.start_element("test");
            writer.write_attribute("name", name);
            writer.write_attribute("compare", test);
            writer.write_element(type, val);
            writer.end_element();
            return;
        }

        protected override void write_match_criteria (XmlWriter writer) {
            if (family == null && font == null)
                return;
            writer.start_element("test");
            writer.write_attribute("name", "family");
            writer.write_element("string", family);
            writer.end_element();
            if (less != 0.0)
                write_comparison(writer, "size", "less", "double", less.to_string());
            if (more != 0.0)
                write_comparison(writer, "size", "more", "double", more.to_string());
            if (font == null)
                return;
            write_comparison(writer, "slant", "eq", "int", font.slant.to_string());
            write_comparison(writer, "weight", "eq", "int", font.weight.to_string());
            write_comparison(writer, "width", "eq", "int", font.width.to_string());
            return;
        }

    }

}
