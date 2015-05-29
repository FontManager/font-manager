/* LabeledSpinButton.vala
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

public class LabeledSpinButton : Gtk.Grid {

    public double @value { get; set; default = 0.0; }

    private Gtk.Label label;
    private Gtk.SpinButton spin;

    public LabeledSpinButton (string label = "", double min, double max, double step) {
        margin = 12;
        this.label = new Gtk.Label(label);
        this.label.hexpand = true;
        this.label.halign = Gtk.Align.START;
        spin = new Gtk.SpinButton.with_range(min, max, step);
        attach(this.label, 0, 0, 2, 1);
        attach(spin, 2, 0, 1, 1);
        bind_property("value", spin, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
    }

    public override void show () {
        label.show();
        spin.show();
        base.show();
        return;
    }

}
