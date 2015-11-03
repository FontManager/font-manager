/* Title.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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

    namespace Metadata {

        const string font_desc_templ = "<span size=\"xx-large\" weight=\"bold\">%s</span>    <span size=\"large\" weight=\"bold\">%s</span>";

        struct FontTypeEntry {

            public string name;
            public string tooltip;
            public string url;

            public FontTypeEntry (string name, string tooltip, string url) {
                this.name = name;
                this.tooltip = tooltip;
                this.url = url;
            }

        }

        class TypeInfoCache : Object {

            FontTypeEntry [] types = {
                FontTypeEntry("null", "", ""),
                FontTypeEntry("opentype", _("OpenType Font"), "http://wikipedia.org/wiki/OpenType"),
                FontTypeEntry("truetype", _("TrueType Font"), "http://wikipedia.org/wiki/TrueType"),
                FontTypeEntry("type1", _("PostScript Type 1 Font"), "http://wikipedia.org/wiki/Type_1_Font#Type_1"),
            };

            public void update (Gtk.Image icon, string key) {
                var entry = this[key];
            #if GTK_314_OR_LATER
                icon.set_from_icon_name(entry.name, Gtk.IconSize.DIALOG);
            #else
                icon.set_from_resource("/org/gnome/FontManager/icons/%s.svg".printf(entry.name));
            #endif
                icon.set_tooltip_text(entry.tooltip);
            }

            public new FontTypeEntry get (string key) {
                var _key = key.down().replace(" ", "");
                foreach (var entry in types)
                    if (entry.name == _key)
                        return entry;
                return types[0];
            }

        }

        public class Title : Gtk.Grid {

            Gtk.Label font;
            Gtk.Image type_icon;
            TypeInfoCache type_info_cache;

            construct {
                font = new Gtk.Label(null);
                font.hexpand = true;
                font.halign = Gtk.Align.START;
                font.margin_start = font.margin_end = 12;
                font.margin_top = font.margin_bottom = 6;
                type_info_cache = new TypeInfoCache();
                type_icon = new Gtk.Image.from_icon_name("null", Gtk.IconSize.DIALOG);
                type_icon.margin_start = type_icon.margin_end = 12;
                type_icon.margin_top = type_icon.margin_bottom = 6;
                attach(font, 0, 0, 1, 1);
                attach(type_icon, 1, 0, 1, 1);
                get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            }

            public override void show () {
                font.show();
                type_icon.show();
                base.show();
                return;
            }

            void reset () {
                font.set_text("");
                type_info_cache.update(type_icon, "null");
                return;
            }

            public virtual void update (string? family, string? style, string? filetype) {
                this.reset();
                if (family == null && style == null) {
                    var font_desc = font_desc_templ.printf(_("No file selected"), _("Or unsupported filetype."));
                    font.set_markup(font_desc);
                    return;
                }
                var font_desc = font_desc_templ.printf(family, style);
                font.set_markup(font_desc);
                type_info_cache.update(type_icon, filetype);
                return;
            }

        }

    }

}
