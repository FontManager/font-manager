/* Interface.vala
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-title-button-style.ui")]
    public class TitleButtonStyle : Gtk.Box {

        [GtkChild] unowned Gtk.ComboBoxText combo;

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
                MainWindow? main_window = get_default_application().main_window;
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
        Gtk.Revealer wide_layout_options;
        Gtk.CheckButton on_maximize;

        public UserInterfacePreferences () {
            wide_layout = new LabeledSwitch(_("Wide Layout"));
            wide_layout_options = new Gtk.Revealer();
            wide_layout_options.set_transition_duration(450);
            on_maximize = new Gtk.CheckButton.with_label(_("Only When Maximized"));
            on_maximize.margin = DEFAULT_MARGIN / 2;
            on_maximize.margin_start = on_maximize.margin_end = DEFAULT_MARGIN * 4;
            use_csd = new LabeledSwitch(_("Client Side Decorations"));
            wide_layout_options.add(on_maximize);
            on_maximize.show();
            wide_layout_options.show();
            enable_animations = new LabeledSwitch(_("Enable Animations"));
            prefer_dark_theme = new LabeledSwitch(_("Prefer Dark Theme"));
            button_style = new TitleButtonStyle();
            var scroll = new Gtk.ScrolledWindow(null, null);
            var list = new Gtk.ListBox();
            Gtk.Widget [] widgets = { wide_layout, wide_layout_options, use_csd,
                                      enable_animations, prefer_dark_theme, button_style };
            foreach (var widget in widgets) {
                var row = new Gtk.ListBoxRow() {
                    activatable = false,
                    selectable = false
                };
                row.add(widget);
                list.add(row);
                widget.show();
                row.show();
            }
            box.pack_end(scroll);
            scroll.add(list);
            list.show();
            scroll.show();
            default_gtk_settings = Gtk.Settings.get_default();
            connect_signals();
            bind_properties();
            revealer.set_reveal_child(false);
        }

        void bind_properties () {
            GLib.Settings? settings = get_default_application().settings;
            return_if_fail(settings != null);
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("use-csd", use_csd.toggle, "active", flags);
            settings.bind("wide-layout", wide_layout.toggle, "active", flags);
            settings.bind("wide-layout-on-maximize", on_maximize, "active", flags);
            settings.bind("enable-animations", enable_animations.toggle, "active", flags);
            settings.bind("prefer-dark-theme", prefer_dark_theme.toggle, "active", flags);
            settings.bind("title-button-style", button_style, "active", flags);
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
