/* Substitute.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    /**
     * Substitute:
     *
     * Single line widget representing a substitute font family
     * in a Fontconfig <alias> entry.
     */
    public class Substitute : Gtk.Grid {

        /**
         * Substitute::changed:
         *
         * Emitted when a selection has changed
         */
        public signal void changed ();

        /**
         * Substitute::removed:
         *
         * Emitted when user requests removal of this Substitute
         */
        public signal void removed ();

        /**
         * Substitute:priority:
         *
         * prefer, accept, or default
         */
        public string priority {
            get {
                return _priority;
            }
        }

        /**
         * Substitute:family:
         *
         * Name of replacement family
         */
        public string? family {
            get {
                return _family;
            }
        }

        string? _priority;
        string? _family;
        Gtk.Button close;
        Gtk.ComboBoxText type;
        Gtk.ComboBoxText target;

        construct {
            type = new Gtk.ComboBoxText();
            type.append_text(_("prefer"));
            type.append_text(_("accept"));
            type.append_text(_("default"));
            type.set_active(0);
            target = new Gtk.ComboBoxText.with_entry();
            close = new Gtk.Button();
            close.set_image(new Gtk.Image.from_icon_name("close-symbolic", Gtk.IconSize.MENU));
            close.get_style_context().add_class("circular-button");
            close.expand = false;
            attach(type, 0, 0, 2, 1);
            attach(target, 3, 0, 2, 1);
            attach(close, 5, 0, 1, 1);
            connect_signals();
        }

        /**
         * @families    string [] of available font family names
         */
        public Substitute (string [] families) {
            Object(name: "Substitute", margin: 0);
            foreach (var family in families)
                target.append_text(family);
        }

        /**
         * {@inheritDoc}
         */
        public override void show () {
            type.show();
            target.show();
            close.show();
            base.show();
        }

        void connect_signals () {
            type.format_entry_text.connect((p) => {
                Gtk.TreeIter iter;
                Value val;
                type.get_model().get_iter_from_string(out iter, p);
                type.get_model().get_value(iter, 0, out val);
                return ("<%s>".printf((string) val));
            });
            target.format_entry_text.connect((p) => {
                Gtk.TreeIter iter;
                Value val;
                target.get_model().get_iter_from_string(out iter, p);
                target.get_model().get_value(iter, 0, out val);
                return ("<%s>".printf((string) val));
            });
            type.changed.connect(() => {
                _priority = type.get_active_text();
                changed();
                return;
            });
            target.changed.connect(() => {
                _family = target.get_active_text();
                changed();
                return;
            });
            close.clicked.connect(() => {
                removed();
                return;
            });
            return;
        }

    }

}
