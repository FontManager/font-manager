/* PlaceHolder.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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
     * PlaceHolder:
     *
     * It's intended use is to provide helpful information about an area
     * which is empty and the user may not yet be familiar with.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-place-holder.ui")]
    public class PlaceHolder : Gtk.Box {

        [GtkChild] public Gtk.Image image { get; }
        [GtkChild] public Gtk.Label label { get; }

        public PlaceHolder (string? str, string? icon) {
            label.set_markup(str);
            image.set_from_icon_name(icon, Gtk.IconSize.DIALOG);
        }

    }

}


