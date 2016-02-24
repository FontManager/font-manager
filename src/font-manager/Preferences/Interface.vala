/* Interface.vala
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

namespace FontManager {

    namespace Preferences {

        public class Interface : Gtk.Grid {

            public LabeledSwitch wide_layout { get; private set; }
            public LabeledSwitch use_csd { get; private set; }

            construct {
                margin_top = margin_right = 24;
                wide_layout = new LabeledSwitch();
                wide_layout.label.set_markup(_("Wide Layout"));
                attach(wide_layout, 0, 0, 3, 1);
                use_csd = new LabeledSwitch();
                use_csd.label.set_markup(_("Client Side Decorations"));
                attach(use_csd, 0, 1, 3, 1);
            }

            public override void show () {
                wide_layout.show();
                use_csd.show();
                base.show();
                return;
            }

        }

    }

}


