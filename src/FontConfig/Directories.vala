/* Directories.vala
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

    public class Directories : Selections {

        construct {
            target_element = "dir";
            target_file = "09-Directories.conf";
        }

        protected new virtual void parse (Xml.Node * root) {
            parse_node(root->children);
        }

        protected override void write_node (XmlWriter writer) {
            foreach (string path in this)
                writer.write_element(target_element, path.strip());
            return;
        }

    }

}
