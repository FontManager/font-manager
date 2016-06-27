/* Directories.vala
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
     * Directories - Represents a Fontconfig configuration file
     *
     * @config_dir      directory to store configuration file
     * @target_file     filename following the form [0][0-9]*.conf
     *
     * <dir> elements contain a directory name which will be scanned
     * for font files to include in the set of available fonts.
     *
     * Is actually a #Gee.HashSet holding directory paths.
     * Provides methods to save() / load() configuration files.
     */
    public class Directories : Selections {

        public Directories () {
            target_element = "dir";
            target_file = "09-Directories.conf";
        }

        protected override void parse (Xml.Node * root) {
            parse_node(root->children);
        }

        protected override void write_node (XmlWriter writer) {
            foreach (string path in this)
                writer.write_element(target_element, Markup.escape_text(path.strip()));
            return;
        }

    }

}
