/* Preferences.vala
 *
 * Copyright (C) 2009-2023 Jerry Casiano
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preferences.ui")]
    public class Preferences : Gtk.Box {

        [GtkChild] unowned Gtk.Stack stack;

        public void add_page (Gtk.Widget widget, string name, string title) {
            Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow();
            scroll.set_child(widget);
            stack.add_titled(scroll, name, title);
            return;
        }

        public new Gtk.Widget? get (string name) {
            Gtk.Widget? child = stack.get_child_by_name(name);
            return_val_if_fail(child != null, null);
            return ((child is Gtk.ScrolledWindow) ? child.get_child() : child);
        }

        public void init () {
            add_page(new UserInterfacePreferences(), "Interface", _("Interface"));
            add_page(new DesktopPreferences(), "Desktop", _("Desktop"));
            add_page(new UserActionList(), "UserActions", _("Actions"));
            add_page(new UserSourceList(), "Sources", _("Sources"));
            add_page(new SubstituteList(), "Substitutions", _("Substitutions"));
            add_page(new DisplayPreferences(), "Display", _("Display"));
            add_page(new RenderingPreferences(), "Rendering", _("Rendering"));
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-preference-list.ui")]
    public class PreferenceList : Gtk.Box {

        [GtkChild] protected unowned Gtk.ListBox list;
        [GtkChild] protected unowned BaseControls controls;
        [GtkChild] protected unowned Gtk.Separator separator;

        construct {
            set_control_sensitivity(controls.add_button, true);
            set_control_sensitivity(controls.remove_button, false);
            controls.add_selected.connect(on_add_selected);
            controls.remove_selected.connect(on_remove_selected);
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            controls.bind_property("visible", separator, "visible", flags);
        }

        protected virtual void on_add_selected () {}

        [GtkCallback]
        protected virtual void on_list_row_selected (Gtk.ListBox box,
                                                     Gtk.ListBoxRow? row) {
            set_control_sensitivity(controls.remove_button, row != null);
            return;
        }

        [GtkCallback]
        protected virtual void on_map () {
            select_first_row();
            return;
        }

        protected virtual void on_remove_selected () {}

        [GtkCallback]
        protected virtual void on_unmap () {}

        protected void select_first_row () {
            if (list.selection_mode == Gtk.SelectionMode.NONE)
                return;
            Gtk.ListBoxRow? row = list.get_row_at_index(0);
            if (row != null && row.selectable)
                list.select_row(row);
            return;
        }

        protected Gtk.Switch add_preference_switch (string name) {
            var control = new Gtk.Switch();
            var widget = new PreferenceRow(name, null, null, control);
            var row = new Gtk.ListBoxRow() { activatable = false, selectable = false };
            row.set_child(widget);
            list.insert(row, -1);
            return control;
        }

        protected void append_row (Gtk.Widget widget) {
            var row = new Gtk.ListBoxRow() { activatable = false, selectable = false };
            row.set_child(widget);
            list.insert(row, -1);
            return;
        }

    }

}

