/* TreeViews.vala
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

public class BaseTreeView : Gtk.TreeView {

    public signal void menu_request (Gtk.Widget widget, Gdk.EventButton event);

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.button == 3) {
            menu_request(this, event);
            debug("Context menu request - %s", this.name);
            return true;
        }
        return base.button_press_event(event);
    }

}

public class MultiDNDTreeView : BaseTreeView {

    private struct PendingEvent {
        double x;
        double y;
        bool active;
    }

    private PendingEvent pending_event;

    public MultiDNDTreeView () {
        get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);
        rubber_banding = true;
        pending_event = PendingEvent();
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.button == 3)
            return base.button_press_event(event);
        Gtk.TreePath path;
        get_path_at_pos((int) event.x, (int) event.y, out path, null, null, null);
        if (path == null)
            return true;
        var selection = get_selection();
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
        return base.button_press_event(event);
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (pending_event.active) {
            var selection = get_selection();
            selection.set_select_function((s, m, p, b) => { return true; });
            pending_event.active = false;
            if (pending_event.x != event.x || pending_event.y != event.y)
                return true;
            Gtk.TreePath path;
            if (get_path_at_pos((int) event.x, (int) event.y, out path, null, null, null))
                set_cursor(path, null, false);
        }
        return base.button_release_event(event);
    }

    public override void drag_begin (Gdk.DragContext context) {
        return;
    }

}

