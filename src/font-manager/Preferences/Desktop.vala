/* Desktop.vala
 *
 * Copyright (C) 2018 Jerry Casiano
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

    internal const string GNOME_INTERFACE_ID = "org.gnome.desktop.interface";
    internal const string GNOME_XSETTINGS_ID = "org.gnome.settings-daemon.plugins.xsettings";

    internal struct FontSettingKey {
        public string key;
        public string name;
        public string description;
        public string type;
    }

    internal const FontSettingKey [] DesktopSettings = {
        {
            "font-name",
            N_("Interface Font"),
            N_("Font used throughout interface."),
            "string",
        },
        {
            "document-font-name",
            N_("Document Font"),
            N_("Font used for reading documents."),
            "string",
        },
        {
            "monospace-font-name",
            N_("Monospace Font"),
            N_("Monospaced (fixed-width) font for use in locations such as terminals."),
            "string",
        },
        {
            "text-scaling-factor",
            N_("Text Scaling Factor"),
            N_("Factor used to enlarge or reduce text display, without changing font size"),
            "double",
        },
        {
            "antialiasing",
            N_("Antialiasing"),
            N_("The type of antialiasing to use when rendering fonts."),
            "int",
        },
        {
            "rgba-order",
            N_("RGBA order"),
            N_("The order of subpixel elements on an LCD screen; only used when antialiasing is set to rgba."),
            "int",
        },
        {
            "hinting",
            N_("Hinting"),
            N_("The type of hinting to use when rendering fonts."),
            "int",
        },
    };

    public class DesktopPreferences : SettingsPage {

        Gtk.Widget grid;

        static Settings? interface_settings = null;
        static Settings? x_settings = null;
        static bool initialized = false;

        public static bool available () {
            if (!initialized) {
                interface_settings = get_gsettings(GNOME_INTERFACE_ID);
                x_settings = get_gsettings(GNOME_XSETTINGS_ID);
                initialized = true;
            }
            return (interface_settings != null && x_settings != null);
        }

        public DesktopPreferences () {
            if (DesktopPreferences.available())
                grid = generate_options_grid(interface_settings, x_settings);
            else
                grid = new PlaceHolder(_("GNOME desktop settings schema not found"), "dialog-warning-symbolic");
            add(grid);
        }

        public override void show () {
            grid.show();
            base.show();
            return;
        }

        Gtk.Grid generate_options_grid (Settings? interface_settings,
                                        Settings? x_settings) {
            var grid = new Gtk.Grid();
            int left = 0, top = 0, width = 1, height = 1;
            Gtk.Revealer spg_revealer = new Gtk.Revealer();
            OptionScale? antialias = null;
            foreach (var setting in DesktopSettings) {
                Gtk.Widget? widget = null;
                if (setting.type == "string") {
                    widget = new LabeledFontButton(dgettext(null, setting.name));
                    interface_settings.bind(setting.key, widget, "font", SettingsBindFlags.DEFAULT);
                } else if (setting.type == "double") {
                    widget = new LabeledSpinButton(dgettext(null, setting.name), 0.5, 3.0, 0.1);
                    interface_settings.bind(setting.key, widget, "value", SettingsBindFlags.DEFAULT);
                } else if (setting.type == "int") {
                    if (setting.key != "rgba-order") {
                        string? [] options = null;
                        if (setting.key == "antialiasing")
                            options = { "None", "Grayscale", "RGBA" };
                        else if (setting.key == "hinting")
                            options = { "None", "Slight", "Medium", "Full" };
                        widget = new OptionScale(dgettext(null, setting.name), options);
                        var scale = widget as OptionScale;
                        if (setting.key == "antialiasing")
                            antialias = scale;
                        scale.value = (double) x_settings.get_enum(setting.key);
                        scale.notify["value"].connect(() => {
                            x_settings.set_enum(setting.key, (int) scale.value);
                        });
                        x_settings.changed.connect((key) => {
                            if (key != setting.key)
                                return;
                            var new_value = (double) x_settings.get_enum(setting.key);
                            if (scale.value != new_value)
                                scale.value = new_value;
                        });
                    } else {
                        widget = spg_revealer;
                        spg_revealer.set_transition_duration(450);
                        var spg = new SubpixelGeometry();
                        spg_revealer.add(spg);
                        spg.show();
                        spg.options.nth_data(0).hide();
                        spg.rgba = x_settings.get_enum(setting.key);
                        spg.notify["rgba"].connect(() => {
                            x_settings.set_enum(setting.key, spg.rgba);
                        });
                        x_settings.changed.connect((key) => {
                            if (key != setting.key)
                                return;
                            int new_value = x_settings.get_enum(setting.key);
                            if (spg.rgba != new_value)
                                spg.rgba = new_value;
                        });
                    }

                }
                if (widget == null)
                    continue;
                grid.attach(widget, left, top++, width, height);
                widget.set_tooltip_text(dgettext(null, setting.description));
                widget.show();
            }
            return_val_if_fail(antialias != null, grid);
            spg_revealer.set_reveal_child(antialias.value == 2);
            antialias.notify["value"].connect(() => {
                spg_revealer.set_reveal_child(antialias.value == 2);
            });
            return grid;
        }

    }

}
