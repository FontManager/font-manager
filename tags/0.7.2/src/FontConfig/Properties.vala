/* Properties.vala
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

    public class Properties : Object {

        public static bool skip_save = false;

        protected string target_file { get; protected set; default = ""; }

        protected Gee.ArrayList <string> skip_property_assignment;

        construct {
            skip_property_assignment = new Gee.ArrayList <string> ();
            skip_property_assignment.add("target-file");
        }

        public virtual string get_config_file () {
            return target_file;
        }

        public virtual void reset_properties () {
            return;
        }
            /* XXX : Bug?
             *
             * What is set_value_default supposed to do?
             *
             * Could access default_value directly but...
             * ((ParamSpecTYPE) pspec) generates invalid C code.
             *
            foreach (var pspec in get_class().list_properties()) {
                Value val = Value(pspec.value_type);
                pspec.set_value_default(val);
                assert(pspec.value_defaults(val));
                set_property(pspec.name, val);
                val.unset();
            }
            return;
        }*/

        public virtual bool load (string? target = null) {
            if (target == null)
                target = target_file;
            if (FileUtils.test(target, FileTest.EXISTS)) {
                load_assignments(target);
                return true;
            }
            /* File not found */
            return false;
        }

        public virtual bool save () {
            if (skip_save)
                return false;
            var writer = new XmlWriter(get_config_file());
            writer.start_element("match");
            writer.write_attribute("target", "font");
            write_match_criteria(writer);
            write_assignments(writer);
            writer.end_element();
            writer.close();
            return true;
        }

        public virtual bool discard () {
            string target = get_config_file();
            if (FileUtils.test(target, FileTest.EXISTS) && FileUtils.remove(target) != 0)
                return false;
            /* Force update */
            XmlWriter writer = new XmlWriter(target);
            writer.close();
            reset_properties();
            return true;
        }

        protected virtual void load_assignments (string target_file) {
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

            for (Xml.Node * iter = root->children; iter != null; iter=iter->next)
                if (iter->name == "match") {
                    parse_node(iter);
                    break;
                }

            delete doc;
            Xml.Parser.cleanup();
            return;
        }

        protected virtual void parse_edit_node (Xml.Node * iter) {
            string? pname = null;
            string? pval = null;

            for (Xml.Attr * prop = iter->properties; prop != null; prop = prop->next) {
                if (prop->name == "name") {
                    pname = prop->children->content;
                    break;
                }
            }

            for (Xml.Node * val = iter->children; val != null; val = val->next) {
                pval = val->get_content();
                if (pval == null)
                    continue;
                if (val->name == "bool")
                    this.set(pname, bool.parse(pval));
                else if (val->name == "int")
                    this.set(pname, int.parse(pval));
                else if (val->name == "double")
                    this.set(pname, double.parse(pval));
                else if (val->name == "string")
                    this.set(pname, pval);
            }

            return;
        }

        protected virtual void parse_test_node (Xml.Node * iter) {
            return;
        }

        protected virtual void parse_node (Xml.Node * node) {
            for (Xml.Node * iter = node->children; iter != null; iter=iter->next) {
                /* Spaces between tags are also nodes, discard them */
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                    continue;
                else if (iter->name == "edit")
                    parse_edit_node(iter);
                else if (iter->name == "test")
                    parse_test_node(iter);
            }
            return;
        }

        protected virtual string? type_to_string (Type t) {
            switch (t.name()) {
                case "gint":
                    return "int";
                case "gboolean":
                    return "bool";
                case "gchararray":
                    return "string";
                case "gdouble":
                    return "double";
                default:
                    return null;
            }
        }

        protected virtual string? value_to_string (string type, Value val) {
            switch(type) {
                case "int":
                    return ((int) val).to_string();
                case "bool":
                    return ((bool) val).to_string();
                case "string":
                    return ((string) val);
                case "double":
                    return ((double) val).to_string();
                default:
                    return null;
            }
        }

        protected virtual void write_assignments (XmlWriter writer) {
            foreach (var pspec in this.get_class().list_properties()) {
                if (pspec.name in skip_property_assignment)
                    continue;
                string? type = type_to_string(pspec.value_type);
                if (type == null)
                    continue;
                Value val = Value(pspec.value_type);
                this.get_property(pspec.name, ref val);
//                if (pspec.value_defaults(val)) {
//                    val.unset();
//                    continue;
//                }
                string? res = value_to_string(type, val);
                if (res != null)
                    writer.write_assignment(pspec.name, type, res);
                val.unset();
            }
            return;
        }

        protected virtual void write_match_criteria (XmlWriter writer) {
            return;
        }


    }

}
