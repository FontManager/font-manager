/* FontListControls.vala
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

    public class FontListControls : Gtk.EventBox {

        public signal void remove_selected ();
        public signal void expand_all (bool expand);

        public bool expanded { get; private set; }
        public Gtk.SearchEntry entry { get; private set; }

        Gtk.Button _remove;
        Gtk.Button _expand;
        Gtk.Arrow arrow;

        public FontListControls () {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
            box.border_width = 2;
            _expand = new Gtk.Button();
            arrow = new Gtk.Arrow(Gtk.ArrowType.RIGHT, Gtk.ShadowType.ETCHED_IN);
            _expand.add(arrow);
            _expand.set_tooltip_text(_("Expand all"));
            _remove = new Gtk.Button();
            _remove.set_image(new Gtk.Image.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU));
            _remove.set_tooltip_text(_("Remove selected fonts"));
            entry = new Gtk.SearchEntry();
            box.pack_end(entry, false, false, 0);
            box.pack_start(_expand, false, false, 0);
            add_separator(box);
            box.pack_start(_remove, false, false, 0);
            set_default_button_relief(box);
            entry.show();
            _remove.show();
            arrow.show();
            _expand.show();
            box.show();
            add(box);
            connect_signals();
        }

        internal void connect_signals () {
            _remove.clicked.connect((w) => { remove_selected(); });
            _expand.clicked.connect((w) => {
                expanded = !expanded;
                expand_all(expanded);
                _expand.set_tooltip_text(expanded ? _("Collapse all") : _("Expand all"));
                if (expanded)
                    arrow.set(Gtk.ArrowType.DOWN, Gtk.ShadowType.ETCHED_IN);
                else
                    arrow.set(Gtk.ArrowType.RIGHT, Gtk.ShadowType.ETCHED_IN);
            });
            return;
        }

        public void set_remove_sensitivity (bool sensitive) {
            _remove.set_sensitive(sensitive);
            return;
        }

    }

}
