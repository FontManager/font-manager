/* Interface.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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


    /**
     * TitleButtonStyle:
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-title-button-style.ui")]
    public class TitleButtonStyle : Gtk.Box {

        [GtkChild] Gtk.ComboBoxText combo;

        /**
         * LabeledSpinButton:value:
         *
         * Current value.
         */
        public string active {
            get {
                return combo.get_active() == 0 ? "Normal" : "Flat";
            }
            set {
                combo.set_active(value == "Normal" ? 0 : 1);
            }
        }

        construct {
            combo.changed.connect(() => {
                this.notify_property("active");
                if (main_window != null) {
                    var style = active == "Normal" ? Gtk.ReliefStyle.NORMAL : Gtk.ReliefStyle.NONE;
                    main_window.titlebar.set_button_style(style);
                }
            });
        }

    }

    public class UserInterfacePreferences : SettingsPage {

        public LabeledSwitch wide_layout { get; private set; }
        public LabeledSwitch use_csd { get; private set; }
        public LabeledSwitch enable_animations { get; private set; }
        public LabeledSwitch prefer_dark_theme { get; private set; }
        public TitleButtonStyle button_style { get; private set; }

        Gtk.Settings default_gtk_settings;
        Gtk.Grid grid;
        Gtk.Revealer wide_layout_options;
        Gtk.CheckButton on_maximize;

        public UserInterfacePreferences () {
            wide_layout = new LabeledSwitch(_("Wide Layout"));
            wide_layout_options = new Gtk.Revealer();
            wide_layout_options.set_transition_duration(450);
            on_maximize = new Gtk.CheckButton.with_label(_("Only When Maximized"));
            on_maximize.margin = DEFAULT_MARGIN_SIZE / 2;
            on_maximize.margin_start = on_maximize.margin_end = DEFAULT_MARGIN_SIZE * 2;
            use_csd = new LabeledSwitch(_("Client Side Decorations"));
            wide_layout_options.add(on_maximize);
            on_maximize.show();
            wide_layout_options.show();
            enable_animations = new LabeledSwitch(_("Enable Animations"));
            prefer_dark_theme = new LabeledSwitch(_("Prefer Dark Theme"));
            button_style = new TitleButtonStyle();
            grid = new Gtk.Grid();
            grid.attach(wide_layout, 0, 0, 1, 1);
            grid.attach(wide_layout_options, 0, 1, 1, 1);
            grid.attach(use_csd, 0, 2, 1, 1);
            grid.attach(enable_animations, 0, 3, 1, 1);
            grid.attach(prefer_dark_theme, 0, 4, 1, 1);
            grid.attach(button_style, 0, 5, 1, 1);
            box.pack_end(grid, true, true, 0);
            default_gtk_settings = Gtk.Settings.get_default();
            connect_signals();
            bind_properties();
            revealer.set_reveal_child(false);
            grid.show();
        }

        void bind_properties () {
            return_if_fail(settings != null);
            settings.bind("use-csd", use_csd.toggle, "active", SettingsBindFlags.DEFAULT);
            settings.bind("wide-layout", wide_layout.toggle, "active", SettingsBindFlags.DEFAULT);
            settings.bind("wide-layout-on-maximize", on_maximize, "active", SettingsBindFlags.DEFAULT);
            settings.bind("enable-animations", enable_animations.toggle, "active", SettingsBindFlags.DEFAULT);
            settings.bind("prefer-dark-theme", prefer_dark_theme.toggle, "active", SettingsBindFlags.DEFAULT);
            settings.bind("title-button-style", button_style, "active", SettingsBindFlags.DEFAULT);
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
            enable_animations.toggle.state_set.connect((active) => {
                default_gtk_settings.gtk_enable_animations = active;
                return false;
            });
            prefer_dark_theme.toggle.state_set.connect((active) => {
                default_gtk_settings.gtk_application_prefer_dark_theme = active;
                return false;
            });
            return;

        }

    }

}
