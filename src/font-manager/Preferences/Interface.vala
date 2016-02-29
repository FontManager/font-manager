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

        public class Interface : Gtk.Grid {

            public LabeledSwitch wide_layout { get; private set; }
            public LabeledSwitch use_csd { get; private set; }

            Gtk.Box box;
            Gtk.Revealer wide_layout_options;
            Gtk.CheckButton on_maximize;

            construct {
                margin_top = margin_right = 24;
                wide_layout = new LabeledSwitch();
                wide_layout.label.set_markup(_("Wide Layout"));
                wide_layout_options = new Gtk.Revealer();
                on_maximize = new Gtk.CheckButton.with_label(_("Only when maximized"));
                on_maximize.margin = 12;
                wide_layout_options.margin_start = wide_layout_options.margin_end = 32;
                on_maximize.margin_start = on_maximize.margin_end = 48;
                use_csd = new LabeledSwitch();
                use_csd.label.set_markup(_("Client Side Decorations"));
                box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                box.margin = 6;
                var separator = add_separator(box, Gtk.Orientation.HORIZONTAL);
                separator.margin_start = separator.margin_end = 48;
                separator.opacity = 0.333;
                separator = add_separator(box, Gtk.Orientation.HORIZONTAL, Gtk.PackType.END);
                separator.margin_start = separator.margin_end = 48;
                separator.opacity = 0.333;
                box.pack_start(on_maximize, true, false, 0);
                wide_layout_options.add(box);
                attach(wide_layout, 0, 0, 1, 1);
                attach(wide_layout_options, 0, 1, 1, 1);
                attach(use_csd, 0, 2, 1, 1);
                connect_signals();
                bind_properties();
            }

            public override void show () {
                box.show();
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

            void connect_signals () {
                wide_layout.toggle.notify["active"].connect(() => {
                    wide_layout_options.set_reveal_child(wide_layout.toggle.get_active());
                });
                return;
            }

        }

    }

}


