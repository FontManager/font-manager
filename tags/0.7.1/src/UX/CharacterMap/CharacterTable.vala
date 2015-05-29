/* CharacterTable.vala
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


namespace FontManager {

    public class CharacterTable : AdjustablePreview {

        public signal void active_character (unichar uc);

        public Gucharmap.Chartable table { get; private set; }

        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = table.font_desc = value;
            }
        }

        Pango.FontDescription _font_desc;

        public CharacterTable () {
            base.init();
            orientation = Gtk.Orientation.VERTICAL;
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            table = new Gucharmap.Chartable();
            table.font_fallback = false;
            table.zoom_enabled = true;
            table.codepoint_list = new Gucharmap.ScriptCodepointList();
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            var scroll = new Gtk.ScrolledWindow(null, null);
            var table_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            scroll.add(table);
            table_box.pack_end(fontscale, false, true, 0);
            table_box.pack_end(scroll, true, true, 0);
            pack_end(table_box, true, true, 0);
            table.show();
            table_box.show();
            fontscale.show();
            scroll.show();
            connect_signals();
        }

        internal void connect_signals () {
            table.notify["active-character"].connect(() => {
                active_character(table.get_active_character());
            });
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            _font_desc.set_size((int) (new_size * Pango.SCALE));
            font_desc = _font_desc;
            return;
        }

    }

}
