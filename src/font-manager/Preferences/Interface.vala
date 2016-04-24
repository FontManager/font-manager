/* Interface.vala
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

namespace FontManager {

    namespace Preferences {

        public class Interface : Gtk.Box {

            public LabeledSwitch wide_layout { get; private set; }
            public LabeledSwitch use_csd { get; private set; }

            Gtk.Grid grid;
            Gtk.Label message;
            Gtk.InfoBar infobar;
            Gtk.Revealer wide_layout_options;
            Gtk.CheckButton on_maximize;

            construct {
                orientation = Gtk.Orientation.VERTICAL;
                wide_layout = new LabeledSwitch();
                wide_layout.label.set_markup(_("Wide Layout"));
                wide_layout_options = new Gtk.Revealer();
                on_maximize = new Gtk.CheckButton.with_label(_("Only when maximized"));
                on_maximize.margin = 6;
                on_maximize.margin_start = on_maximize.margin_end = 48;
                use_csd = new LabeledSwitch();
                use_csd.label.set_markup(_("Client Side Decorations"));
                message = new Gtk.Label(null);
                infobar = new Gtk.InfoBar();
                infobar.get_content_area().add(message);
                infobar.response.connect((id) => {
                    if (id == Gtk.ResponseType.CLOSE)
                        infobar.hide();
                });
                wide_layout_options.add(on_maximize);
                grid = new Gtk.Grid();
                grid.attach(wide_layout, 0, 0, 1, 1);
                grid.attach(wide_layout_options, 0, 1, 1, 1);
                grid.attach(use_csd, 0, 2, 1, 1);
                pack_start(infobar, false, false, 0);
                pack_end(grid, true, true, 0);
                connect_signals();
                bind_properties();
            }

            public override void show () {
                grid.show();
                message.show();
//                box.show();
                wide_layout.show();
                on_maximize.show();
                wide_layout_options.show();
                use_csd.show();
                base.show();
                return;
            }

            void bind_properties () {
                if (Main.instance.settings == null)
                    return;
                Main.instance.settings.bind("wide-layout-on-maximize", on_maximize, "active", SettingsBindFlags.DEFAULT);
                return;
            }

            void show_message (string m) {
                message.set_markup("<b>%s</b>".printf(m));
                infobar.show();
                Timeout.add_seconds(3, () => {
                    infobar.hide();
                    return false;
                });
                return;
            }

            void connect_signals () {
                wide_layout.toggle.notify["active"].connect(() => {
                    wide_layout_options.set_reveal_child(wide_layout.toggle.get_active());
                });
                use_csd.toggle.notify["active"].connect(() => {
                    if (use_csd.toggle.active)
                        show_message(_("CSD enabled. Change will take effect next time the application is started."));
                    else
                        show_message(_("CSD disabled. Change will take effect next time the application is started."));
                });
                /* XXX : Shouldn't need this... but do. */
                this.realize.connect(() => { infobar.hide(); });
                return;

            }

        }

    }

}


