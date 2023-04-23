/* Paned.vala
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-paned.ui")]
    public class Paned : Gtk.Box {

        public Gtk.Orientation orientation {
            get {
                return content_pane.orientation;
            }
            set {
                content_pane.orientation = value;
            }
        }

        public int sidebar_position {
            get {
                return sidebar_pos;
            }
            set {
                sidebar_pos = value;
                Idle.add(() => {
                    return update_pane_positions();
                });
            }
        }

        public int content_position {
            get {
                return content_pos;
            }
            set {
                content_pos = value;
                Idle.add(() => {
                    return update_pane_positions();
                });
            }
        }

        [GtkChild] protected unowned Gtk.Box content_area;
        [GtkChild] protected unowned Gtk.Box list_area;
        [GtkChild] protected unowned Gtk.Box sidebar_area;
        [GtkChild] protected unowned Gtk.Paned content_pane;
        [GtkChild] protected unowned Gtk.Paned main_pane;
        [GtkChild] protected unowned Gtk.Overlay overlay;

        int sidebar_pos = 33;
        int content_pos = 40;

        public Paned () {
            list_area.set_size_request(-1, 200);
            map.connect_after(() => {
                Idle.add(() => {
                    return update_pane_positions();
                });
            });
            main_pane.notify["position"].connect((obj, pspec) => {
                sidebar_pos = position_to_percentage(main_pane).clamp(2, 98);
            });
            content_pane.notify["position"].connect((obj, pspec) => {
                content_pos = position_to_percentage(content_pane).clamp(2, 98);
            });
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

        bool update_pane_positions () {
            int pos_a = percentage_to_position(main_pane, sidebar_position);
            int pos_b = percentage_to_position(content_pane, content_position);
            if (pos_a == 0 || pos_b == 0)
                return GLib.Source.CONTINUE;
            main_pane.set_position(pos_a);
            content_pane.set_position(pos_b);
            return GLib.Source.REMOVE;
        }

        double get_alloc (Gtk.Paned paned) {
            return (orientation == Gtk.Orientation.HORIZONTAL) ?
                          (double) paned.get_allocated_width() :
                          (double) paned.get_allocated_height();
        }

        int position_to_percentage (Gtk.Paned paned) {
            double position = (double) paned.position;
            return (int) Math.round((position / get_alloc(paned)) * 100.0);
        }

        int percentage_to_position (Gtk.Paned paned, int percent) {
            return (int) Math.round(((double) percent / 100.0) * get_alloc(paned));
        }

    }

}

