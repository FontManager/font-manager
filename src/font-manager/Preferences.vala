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

    public PreferencePane construct_preference_pane () {
        PreferencePane pane = new PreferencePane();
        InterfacePreferences ui = new InterfacePreferences();
        RenderingPreferences render = new RenderingPreferences();
        DisplayPreferences display = new DisplayPreferences();
        pane.add_page(ui, "Interface", _("Interface"));
        pane.add_page(render, "Rendering", _("Rendering"));
        pane.add_page(display, "Display", _("Display"));
        return pane;
    }

    public class PreferencePane : Gtk.Paned {

        Gtk.Stack stack;
        Gtk.StackSidebar sidebar;

        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            expand = true;
            position = 275;
            stack = new Gtk.Stack();
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            sidebar = new Gtk.StackSidebar();
            sidebar.set_stack(stack);
            sidebar.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            box.pack_start(sidebar, true, true, 0);
            add_separator(box);
            box.show();
            stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
            add1(box);
            add2(stack);
        }

        public override void show () {
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
            return ((Gtk.Container) viewport).get_children().nth_data(0);
        }

    }

    public class InterfacePreferences : Gtk.Grid {

        public LabeledSwitch wide_layout { get; private set; }
        public LabeledSwitch use_csd { get; private set; }

        construct {
            wide_layout = new LabeledSwitch();
            wide_layout.label.set_markup("<b>%s</b>".printf(_("Wide Layout")));
            attach(wide_layout, 0, 0, 3, 1);
            use_csd = new LabeledSwitch();
            use_csd.label.set_markup("<b>%s</b>".printf(_("Client Side Decorations")));
            use_csd.dim_label.set_text(_("Restart required"));
            attach(use_csd, 0, 1, 3, 1);
        }

        public override void show () {
            wide_layout.show();
            use_csd.show();
            base.show();
            return;
        }

    }

    public class RenderingPreferences : Gtk.Box {

        FontConfig.FontPropertiesPane properties;
        FontConfig.Controls controls;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            properties = new FontConfig.FontPropertiesPane();
            controls = new FontConfig.Controls();
            pack_start(properties, true, true, 0);
            pack_end(controls, false, false, 0);
        }

        public override void show () {
            properties.show();
            controls.show();
            base.show();
            return;
        }

    }

    public class DisplayPreferences : Gtk.Box {

        FontConfig.DisplayPropertiesPane properties;
        FontConfig.Controls controls;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            properties = new FontConfig.DisplayPropertiesPane();
            controls = new FontConfig.Controls();
            pack_start(properties, true, true, 0);
            pack_end(controls, false, false, 0);
        }

        public override void show () {
            properties.show();
            controls.show();
            base.show();
            return;
        }

    }
}
