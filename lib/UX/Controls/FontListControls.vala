/* FontListControls.vala
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

    /**
     * {@inheritDoc}
     */
    public class FontListControls : BaseControls {

        /**
         * FontListControls::expand_all:
         *
         * Emitted when the expand_button is clicked
         */
        public signal void expand_all (bool expand);

        public bool expanded { get; private set; }
        public Gtk.Button expand_button { get; private set; }
        public Gtk.SearchEntry entry { get; private set; }

        Gtk.Arrow arrow;

        public FontListControls () {
            Object(name: "FontListControls", margin: 1);
            remove_button.set_tooltip_text(_("Remove selected font from collection"));
            expand_button = new Gtk.Button();
            arrow = new Gtk.Arrow(Gtk.ArrowType.RIGHT, Gtk.ShadowType.ETCHED_IN);
            expand_button.add(arrow);
            expand_button.set_tooltip_text(_("Expand all"));
            entry = new Gtk.SearchEntry();
            entry.set_size_request(0, 0);
            entry.margin_end = 2;
            entry.placeholder_text = _("Search Families...");
            box.pack_end(entry, false, false, 0);
            box.pack_start(expand_button, false, false, 0);
            box.reorder_child(expand_button, 0);
            set_default_button_relief(box);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            get_style_context().add_class(name);
            set_size_request(0, 0);
            expand_button.clicked.connect((w) => {
                expanded = !expanded;
                expand_all(expanded);
                expand_button.set_tooltip_text(expanded ? _("Collapse all") : _("Expand all"));
                if (expanded)
                    arrow.set(Gtk.ArrowType.DOWN, Gtk.ShadowType.ETCHED_IN);
                else
                    arrow.set(Gtk.ArrowType.RIGHT, Gtk.ShadowType.ETCHED_IN);
            });
        }

        public override void show () {
            entry.show();
            arrow.show();
            expand_button.show();
            base.show();
            add_button.hide();
            return;
        }

        public void set_remove_sensitivity (bool sensitive) {
            remove_button.set_sensitive(sensitive);
            remove_button.set_has_tooltip(sensitive);
            remove_button.opacity = sensitive ? 1.0 : 0.1;
            return;
        }

    }

}
