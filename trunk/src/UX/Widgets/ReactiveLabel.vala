/* ReactiveLabel.vala
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

public class ReactiveLabel : Gtk.EventBox {

    public signal void clicked ();

    public Gtk.Label label { get; private set; }

    private Gdk.RGBA normal;
    private Gdk.RGBA hover;

    public ReactiveLabel (string? str) {
        label = new Gtk.Label(str);
        add(label);
        style_updated();
    }

    public override void show () {
        label.show();
        base.show();
        return;
    }

    public void set_markup (string str) {
        label.set_markup(str);
        return;
    }

    public override bool enter_notify_event (Gdk.EventCrossing event) {
        label.override_color(Gtk.StateFlags.NORMAL, hover);
        return false;
    }

    public override bool leave_notify_event (Gdk.EventCrossing event) {
        label.override_color(Gtk.StateFlags.NORMAL, normal);
        return false;
    }

    public override void style_updated () {
        normal = hover = get_style_context().get_color(Gtk.StateFlags.NORMAL);
        normal.alpha = 0.65;
        label.override_color(Gtk.StateFlags.NORMAL, normal);
        return;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        this.clicked();
        return false;
    }

}
