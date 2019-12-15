/* ActivePreview.vala
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

    /**
     * ActivePreview:
     *
     * Default preview allows justification, editing and zooming of preview text
     */
    public class ActivePreview : AdjustablePreview {

        public signal void preview_text_changed (string preview_text);

        public StandardTextView preview { get; private set; }
        public PreviewControls controls { get; private set; }

        bool editing = false;
        bool initialized = false;
        bool update_required = true;

        public class ActivePreview (StandardTextTagTable tag_table) {
            Object(name: "ActivePreview", orientation: Gtk.Orientation.VERTICAL);
            preview = new StandardTextView(tag_table);
            preview.view.margin_top = DEFAULT_MARGIN_SIZE * 2;
            preview.view.justification = Gtk.Justification.CENTER;
            set_preview_text(get_localized_preview_text());
            controls = new PreviewControls();
            pack_start(controls, false, true, 0);
            pack_start(preview, true, true, 0);
            connect_signals();
            controls.show();
            preview.show();
        }

        /**
         * get_preview_text:
         *
         * Returns: (transfer full): a newly allocated string containing the text
         *                           currently displayed in view.
         */
        public string get_preview_text () {
            return preview.get_buffer_text();
        }

        /**
         * set_preview_text:
         * @preview_text:   text to display in preview
         */
        public void set_preview_text (string preview_text) {
            preview.buffer.set_text(preview_text, -1);
            update_required = true;
            update();
            return;
        }

        public void update () {
            if (initialized && !update_required)
                return;
            Gtk.TextBuffer buffer = preview.buffer;
            Gtk.TextIter start, end;
            buffer.get_bounds(out start, out end);
            buffer.apply_tag(preview.tag_table.lookup("FontDescription"), start, end);
            initialized = true;
            update_required = false;
            return;
        }

        void connect_signals () {
            map.connect(() => { update(); });
            preview.buffer.changed.connect((b) => {
                update();
                string new_preview = preview.get_buffer_text();
                bool sensitive = (get_localized_preview_text() != new_preview);
                controls.clear_is_sensitive = sensitive;
                preview_text_changed(new_preview);
            });
            controls.justification_set.connect((j) => { preview.view.set_justification(j); });
            controls.editing.connect((e) => { on_edit_toggled(e); } );
            controls.on_clear_clicked.connect(() => { on_clear(); });
            preview.view.event.connect(on_textview_event);
            return;
        }

        void on_clear () {
            preview.buffer.set_text(get_localized_preview_text(), -1);
            controls.clear_is_sensitive = false;
            return;
        }

        bool on_textview_event (Gtk.Widget widget, Gdk.Event event) {
            if (editing || event.type == Gdk.EventType.SCROLL)
                return false;
            else if (event.triggers_context_menu() && event.type == Gdk.EventType.BUTTON_PRESS)
                return preview.on_event(event);
            else {
                ((Gtk.TextView) widget).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
                return true;
            }
        }

        void on_edit_toggled (bool state) {
            editing = state;
            preview.view.set("editable", editing, "cursor-visible", editing,
                              "accepts-tab", editing, null);
            if (editing) {
                Gdk.Cursor cursor = new Gdk.Cursor.for_display(Gdk.Display.get_default(), Gdk.CursorType.XTERM);
                Gdk.Window text_window = preview.view.get_window(Gtk.TextWindowType.TEXT);
                text_window.set_cursor(cursor);
                preview.grab_focus();
            } else {
                Gtk.TextIter end;
                Gtk.TextBuffer buff = preview.buffer;
                buff.get_end_iter(out end);
                buff.select_range(end, end);
            }
            return;
        }

    }

}
