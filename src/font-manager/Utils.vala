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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-item-list-box-row.ui")]
    public class ItemListBoxRow : Gtk.Box {

        public Object? item { get; set; default = null; }

        [GtkChild] public unowned Gtk.CheckButton item_state { get; }
        [GtkChild] public unowned Gtk.Image item_icon { get; }
        [GtkChild] public unowned Gtk.Label item_label { get; }
        [GtkChild] public unowned Gtk.Label item_count { get; }

    }

    namespace ProgressDialog {

        public Gtk.MessageDialog create (Gtk.Window? parent, string? title) {
            var dialog = new Gtk.MessageDialog(parent,
                                               Gtk.DialogFlags.MODAL |
                                               Gtk.DialogFlags.DESTROY_WITH_PARENT |
                                               Gtk.DialogFlags.USE_HEADER_BAR,
                                               Gtk.MessageType.INFO,
                                               Gtk.ButtonsType.NONE,
                                               "%s", title != null ? title : "");
            var progress = new Gtk.ProgressBar();
            var box = dialog.get_message_area() as Gtk.Box;
            box.append(progress);
            dialog.set_default_size(475, 125);
            return dialog;
        }

        public void update (Gtk.MessageDialog dialog, ProgressData data) {
            var child = dialog.get_message_area().get_last_child();
            return_if_fail(child is Gtk.ProgressBar);
            var progress_bar = child as Gtk.ProgressBar;
            dialog.secondary_text = data.message;
            progress_bar.set_fraction(data.progress);
            dialog.queue_draw();
            return;
        }

    }





}
