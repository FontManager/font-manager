/* Desktop.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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
            "font-rendering",
            N_("GTK 4 Font Rendering"),
            N_("Automatic option allows GTK 4 to disregard hinting settings."),
            "bool",
        },
        {
            "antialiasing",
            N_("Antialiasing"),
            N_("The type of antialiasing to use when rendering fonts.\n\nNote : Does not apply to GTK 4 or later."),
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
            "font-hinting",
            N_("Hinting"),
            N_("The type of hinting to use when rendering fonts."),
            "int",
        },
        {
            "font-antialiasing",
            N_("Antialiasing"),
            N_("The type of antialiasing to use when rendering fonts.\n\nNote : Does not apply to GTK 4 or later."),
            "int",
        },
        {
            "font-rgba-order",
            N_("RGBA order"),
            N_("The order of subpixel elements on an LCD screen; only used when antialiasing is set to rgba."),
            "int",
        },
    };

    public class DesktopPreferences : PreferenceList {

        static bool initialized = false;
        static Settings? interface_settings = null;
        static Settings? x_settings = null;

        static bool available () {
            if (!initialized) {
                interface_settings = get_gsettings(GNOME_INTERFACE_ID);
                x_settings = get_gsettings(GNOME_XSETTINGS_ID);
                initialized = true;
            }
            return (interface_settings != null);
        }

        public DesktopPreferences () {
            widget_set_name(this, "FontManagerDesktopPreferences");
            list.set_selection_mode(Gtk.SelectionMode.NONE);
            var place_holder = new PlaceHolder(null, null,
                                               _("GNOME desktop settings schema not found"),
                                                 "computer-fail-symbolic");
            list.set_placeholder(place_holder);
        }

        protected override void on_map () {
            if (initialized)
                return;
            if (DesktopPreferences.available())
                generate_options_list();
            return;
        }

        static string? [] get_enum_values (string k) {
            if (k.contains("antialiasing"))
                return { "none", "grayscale" ,"rgba" };
            else if (k.contains("hinting"))
                return { "none", "slight" ,"medium", "full" };
            else if (k.contains("rgba"))
                return { "rgba", "rgb", "bgr", "vrgb", "vbgr" };
            else if (k.contains("font-rendering"))
                return { "automatic", "manual" };
            else
                return_val_if_reached(null);
        }

        static bool from_enum_setting (Value v, Variant r, string k) {
            string s = r.get_string();
            string? [] settings = get_enum_values(k);
            for (uint i = 0; i < settings.length; i++) {
                if (s == settings[i]) {
                    v.set_uint(i);
                    break;
                }
            }
            return true;
        }

        static Variant to_enum_setting (Value v, VariantType t, string k) {
            string? [] settings = get_enum_values(k);
            string s = settings[(uint) v];
            return new Variant.string(s);
        }

        static bool from_font_setting (Value v, Variant r, string k) {
            // ??? : Not using a variable here results in leaking the description?
            Pango.FontDescription font_desc = Pango.FontDescription.from_string(r.get_string());
            v.set_boxed(font_desc);
            return true;
        }

        static Variant to_font_setting (Value v, VariantType t, string k) {
            var font_desc = (Pango.FontDescription) v.get_boxed();
            return new Variant.string(font_desc.to_string());
        }

        void generate_options_list () {
            // Settings instance to be used below
            Settings? _settings = interface_settings;
            // Ensure keys exist since we don't control these schemas and GSettings crashes on any error
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
            // Newer key not found use deprecated xsettings keys if possible
            if (x_settings != null)
                _settings = x_settings;
            SubpixelGeometry spg = new SubpixelGeometry() { margin_top = DEFAULT_MARGIN * 3};
            spg.options[SubpixelOrder.UNKNOWN].set_visible(false);
            spg.options[SubpixelOrder.NONE].set_visible(false);
            foreach (var setting in DesktopSettings) {
                if (!(setting.key in interface_keys) && !(setting.key in xsettings_keys))
                    continue;
                Gtk.Widget? widget = null;
                if (setting.type == "string") {
                    var dialog = new Gtk.FontDialog();
                    var control = new Gtk.FontDialogButton(dialog);
                    widget = new PreferenceRow(dgettext(null, setting.name), null, null, control);
                    interface_settings.bind_with_mapping(setting.key, control, "font-desc",
                                                          SettingsBindFlags.DEFAULT,
                                                          from_font_setting,
                                                          to_font_setting,
                                                          setting.key, null);
                } else if (setting.type == "bool") {
                    if (setting.key.contains("font-rendering")) {
                        string [] options = { _("Automatic"), _("Manual") };
                        var option_list = new Gtk.StringList(options);
                        var combo = new Gtk.DropDown(option_list, null);
                        widget = new PreferenceRow(dgettext(null, setting.name), null, null, combo);
                        _settings.bind_with_mapping(setting.key, combo, "selected",
                                                    SettingsBindFlags.DEFAULT,
                                                    from_enum_setting,
                                                    to_enum_setting,
                                                    setting.key, null);
                    }
                } else if (setting.type == "double") {
                    var control = new Gtk.SpinButton.with_range(0.5, 3.0, 0.1);
                    widget = new PreferenceRow(dgettext(null, setting.name), null, null, control);
                    interface_settings.bind(setting.key, control, "value", SettingsBindFlags.DEFAULT);
                } else if (setting.type == "int") {
                    Object? target = null;
                    if (!(setting.key.contains("rgba-order"))) {
                        string? [] options = null;
                        if (setting.key.contains("antialiasing"))
                            options = { _("None"), _("Grayscale"), _("RGBA") };
                        else if (setting.key.contains("hinting"))
                            options = { _("None"), _("Slight"), _("Medium"), _("Full") };
                        var option_list = new Gtk.StringList(options);
                        var combo = new Gtk.DropDown(option_list, null);
                        target = combo;
                        widget = new PreferenceRow(dgettext(null, setting.name), null, null, combo);
                        if (setting.key.contains("antialiasing")) {
                            var child = new PreferenceRow(_("Subpixel Geometry"), null, null, spg);
                            var parent = widget as PreferenceRow;
                            parent.append_child(child);
                            parent.set_reveal_child(combo.selected == 2);
                            combo.notify["selected"].connect(() => {
                                parent.set_reveal_child(combo.selected == 2);
                            });
                        }
                    } else {
                        target = spg;
                        var pref_row = spg.get_ancestor(typeof(PreferenceRow));
                        pref_row.set_tooltip_text(dgettext(null, setting.description));
                    }
                    _settings.bind_with_mapping(setting.key, target, "selected",
                                                SettingsBindFlags.DEFAULT,
                                                from_enum_setting,
                                                to_enum_setting,
                                                setting.key, null);
                }
                if (widget == null)
                    continue;
                widget.set_tooltip_text(dgettext(null, setting.description));
                append_row(widget);
            }
            return;
        }

    }

}

