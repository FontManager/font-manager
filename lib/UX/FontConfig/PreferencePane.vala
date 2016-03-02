/* PreferencePane.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    public class PreferencePane : Gtk.Box {

        protected Gtk.Label message;
        protected Gtk.InfoBar infobar;
        protected FontConfig.Controls controls;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            controls = new FontConfig.Controls();
            infobar = new Gtk.InfoBar();
            infobar.message_type = Gtk.MessageType.INFO;
            message = new Gtk.Label(null);
            infobar.get_content_area().add(message);
            pack_start(infobar, false, false, 0);
            pack_end(controls, false, false, 0);
            infobar.response.connect((id) => {
                if (id == Gtk.ResponseType.CLOSE)
                    infobar.hide();
            });
        }

        public override void show () {
            message.show();
            controls.show();
            base.show();
            return;
        }

        protected void show_message (string m) {
            message.set_markup("<b>%s</b>".printf(m));
            infobar.show();
            Timeout.add_seconds(3, () => {
                infobar.hide();
                return false;
            });
            return;
        }

    }

}
