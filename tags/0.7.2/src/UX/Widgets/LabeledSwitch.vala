/* LabeledSwitch.vala
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

public class LabeledSwitch : Gtk.Grid {

    public Gtk.Image image { get; private set; }
    public Gtk.Label label { get; private set; }
    public Gtk.Switch toggle { get; private set; }

    construct {
        margin = 12;
        label = new Gtk.Label(null);
        label.hexpand = true;
        label.halign = Gtk.Align.START;
        toggle = new Gtk.Switch();
        toggle.expand = false;
        image = new Gtk.Image();
        image.expand = false;
        image.margin_end = 12;
        attach(image, 0, 0, 1, 1);
        attach(label, 1, 0, 1, 1);
        attach(toggle, 2, 0, 1, 1);
    }

    public LabeledSwitch (string label = "") {
        this.label.set_text(label);
    }

    public override void show () {
        image.show();
        label.show();
        toggle.show();
        base.show();
        return;
    }
}
