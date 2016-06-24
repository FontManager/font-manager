/* RenderingOptions.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    public class RenderingOptions : Gtk.Window {

        public FontConfig.FontProperties properties {
            get {
                return pane.properties;
            }
        }

        Gtk.Box box;
        Gtk.HeaderBar header_bar;
        FontConfig.FontPropertiesPane pane;
        FontConfig.Controls controls;

        public RenderingOptions () {
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            pane = new FontConfig.FontPropertiesPane();
            controls = new FontConfig.Controls();
            header_bar = new Gtk.HeaderBar();
            if (((Application) GLib.Application.get_default()).use_csd) {
                set_titlebar(header_bar);
                header_bar.show_close_button = true;
            } else {
                box.pack_start(header_bar, true, true, 0);
            }
            box.pack_start(pane, true, true, 0);
            box.pack_end(controls, false, false, 0);
            add(box);
            connect_signals();
        }

        public override void show () {
            pane.show();
            controls.show();
            header_bar.show();
            box.show();
            base.show();
            return;
        }

        void connect_signals () {
            controls.save_selected.connect(() => {
                properties.save();
                this.hide();
            });
            controls.discard_selected.connect(() => {
                properties.discard();
                this.hide();
            });
            delete_event.connect(() => {
                return this.hide_on_delete();
            });
            properties.changed.connect(() => {
                header_bar.set_title(properties.family);
                if (properties.font != null)
                    header_bar.set_subtitle(properties.font.style);
                else
                    header_bar.set_subtitle(null);
            });
            return;
        }

    }

}
