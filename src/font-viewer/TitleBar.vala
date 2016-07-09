/* TitleBar.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontManager {

    namespace Metadata {

        public class TitleBar : Gtk.HeaderBar {

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

                public new FontTypeEntry get (string key) {
                    var _key = key.down().replace(" ", "");
                    foreach (var entry in types)
                        if (entry.name == _key)
                            return entry;
                    return types[0];
                }

                public void update (Gtk.Image icon, string key) {
                    var entry = this[key];
                    icon.set_from_icon_name(entry.name, Gtk.IconSize.LARGE_TOOLBAR);
                    icon.set_tooltip_text(entry.tooltip);
                }

            }

            Gtk.Image type_icon;
            TypeInfoCache type_info_cache;

            construct {
                show_close_button = true;
                spacing = 6;
                type_info_cache = new TypeInfoCache();
                type_icon = new Gtk.Image();
                reset();
                pack_start(type_icon);
                get_style_context().add_class("MetadataTitle");
            }

            public override void show () {
                type_icon.show();
                base.show();
                return;
            }

            void reset () {
                set_title(null);
                set_subtitle(null);
                type_info_cache.update(type_icon, "null");
                return;
            }

            public virtual void update (string? family, string? style, string? filetype) {
                this.reset();
                if (family == null && style == null) {
                    set_title(_("No file selected"));
                    set_subtitle(_("Or unsupported filetype."));
                    return;
                }
                set_title(family);
                set_subtitle(style);
                const string tt_tmpl = "<big><b>%s</b> </big><b>%s</b>";
                set_tooltip_markup(tt_tmpl.printf(Markup.escape_text(family), style));
                type_info_cache.update(type_icon, filetype);
                return;
            }

        }

    }

}
