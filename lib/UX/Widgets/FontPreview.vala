/* FontPreview.vala
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

    public class FontPreview : Gtk.Box {

        public signal void mode_changed (string mode);
        public signal void preview_text_changed (string preview_text);

        public string pangram {
            get {
                return waterfall.pangram;
            }
            set {
                waterfall.pangram = "%s\n".printf(value);
            }
        }

        public double preview_size {
            get {
                return preview.preview_size;
            }
            set {
                preview.preview_size = body_text.preview_size = value;
            }
        }

        public Pango.FontDescription font_desc {
            get {
                return _font_desc;
            }
            set {
                _font_desc = preview.font_desc = body_text.font_desc = value;
                tag_table.lookup("FontDescription").font_desc = _font_desc;
            }
        }

        public string mode {
            get {
                return stack.get_visible_child_name();
            }
            set {
                stack.set_visible_child_name(value);
            }
        }

        protected Gtk.Stack stack;
        protected Pango.FontDescription _font_desc;
        protected ActivePreview preview;
        protected WaterfallPreview waterfall;
        protected TextPreview body_text;
        protected StandardTextTagTable tag_table;

        public FontPreview () {
            set_orientation(Gtk.Orientation.VERTICAL);
            var adjustment = new Gtk.Adjustment(DEFAULT_PREVIEW_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5, 1.0, 0);
            tag_table = new StandardTextTagTable();
            preview = new ActivePreview(tag_table);
            waterfall = new WaterfallPreview(tag_table);
            body_text = new TextPreview(tag_table);
            body_text.preview.name = "FontManagerBodyTextPreview";
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            preview.adjustment = adjustment;
            body_text.adjustment = adjustment;
            stack = new Gtk.Stack();
            stack.add_titled(preview, "Preview", _("Preview"));
            stack.add_titled(waterfall, "Waterfall", _("Waterfall"));
            stack.add_titled(body_text, "Body Text", _("Body Text"));
            stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            pack_end(stack, true, true, 0);
            connect_signals();
        }

        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        public override void show () {
            preview.show();
            waterfall.show();
            body_text.show();
            stack.show();
            base.show();
            return;
        }

        void connect_signals () {
            stack.notify["visible-child-name"].connect(() => { on_mode_changed(); });
            preview.preview_text_changed.connect((n) => { this.preview_text_changed(n); });
            preview.notify["preview-size"].connect(() => { notify_property("preview-size"); });
            return;
        }

        void on_mode_changed () {
            string mode = stack.get_visible_child_name();
            switch (mode) {
                case "Preview":
                    Idle.add(() => {
                        preview.preview.queue_draw();
                        return false;
                    });
                    break;
                case "Waterfall":
                    Idle.add(() => {
                        waterfall.view.queue_draw();
                        return false;
                    });
                    break;
                case "Body Text":
                    Idle.add(() => {
                        body_text.preview.queue_draw();
                        return false;
                    });
                    break;
            }
            mode_changed(mode);
            return;
        }

    }

}
