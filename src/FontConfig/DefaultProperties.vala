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

        public int hintstyle { get; set; default = 1; }
        public bool antialias { get; set; default = true; }
        public bool hinting { get; set; default = true; }
        public bool autohint { get; set; default = false; }
        public bool embeddedbitmap { get; set; default = false; }

        public DefaultProperties () {
            skip_property_assignment.add("family");
            skip_property_assignment.add("font");
            target_file = Path.build_filename(get_config_dir(), "19-DefaultProperties.conf");
            load();
        }

        public override void reset_properties () {
            hintstyle = 1;
            antialias = true;
            hinting = true;
            autohint = false;
            embeddedbitmap = false;
            return;
        }

    }

}

