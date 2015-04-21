/* TextViews.vala
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

    public class StandardTextTagTable : Gtk.TextTagTable {

        private string [] defaults = {
            "FontDescription",
            "FontSize",
            "SizePoint",
        #if GTK_316_OR_LATER
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
        #if GTK_316_OR_LATER
            Gtk.TextTag fb = lookup(defaults[3]);
            fb.fallback = false;
        #endif
        }

    }

    public class StandardTextView : Gtk.ScrolledWindow {

        public signal void menu_request (Gtk.Widget widget, Gdk.EventButton event);

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
            view.margin_top = 6;
            view.editable = false;
            view.cursor_visible = false;
            view.accepts_tab = false;
            view.overwrite = false;
            view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            expand = true;
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

        public virtual bool on_event (Gdk.Event event) {
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button.button == 3) {
                 menu_request (this, event.button);
                 debug("Context menu request - %s", this.name);
                 return true;
             }
            return false;
        }

    }

    public class StaticTextView : StandardTextView {

        public StaticTextView (StandardTextTagTable? tag_table) {
            base(tag_table);
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


}
