/* CustomPreviewEntry.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    public class CustomPreviewEntry : Gtk.Entry {

        public CustomPreviewEntry () {
            Object(margin: 6, opacity: 0.75);
            changed.connect(() => { update(); });
            icon_press.connect((pos, ev) => {
                if (pos == Gtk.EntryIconPosition.SECONDARY)
                    set_text("");
            });
            update();
        }

        void update () {
            if (text_length > 0) {
                set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
                set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
            } else {
                set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "document-edit-symbolic");
                set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, false);
            }
            return;
        }

    }

}
