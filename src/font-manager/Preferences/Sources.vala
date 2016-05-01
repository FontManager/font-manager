/* Sources.vala
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

    namespace Preferences {

        public class Sources : Gtk.Box {

            public FontSourceList source_list { get; private set; }

            BaseControls controls;

            public Sources () {
                orientation = Gtk.Orientation.VERTICAL;
                source_list = new FontSourceList();
                source_list.expand = true;
                source_list.sources = Main.instance.sources;
                controls = new BaseControls();
                controls.add_button.set_tooltip_text(_("Add source"));
                controls.remove_button.set_tooltip_text(_("Remove selected source"));
                controls.remove_button.sensitive = false;
                pack_start(controls, false, false, 1);
                add_separator(this, Gtk.Orientation.HORIZONTAL);
                pack_end(source_list, true, true, 1);
                connect_signals();
            }

            public override void show () {
                controls.show();
                controls.remove_button.hide();
                source_list.show();
                base.show();
                return;
            }

            void connect_signals () {
                controls.add_selected.connect(() => {
                    source_list.on_add_source();
                });
                controls.remove_selected.connect(() => {
                    source_list.on_remove_source();
                });
                source_list.row_selected.connect((r) => {
                    if (r != null)
                        controls.remove_button.show();
                    else
                        controls.remove_button.hide();
                    controls.remove_button.sensitive = (r != null);
                });
                return;
            }

        }

    }

}

