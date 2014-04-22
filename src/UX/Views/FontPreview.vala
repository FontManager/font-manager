/* FontPreview.vala
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

    public enum PreviewMode {
            PREVIEW,
            WATERFALL,
            BODY_TEXT
    }

    public class FontPreview : AdjustablePreview {

        public signal void mode_changed (int mode);

        public string pangram {
            get {
                return _pangram;
            }
            set {
                _pangram = "%s\n".printf(value);
                update_waterfall();
            }
        }

        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = value;
                tag_table.lookup("FontDescription").font_desc = _font_desc;
                apply_text_tags();
                preview.set_tooltip_text(font_desc.to_string());
            }
        }

        public PreviewMode mode {
            get {
                return (PreviewMode) selector.mode;
            }
            set {
                selector.mode = (int) value;
            }
        }

        bool editing = false;
        string _pangram;
        Gtk.Notebook notebook;
        Pango.FontDescription _font_desc;
        StandardTextView preview;
        StaticTextView waterfall;
        StaticTextView body_text;
        PreviewControls controls;
        ModeSelector selector;
        StandardTextTagTable tag_table;

        public FontPreview () {
            base.init();
            set_orientation(Gtk.Orientation.VERTICAL);
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            controls = new PreviewControls();
            tag_table = new StandardTextTagTable();
            preview = new StandardTextView(tag_table);
            preview.view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            preview.view.justification = Gtk.Justification.CENTER;
            waterfall = new StaticTextView(tag_table);
            waterfall.view.pixels_above_lines = 1;
            body_text = new StaticTextView(tag_table);
            body_text.view.left_margin = 12;
            body_text.view.right_margin = 12;
            body_text.view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            body_text.view.justification = Gtk.Justification.FILL;
            selector = new ModeSelector();
            selector.set_border_width(6);
            notebook = new Gtk.Notebook();
            selector.notebook = notebook;
            notebook.append_page(preview, new Gtk.Label("Preview"));
            notebook.append_page(waterfall, new Gtk.Label("Waterfall"));
            notebook.append_page(body_text, new Gtk.Label("Body Text"));
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            body_text.buffer.set_text(LOREM_IPSUM);
            preview.buffer.set_text("\n\n" + get_localized_preview_text(), -1);
            /* Setting pangram updates the waterfall view */
            pangram = get_localized_pangram();
            connect_signals();
            pack_start(selector, false, true, 0);
            add_separator(this, Gtk.Orientation.HORIZONTAL);
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(controls, false, true, 0);
            box.pack_start(notebook, true, true, 0);
            box.pack_end(fontscale, false, true, 0);
            pack_end(box, true, true, 0);
            preview.show();
            waterfall.show();
            body_text.show();
            selector.show();
            notebook.show();
            fontscale.show();
            controls.show();
            box.show();
        }

        internal void connect_signals () {
            selector.selection_changed.connect((mode) => { on_mode_changed(mode); });
            preview.buffer.changed.connect((b) => {
                apply_text_tags();
                bool sensitive = (get_localized_preview_text() != preview.get_buffer_text());
                controls.clear_is_sensitive = sensitive;
            });
            controls.justification_set.connect((j) => { preview.view.set_justification(j); });
            controls.editing.connect((e) => { on_edit_toggled(e); } );
            controls.on_clear_clicked.connect(() => { on_clear(); });
            preview.view.event.connect((w, e) => { return on_textview_event(w, e); });
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            tag_table.lookup("FontSize").size_points = new_size;
            apply_text_tags();
            return;
        }

        void apply_text_tags () {
            Gtk.TextView [] views = {preview.view, body_text.view};
            foreach (var view in views) {
                Gtk.TextIter start, end;
                view.buffer.get_bounds(out start, out end);
                view.buffer.apply_tag(tag_table.lookup("FontDescription"), start, end);
                view.buffer.apply_tag(tag_table.lookup("FontSize"), start, end);
            }
            return;
        }

        void on_mode_changed (int mode) {
            switch (mode) {
                case PreviewMode.PREVIEW:
                    controls.show();
                    fontscale.show();
                    preview.view.queue_draw();
                    break;
                case PreviewMode.WATERFALL:
                    controls.hide();
                    fontscale.hide();
                    waterfall.view.queue_draw();
                    break;
                case PreviewMode.BODY_TEXT:
                    controls.hide();
                    fontscale.show();
                    body_text.view.queue_draw();
                    break;
            }
            mode_changed(mode);
            return;
        }

        void update_waterfall () {
            Gtk.TextBuffer buffer = waterfall.buffer;
            Gtk.TextIter iter;
            for (int i = (int) MIN_FONT_SIZE; i <= MAX_FONT_SIZE; i++) {
                var line = i.to_string();
                string point;
                if (i < 10)
                    point = "%spt.   ".printf(line);
                else
                    point = "%spt.  ".printf(line);
                buffer.get_iter_at_line(out iter, i);
                buffer.insert_with_tags_by_name(iter, point, -1, "SizePoint", null);
                if (waterfall.tag_table.lookup(line) == null)
                    buffer.create_tag(line, "size-points", (double) i, null);
                buffer.get_end_iter(out iter);
                buffer.insert_with_tags_by_name(iter, pangram, -1, line, "FontDescription", null);
            }
            return;
        }

        bool on_textview_event (Gtk.Widget widget, Gdk.Event event) {
            if (editing || event.type == Gdk.EventType.SCROLL)
                return false;
            else {
                ((Gtk.TextView) widget).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
                return true;
            }
        }

        void on_clear () {
            preview.buffer.set_text("\n\n" + get_localized_preview_text(), -1);
            controls.clear_is_sensitive = false;
            return;
        }

        void on_edit_toggled (bool allow_edit) {
            editing = allow_edit;
            preview.view.editable = allow_edit;
            preview.view.cursor_visible = allow_edit;
            preview.view.accepts_tab = allow_edit;
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
