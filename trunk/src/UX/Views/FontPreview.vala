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

    public class FontPreview : Gtk.Box {

        public signal void mode_changed (string mode);
        public signal void preview_changed (string preview_text);

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

        private Gtk.Box box;
        private Gtk.Stack stack;
        private Gtk.StackSwitcher switcher;
        private Gtk.EventBox blend;
        private Pango.FontDescription _font_desc;
        private ActivePreview preview;
        private WaterfallPreview waterfall;
        private TextPreview body_text;
        private StandardTextTagTable tag_table;

        public FontPreview () {
            set_orientation(Gtk.Orientation.VERTICAL);
            var adjustment = new Gtk.Adjustment(DEFAULT_PREVIEW_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5, 1.0, 0);
            tag_table = new StandardTextTagTable();
            preview = new ActivePreview(tag_table);
            waterfall = new WaterfallPreview(tag_table);
            body_text = new TextPreview(tag_table);
            font_desc = Pango.FontDescription.from_string(DEFAULT_FONT);
            preview.adjustment = adjustment;
            body_text.adjustment = adjustment;
            stack = new Gtk.Stack();
            stack.add_titled(preview, "Preview", _("Preview"));
            stack.add_titled(waterfall, "Waterfall", _("Waterfall"));
            stack.add_titled(body_text, "Body Text", _("Body Text"));
            stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            blend = new Gtk.EventBox();
            switcher = new Gtk.StackSwitcher();
            switcher.set_stack(stack);
            switcher.set_border_width(5);
            switcher.halign = Gtk.Align.CENTER;
            switcher.valign = Gtk.Align.CENTER;
            switcher.homogeneous = true;
            switcher.orientation = Gtk.Orientation.HORIZONTAL;
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            blend.add(switcher);
            connect_signals();
            pack_start(blend, false, true, 0);
            add_separator(this, Gtk.Orientation.HORIZONTAL);
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(stack, true, true, 0);
            pack_end(box, true, true, 0);
        }

        public override void show () {
            blend.show();
            preview.show();
            waterfall.show();
            body_text.show();
            stack.show();
            switcher.show();
            box.show();
            base.show();
            return;
        }

        private void connect_signals () {
            stack.notify["visible-child-name"].connect(() => { on_mode_changed(); });
            preview.preview_changed.connect((n) => { this.preview_changed(n); });
            preview.notify["preview-size"].connect(() => { notify_property("preview-size"); });
            return;
        }

        public void set_preview_text (string preview_text) {
            preview.set_preview_text(preview_text);
            return;
        }

        private void on_mode_changed () {
            string mode = stack.get_visible_child_name();
            switch (mode) {
                case "Preview":
                    preview.preview.queue_draw();
                    break;
                case "Waterfall":
                    waterfall.view.queue_draw();
                    break;
                case "Body Text":
                    body_text.preview.queue_draw();
                    break;
            }
            mode_changed(mode);
            return;
        }

    }

}
