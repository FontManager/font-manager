/* Preferences.vala
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

    public Preferences.Pane construct_preference_pane () {
        Preferences.Pane pane = new Preferences.Pane();
        pane.add_page(new Preferences.Sources(), "Sources", _("Sources"));
        pane.add_page(new Preferences.Rendering(), "Rendering", _("Rendering"));
        pane.add_page(new Preferences.Display(), "Display", _("Display"));
        pane.add_page(new Preferences.Interface(), "Interface", _("Interface"));
        return pane;
    }

    namespace Preferences {

        public class Pane : Gtk.Paned {

            public Gtk.Widget visible_child { get; set; }
            public string visible_child_name { get; set; }

            Gtk.Box box;
            Gtk.Stack stack;
            Gtk.StackSidebar sidebar;

            construct {
                orientation = Gtk.Orientation.HORIZONTAL;
                expand = true;
                position = 275;
                stack = new Gtk.Stack();
                stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
                box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                sidebar = new Gtk.StackSidebar();
                sidebar.set_stack(stack);
                sidebar.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
                box.pack_start(sidebar, true, true, 0);
                add_separator(box);
                add1(box);
                add2(stack);
                bind_properties();
                connect_signals();
            }

            void bind_properties () {
                stack.bind_property("visible-child", this, "visible-child");
                stack.bind_property("visible-child-name", this, "visible-child-name");
            }

            void connect_signals () {
                notify["visible-child"].connect(() => {
                    debug("Visible child : %s", stack.visible_child_name);
                    if (stack.visible_child_name == "Sources")
                        ((Sources) get_page("Sources")).user_source_list.update();
                });
                return;
            }

            public override void show () {
                box.show();
                stack.show();
                sidebar.show();
                base.show();
                return;
            }

            public void add_page (Gtk.Widget widget, string name, string title) {
                Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
                scroll.add(widget);
                scroll.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                stack.add_titled(scroll, name, title);
                widget.show();
                scroll.show();
                return;
            }

            public Gtk.Widget get_page (string name) {
                var scroll = ((Gtk.Container) stack.get_child_by_name(name));
                var viewport = scroll.get_children().nth_data(0);
                var widget = ((Gtk.Container) viewport).get_children().nth_data(0);
                return widget;
            }

        }

    }

}
