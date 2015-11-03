/* DefaultProperties.vala
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
            skip_property_assignment.add("modified");
            notify.connect((pspec) => {
                if (pspec.name == "modified")
                    return;
                if (!skip_property_assignment.contains(pspec.name))
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

}

