/* TextPreview.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

}
