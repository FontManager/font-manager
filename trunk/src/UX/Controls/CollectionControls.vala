/* CollectionControls.vala
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

    public class CollectionControls : BaseControls {

        public CollectionControls () {
            add_button.set_tooltip_text(_("Add new collection"));
            remove_button.set_tooltip_text(_("Remove selected collection"));
            var blend = get_style_context();
            blend.add_class(Gtk.STYLE_CLASS_VIEW);
            blend.add_class(Gtk.STYLE_CLASS_SIDEBAR);
        }

    }

}
