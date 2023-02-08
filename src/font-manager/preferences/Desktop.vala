/* Desktop.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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
        {
            "font-antialiasing",
            N_("Antialiasing"),
            N_("The type of antialiasing to use when rendering fonts."),
            "int",
        },
        {
            "font-rgba-order",
            N_("RGBA order"),
            N_("The order of subpixel elements on an LCD screen; only used when antialiasing is set to rgba."),
            "int",
        },
        {
            "font-hinting",
            N_("Hinting"),
            N_("The type of hinting to use when rendering fonts."),
            "int",
        },
    };

    public class DesktopPreferences : Gtk.Box {

        static Settings? interface_settings = null;
        static Settings? x_settings = null;
        static bool initialized = false;
        Gtk.ListBox list;
        Gtk.ScrolledWindow scroll;

        public static bool available () {
            if (!initialized) {
                interface_settings = get_gsettings(GNOME_INTERFACE_ID);
                x_settings = get_gsettings(GNOME_XSETTINGS_ID);
                initialized = true;
            }
            return (interface_settings != null);
        }

        public DesktopPreferences () {
            Object(name: "FontManagerDesktopPreferences");
            list = new Gtk.ListBox();
            list.set_selection_mode(Gtk.SelectionMode.NONE);
            var place_holder = new PlaceHolder(null, null, _("GNOME desktop settings schema not found"), "dialog-warning-symbolic");
            list.set_placeholder(place_holder);
            place_holder.show();
            if (DesktopPreferences.available())
                generate_options_list(interface_settings, x_settings);
            scroll = new Gtk.ScrolledWindow();
            scroll.set_child(list);
            append(scroll);
        }

        void generate_options_list (Settings interface_settings,
                                    Settings? x_settings) {
            /* Settings instance to be used below for scale widgets */
            Settings? _settings = interface_settings;
            /* Ensure keys exist since we don't control these schemas and GSettings crashes on any error */
            SettingsSchemaSource default_schemas = SettingsSchemaSource.get_default();
            SettingsSchema? interface_schema = default_schemas.lookup(GNOME_INTERFACE_ID, true);
            string [] interface_keys = {};
            if (interface_schema != null)
                interface_keys = interface_schema.list_keys();
            string [] xsettings_keys = {};
            if ("font-antialiasing" in interface_keys) {
                x_settings = null;
            } else {
                SettingsSchema? xsettings_schema = default_schemas.lookup(GNOME_XSETTINGS_ID, true);
                if (xsettings_schema != null)
                    xsettings_keys = xsettings_schema.list_keys();
            }
            /* Newer key not found use deprecated xsettings keys if possible */
            if (x_settings != null)
                _settings = x_settings;
            Gtk.Revealer spg_revealer = new Gtk.Revealer();
            OptionScale? antialias = null;
            foreach (var setting in DesktopSettings) {
                if (!(setting.key in interface_keys) && !(setting.key in xsettings_keys))
                    continue;
                Gtk.Widget? widget = null;
                if (setting.type == "string") {
                    var control = new Gtk.FontButton();
                    widget = new PreferenceRow(dgettext(null, setting.name), null, null, control);
                    interface_settings.bind(setting.key, control, "font", SettingsBindFlags.DEFAULT);
                } else if (setting.type == "double") {
                    var control = new Gtk.SpinButton.with_range(0.5, 3.0, 0.1);
                    widget = new PreferenceRow(dgettext(null, setting.name), null, null, control);
                    interface_settings.bind(setting.key, control, "value", SettingsBindFlags.DEFAULT);
                } else if (setting.type == "int") {
                    if (!(setting.key.contains("rgba-order"))) {
                        string? [] options = null;
                        if (setting.key.contains("antialiasing"))
                            options = { "None", "Grayscale", "RGBA" };
                        else if (setting.key.contains("hinting"))
                            options = { "None", "Slight", "Medium", "Full" };
                        widget = new OptionScale(dgettext(null, setting.name), options);
                        var scale = widget as OptionScale;
                        if (setting.key.contains("antialiasing"))
                            antialias = scale;
                        scale.value = (double) _settings.get_enum(setting.key);
                        scale.notify["value"].connect(() => {
                            _settings.set_enum(setting.key, (int) scale.value);
                        });
                        _settings.changed.connect((key) => {
                            if (key != setting.key)
                                return;
                            var new_value = (double) _settings.get_enum(setting.key);
                            if (scale.value != new_value)
                                scale.value = new_value;
                        });
                    } else {
                        widget = spg_revealer;
                        spg_revealer.set_transition_duration(450);
                        var spg = new SubpixelGeometry();
                        spg_revealer.set_child(spg);
                        spg.options[0].hide();
                        spg.rgba = _settings.get_enum(setting.key);
                        spg.notify["rgba"].connect(() => {
                            _settings.set_enum(setting.key, spg.rgba);
                        });
                        _settings.changed.connect((key) => {
                            if (key != setting.key)
                                return;
                            int new_value = _settings.get_enum(setting.key);
                            if (spg.rgba != new_value)
                                spg.rgba = new_value;
                        });
                    }

                }
                if (widget == null)
                    continue;
                var row = new Gtk.ListBoxRow() { activatable = false, selectable = false };
                row.set_child(widget);
                list.insert(row, -1);
                widget.set_tooltip_text(dgettext(null, setting.description));
            }
            if (antialias != null) {
                spg_revealer.set_reveal_child(antialias.value == 2);
                antialias.notify["value"].connect(() => {
                    spg_revealer.set_reveal_child(antialias.value == 2);
                });
            }
            return;
        }

    }

}
