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

    public class Paned : Gtk.Widget {

        public double position { get; set; default = 50; }
        public Gtk.Orientation orientation { get; set; default = Gtk.Orientation.HORIZONTAL; }

        Gtk.Paned child;

        construct {
            set_layout_manager(new Gtk.BoxLayout(Gtk.Orientation.HORIZONTAL));
            widget_set_expand(this, true);
            child = new Gtk.Paned(orientation);
            child.set_parent(this);
            BindingFlags flags = BindingFlags.DEFAULT;
            bind_property("orientation", child, "orientation", flags);
            notify["position"].connect(on_position_set);
            child.notify["position"].connect(on_child_position_changed);
            map.connect_after(on_map);
        }

        public Gtk.Widget? get_start_child () {
            return child.get_start_child();
        }

        public Gtk.Widget? get_end_child () {
            return child.get_end_child();
        }

        public void set_start_child (Gtk.Widget widget) {
            child.set_start_child(widget);
            return;
        }

        public void set_end_child (Gtk.Widget widget) {
            child.set_end_child(widget);
            return;
        }

        void on_map () {
            Idle.add_full(GLib.Priority.LOW, () => { on_position_set(); return GLib.Source.REMOVE; });
            Idle.add_full(GLib.Priority.LOW, () => { child.queue_resize(); return GLib.Source.REMOVE; });
            return;
        }

        int get_alloc () {
            return (orientation == Gtk.Orientation.HORIZONTAL) ? get_width() : get_height();
        }

        void on_position_set () {
            child.set_position((int) ((position / 100) * (double) get_alloc()));
            return;
        }

        void on_child_position_changed () {
            double new_position = ((double) child.position / (double) get_alloc()) * 100;
            if (position != new_position)
                position = new_position;
            return;
        }

    }

    public class DualPaned : Gtk.Widget {

        public GLib.Settings? settings { get; protected set; default = null; }
        public Gtk.Orientation orientation { get; set; default = Gtk.Orientation.VERTICAL; }

        public double sidebar_position {
            get {
                return (orientation == Gtk.Orientation.HORIZONTAL) ? hor_sidebar_size : sidebar_size;
            }
            set {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    hor_sidebar_size = value;
                else
                    sidebar_size = value;
                notify_property("sidebar-position");
            }
        }

        public double content_position {
            get {
                return (orientation == Gtk.Orientation.HORIZONTAL) ? hor_content_size : content_size;
            }
            set {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    hor_content_size = value;
                else
                    content_size = value;
                notify_property("content-position");
            }
        }

        // These four properties are only here to make binding to GSettings easier
        public double content_size { get; set; default = 40; }
        public double sidebar_size { get; set; default = 33; }
        public double hor_content_size { get; set; default = 36; }
        public double hor_sidebar_size { get; set; default = 20; }

        protected Gtk.Overlay overlay;

        Paned main_pane;
        Paned content_pane;
        Gtk.Box content_area;
        Gtk.Box list_area;
        Gtk.Box sidebar_area;

        construct {
            set_layout_manager(new Gtk.BoxLayout(Gtk.Orientation.HORIZONTAL));
            widget_set_expand(this, true);
            overlay = new Gtk.Overlay();
            overlay.set_parent(this);
        }

        public DualPaned (GLib.Settings? settings) {
            Object(settings: settings);
            main_pane = new Paned();
            content_pane = new Paned();
            main_pane.set_end_child(content_pane);
            overlay.set_child(main_pane);
            content_area = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            list_area = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            sidebar_area = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            // Setting size request is necessary to make these empty containers map properly
            content_area.set_size_request(-1, 250);
            list_area.set_size_request(-1, 250);
            sidebar_area.set_size_request(-1, 250);
            main_pane.set_start_child(sidebar_area);
            content_pane.set_start_child(list_area);
            content_pane.set_end_child(content_area);
            main_pane.notify["position"].connect((obj, pspec) => {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    hor_sidebar_size = main_pane.position;
                else
                    sidebar_size = main_pane.position;
            });
            content_pane.notify["position"].connect((obj, pspec) => {
                if (orientation == Gtk.Orientation.HORIZONTAL)
                    hor_content_size = content_pane.position;
                else
                    content_size = content_pane.position;
            });
            notify["orientation"].connect(() => {
                if (orientation == Gtk.Orientation.HORIZONTAL) {
                    main_pane.position = hor_sidebar_size;
                    content_pane.position = hor_content_size;
                } else {
                    main_pane.position = sidebar_size;
                    content_pane.position = content_size;
                }
            });
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("orientation", content_pane, "orientation", flags);
            bind_property("sidebar-position", main_pane, "position", flags);
            bind_property("content-position", content_pane, "position", flags);
            map.connect_after(on_map);
        }

        public virtual void on_map () {
            if (settings == null)
                return;
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                sidebar_position = settings.get_double("hor-sidebar-size");
                content_position = settings.get_double("hor-content-size");
            } else {
                sidebar_position = settings.get_double("sidebar-size");
                content_position = settings.get_double("content-size");
            }
            SettingsBindFlags flags = SettingsBindFlags.DEFAULT;
            settings.bind("sidebar-size", this, "sidebar-size", flags);
            settings.bind("content-size", this, "content-size", flags);
            settings.bind("hor-sidebar-size", this, "hor-sidebar-size", flags);
            settings.bind("hor-content-size", this, "hor-content-size", flags);
            return;
        }

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

    }

}


