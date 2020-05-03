/* TextViews.vala
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
            return view.button_press_event(event);
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
            ((Gtk.TextView) this.view).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
            return true;
        }

    }

}
