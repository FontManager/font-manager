/* TextViews.vala
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
     * StandardTextTagTable:
     *
     * Convenience class for setting attributes related to font rendering
     * in a #GtkTextView
     */
    public class StandardTextTagTable : Gtk.TextTagTable {

        construct {
            Gtk.TextTag font = new Gtk.TextTag("FontDescription");
            font.fallback = false;
            Gtk.TextTag point = new Gtk.TextTag("SizePoint");
            point.set("family", "Monospace", "rise", 1250, "size-points", 6.0, null);
            add(font);
            add(point);
        }

    }

    /**
     * StandardTextView:
     *
     * Is actually a #GtkScrolledWindow containing a #GtkTextView.
     */
    public class StandardTextView : Gtk.ScrolledWindow {

        /**
         * StandardTextView:view:
         *
         * The actual #GtkTextView
         */
        public Gtk.TextView view { get; private set; }

        /**
         * StandardTextView:buffer:
         *
         * The #GtkTextbuffer attached to this view
         */
        public Gtk.TextBuffer buffer {
            get {
                return view.get_buffer();
            }
            set {
                view.set_buffer(value);
            }
        }

        /**
         * StandardTextView:tag_table:
         *
         * The #GtkTextTagTable attached to this view
         */
        public Gtk.TextTagTable? tag_table {
            get {
                return buffer.get_tag_table();
            }
            set {
                buffer = new Gtk.TextBuffer(value);
            }
        }

        construct {
            view = new Gtk.TextView();
            view.set("margin", DEFAULT_MARGIN_SIZE, "editable", false,
                     "cursor-visible", false, "accepts-tab", false,
                     "overwrite", false, "wrap-mode", Gtk.WrapMode.WORD_CHAR, null);
            add(view);
            view.show();
        }

        public StandardTextView (StandardTextTagTable? tag_table) {
            Object(name: "StandardTextView", tag_table: tag_table, expand: true);
            Gtk.drag_dest_unset(view);
        }

        /**
         * get_buffer_text:
         *
         * Returns: (transfer full): a newly allocated string containing the text
         *                           currently displayed in view.
         */
        public string get_buffer_text () {
            Gtk.TextIter start, end;
            view.get_buffer().get_bounds(out start, out end);
            return view.get_buffer().get_text(start, end, false);
        }

        /**
         * show_context_menu:
         *
         * Called on right click events.
         *
         * Returns:     %TRUE to stop other handlers from being invoked for the event.
         *              %FALSE to propagate the event further.
         */
        protected virtual bool show_context_menu (Gdk.EventButton event) {
            return base.button_press_event(event);
        }


        public virtual bool on_event (Gdk.Event event) {
            if (event.triggers_context_menu() && event.type == Gdk.EventType.BUTTON_PRESS)
                return show_context_menu(event.button);
            return false;
        }

    }

    /**
     * StaticTextView:
     *
     * Discards all events except right click
     */
    public class StaticTextView : StandardTextView {

        public StaticTextView (StandardTextTagTable? tag_table) {
            Object(name: "StaticTextView", tag_table: tag_table);
            this.view.event.connect(on_event);
        }

        protected override bool show_context_menu (Gdk.EventButton event) {
            return true;
        }

        public override bool on_event (Gdk.Event event) {
            if (event.type == Gdk.EventType.SCROLL)
                return false;
            if (event.triggers_context_menu() && event.type == Gdk.EventType.BUTTON_PRESS)
                return base.on_event(event);
            ((Gtk.TextView) this.view).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
            return true;
        }

    }

    /**
     * AdjustablePreview:
     *
     * Base class for zoomable text previews
     */
    public abstract class AdjustablePreview : Gtk.Box {

        public double preview_size {
            get {
                return adjustment.value;
            }
            set {
                adjustment.value = value;
            }
        }

        public Gtk.Adjustment adjustment {
            get {
                return fontscale.adjustment;
            }
            set {
                fontscale.adjustment = value;
                value.value_changed.connect(() => { notify_property("preview-size"); });
            }
        }

        protected FontScale fontscale;

        construct {
            name = "AdjustablePreview";
            fontscale = new FontScale();
            adjustment = fontscale.adjustment;
            pack_end(fontscale, false, true, 0);
            fontscale.show();
        }

    }

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

    /**
     * TextPreview:
     *
     * Used to display zoomable paragraphs of text.
     */
    public class TextPreview : AdjustablePreview {

        public StaticTextView preview { get; private set; }

        bool initialized = false;
        bool update_required = true;

        public class TextPreview (StandardTextTagTable tag_table) {
            Object(name: "TextPreview", orientation: Gtk.Orientation.VERTICAL);
            preview = new StaticTextView(tag_table);
            preview.view.justification = Gtk.Justification.FILL;
            set_preview_text(LOREM_IPSUM);
            pack_start(preview, true, true, 0);
            map.connect(() => { update(); });
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

    }

    /**
     * WaterfallPreview:
     * @tag_table       #StandardTextTagTable
     *
     * #GtkTextView which will render the given pangram in waterfall style
     * from MIN_FONT_SIZE to MAX_FONT_SIZE with the attributes specified
     * in @tag_table
     */
    public class WaterfallPreview : StaticTextView {

        public string? pangram {
            get {
                return _pangram;
            }
            set {
                if (value != null)
                    _pangram = "%s\n".printf(value);
                else
                    _pangram = "%s\n".printf(get_localized_pangram());
                update_required = true;
                update();
            }
        }

        bool initialized = false;
        bool update_required = true;
        string _pangram;

        public WaterfallPreview (StandardTextTagTable tag_table) {
            base(tag_table);
            name = "WaterfallPreview";
            view.set("pixels-above-lines", 1, "wrap-mode", Gtk.WrapMode.NONE, null);
            pangram = get_localized_pangram();
        }

        void update () {
            if (initialized && !update_required)
                return;
            buffer.set_text("", -1);
            Gtk.TextIter iter;
            for (int i = (int) MIN_FONT_SIZE; i <= MAX_FONT_SIZE; i++) {
                string line = i.to_string();
                string point = i < 10 ? " %spt.  ".printf(line) : "%spt.  ".printf(line);
                buffer.get_iter_at_line(out iter, i);
                buffer.insert_with_tags_by_name(ref iter, point, -1, "SizePoint", null);
                if (tag_table.lookup(line) == null)
                    buffer.create_tag(line, "size-points", (double) i, null);
                buffer.get_end_iter(out iter);
                buffer.insert_with_tags_by_name(ref iter, _pangram, -1, line, "FontDescription", null);
            }
            initialized = true;
            update_required = false;
            return;
        }

    }

}
