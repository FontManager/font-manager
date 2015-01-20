/* CellRendererPill.vala
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

/* XXX : This shit here needs work... */


public class CellRendererCount : CellRendererPill {

    public int count { get; set; default = -1; }
    public string? type_name { get; set; default = _("Variation "); }
    public string? type_name_plural { get; set; default = _("Variations"); }

    protected override string _get_markup () {
        string markup = "<span size=\"small\" weight=\"heavy\">%i  </span>";
        string markup_w_type = "<span size=\"small\" weight=\"heavy\">%i  %s</span>";
        if (count == -1)
            return "";
        else if (type_name != null && type_name_plural != null)
            return markup_w_type.printf((int) count, ngettext(type_name, type_name_plural, (ulong) count));
        else
            return markup.printf((int) count);
    }

}

public class CellRendererTitle : CellRendererPill {

    public string title { get; set; }

    protected override string _get_markup () {
        if (title != null)
            return "<b>%s</b>".printf(Markup.escape_text(title));
        else
            return "";
    }

}

public abstract class CellRendererPill : Gtk.CellRendererText {

    public int radius { get; set; default = 9; }
    public bool fallthrough { get; set; default = false; }
    public Gtk.JunctionSides junction_side { get; set; default = Gtk.JunctionSides.NONE; }

    protected abstract string _get_markup ();

    public override void render (Cairo.Context cr,
                                   Gtk.Widget widget,
                                   Gdk.Rectangle background_area,
                                   Gdk.Rectangle cell_area,
                                   Gtk.CellRendererState flags) {
        if (fallthrough) {
            base.render(cr, widget, background_area, cell_area, flags);
            return;
        }

        /* Without some default padding our pill shape touches the text */
        if (xpad < 12) xpad = 12;
        if (ypad < 2) ypad = 2;

        Gtk.StateFlags state = get_widget_state(widget, flags);

        Gdk.RGBA text_color;
        Gdk.RGBA pill_color;
        Gdk.RGBA shadow_color;
        Gtk.StyleContext context = widget.get_style_context();
        shadow_color = context.get_color(state);
        if (state == Gtk.StateFlags.NORMAL) {
            pill_color = context.get_color(state);
            text_color = context.get_background_color(state);
        } else {
            pill_color = context.get_background_color(state);
            text_color = context.get_color(state);
        }

        /* Need layout size */
        int layout_w, layout_h;

        Pango.Layout layout = widget.create_pango_layout(null);
        layout.set_markup(_get_markup(), -1);
        Pango.FontDescription font_desc;
        get("font-desc", out font_desc, null);
        if (font_desc != null)
            layout.set_font_description(font_desc);
        else
            layout.set_font_description(context.get_font(state));
        layout.get_pixel_size(out layout_w, out layout_h);

        if (state == Gtk.StateFlags.NORMAL)
            cr_set_source_rgba(cr, pill_color, 0.25);
        else
            cr_set_source_rgba(cr, darker(pill_color, 0.33), 0.75);

        int h = cell_area.height - ((int) ypad * 2);
        int w = layout_w + ((int) xpad * 2);
        int x;
        var cutoff = radius + ((int) xpad / 3);
        switch (junction_side) {
            case Gtk.JunctionSides.RIGHT:
                if (is_left_to_right(widget))
                    x = (cell_area.x + cell_area.width) - (w - cutoff);
                else
                    x = cell_area.x - cutoff;
                break;
            case Gtk.JunctionSides.LEFT:
                if (is_left_to_right(widget))
                    x = cell_area.x - cutoff;
                else
                    x = (cell_area.x + cell_area.width) - (w - cutoff);
                break;
            default:
                x = cell_area.x + (int) ((cell_area.width - w) * xalign);
                while (x + w > (cell_area.x + cell_area.width))
                    x--;
                while (x < cell_area.x)
                    x++;
                break;
        }
        int y = cell_area.y + (int) ypad;
        int text_x = x + (int) (xpad * 1.15);
        int text_y = y + ((cell_area.height - layout_h) / 2) - (int) ypad;

        _cr_draw_pill_shape(cr, x, y, h, w);
        cr_set_source_rgba(cr, darker(shadow_color, 0.50), 0.333);
        cr.move_to(text_x + 0.5, text_y + 0.5);
        Pango.cairo_show_layout(cr, layout);
        cr_set_source_rgba(cr, text_color);
        cr.move_to(text_x, text_y);
        Pango.cairo_show_layout(cr, layout);
        return;
    }

    public override void get_preferred_width (Gtk.Widget widget, out int minimum_size, out int natural_size) {
        int w, h;
        _get_preferred_size(widget, out w, out h);
        minimum_size = natural_size = w;
        return;
    }

    public override void get_preferred_height_for_width (Gtk.Widget widget, int width, out int minimum_height, out int natural_height) {
        int w, h;
        _get_preferred_size(widget, out w, out h);
        minimum_height = natural_height = h;
        return;
    }

    public void _get_preferred_size (Gtk.Widget widget, out int w, out int h) {
        int layout_w, layout_h;
        if (xpad < 12) xpad = 12;
        if (ypad < 2) ypad = 2;
        Gtk.StyleContext context = widget.get_style_context();
        Pango.Layout layout = widget.create_pango_layout(null);
        layout.set_markup(_get_markup(), -1);
        Pango.FontDescription font_desc;
        get("font-desc", out font_desc, null);
        if (font_desc != null)
            layout.set_font_description(font_desc);
        else
            layout.set_font_description(context.get_font(Gtk.StateFlags.NORMAL));
        layout.get_pixel_size(out layout_w, out layout_h);
        w = layout_w + ((int) xpad * 2);
        h = layout_h + ((int) ypad * 2);
        return;
    }

    protected void _cr_draw_pill_shape (Cairo.Context cr, int x, int y, int h, int w) {
        cr.move_to(x + radius, y);
        cr.line_to(x + (w - (radius)), y);
        cr.curve_to(x + w, y, x + w, y + h, x + w - (radius), y + h);
        cr.line_to(x + radius, y + h);
        cr.curve_to(x, y + h, x, y, x + radius, y);
        cr.fill();
        return;
    }

    protected virtual Gtk.StateFlags get_widget_state (Gtk.Widget widget, Gtk.CellRendererState flags) {
        /* Ignore most states */
        if ((flags & Gtk.CellRendererState.SELECTED) == Gtk.CellRendererState.SELECTED && widget.has_focus)
            return Gtk.StateFlags.SELECTED;
        else
            return Gtk.StateFlags.NORMAL;
    }

}
