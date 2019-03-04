/* CellRendererPill.vala
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

public class CellRendererCount : CellRendererPill {

    private int _count = -1;

    public int count {
        get {
            return _count;
        }
        set {
            _count = value;
            if (_count < 0) {
                text = "";
                render_background = false;
            } else {
                text = "%i".printf((int) count);
                render_background = true;
            }
        }
    }

}

public class CellRendererStyleCount : CellRendererPill {

    private int _count = -1;

    public int count {
        get {
            return _count;
        }
        set {
            _count = value;
            if (_count < 1) {
                text = "";
                render_background = false;
            } else {
                text = "%i %s".printf((int) count,
                ngettext(_("Variation "), _("Variations"), (ulong) count));
                render_background = true;
            }
        }
    }

}

public class CellRendererTitle : CellRendererPill {

    private string? _title = null;

    public string? title {
        get {
            return _title;
        }
        set {
            _title = value;
            if (_title == null)
                markup = "";
            else
                markup = "<b>%s</b>".printf(Markup.escape_text(title));
        }
    }

    construct {
        set_alignment(0.0f, 0.5f);
        style_class = "CellRendererTitle";
    }

}

public class CellRendererPill : Gtk.CellRendererText {

    public string style_class { get; set; default = "CellRendererPill"; }
    public bool render_background { get; set; default = true; }

    construct {
        set_alignment(1.0f, 0.5f);
        set_padding(12, 1);
    }

    public override void render (Cairo.Context cr,
                                 Gtk.Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 Gtk.CellRendererState flags)
    {
        if (render_background) {
            Gdk.Rectangle a = get_aligned_area(widget, flags, cell_area);
            Gtk.StyleContext ctx = widget.get_style_context();
            Gtk.StateFlags state = ctx.get_state();
            Gtk.Border m = ctx.get_margin(state);
            a.x += ((state & Gtk.StateFlags.DIR_LTR) != 0) ? m.left : m.right;
            a.y += m.top;
            a.width -= m.left + m.right;
            a.height -= m.top + m.bottom;
            ctx.add_class(style_class);
            ctx.render_background(cr, a.x, a.y, a.width, a.height);
            ctx.render_frame(cr, a.x, a.y, a.width, a.height);
        }
        base.render(cr, widget, background_area, cell_area, flags);
        return;
    }

}
