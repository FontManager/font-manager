/* WaterfallPreview.vala
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
