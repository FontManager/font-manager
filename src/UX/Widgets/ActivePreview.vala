/* ActivePreview.vala
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

    public class ActivePreview : AdjustablePreview {

        public signal void preview_changed (string preview_text);

        public StandardTextView preview { get; private set; }


        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = value;
                preview.tag_table.lookup("FontDescription").font_desc = _font_desc;
                this.update();
            }
        }

        private bool editing = false;
        private PreviewControls controls;
        private Pango.FontDescription _font_desc;

        public class ActivePreview (StandardTextTagTable tag_table) {
            base.init();
            set_orientation(Gtk.Orientation.VERTICAL);
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            preview = new StandardTextView(tag_table);
            preview.view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            preview.view.justification = Gtk.Justification.CENTER;
            set_preview_text("\n\n" + get_localized_preview_text());
            controls = new PreviewControls();
            pack_start(controls, false, true, 0);
            pack_start(preview, true, true, 0);
            pack_end(fontscale, false, true, 0);
            connect_signals();
        }

        public override void show () {
            controls.show();
            preview.show();
            fontscale.show();
            base.show();
            return;
        }

        public string get_buffer_text () {
            return preview.get_buffer_text();
        }

        public void set_preview_text (string preview_text) {
            preview.buffer.set_text(preview_text, -1);
            return;
        }

        public void update () {
            var buffer = preview.buffer;
            Gtk.TextIter start, end;
            buffer.get_bounds(out start, out end);
            buffer.apply_tag(preview.tag_table.lookup("FontDescription"), start, end);
            buffer.apply_tag(preview.tag_table.lookup("FontSize"), start, end);
        #if GTK_316
            buffer.apply_tag(preview.tag_table.lookup("FontFallback"), start, end);
        #endif
            preview.view.set_tooltip_text(_font_desc.to_string());
            preview.queue_draw();
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            preview.tag_table.lookup("FontSize").size_points = new_size;
            if (unlikely(_font_desc != null))
                this.update();
            return;
        }

        private void connect_signals () {
            preview.buffer.changed.connect((b) => {
                this.update();
                var new_preview = preview.get_buffer_text();
                bool sensitive = (get_localized_preview_text() != new_preview);
                controls.clear_is_sensitive = sensitive;
                preview_changed(new_preview);
            });
            controls.justification_set.connect((j) => { preview.view.set_justification(j); });
            controls.editing.connect((e) => { on_edit_toggled(e); } );
            controls.on_clear_clicked.connect(() => { on_clear(); });
            preview.view.event.connect((w, e) => { return on_textview_event(w, e); });
            return;
        }

        private void on_clear () {
            preview.buffer.set_text("\n\n" + get_localized_preview_text(), -1);
            controls.clear_is_sensitive = false;
            return;
        }

        private bool on_textview_event (Gtk.Widget widget, Gdk.Event event) {
            if (editing || event.type == Gdk.EventType.SCROLL)
                return false;
            else {
                ((Gtk.TextView) widget).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
                return true;
            }
        }

        private void on_edit_toggled (bool allow_edit) {
            editing = allow_edit;
            preview.view.editable = allow_edit;
            preview.view.cursor_visible = allow_edit;
            preview.view.accepts_tab = allow_edit;
            preview.view.overwrite = allow_edit;
            if (allow_edit) {
                Gdk.Cursor cursor = new Gdk.Cursor(Gdk.CursorType.XTERM);
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
