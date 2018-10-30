/* Interface.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

namespace FontManager {

    public class UserInterfacePreferences : SettingsPage {

        public LabeledSwitch wide_layout { get; private set; }
        public LabeledSwitch use_csd { get; private set; }

        Gtk.Grid grid;
        Gtk.Revealer wide_layout_options;
        Gtk.CheckButton on_maximize;

        public UserInterfacePreferences () {
            orientation = Gtk.Orientation.VERTICAL;
            wide_layout = new LabeledSwitch();
            wide_layout.label.set_markup(_("Wide Layout"));
            wide_layout_options = new Gtk.Revealer();
            on_maximize = new Gtk.CheckButton.with_label(_("Only when maximized"));
            on_maximize.margin = DEFAULT_MARGIN_SIZE / 2;
            on_maximize.margin_start = on_maximize.margin_end = DEFAULT_MARGIN_SIZE * 2;
            use_csd = new LabeledSwitch();
            use_csd.label.set_markup(_("Client Side Decorations"));
            wide_layout_options.add(on_maximize);
            grid = new Gtk.Grid();
            grid.attach(wide_layout, 0, 0, 1, 1);
            grid.attach(wide_layout_options, 0, 1, 1, 1);
            grid.attach(use_csd, 0, 2, 1, 1);
            pack_end(grid, true, true, 0);
            connect_signals();
            bind_properties();
        }

        public override void show () {
            grid.show();
            wide_layout.show();
            on_maximize.show();
            wide_layout_options.show();
            use_csd.show();
            base.show();
            return;
        }

        void bind_properties () {
            return_if_fail(settings != null);
            settings.bind("use-csd", use_csd.toggle, "active", SettingsBindFlags.DEFAULT);
            settings.bind("wide-layout", wide_layout.toggle, "active", SettingsBindFlags.DEFAULT);
            settings.bind("wide-layout-on-maximize", on_maximize, "active", SettingsBindFlags.DEFAULT);
            return;
        }

        void connect_signals () {
            wide_layout.toggle.state_set.connect((active) => {
                wide_layout_options.set_reveal_child(active);
                return false;
            });
            use_csd.toggle.state_set.connect((active) => {
                if (active)
                    show_message(_("CSD enabled. Change will take effect next time the application is started."));
                else
                    show_message(_("CSD disabled. Change will take effect next time the application is started."));
                return false;
            });
            return;

        }

    }

}
