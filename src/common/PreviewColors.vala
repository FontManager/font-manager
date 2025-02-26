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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-preview-colors.ui")]
    public class PreviewColors : Gtk.Box {

        public signal void style_updated ();

        public Gdk.RGBA foreground_color { get; set; }
        public Gdk.RGBA background_color { get; set; }
        public GLib.Settings settings { get; set; }

        [GtkChild] unowned Gtk.ColorDialogButton bg_color_button;
        [GtkChild] unowned Gtk.ColorDialogButton fg_color_button;

        Gtk.CssProvider css_provider;

        public void update_style () {
            css_provider.load_from_string(@".FontManagerFontPreviewArea {color: $foreground_color;background-color: $background_color;} .FontManagerFontPreviewArea text selection {color: $background_color;background-color: $foreground_color;}");
            style_updated();
            return;
        }

        void flatten_color_button (Gtk.ColorDialogButton button) {
            button.get_first_child().remove_css_class("color");
            button.get_first_child().add_css_class("flat");
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

        public void restore_state (GLib.Settings settings) {
            this.settings = settings;
            if (settings == null)
                return;
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind_with_mapping("preview-foreground-color",
                                       fg_color_button,
                                       "rgba",
                                       flags,
                                       (GLib.SettingsBindGetMappingShared) PreviewColors.from_setting,
                                       (GLib.SettingsBindSetMappingShared) PreviewColors.to_setting,
                                       null, null);
            settings.bind_with_mapping("preview-background-color",
                                       bg_color_button,
                                       "rgba",
                                       flags,
                                       (GLib.SettingsBindGetMappingShared) PreviewColors.from_setting,
                                       (GLib.SettingsBindSetMappingShared) PreviewColors.to_setting,
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

        public override void constructed () {
            flatten_color_button(bg_color_button);
            flatten_color_button(fg_color_button);
            css_provider = new Gtk.CssProvider();
            Gdk.Display display = Gdk.Display.get_default();
            Gtk.StyleContext.add_provider_for_display(display, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bg_color_button.bind_property("rgba", this, "background-color", flags);
            fg_color_button.bind_property("rgba", this, "foreground-color", flags);
            map.connect(() => {
                update_default_colors_if_needed();
                update_style();
            });
            base.constructed();
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

}
