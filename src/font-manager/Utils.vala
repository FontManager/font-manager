/* Utils.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

    public void set_control_sensitivity(Gtk.Widget widget, bool sensitive) {
        widget.sensitive = sensitive;
        widget.opacity = sensitive ? 0.9 : 0.45;
        widget.has_tooltip = sensitive;
        return;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-item-list-box-row.ui")]
    public class ItemListBoxRow : Gtk.Box {

        public Object? item { get; set; default = null; }

        [GtkChild] public unowned Gtk.CheckButton item_state { get; }
        [GtkChild] public unowned Gtk.Image item_icon { get; }
        [GtkChild] public unowned Gtk.Label item_label { get; }
        [GtkChild] public unowned Gtk.Label item_count { get; }

    }

}
