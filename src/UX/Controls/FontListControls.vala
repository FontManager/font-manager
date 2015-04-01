/* FontListControls.vala
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

    public class FontListControls : Gtk.EventBox {

        public signal void remove_selected ();
        public signal void expand_all (bool expand);
        public signal void show_metadata (bool show);

        public bool expanded { get; private set; }
        public Gtk.SearchEntry entry { get; private set; }

        private Gtk.Button _remove;
        private Gtk.Button _expand;
        private Gtk.Arrow arrow;
        private Gtk.Box box;
        private Gtk.ToggleButton _show_metadata;

        public FontListControls () {
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
            box.border_width = 2;
            _expand = new Gtk.Button();
            arrow = new Gtk.Arrow(Gtk.ArrowType.RIGHT, Gtk.ShadowType.ETCHED_IN);
            _expand.add(arrow);
            _expand.set_tooltip_text(_("Expand all"));
            _remove = new Gtk.Button();
            _remove.set_image(new Gtk.Image.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU));
            _remove.set_tooltip_text(_("Remove selected fonts"));
            entry = new Gtk.SearchEntry();
            entry.margin_end = 2;
            entry.set_size_request(0, 0);
            entry.placeholder_text = _("Search Families...");
            _show_metadata = new Gtk.ToggleButton();
        #if GTK_314
            _show_metadata.set_image(new Gtk.Image.from_icon_name("stock-eye-symbolic", Gtk.IconSize.MENU));
        #else
            _show_metadata.set_image(new Gtk.Image.from_resource("/org/gnome/FontManager/icons/16x16/actions/stock-eye-symbolic.svg"));
        #endif
            _show_metadata.set_tooltip_text(_("View font information"));
            box.pack_end(entry, false, false, 0);
            box.pack_end(_show_metadata, false, false, 2);
            box.pack_start(_expand, false, false, 0);
            box.pack_start(_remove, false, false, 0);
            set_default_button_relief(box);
            add(box);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            connect_signals();
            set_size_request(0, 0);
        }

        public override void show () {
            entry.show();
            _remove.show();
            arrow.show();
            _expand.show();
            _show_metadata.show();
            box.show();
            base.show();
            return;
        }

        private void connect_signals () {
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
            _show_metadata.toggled.connect(() => {
                show_metadata(_show_metadata.active);
                if (_show_metadata.active)
                    _show_metadata.set_tooltip_text(_("Hide font information"));
                else
                    _show_metadata.set_tooltip_text(_("View font information"));

            });
            return;
        }

        public void set_remove_sensitivity (bool sensitive) {
            _remove.set_sensitive(sensitive);
            _remove.set_has_tooltip(sensitive);
            return;
        }

        public void set_metadata_sensitivity (bool sensitive) {
            _show_metadata.set_active(false);
            _show_metadata.set_sensitive(sensitive);
            _show_metadata.set_has_tooltip(sensitive);
            return;
        }

    }

}
