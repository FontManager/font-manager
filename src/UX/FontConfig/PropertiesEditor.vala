/* PropertiesEditor.vala
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

namespace FontConfig {

    public class PropertiesEditor : Gtk.Dialog {

        private FontPropertiesPane general_pane;
        private DisplayPropertiesPane display_pane;
        private Gtk.Stack stack;
        private Gtk.StackSwitcher switcher;
        private Gtk.HeaderBar header;
        private Gtk.Button discard;

        construct {
            modal = true;
            destroy_with_parent = true;
        }

        public PropertiesEditor (Gtk.Window? parent = null) {
            set_transient_for(parent);
            general_pane = new FontPropertiesPane();
            general_pane.expand = true;
            display_pane = new DisplayPropertiesPane();
            display_pane.expand = true;
            stack = new Gtk.Stack();
            stack.add_titled(general_pane, "General", _("General"));
            stack.add_titled(display_pane, "Display", _("Display"));
            stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            switcher = new Gtk.StackSwitcher();
            switcher.set_stack(stack);
            header = new Gtk.HeaderBar();
            header.set_title(_("FontConfig Properties"));
            header.set_custom_title(switcher);
            header.show_close_button = true;
            discard = new Gtk.Button.from_icon_name("user-trash-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            discard.set_tooltip_text(_("Discard configuration"));
            discard.clicked.connect((w) => {
                Properties.skip_save = true;
                general_pane.properties.discard();
                display_pane.properties.discard();
                general_pane.properties.load();
                display_pane.properties.load();
                Properties.skip_save = false;
            });
            header.pack_start(discard);
            set_titlebar(header);
            get_content_area().add(stack);
            delete_event.connect((ev) => {
                return hide_on_delete();
            });
            general_pane.properties.notify.connect((pspec) => {
                general_pane.properties.save();
            });
            display_pane.properties.notify.connect((pspec) => {
                display_pane.properties.save();
            });
        }

        public override void show () {
            general_pane.show();
            display_pane.show();
            stack.show();
            header.show_all();
            base.show();
            return;
        }
    }

}
