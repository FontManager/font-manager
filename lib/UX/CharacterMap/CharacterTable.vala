/* CharacterTable.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontManager {

    public class CharacterTable : AdjustablePreview {

        public unichar active_character { get; set; }
        public bool show_details { get; set; default = false; }

        public Gucharmap.Chartable table { get; private set; }
        public CharacterDetails details { get; private set; }

        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            /* XXX : Bug?
             * Workaround broken rendering by temporarily changing size.
             * This does cause visual glitches.
             * But without it rendering at current size may fail when font changes.
             */
            set {
                if (_font_desc == null) {
                    _font_desc = table.font_desc = value;
                    return;
                }
                preview_size = preview_size - 0.1;
                _font_desc = table.font_desc = value;
                preview_size = preview_size + 0.1;
            }
        }

        Gtk.ScrolledWindow scroll;
        Pango.FontDescription _font_desc;

        public CharacterTable () {
            orientation = Gtk.Orientation.VERTICAL;
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            table = new Gucharmap.Chartable();
            table.font_fallback = false;
            table.zoom_enabled = false;
            table.codepoint_list = new Gucharmap.ScriptCodepointList();
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            scroll = new Gtk.ScrolledWindow(null, null);
            details = new CharacterDetails();
            scroll.add(table);
            pack_start(details, false, true, 0);
            pack_start(scroll, true, true, 1);
            table.bind_property("active-character", this, "active-character", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            table.bind_property("active-character", details, "active-character", BindingFlags.SYNC_CREATE);
            notify["show-details"].connect(() => {
                if (show_details)
                    details.show();
                else
                    details.hide();
            });
        }

        public override void show () {
            table.show();
            scroll.show();
            if (show_details)
                details.show();
            base.show();
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            _font_desc.set_size((int) (new_size * Pango.SCALE));
            table.font_desc = _font_desc;
            return;
        }

    }

}
