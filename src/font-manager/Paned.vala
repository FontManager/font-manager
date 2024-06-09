/* Paned.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-paned.ui")]
    public class Paned : Gtk.Box {

        public GLib.Settings? settings { get; protected set; default = null; }

        public Gtk.Orientation orientation {
            get {
                return content_pane.orientation;
            }
            set {
                if (value == content_pane.orientation)
                    return;
                content_pane.orientation = value;
                Idle.add(() => {
                    update_pane_positions();
                    return GLib.Source.REMOVE;
                });
            }
        }

        public double sidebar_position {
            get {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    return hor_sidebar_pos;
                else
                    return sidebar_pos;
            }
            set {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    hor_sidebar_pos = value;
                else
                    sidebar_pos = value;
                update_pane_positions();
            }
        }

        public double content_position {
            get {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    return hor_content_pos;
                else
                    return content_pos;
            }
            set {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    hor_content_pos = value;
                else
                    content_pos = value;
                update_pane_positions();
            }
        }

        // These four properties are only here to make binding to GSettings easier
        public double content_size {
            get {
                return content_pos;
            }
            set {
                content_pos = value;
            }
        }

        public double sidebar_size {
            get {
                return sidebar_pos;
            }
            set {
                sidebar_pos = value;
            }
        }

        public double hor_content_size {
            get {
                return hor_content_pos;
            }
            set {
                hor_content_pos = value;
            }
        }

        public double hor_sidebar_size {
            get {
                return hor_sidebar_pos;
            }
            set {
                hor_sidebar_pos = value;
            }
        }

        [GtkChild] protected unowned Gtk.Box content_area;
        [GtkChild] protected unowned Gtk.Box list_area;
        [GtkChild] protected unowned Gtk.Box sidebar_area;
        [GtkChild] protected unowned Gtk.Paned content_pane;
        [GtkChild] protected unowned Gtk.Paned main_pane;
        [GtkChild] protected unowned Gtk.Overlay overlay;

        double sidebar_pos = 33.0;
        double content_pos = 40.0;
        double hor_sidebar_pos = 20.0;
        double hor_content_pos = 36.0;

        public Paned (GLib.Settings? settings) {
            this.settings = settings;
            // Necessary to get an acceptable initial size for pane layout
            sidebar_area.set_size_request(-1, 250);
            list_area.set_size_request(-1, 250);
            main_pane.notify["position"].connect((obj, pspec) => {
                var new_pos = position_to_percentage(main_pane).clamp(2, 98);
                if (orientation == Gtk.Orientation.HORIZONTAL) {
                    hor_sidebar_pos = new_pos;
                    notify_property("hor-sidebar-size");
                } else {
                    sidebar_pos = new_pos;
                    notify_property("sidebar-size");
                }
                notify_property("sidebar-position");
            });
            content_pane.notify["position"].connect((obj, pspec) => {
                var new_pos = position_to_percentage(content_pane).clamp(2, 98);
                if (orientation == Gtk.Orientation.HORIZONTAL) {
                    hor_content_pos = new_pos;
                    notify_property("hor-content-size");
                } else {
                    content_pos = new_pos;
                    notify_property("content-size");
                }
                notify_property("content-position");
            });
        }

        [GtkCallback]
        public virtual void on_map () {
            if (settings != null) {
                SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
                settings.bind("sidebar-size", this, "sidebar-size", flags);
                settings.bind("content-size", this, "content-size", flags);
                settings.bind("hor-sidebar-size", this, "hor-sidebar-size", flags);
                settings.bind("hor-content-size", this, "hor-content-size", flags);
                if (orientation == Gtk.Orientation.HORIZONTAL) {
                    sidebar_position = settings.get_double("hor-sidebar-size");
                    content_position = settings.get_double("hor-content-size");
                } else {
                    sidebar_position = settings.get_double("sidebar-size");
                    content_position = settings.get_double("content-size");
                }
            }
            Idle.add(() => {
                update_pane_positions();
                return GLib.Source.REMOVE;
            });
            notify_property("sidebar-position");
            notify_property("content-position");

            return;
        }

        [GtkCallback]
        public virtual void on_unmap () {}

        public Gtk.Widget? get_content_widget () {
            return content_area.get_first_child();
        }

        public Gtk.Widget? get_list_widget () {
            return list_area.get_first_child();
        }

        public Gtk.Widget? get_sidebar_widget () {
            return sidebar_area.get_first_child();
        }

        public void set_content_widget (Gtk.Widget? widget) {
            set_child(content_area, widget);
            return;
        }

        public void set_list_widget (Gtk.Widget? widget) {
            set_child(list_area, widget);
            return;
        }

        public void set_sidebar_widget (Gtk.Widget? widget) {
            set_child(sidebar_area, widget);
            return;
        }

        void set_child (Gtk.Box parent, Gtk.Widget? child) {
            Gtk.Widget? current_child = parent.get_first_child();
            if (current_child != null)
                parent.remove(current_child);
            if (child != null) {
                widget_set_expand(child, true);
                parent.append(child);
            }
            return;
        }

        public bool update_pane_positions () {
            int pos_a = (int) percentage_to_position(main_pane, sidebar_position);
            int pos_b = (int) percentage_to_position(content_pane, content_position);
            if (pos_a == 0 && pos_b == 0)
                return GLib.Source.REMOVE;
            main_pane.set_position(pos_a);
            content_pane.set_position(pos_b);
            return GLib.Source.REMOVE;
        }

        int get_alloc (Gtk.Paned paned) {
            int alloc = paned.max_position;
            // max_position is more reliable than get_width function
            // except when it returns the default value of MAX_INT
            if (alloc != int.MAX)
                return alloc;
            // get_width seems to regularly returns a smaller than actual value
            // which could be due to our use of panes within a pane
            return (paned.orientation == Gtk.Orientation.HORIZONTAL) ? paned.get_width() : paned.get_height();
        }

        double position_to_percentage (Gtk.Paned paned) {
            int position = paned.position;
            return ((double) position / (double) get_alloc(paned)) * 100;
        }

        double percentage_to_position (Gtk.Paned paned, double percent) {
            return (percent / 100) * (double) get_alloc(paned);
        }

    }

}


