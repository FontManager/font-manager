/* MultiDNDTreeView.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

public class MultiDNDTreeView : Gtk.TreeView {

    public signal void menu_request (Gtk.Widget widget, Gdk.EventButton event);

    struct PendingEvent {
        double x;
        double y;
        bool active;
    }

    PendingEvent pending_event;

    public MultiDNDTreeView () {
        get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);
        rubber_banding = true;
        pending_event = PendingEvent();
        button_press_event.connect(on_button_press_event);
        button_release_event.connect(on_button_release_event);
        drag_begin.connect_after(on_drag_begin);
    }

    bool on_button_press_event (Gtk.Widget widget, Gdk.EventButton event) {
        if (event.button == 3) {
            menu_request(widget, event);
            return true;
        }
        var _widget = widget as Gtk.TreeView;
        Gtk.TreePath path;
        _widget.get_path_at_pos((int) event.x, (int) event.y, out path, null, null, null);
        if (path == null)
            return true;
        var selection = _widget.get_selection();
        if (selection.path_is_selected(path) && (event.state & (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK)) == 0) {
            pending_event.x = event.x;
            pending_event.y = event.y;
            pending_event.active = true;
            selection.set_select_function((s, m, p, b) => { return false; });
        } else {
            pending_event.x = 0.0;
            pending_event.y = 0.0;
            pending_event.active = false;
            selection.set_select_function((s, m, p, b) => { return true; });
        }
        path = null;
        return false;
    }

    bool on_button_release_event (Gtk.Widget widget, Gdk.EventButton event) {
        if (pending_event.active) {
            var _widget = widget as Gtk.TreeView;
            var selection = _widget.get_selection();
            selection.set_select_function((s, m, p, b) => { return true; });
            pending_event.active = false;
            if (pending_event.x != event.x || pending_event.y != event.y)
                return true;
            Gtk.TreePath path;
            if (_widget.get_path_at_pos((int) event.x, (int) event.y, out path, null, null, null))
                _widget.set_cursor(path, null, false);
        }
        return false;
    }

    protected virtual void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        return;
    }

}

