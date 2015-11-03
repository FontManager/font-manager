/* OptionScale.vala
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

public class OptionScale : Gtk.Grid {

    public Gtk.Label label { get; private set; }
    public Gtk.Scale scale { get; private set; }
    public string [] options { get; private set; }

    public OptionScale (string? heading = null, string [] options) {
        hexpand = true;
        margin = 12;
        margin_start = 24;
        margin_end = 24;
        this.options = options;
        scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, options.length, 1);
        scale.hexpand = true;
        scale.draw_value = false;
        scale.round_digits = 1;
        scale.adjustment.lower = 0;
        scale.adjustment.page_increment = 1;
        scale.adjustment.step_increment = 1;
        scale.adjustment.upper = options.length - 1;
        scale.show_fill_level = false;
        for (int i = 0; i < options.length; i++)
            scale.add_mark(i, Gtk.PositionType.BOTTOM, options[i]);
        scale.value_changed.connect(() => {
            scale.set_value(Math.round(scale.adjustment.get_value()));
        });
        label = new Gtk.Label(null);
        label.hexpand = true;
        label.margin = 12;
        if (heading != null)
            label.set_text(heading);
        attach(label, 0, 0, options.length, 1);
        attach(scale, 0, 1, options.length, 1);
    }

    public override void show () {
        label.show();
        scale.show();
        base.show();
        return;
    }

}
