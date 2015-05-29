/* DisplayProperties.vala
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

    public class DisplayProperties : Properties {

        public int rgba { get; set; default = 1; }
        public int lcdfilter { get; set; default = 1; }
        public double scale { get; set; default = 1.00; }
        public double dpi { get; set; default = 96; }

        public DisplayProperties () {
            target_file = Path.build_filename(get_config_dir(), "19-DisplayProperties.conf");
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

}
