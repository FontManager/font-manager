/* PreviewColors.vala
 *
 * Copyright (C) 2022-2025 Jerry Casiano
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

    const string TEXT_PREVIEW_CSS = """
    .FontManagerFontPreviewArea, .FontManagerPreviewArea text {
        color: %s;
        background-color: %s;
    }
    .FontManagerFontPreviewArea text selection {
        color: %s;
        background-color: %s;
    }
    """;

    [SingleInstance]
    public class PreviewColorsCSSProvider : Object {

        public signal void style_updated ();

        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public GLib.Settings settings { get; set; }

        Gtk.CssProvider css_provider;

        construct {
            css_provider = new Gtk.CssProvider();
            Gdk.Display display = Gdk.Display.get_default();
            Gtk.StyleContext.add_provider_for_display(display, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }

        public PreviewColorsCSSProvider (GLib.Settings? settings) {
            Object(settings: settings);
            restore_state();
        }

        public void update_style () {
            string bg = background_color.to_string();
            string fg = foreground_color.to_string();
            string CSS = TEXT_PREVIEW_CSS.printf(fg, bg, bg, fg);
            css_provider.load_from_string(CSS);
            style_updated();
            return;
        }

        public void register_controls (PreviewColors controls) {
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("background-color", controls.bg_color_button, "rgba", flags);
            bind_property("foreground-color", controls.fg_color_button, "rgba", flags);
            return;
        }

        void update_default_colors_if_needed () {
            if (settings == null)
                return;
            bool prefer_dark = settings.get_boolean("prefer-dark-theme");
            var default_light_bg = Gdk.RGBA();
            var default_light_fg = Gdk.RGBA();
            var default_dark_bg = Gdk.RGBA();
            var default_dark_fg = Gdk.RGBA();
            default_light_bg.parse("white");
            default_light_fg.parse("black");
            default_dark_bg.parse("black");
            default_dark_fg.parse("white");
            if (prefer_dark) {
                if (foreground_color.equal(default_light_fg) && background_color.equal(default_light_bg)) {
                    foreground_color = default_dark_fg;
                    background_color = default_dark_bg;
                }
            } else {
                if (foreground_color.equal(default_dark_fg) && background_color.equal(default_dark_bg)) {
                    foreground_color = default_light_fg;
                    background_color = default_light_bg;
                }
            }
            return;
        }

        void restore_state () {
            if (settings == null) {
                warning("NULL settings instance in use : Preview Colors will not work as expected");
            }
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind_with_mapping("preview-foreground-color",
                                       this,
                                       "foreground-color",
                                       flags,
                                       (GLib.SettingsBindGetMappingShared) PreviewColorsCSSProvider.from_setting,
                                       (GLib.SettingsBindSetMappingShared) PreviewColorsCSSProvider.to_setting,
                                       null, null);
            settings.bind_with_mapping("preview-background-color",
                                       this,
                                       "background-color",
                                       flags,
                                       (GLib.SettingsBindGetMappingShared) PreviewColorsCSSProvider.from_setting,
                                       (GLib.SettingsBindSetMappingShared) PreviewColorsCSSProvider.to_setting,
                                       null, null);
            settings.changed.connect((key) => {
                if (key.contains("color"))
                    update_style();
                if (key.contains("dark")) {
                    update_default_colors_if_needed();
                    update_style();
                }
            });
            update_default_colors_if_needed();
            update_style();
            return;
        }

        // GSettingsBind*Mapping functions

        public static Variant to_setting (Value val, VariantType type) {
            return new Variant.string(((Gdk.RGBA) val).to_string());
        }

        public static bool from_setting (Value val, Variant variant) {
            Gdk.RGBA rgba = Gdk.RGBA();
            string rgba_string = variant.get_string();
            bool result = rgba.parse(rgba_string);
            val.set_boxed(&rgba);
            return result;
        }


    }


    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-preview-colors.ui")]
    public class PreviewColors : Gtk.Box {

        [GtkChild] public unowned Gtk.ColorDialogButton bg_color_button { get; }
        [GtkChild] public unowned Gtk.ColorDialogButton fg_color_button { get; }

        void flatten_color_button (Gtk.ColorDialogButton button) {
            button.get_first_child().remove_css_class("color");
            button.get_first_child().add_css_class("flat");
            return;
        }

        public override void constructed () {
            flatten_color_button(bg_color_button);
            flatten_color_button(fg_color_button);
            base.constructed();
            return;
        }

    }

}

