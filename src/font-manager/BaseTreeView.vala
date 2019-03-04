/* BaseTreeView.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

static uint mask = (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK);

struct PendingEvent {

    public double x;
    public double y;
    public bool active;

    public void update (double x, double y, bool active) {
        this.x = x;
        this.y = y;
        this.active = active;
        return;
    }

}

namespace FontManager {

    /**
     * BaseTreeView:
     *
     * #GtkTreeView which supports multiple selection drag and drop
     */
    public class BaseTreeView : Gtk.TreeView {

        PendingEvent pending_event;

        construct {
            pending_event = PendingEvent();
        }

        /**
         * show_context_menu:
         *
         * Called on right click events.
         *
         * Returns:     %TRUE to stop other handlers from being invoked for the event.
         *              %FALSE to propagate the event further.
         */
        protected virtual bool show_context_menu (Gdk.EventButton event) {
            return base.button_press_event(event);
        }

        /**
         * {@inheritDoc}
         */
        public override bool button_press_event (Gdk.EventButton event) {
            if (event.triggers_context_menu() && event.type == Gdk.EventType.BUTTON_PRESS)
                return show_context_menu(event);
            Gtk.TreePath path;
            get_path_at_pos((int) event.x, (int) event.y, out path, null, null, null);
            if (path == null)
                return true;
            Gtk.TreeSelection selection = get_selection();
            bool pending = (selection.path_is_selected(path) && (event.state & mask) == 0);
            pending_event.update(event.x, event.y, pending);
            selection.set_select_function((s, m, p, b) => { return !pending; });
            return base.button_press_event(event);
        }

        /**
         * {@inheritDoc}
         */
        public override bool button_release_event (Gdk.EventButton event) {
            if (pending_event.active) {
                Gtk.TreeSelection selection = get_selection();
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

    }

}
