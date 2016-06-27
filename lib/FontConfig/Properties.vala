/* Properties.vala
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
     * FontProperties:
     *
     * @family      name of font family
     * @font        #FontConfig.font
     * @less        limit configuration to point sizes smaller than
     * @more        limit configuration to point sizes larger than
     *
     * If only family is set, configuration will apply to all variations.
     * If font is set, configuration will apply only to that specific variation.
     *
     */
    public class FontProperties : DefaultProperties {

        /**
         * FontProperties::changed:
         *
         * Emitted when family or font has changed.
         */
        public signal void changed ();

        public double less { get; set; default = 0.0; }
        public double more { get; set; default = 0.0; }

        /**
         * FontProperties:family:
         *
         * Name of font family this configuration will apply to.
         */
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

        /**
         * FontProperties:font:
         *
         * #FontConfig.Font this configuration will apply to.
         */
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
            skip_assignment.add("family");
            skip_assignment.add("font");
            skip_assignment.add("less");
            skip_assignment.add("more");
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

    /**
     * DisplayProperties:
     */
    public class DisplayProperties : Properties {

        public int rgba { get; set; default = 1; }
        public int lcdfilter { get; set; default = 1; }
        public double scale { get; set; default = 1.00; }
        public double dpi { get; set; default = 96; }

        public DisplayProperties () {
            target_file = "19-DisplayProperties.conf";
            load();
        }

        public override void reset_properties () {
            rgba = 1;
            lcdfilter = 1;
            scale = 1.00;
            dpi = 96;
            return;
        }

    }

    /**
     * DefaultProperties:
     */
    public class DefaultProperties : Properties {

        public int hintstyle { get; set; default = 0; }
        public bool antialias { get; set; default = false; }
        public bool hinting { get; set; default = false; }
        public bool autohint { get; set; default = false; }
        public bool embeddedbitmap { get; set; default = false; }

        public bool modified { get; set; default = false; }

        public DefaultProperties () {
            target_file = "19-DefaultProperties.conf";
            load();
            skip_assignment.add("modified");
            notify.connect((pspec) => {
                if (pspec.name == "modified")
                    return;
                if (!skip_assignment.contains(pspec.name))
                    modified = true;
            });
        }

        public override void reset_properties () {
            hintstyle = 0;
            antialias = false;
            hinting = false;
            autohint = false;
            embeddedbitmap = false;
            modified = false;
            return;
        }

    }

    /**
     * Properties - Represents Fontconfig configuration properties
     *
     * By default this class will generate <edit> entries for all of it's
     * properties if their type is a valid Fontconfig type useable in a
     * configuration file.
     *
     *  <edit name=property_name mode="assign" binding="same">
     *      property_value
     *  </edit>
     *
     * add() property names to skip_assignment to ignore them.
     *
     * Provides methods to save() / load() configuration files.
     *
     * write_match_criteria() will be called during save() before write_assignments()
     * and should be overriden to match desired font or family patterns
     */
    public abstract class Properties : Object {

        public string? target_file { get; protected set; default = "19-Properties.conf"; }
        public string? target_dir { get; set; default = get_config_dir(); }

        protected Gee.ArrayList <string> skip_assignment;

        construct {
            skip_assignment = new Gee.ArrayList <string> ();
            skip_assignment.add("target-file");
            skip_assignment.add("target-dir");
        }

        protected string get_config_file () {
            return Path.build_filename(target_dir, target_file);
        }

        public virtual void reset_properties () {
            return;
        }

        public virtual bool load () {
            string target = get_config_file();
            if (FileUtils.test(target, FileTest.EXISTS)) {
                load_assignments(target);
                return true;
            }
            /* File not found */
            return false;
        }

        public virtual bool save () {
            var writer = new XmlWriter(get_config_file());
            writer.start_element("match");
            writer.write_attribute("target", "font");
            write_match_criteria(writer);
            write_assignments(writer);
            writer.end_element();
            return (writer.close() >= 0);
        }

        public virtual bool discard () {
            string target = get_config_file();
            if (FileUtils.test(target, FileTest.EXISTS) && FileUtils.remove(target) != 0)
                return false;
            reset_properties();
            return true;
        }

        protected virtual void load_assignments (string target_file) {
            Xml.Parser.init();
            verbose("Xml.Parser : Opening : %s", target_file);
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

            verbose("Xml.Parser : Closing : %s", target_file);

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
                    return "%.1f".printf((double) val);
                default:
                    return null;
            }
        }

        protected virtual void write_assignment (XmlWriter writer,
                                                         string name,
                                                         string type,
                                                         string val) {
            writer.start_element("edit");
            writer.write_attribute("name", name);
            writer.write_attribute("mode", "assign");
            writer.write_attribute("binding", "same");
            writer.write_element(type, val);
            writer.end_element();
            return;
        }

        protected virtual void write_assignments (XmlWriter writer) {
            foreach (var pspec in this.get_class().list_properties()) {
                if (pspec.name in skip_assignment)
                    continue;
                string? type = type_to_string(pspec.value_type);
                if (type == null)
                    continue;
                Value val = Value(pspec.value_type);
                this.get_property(pspec.name, ref val);
                string? res = value_to_string(type, val);
                if (res != null)
                    write_assignment(writer, pspec.name, type, res);
                val.unset();
            }
            return;
        }

        protected virtual void write_match_criteria (XmlWriter writer) {
            return;
        }


    }

}
