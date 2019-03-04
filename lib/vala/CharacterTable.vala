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

    public class CharacterDetails : Gtk.EventBox {

        public unichar active_character {
            get {
                return ac;
            }
            set {
                ac = value;
                set_details();
            }
        }

        public int count { get; set; default = 0; }

        unichar ac;
        Gtk.Box box;
        Gtk.Box center_box;
        Gtk.Label unicode_label;
        Gtk.Label name_label;
        Gtk.Label count_label;

        public CharacterDetails () {
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            center_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            unicode_label = new Gtk.Label(null);
            unicode_label.halign = Gtk.Align.END;
            unicode_label.selectable = true;
            unicode_label.can_focus = false;
            name_label = new Gtk.Label(null);
            name_label.halign = Gtk.Align.START;
            name_label.opacity = unicode_label.opacity = 0.9;
            unicode_label.margin = name_label.margin = DEFAULT_MARGIN_SIZE / 4;
            count_label = new Gtk.Label(null);
            count_label.set_sensitive(false);
            count_label.margin = DEFAULT_MARGIN_SIZE / 8;
            count_label.get_style_context().add_class("CellRendererPill");
            notify["count"].connect(() => {
                count_label.set_text(count >= 0 ? "   %i   ".printf(count) : "   0   ");
            });
            center_box.pack_start(unicode_label, true, true, 2);
            center_box.pack_end(name_label, true, true, 2);
            box.set_center_widget(center_box);
            box.pack_end(count_label, false, true, 2);
            add(box);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        }

        public override void show () {
            unicode_label.show();
            name_label.show();
            count_label.show();
            center_box.show();
            box.show();
            base.show();
            return;
        }

        void set_details () {
            unicode_label.set_markup(Markup.printf_escaped("<b>U+%4.4X</b>", ac));
            name_label.set_markup(Markup.printf_escaped("<b>%s</b>", Unicode.get_codepoint_name(ac)));
            return;
        }

    }

    public class CharacterMap : Unicode.CharacterMap {

//        Gtk.Menu context_menu;

        public override bool button_press_event (Gdk.EventButton event) {
//            if (event.triggers_context_menu() && event.type == Gdk.EventType.BUTTON_PRESS)
//                message("U+%4.4X", active_character);
            return base.button_press_event(event);
        }

    }

    public class CharacterTable : AdjustablePreview {

        public unichar active_character { get; set; }
        public bool show_details { get; set; default = true; }

        public CharacterMap table { get; private set; }
        public CharacterDetails details { get; private set; }
        public Font? selected_font { get; set; default = null; }

        public void set_filter (Orthography? orthography) {
            table.codepoint_list = null;
            if (orthography != null)
                codepoint_list.filter = orthography.filter;
            else
                codepoint_list.filter = null;
            table.codepoint_list = codepoint_list;
            details.count = codepoint_list.get_last_index();
            return;
        }

        bool _visible_ = false;
        bool update_pending = false;
        Gtk.ScrolledWindow scroll;
        CodepointList? codepoint_list = null;

        public CharacterTable () {
            orientation = Gtk.Orientation.VERTICAL;
            codepoint_list = new CodepointList();
            table = new CharacterMap();
            table.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            table.codepoint_list = codepoint_list;
            scroll = new Gtk.ScrolledWindow(null, null);
            details = new CharacterDetails();
            scroll.add(table);
            pack_start(details, false, true, 0);
            pack_start(scroll, true, true, 1);
            connect_signals();
            bind_properties();
            preview_size = DEFAULT_PREVIEW_SIZE;
        }

        public override void show () {
            table.show();
            scroll.show();
            if (show_details)
                details.show();
            base.show();
            return;
        }

        void connect_signals () {
            notify["show-details"].connect(() => { details.set_visible(show_details); });
            notify["selected-font"].connect(() => { update_pending = true; update_if_needed(); });
            map.connect(() => { _visible_ = true; update_if_needed(); });
            unmap.connect(() => { _visible_ = false; });
        }

        void bind_properties () {
            bind_property("preview-size", table, "preview-size", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            table.bind_property("active-character", this, "active-character", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            bind_property("active-character", details, "active-character", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            return;
        }

        void update_if_needed () {
            if (_visible_ && update_pending) {
                table.codepoint_list = null;
                string description =  is_valid_source(selected_font) ?
                                      selected_font.description :
                                      DEFAULT_FONT;
                codepoint_list.font = is_valid_source(selected_font) ?
                                      selected_font.source_object :
                                      null;
                table.font_desc = Pango.FontDescription.from_string(description);
                table.codepoint_list = codepoint_list;
                details.count = codepoint_list.get_last_index();
                update_pending = false;
            }
            return;
        }

    }

}
