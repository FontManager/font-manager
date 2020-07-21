/* InlineHelp.vala
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-inline-help.ui")]
    public class InlineHelp : Gtk.MenuButton {

        public Gtk.Label message {
            get {
                return ((Gtk.Label) popover.get_child());
            }
        }

        construct {
            var style_context = get_style_context();
            style_context.remove_class("toggle");
            style_context.remove_class(Gtk.STYLE_CLASS_POPUP);
            style_context.add_class("image-button");
            popover.get_style_context().remove_class(Gtk.STYLE_CLASS_BACKGROUND);
        }

    }

}
