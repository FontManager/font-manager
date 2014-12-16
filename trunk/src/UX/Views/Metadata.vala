/* Metadata.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

internal const string font_desc_templ = "<span size=\"xx-large\" weight=\"bold\">%s</span>    <span size=\"large\" weight=\"bold\">%s</span>";


internal struct FontTypeEntry {

    public string name;
    public string tooltip;
    public string url;

    public FontTypeEntry (string name, string tooltip, string url) {
        this.name = name;
        this.tooltip = tooltip;
        this.url = url;
    }

}

namespace FontManager {

    internal class TypeInfoCache : Object {

        FontTypeEntry [] types = {
            FontTypeEntry("null", "", ""),
            FontTypeEntry("opentype", _("OpenType Font"), "http://wikipedia.org/wiki/OpenType"),
            FontTypeEntry("truetype", _("TrueType Font"), "http://wikipedia.org/wiki/TrueType"),
            FontTypeEntry("type1", _("PostScript Type 1 Font"), "http://wikipedia.org/wiki/Type_1_Font#Type_1"),
        };

        construct {
            var icon_theme = Gtk.IconTheme.get_default();
            icon_theme.add_resource_path("/org/gnome/FontManager/icons");
        }

        public void update (Gtk.Image icon, string key) {
            var entry = this[key];
            icon.set_from_icon_name(entry.name, Gtk.IconSize.DIALOG);
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

    public class BaseMetadata : Gtk.Grid {

        Gtk.Label font;
        Gtk.Image type_icon;

        TypeInfoCache type_info_cache;
        StandardTextView view;

        construct {
            font = new Gtk.Label(null);
            font.hexpand = true;
            font.halign = Gtk.Align.START;
            font.xpad = font.ypad = 12;
            type_info_cache = new TypeInfoCache();
            type_icon = new Gtk.Image.from_icon_name("null", Gtk.IconSize.DIALOG);
            type_icon.xpad = type_icon.ypad = 12;
            view = new StandardTextView(null);
            view.view.left_margin = view.view.right_margin = 12;
            view.view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            view.view.justification = Gtk.Justification.LEFT;
            view.view.pixels_above_lines = 1;
            view.hexpand = true;
            view.vexpand = true;
            view.margin_top = 3;
            view.set_size_request(0, 0);
            attach(font, 0, 0, 1, 1);
            attach(type_icon, 1, 0, 1, 1);
            attach(view, 0, 1, 2, 1);
            font.show();
            type_icon.show();
            view.show();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        }

        private void reset () {
            font.set_text("");
            type_info_cache.update(type_icon, "null");
            view.buffer.set_text("");
        }

        public void update (FontInfo? fontinfo, FontConfig.Font? fcfont) {
            this.reset();
            if (fontinfo == null || font == null)
                return;
            var font_desc = font_desc_templ.printf(fcfont.family, fcfont.style);
            font.set_markup(font_desc);
            var version_text = "Version %s".printf(fontinfo.version);
            view.buffer.set_text(version_text);
            if (fontinfo.vendor != "Unknown Vendor")
                view.buffer.set_text("%s\n%s".printf(view.get_buffer_text(), fontinfo.vendor));
            if (fontinfo.copyright != null)
                view.buffer.set_text("%s\n\n%s".printf(view.get_buffer_text(), fontinfo.copyright));
            if (fontinfo.description != null && fontinfo.description.length > 10)
                view.buffer.set_text("%s\n\n%s".printf(view.get_buffer_text(), fontinfo.description));
            view.buffer.set_text("%s\n".printf(view.get_buffer_text()));
            type_info_cache.update(type_icon, fontinfo.filetype);
            return;
        }

    }

}
