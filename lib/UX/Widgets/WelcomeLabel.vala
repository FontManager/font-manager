/* WelcomeLabel.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
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

public class WelcomeLabel : Gtk.Label {

    construct {
        wrap = true;
        wrap_mode = Pango.WrapMode.WORD_CHAR;
        hexpand = true;
        valign = Gtk.Align.START;
        halign = Gtk.Align.FILL;
        justify = Gtk.Justification.CENTER;
        margin = 64;
        use_markup = true;
        sensitive = false;
    }

    public WelcomeLabel (string? str) {
        Object(label: str);
    }

}
