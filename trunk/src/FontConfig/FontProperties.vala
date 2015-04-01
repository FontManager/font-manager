/* FontProperties.vala
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

    public class FontProperties : DefaultProperties {

        public double less { get; set; default = 0.0; }
        public double more { get; set; default = 0.0; }

        public string? family {
            get {
                return _family;
            }
            set {
                _family = value;
                if (_font != null && _font.family != family)
                    _font = null;
                reset_properties();
                load();
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
            }
        }

        private string? _family = null;
        private Font? _font = null;

        public override void reset_properties () {
            less = 0.0;
            more = 0.0;
            base.reset_properties();
            return;
        }

        public override bool save () {
            if (less != 0.0)
                skip_property_assignment.remove("less");
            else
                skip_property_assignment.add("less");
            if (more != 0.0)
                skip_property_assignment.remove("more");
            else
                skip_property_assignment.add("more");
            return base.save();
        }


        public new string get_config_file (bool get_default = false) {
            if (font != null && !get_default)
                return Path.build_filename(get_config_dir(), "29-%s-Properties.conf".printf(font.to_filename()));
            else if (family != null)
                return Path.build_filename(get_config_dir(), "29-%s-Properties.conf".printf(family));
            else
                return base.get_config_file();
        }

        public override bool load (string? target = null) {
            if (target == null)
                target = target_file;
            base.load(target);
            base.load(get_config_file(true));
            base.load(get_config_file());
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


        protected override void write_match_criteria (XmlWriter writer) {
            if (family == null && font == null)
                return;
            writer.start_element("test");
            writer.write_attribute("name", "family");
            writer.write_element("string", family);
            writer.end_element();
            if (less != 0.0)
                writer.write_comparison("size", "less", "double", less.to_string());
            if (more != 0.0)
                writer.write_comparison("size", "more", "double", more.to_string());
            if (font == null)
                return;
            writer.write_comparison("slant", "eq", "int", font.slant.to_string());
            writer.write_comparison("weight", "eq", "int", font.weight.to_string());
            writer.write_comparison("width", "eq", "int", font.width.to_string());
            return;
        }

    }

}
