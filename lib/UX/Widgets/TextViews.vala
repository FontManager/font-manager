/* TextViews.vala
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

    /**
     * FontPreview - Full featured font preview widget
     *
     * -----------------------------------------------------------------
     * |                    |                       |                  |
     * |   #ActivePreview   |   #WaterfallPreview   |   #TextPreview   |
     * |                    |                       |                  |
     * -----------------------------------------------------------------
     */
    public class FontPreview : Gtk.Stack {

        /**
         * FontPreview::mode_changed:
         *
         * Emmitted when a different mode is selected by user
         */
        public signal void mode_changed (string mode);

        /**
         * FontPreview::preview_text_changed:
         *
         * Emitted when the preview text has changed
         */
        public signal void preview_text_changed (string preview_text);

        /**
         * FontPreview:pangram:
         *
         * The pangram displayed in #WaterfallPreview
         */
        public string pangram {
            get {
                return waterfall.pangram;
            }
            set {
                waterfall.pangram = "%s\n".printf(value);
            }
        }

        /**
         * FontPreview:preview_size:
         *
         * Font point size
         */
        public double preview_size {
            get {
                return preview.preview_size;
            }
            set {
                preview.preview_size = body_text.preview_size = value;
            }
        }

        /**
         * FontPreview:font_desc:
         *
         * The #Pango.FontDescription in use
         */
        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = preview.font_desc = body_text.font_desc = value;
                tag_table.lookup("FontDescription").font_desc = _font_desc;
            }
        }

        /**
         * FontPreview:mode:
         *
         * One of "Preview", "Waterfall" or "Body Text"
         */
        public string mode {
            get {
                return get_visible_child_name();
            }
            set {
                set_visible_child_name(value);
            }
        }

        protected Pango.FontDescription _font_desc;
        protected ActivePreview preview;
        protected WaterfallPreview waterfall;
        protected TextPreview body_text;
        protected StandardTextTagTable tag_table;

        public FontPreview () {
            Object(name: "FontPreview");
            tag_table = new StandardTextTagTable();
            preview = new ActivePreview(tag_table);
            waterfall = new WaterfallPreview(tag_table);
            body_text = new TextPreview(tag_table);
            body_text.preview.name = "BodyTextPreview";
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            preview.adjustment =
            body_text.adjustment =
            new Gtk.Adjustment(DEFAULT_PREVIEW_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5, 1.0, 0);
            add_titled(preview, "Preview", _("Preview"));
            add_titled(waterfall, "Waterfall", _("Waterfall"));
            add_titled(body_text, "Body Text", _("Body Text"));
            set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            preview.preview_text_changed.connect((n) => { this.preview_text_changed(n); });
            preview.notify["preview-size"].connect(() => { notify_property("preview-size"); });
            notify["visible-child-name"].connect(() => {
                get_visible_child().queue_draw();
                mode_changed(mode);
                return;
            });
        }

        /**
         * set_preview_text:
         *
         * Sets the text to display in #ActivePreview
         */
        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            preview.show();
            waterfall.show();
            body_text.show();
            base.show();
            return;
        }

    }

    /**
     * StandardTextTagTable:
     *
     * Convenience class for setting attributes related to font rendering
     * in a #Gtk.TextView
     */
    public class StandardTextTagTable : Gtk.TextTagTable {

        const string [] defaults = {
            "FontDescription",
            "FontSize",
            "SizePoint",
            "FontFallback"
        };

        construct {
            foreach (string tag in defaults)
                add(new Gtk.TextTag(tag));
            Gtk.TextTag sp = lookup(defaults[2]);
            sp.family = "Monospace";
            sp.rise = 1250;
            sp.size_points = 6.0;
            Gtk.TextTag fb = lookup(defaults[3]);
            fb.fallback = false;
        }

    }

    /**
     * StandardTextView:
     *
     * Is actually a #Gtk.ScrolledWindow containing a #Gtk.TextView.
     */
    public class StandardTextView : Gtk.ScrolledWindow {

        /**
         * StandardTextView::menu_request:
         *
         * Emitted when the user right clicks the view
         */
        public signal void menu_request (Gtk.Widget widget, Gdk.EventButton event);

        /**
         * StandardTextView:view:
         *
         * The actual #Gtk.TextView
         */
        public Gtk.TextView view { get; private set; }

        /**
         * StandardTextView:buffer:
         *
         * The #Gtk.Textbuffer attached to this view
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
         * The #Gtk.TextTagTable attached to this view
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
            view.margin = DEFAULT_MARGIN_SIZE / 2;
            view.editable = false;
            view.cursor_visible = false;
            view.accepts_tab = false;
            view.overwrite = false;
            view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            add(view);
        }

        public StandardTextView (StandardTextTagTable? tag_table) {
            Object(name: "StandardTextView", tag_table: tag_table, expand: true);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            view.show();
            base.show();
            return;
        }

        /**
         * @return      the text currently displayed in view
         */
        public string get_buffer_text () {
            Gtk.TextIter start, end;
            view.get_buffer().get_bounds(out start, out end);
            return view.get_buffer().get_text(start, end, false);
        }

        public virtual bool on_event (Gdk.Event event) {
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button.button == 3) {
                 menu_request (this, event.button);
                 debug("Context menu request - %s", this.name);
                 return true;
             }
            return false;
        }

    }

    /**
     * StaticTextView:
     *
     * Discards all events except right click which emits menu_request
     */
    public class StaticTextView : StandardTextView {

        public StaticTextView (StandardTextTagTable? tag_table) {
            Object(name: "StaticTextView", tag_table: tag_table);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            this.view.event.connect(on_event);
            /* XXX : Silence warning - Vala binding issue? */
            Gtk.TargetList? list = null;
            Gtk.drag_dest_set_target_list(this.view, list);
        }

        public override bool on_event (Gdk.Event event) {
            if (event.type == Gdk.EventType.SCROLL)
                return false;
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button.button == 3)
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
                return _preview_size;
            }
            set {
                _preview_size = value.clamp(MIN_FONT_SIZE, MAX_FONT_SIZE);
                Idle.add(() => {
                    set_preview_size_internal(_preview_size);
                    return false;
                });
            }
        }

        public Gtk.Adjustment adjustment {
            get {
                return fontscale.adjustment;
            }
            set {
                fontscale.adjustment = value;
                fontscale.adjustment.bind_property("value", this, "preview-size", BindingFlags.BIDIRECTIONAL);
            }
        }

        protected double _preview_size;
        protected FontScale fontscale;

        protected abstract void set_preview_size_internal (double new_size);

        construct {
            name = "AdjustablePreview";
            fontscale = new FontScale();
            adjustment = fontscale.adjustment;
            pack_end(fontscale, false, true, 0);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            fontscale.show();
            base.show();
            return;
        }

        protected double get_desc_size () {
            if (preview_size <= 10)
                return preview_size;
            else if (preview_size <= 20)
                return preview_size / 1.25;
            else if (preview_size <= 30)
                return preview_size / 1.5;
            else if (preview_size <= 50)
                return preview_size / 1.75;
            else
                return preview_size / 2;
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

        bool editing = false;
        PreviewControls controls;
        weak Pango.FontDescription _font_desc;

        construct {
            name = "ActivePreview";
            orientation = Gtk.Orientation.VERTICAL;
        }

        public class ActivePreview (StandardTextTagTable tag_table) {
            preview = new StandardTextView(tag_table);
            preview.view.justification = Gtk.Justification.CENTER;
            set_preview_text(get_localized_preview_text());
            preview_size = DEFAULT_PREVIEW_SIZE;
            controls = new PreviewControls();
            pack_start(controls, false, true, 0);
            pack_start(preview, true, true, 0);
            connect_signals();
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            controls.show();
            preview.show();
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
            buffer.apply_tag(preview.tag_table.lookup("FontFallback"), start, end);
            Idle.add(() => {
                preview.queue_draw();
                return false;
            });
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            preview.tag_table.lookup("FontSize").size_points = new_size;
            if (unlikely(_font_desc != null))
                this.update();
            return;
        }

        void connect_signals () {
            preview.buffer.changed.connect((b) => {
                this.update();
                var new_preview = preview.get_buffer_text();
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
            else if (event.type == Gdk.EventType.BUTTON_PRESS && event.button.button == 3)
                return preview.on_event(event);
            else {
                ((Gtk.TextView) widget).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
                return true;
            }
        }

        void on_edit_toggled (bool allow_edit) {
            editing = allow_edit;
            preview.view.editable = allow_edit;
            preview.view.cursor_visible = allow_edit;
            preview.view.accepts_tab = allow_edit;
            if (allow_edit) {
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


        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = value;
                this.update();
            }
        }

        Pango.FontDescription _font_desc;

        public class TextPreview (StandardTextTagTable tag_table) {
            Object(name: "TextPreview", orientation: Gtk.Orientation.VERTICAL);
            preview = new StaticTextView(tag_table);
            preview.view.justification = Gtk.Justification.FILL;
            set_preview_text(LOREM_IPSUM);
            pack_start(preview, true, true, 0);
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            preview.show();
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
            buffer.apply_tag(preview.tag_table.lookup("FontFallback"), start, end);
            Idle.add(() => {
                preview.queue_draw();
                return false;
            });
            return;
        }

        protected override void set_preview_size_internal (double new_size) {
            preview.tag_table.lookup("FontSize").size_points = new_size;
            this.update();
            return;
        }

    }

    /**
     * WaterfallPreview:
     *
     * @tag_table       #StandardTextTagTable
     *
     * #Gtk.TextView which will render the given pangram in waterfall style
     * from MIN_FONT_SIZE to MAX_FONT_SIZE with the attributes specified
     * in @tag_table
     */
    public class WaterfallPreview : StaticTextView {

        public string pangram {
            get {
                return _pangram;
            }
            set {
                _pangram = "%s\n".printf(value);
                this.update();
            }
        }

        string _pangram;

        public WaterfallPreview (StandardTextTagTable tag_table) {
            base(tag_table);
            name = "WaterfallPreview";
            view.pixels_above_lines = 1;
            view.wrap_mode = Gtk.WrapMode.NONE;
            pangram = get_localized_pangram();
        }

        public void update () {
            buffer.set_text("", -1);
            Gtk.TextIter iter;
            for (int i = (int) MIN_FONT_SIZE; i <= MAX_FONT_SIZE; i++) {
                var line = i.to_string();
                string point;
                if (i < 10)
                    point = "%spt.   ".printf(line);
                else
                    point = "%spt.  ".printf(line);
                buffer.get_iter_at_line(out iter, i);
                buffer.insert_with_tags_by_name(ref iter, point, -1, "SizePoint", null);
                if (tag_table.lookup(line) == null)
                    buffer.create_tag(line, "size-points", (double) i, null);
                buffer.get_end_iter(out iter);
                buffer.insert_with_tags_by_name(ref iter, _pangram, -1, line, "FontDescription", null);
            }
            Gtk.TextIter start, end;
            buffer.get_bounds(out start, out end);
            buffer.apply_tag(this.tag_table.lookup("FontFallback"), start, end);
            return;
        }

    }

}
