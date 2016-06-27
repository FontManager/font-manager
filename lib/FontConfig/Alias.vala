/* Alias.vala
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
     * Standard aliases.
     *
     * These should never appear in font listings.
     */
    public const string [] DEFAULT_ALIASES = {
        "Cursive", "cursive",
        "Fantasy", "fantasy",
        "Monospace", "monospace",
        "Sans", "sans",
        "Sans-Serif", "sans-serif",
        "Serif", "serif"
    };

    /**
     * AliasElement - Represents a Fontconfig <alias> element.
     *
     * Alias elements provide a shorthand notation for the set of common
     * match operations needed to substitute one font family for another.
     * They contain a <family> element followed
     * by optional <prefer>, <accept> and <default> elements.
     * Fonts matching the <family> element are edited to prepend the list of
     * <prefer>ed families before the matching <family>,
     * append the <accept>able families after the matching <family>
     * and append the <default> families to the end of the family list.
     *
     *  <alias>
     *      <family> TARGET_FAMILY_NAME </family>
     *      <!-- The following blocks all accept multiple family elements -->
     *      <prefer>
     *          <family> PREPENDED_TO_LIST </family>
     *          <family> THIS_ONE_TOO </family>
     *      </prefer>
     *      <accept>
     *          <family> APPENDED_IMEDIATELY_AFTER_TARGET </family>
     *      </acccept>
     *      <default>
     *          <family> APPENDED_TO_END_OF_LIST </family>
     *      </default>
     *  </alias>
     *
     */
    public class AliasElement : Object {

        public string? family { get; set; }
        public Gee.HashSet <string> prefer { get; set; }
        public Gee.HashSet <string> accept { get; set; }
        public Gee.HashSet <string> @default { get; set; }

        construct {
            prefer = new Gee.HashSet <string> ();
            accept = new Gee.HashSet <string> ();
            @default = new Gee.HashSet <string> ();
        }

        public AliasElement (string? family) {
            Object(family: family);
        }

    }

    /**
     * Aliases - Represents a Fontconfig configuration file
     *
     * @config_dir      directory to store configuration file
     * @target_file     filename following the form [3][0-9]*.conf
     *
     * Is actually a #Gee.HashMap holding #AliasElement entries.
     * Provides methods to save() / load() configuration files.
     */
    public class Aliases : Gee.HashMap <string, AliasElement> {

        /**
         * Aliases:config_dir:
         *
         * Should be set to one of the directories monitored by Fontconfig for
         * configuration files.
         *
         * Default value :   #get_package_config_dir()
         */
        public string config_dir { get; set; default = get_package_config_dir(); }

        /**
         * Aliases:target_file:
         *
         * Should be set to a filename in the form [3][0-9]*.conf
         *
         * Default value :  "39-Alias.conf"
         */
        public string target_file { get; set; default = "39-Alias.conf"; }

        /**
         * Convenience method to add a new #AliasElement
         */
        public void add (string family_name) {
            base.set(family_name, new AliasElement(family_name));
            return;
        }

        public bool remove (string family_name) {
            return base.unset(family_name);
        }

        public string get_filepath () {
            return Path.build_filename(config_dir, target_file);
        }

        public bool save () {
            var writer = new XmlWriter(get_filepath());
            foreach (var entry in this.entries)
                write_alias_element(writer, entry.value);
            return (writer.close() >= 0);
        }

        public void load () {
            clear();
            string filepath = get_filepath();
            Xml.Parser.init();
            verbose("Xml.Parser : Opening : %s", filepath);
            Xml.Doc * doc = Xml.Parser.parse_file(filepath);
            if (doc == null) {
                /* File not found */
                debug("Xml.Parser : File not found : %s", filepath);
                Xml.Parser.cleanup();
                return;
            }
            Xml.XPath.Context ctx = new Xml.XPath.Context(doc);
            Xml.XPath.Object * res = ctx.eval_expression("//alias");
            for (int i = 0; i < res->nodesetval->length (); i++) {
                AliasElement ae = parse_alias_node(res->nodesetval->item(i));
                this[ae.family] = ae;
                debug("Loaded alias entry for %s", ae.family);
            }
            verbose("Xml.Parser : Closing : %s", filepath);
            delete res;
            delete doc;
            Xml.Parser.cleanup();
            return;
        }

        const string [] AE_PROPS = { "prefer", "accept", "default" };

        AliasElement parse_alias_node (Xml.Node * alias_node) {
            var ae = new AliasElement(null);
            for (Xml.Node * iter = alias_node->children; iter != null; iter = iter->next) {
                if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                    if (iter->name == "family") {
                        ae.family = iter->get_content();
                    } else {
                        unowned ObjectClass obj_cls = ((Object) ae).get_class();
                        ParamSpec? pspec = obj_cls.find_property(iter->name);
                        if (pspec != null && pspec.name in AE_PROPS) {
                            Gee.HashSet <string> l = new Gee.HashSet <string> ();
                            /* Object.get (name, out value ...); */
                            ((Object) ae).get(pspec.name, out l);
                            for (Xml.Node * _iter = iter->children; _iter != null; _iter = _iter->next) {
                                if (_iter->type == Xml.ElementType.ELEMENT_NODE) {
                                    if (_iter->name == "family")
                                        l.add(_iter->get_content());
                                }
                            }
                        } else {
                            verbose("Skipping unknown element : %s", iter->name);
                        }
                    }
                }
            }
            return ae;
        }

        void write_alias_element (XmlWriter writer, AliasElement ae) {
            if (ae.family == null)
                return;
            writer.start_element("alias");
            writer.write_element("family", ae.family);
            foreach (var prop in AE_PROPS) {
                writer.start_element(prop);
                var l = new Gee.HashSet <string> ();
                /* Object.get (name, out value ...); */
                ((Object) ae).get(prop, out l);
                foreach (string f in l)
                    writer.write_element("family", f);
                writer.end_element();
            }
            writer.end_element();
            return;
        }

    }

}
