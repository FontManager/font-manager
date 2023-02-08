/* Preferences.vala
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

    public void initialize_preference_pane (Preferences pane) {
        // pane.add_page(new UserInterfacePreferences(), "Interface", _("Interface"));
        pane.add_page(new DesktopPreferences(), "Desktop", _("Desktop"));
        pane.add_page(new UserSourceList(), "Sources", _("Sources"));
        // pane.add_page(new UserActionList(), "UserActions", _("Actions"));
        // pane.add_page(new SubstitutionPreferences(), "Substitutions", _("Substitutions"));
        // pane.add_page(new DisplayPreferences(), "Display", _("Display"));
        // pane.add_page(new RenderingPreferences(), "Rendering", _("Rendering"));
        return;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preferences.ui")]
    public class Preferences : Gtk.Box {

        public Gtk.Widget visible_child { get; set; }
        public string visible_child_name { get; set; }

        [GtkChild] unowned Gtk.Stack stack;
        [GtkChild] unowned Gtk.StackSidebar sidebar;

        public override void constructed () {
            sidebar.remove_css_class(STYLE_CLASS_SIDEBAR);
            stack.bind_property("visible-child", this, "visible-child");
            stack.bind_property("visible-child-name", this, "visible-child-name");
            base.constructed();
            return;
        }

        public void add_page (Gtk.Widget widget, string name, string title) {
            Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow();
            scroll.set_child(widget);
            stack.add_titled(scroll, name, title);
            return;
        }

        public new Gtk.Widget? get (string name) {
            Gtk.Widget? widget = null;
            var child = stack.get_child_by_name(name);
            if (child is Gtk.ScrolledWindow)
                widget = child.get_child();
            else
                widget = child;
            return widget;
        }

    }

    /**
     * Base class for preference panes.
     */
    public class SettingsPage : Gtk.Box {

        protected Gtk.Label message;
        protected Gtk.InfoBar infobar;
        protected Gtk.Box box;
        protected Gtk.Revealer revealer;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            spacing = 0;
            revealer = new Gtk.Revealer();
            infobar = new Gtk.InfoBar();
            infobar.message_type = Gtk.MessageType.INFO;
            message = new Gtk.Label(null);
            infobar.add_child(message);
            infobar.set_show_close_button(true);
            revealer.set_child(infobar);
            append(revealer);
            infobar.response.connect((id) => {
                if (id == Gtk.ResponseType.CLOSE)
                    revealer.set_reveal_child(false);
            });
            add_css_class(STYLE_CLASS_VIEW);
        }

        protected virtual void show_message (string m) {
            message.set_markup("<b>%s</b>".printf(m));
            revealer.set_reveal_child(true);
            return;
        }

    }

}

