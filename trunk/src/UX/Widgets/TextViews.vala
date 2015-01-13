/* TextViews.vala
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

    public class StandardTextTagTable : Gtk.TextTagTable {

        private string [] defaults = {
            "FontDescription",
            "FontSize",
            "SizePoint",
        #if GTK_316
            "FontFallback"
        #endif
        };

        construct {
            foreach (string tag in defaults)
                add(new Gtk.TextTag(tag));
            Gtk.TextTag sp = lookup(defaults[2]);
            sp.family = "Monospace";
            sp.rise = 1250;
            sp.size_points = 6.0;
        #if GTK_316
            Gtk.TextTag fb = lookup(defaults[3]);
            fb.fallback = false;
        #endif
        }

    }

    public class StandardTextView : Gtk.ScrolledWindow {

        public Gtk.TextView view { get; private set; }

        public Gtk.TextBuffer buffer {
            get {
                return view.get_buffer();
            }
            set {
                view.set_buffer(value);
            }
        }

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
            view.left_margin = 6;
            view.right_margin = 6;
            view.editable = false;
            view.cursor_visible = false;
            view.accepts_tab = false;
            view.overwrite = false;
            view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            hexpand = true;
            vexpand = true;
            add(view);
        }

        public override void show () {
            view.show();
            base.show();
            return;
        }

        public StandardTextView (StandardTextTagTable? tag_table) {
            this.tag_table = tag_table;
        }

        public string get_buffer_text () {
            Gtk.TextIter start, end;
            view.get_buffer().get_bounds(out start, out end);
            return view.get_buffer().get_text(start, end, false);
        }

    }

    public class StaticTextView : StandardTextView {

        public StaticTextView (StandardTextTagTable? tag_table) {
            base(tag_table);
            this.view.event.connect((e) => { return on_event(e); });
            /* XXX : Silence warning - Vala binding issue? */
            Gtk.TargetList? list = null;
            Gtk.drag_dest_set_target_list(this.view, list);
        }

        protected bool on_event (Gdk.Event event) {
            if (event.type == Gdk.EventType.SCROLL)
                return false;
            ((Gtk.TextView) this.view).get_window(Gtk.TextWindowType.TEXT).set_cursor(null);
            return true;
        }

    }


}
