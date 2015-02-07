/* TextPreview.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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

        private Pango.FontDescription _font_desc;

        public class TextPreview (StandardTextTagTable tag_table) {
            base.init();
            set_orientation(Gtk.Orientation.VERTICAL);
            fontscale.add_style_class(Gtk.STYLE_CLASS_VIEW);
            preview = new StaticTextView(tag_table);
            preview.view.left_margin = 12;
            preview.view.right_margin = 12;
            preview.view.justification = Gtk.Justification.FILL;
            set_preview_text(LOREM_IPSUM);
            pack_start(preview, true, true, 0);
            pack_end(fontscale, false, true, 0);
        }

        public override void show () {
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
            this.update();
            return;
        }

    }

}
