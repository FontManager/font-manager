/* CharacterTable.vala
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

    public class CharacterTable : AdjustablePreview {

        public unichar active_character { get; set; }

        public Gucharmap.Chartable table { get; private set; }

        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = table.font_desc = value;
            }
        }

        private Gtk.Box table_box;
        private Gtk.ScrolledWindow scroll;
        private Pango.FontDescription _font_desc;

        public CharacterTable () {
            base.init();
            orientation = Gtk.Orientation.VERTICAL;
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            table = new Gucharmap.Chartable();
            table.font_fallback = false;
            table.zoom_enabled = true;
            table.codepoint_list = new Gucharmap.ScriptCodepointList();
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            scroll = new Gtk.ScrolledWindow(null, null);
            table_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            scroll.add(table);
            table_box.pack_end(fontscale, false, true, 1);
            table_box.pack_end(scroll, true, true, 1);
            pack_end(table_box, true, true, 0);
            table.bind_property("active-character", this, "active-character", BindingFlags.SYNC_CREATE);
        }

        public override void show () {
            table.show();
            table_box.show();
            fontscale.show();
            scroll.show();
            base.show();
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            _font_desc.set_size((int) (new_size * Pango.SCALE));
            font_desc = _font_desc;
            return;
        }

    }

}
