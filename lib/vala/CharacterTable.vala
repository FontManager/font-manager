/* CharacterTable.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    public class BaseCharacterMap : Unicode.CharacterMap {

        public override bool button_press_event (Gdk.EventButton event) {
            return base.button_press_event(event);
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-character-map.ui")]
    public class CharacterMap : Gtk.Box {

        public int count { get; set; default = 0; }
        public double preview_size { get; set;}
        public unichar active_character { get; set; }

        public Font? selected_font { get; set; default = null; }
        public BaseCharacterMap table { get; private set; }
        public Gtk.Adjustment adjustment { get; set;}

        bool _visible_ = false;
        bool _update_required_ = false;
        CodepointList? codepoint_list = null;

        [GtkChild] Gtk.Label unicode_label;
        [GtkChild] Gtk.Label name_label;
        [GtkChild] Gtk.Label count_label;
        [GtkChild] Gtk.ScrolledWindow scrolled_window;
        [GtkChild] FontScale fontscale;

        public void set_filter (Orthography? orthography) {
            table.codepoint_list = null;
            codepoint_list.filter = orthography != null ? orthography.filter : null;
            table.codepoint_list = codepoint_list;
            count = codepoint_list.get_last_index();
            return;
        }

        public override void constructed () {
            codepoint_list = new CodepointList();
            table = new BaseCharacterMap();
            table.codepoint_list = codepoint_list;
            table.show();
            scrolled_window.add(table);

            map.connect(() => { _visible_ = true; update_if_needed(); });
            unmap.connect(() => { _visible_ = false; });
            notify["selected-font"].connect(() => { _update_required_ = true; update_if_needed(); });
            notify["active-character"].connect(() => {
                unichar ac = active_character;
                unicode_label.set_markup(Markup.printf_escaped("<b>U+%4.4X</b>", ac));
                name_label.set_markup(Markup.printf_escaped("<b>%s</b>", Unicode.get_codepoint_name(ac)));
            });
            notify["count"].connect(() => {
                count_label.set_text(count >= 0 ? "   %i   ".printf(count) : "   0   ");
            });

            bind_property("preview-size", table, "preview-size", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            bind_property("preview-size", fontscale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            fontscale.bind_property("adjustment", this, "adjustment", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            table.bind_property("active-character", this, "active-character", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            preview_size = DEFAULT_PREVIEW_SIZE;
            return;
        }

        void update_if_needed () {
            if (!_visible_ || !_update_required_)
                return;
            table.codepoint_list = null;
            string description =  is_valid_source(selected_font) ?
                                  selected_font.description :
                                  DEFAULT_FONT;
            codepoint_list.font = is_valid_source(selected_font) ?
                                  selected_font.source_object :
                                  null;
            table.font_desc = Pango.FontDescription.from_string(description);
            table.codepoint_list = codepoint_list;
            count = codepoint_list.get_last_index();
            _update_required_ = false;
            return;
        }

    }

}
