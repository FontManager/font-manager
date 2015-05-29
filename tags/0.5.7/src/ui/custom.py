"""
Custom user interface elements.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009, 2010 Jerry Casiano
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to:
#
#    Free Software Foundation, Inc.
#    51 Franklin Street, Fifth Floor
#    Boston, MA 02110-1301, USA.

# Disable warnings related to missing docstrings, for now...
# pylint: disable-msg=C0111

import gtk
import gobject
import colorsys
import UserDict


class ColorParse(object):
    """
    Taken from Project Hamster by Toms Baugis
    """
    @staticmethod
    def _parse(color):
        """
        Parse color into rgb values.
        """
        assert color is not None
        if isinstance(color, (str, unicode)):
            color = gtk.gdk.Color(color)
        if isinstance(color, gtk.gdk.Color):
            color = [color.red / 65535.0, color.green / 65535.0,
                                            color.blue / 65535.0]
        else:
            # otherwise we assume we have color components in 0..255 range
            if color[0] > 1 or color[1] > 1 or color[2] > 1:
                color = [c / 255.0 for c in color]
        return color

    def rgb(self, color):
        return [c * 255 for c in self._parse(color)]

    def is_light(self, color):
        """
        Determine if given color is light or dark.
        """
        return colorsys.rgb_to_hls(*self.rgb(color))[1] > 150

    def darker(self, color, step):
        """
        Return color darkened by step (where step is in range 0..255)
        """
        hls = colorsys.rgb_to_hls(*self.rgb(color))
        return colorsys.hls_to_rgb(hls[0], hls[1] - step, hls[2])


class CairoColors(UserDict.UserDict):
    """
    This class takes all the colors associated with a widget and tranforms them
    into rgb values. The result is a dictionary which mimics gtk.Style, but only
    contains color values in a format suitable for use with Cairo.
    """
    _styles = ( "fg", "bg", "light", "dark", "mid", "text", "base", "text_aa")
    _states = ( gtk.STATE_NORMAL, gtk.STATE_ACTIVE, gtk.STATE_PRELIGHT,
                gtk.STATE_SELECTED, gtk.STATE_INSENSITIVE )
    def __init__(self, widget):
        UserDict.UserDict.__init__(self)
        self.style = widget.get_style().copy()
        self.data = {}
        self._get_colors()

    @staticmethod
    def _color_to_cairo_rgb(color):
        return color.red/65535.0, color.green/65535.0, color.blue/65535.0

    def _get_colors(self):
        for style in self._styles:
            colors = {}
            original_colors = getattr(self.style, style, None)
            if original_colors:
                for state in self._states:
                    color = original_colors[state]
                    colors[state] = self._color_to_cairo_rgb(color)
            self.data[style] = colors
        return


# Disable warnings related to invalid names
# pylint: disable-msg=C0103
class CellRendererTotal(gtk.CellRendererText):
    """
    A custom version of gtk.CellRendererText that displays a pill-shaped
    count at the right end of the cell.

    If using markup, the label column should be the same as the markup column.
    """
    __gproperties__ = {
                        'label' :   (gobject.TYPE_STRING,
                                    'Label',
                                    'Label to be displayed',
                                    None,
                                    gobject.PARAM_READWRITE),
                        'count' :   (gobject.TYPE_STRING,
                                    'Count',
                                    'Count to be displayed',
                                    None,
                                    gobject.PARAM_READWRITE),
                    'show-count':   (gobject.TYPE_BOOLEAN,
                                    'Display count',
                                    'Whether to display count or not',
                                    True,
                                    gobject.PARAM_READWRITE),
                        'radius':   (gobject.TYPE_INT,
                                    '"Pill" radius',
                                    '"Pill" radius',
                                    0,
                                    24,
                                    12,
                                    gobject.PARAM_READWRITE)
                                    }
    def __init__(self):
        gtk.CellRendererText.__init__(self)
        self.colors = None
        setattr(self, 'label', None)
        setattr(self, 'count', None)
        setattr(self, 'show-count', True)
        setattr(self, 'radius', 12)

    def do_set_property(self, pspec, value):
        setattr(self, pspec.name, value)

    def do_get_property(self, pspec):
        return getattr(self, pspec.name)

    def do_render(self, *args):
        """
        window, widget, background_area, cell_area, expose_area, flags
        """
        widget_state = self._get_state(args)
        style = args[1].get_style().copy()
        self.colors = ColorParse()
        theme = CairoColors(args[1])
        if widget_state == gtk.STATE_SELECTED:
            text = theme['text'][gtk.STATE_SELECTED]
            pill = theme['dark'][gtk.STATE_SELECTED]
            if not self.colors.is_light(text):
                # If selected text is dark it's likely the pill itself
                # is also dark, so lighten it.
                pill = self.colors.darker(pill, -50)
        else:
            text = theme['text'][gtk.STATE_NORMAL]
            pill = theme['bg'][gtk.STATE_PRELIGHT]
        context = args[0].cairo_create()
        self._draw_text(context, style, text, args)
        if self.get_property('count') and self.get_property('show-count'):
            self._draw_count(context, style, widget_state, text, pill, args)
        return

    def _draw_count(self, context, style, state, text, pill, args):
        cell_x, cell_y, cell_w, cell_h = args[3]
        layout = context.create_layout()
        layout.set_font_description(style.font_desc)
        count = self.get_property('count')
        markup = '<span size="small" weight="heavy">{0}</span>'.format(count)
        layout.set_markup(markup)
        layout_w, layout_h = layout.get_pixel_size()
        center_h = cell_y + ((cell_h - layout_h) / 2)
        if state == gtk.STATE_SELECTED:
            context.set_source_rgba(pill[0], pill[1], pill[2], 0.25)
        elif not self.colors.is_light(pill):
            context.set_source_rgba(pill[0], pill[1], pill[2], 0.15)
        else:
            context.set_source_rgba(pill[0], pill[1], pill[2], 0.50)
        self._draw_pill(context,
                        cell_x + (cell_w - (layout_w + 20)),
                        cell_y, layout_w + 20, cell_h)
        context.set_source_rgba(text[0], text[1], text[2], 1)
        center_w = cell_x + ((cell_w - layout_w) - 10)
        context.move_to(center_w, center_h)
        context.show_layout(layout)
        return

    def _draw_text(self, context, style, text, args):
        markup = self.get_property('label')
        if not markup:
            markup = self.get_property('text')
        cell_x, cell_y, cell_w, cell_h = args[3]
        layout = context.create_layout()
        layout.set_font_description(style.font_desc)
        layout.set_markup(markup)
        layout_w, layout_h = layout.get_pixel_size()
        context.set_source_rgba(text[0], text[1], text[2], 1)
        center_h = cell_y + ((cell_h - layout_h) / 2)
        context.move_to(cell_x + self.get_property('xpad'), center_h)
        context.show_layout(layout)
        return

    def _draw_pill(self, context, x, y, w, h):
        pad = self.get_property('ypad')
        radius = self.get_property('radius')
        context.move_to(x + radius, y + pad)
        context.line_to(x + (w - radius), y + pad)
        context.curve_to(x + w, y, x + w , y + h, x + (w - radius), y + h - pad)
        context.line_to(x + radius, y + h - pad)
        context.curve_to(x, y + h, x , y, x + radius, y + pad)
        context.fill()
        return

    @staticmethod
    def _get_editable_state(args):
        x, y = args[1].widget_to_tree_coords(args[3].x, args[3].y)
        path = args[1].get_path_at_pos(x, y)
        selected_paths = args[1].get_selection().get_selected_rows()[1]
        if path and selected_paths:
            if path[0] == selected_paths[0]:
                return gtk.STATE_SELECTED
            else:
                return gtk.STATE_NORMAL
        return None

    def _get_state(self, args):
        """
        window, widget, background_area, cell_area, expose_area, flags
        """
        # FIXME
        # This is fugly, I'm probably just missing something obvious...
        # But selected state for editable cells is very flaky...
        if self.get_property('editable'):
            state = self._get_editable_state(args)
            if state is not None:
                return state
        if args[5] == gtk.CELL_RENDERER_SELECTED:
            return gtk.STATE_SELECTED
        elif args[5] == gtk.CELL_RENDERER_SELECTED | gtk.CELL_RENDERER_PRELIT:
            return gtk.STATE_SELECTED
        else:
            return gtk.STATE_NORMAL

gobject.type_register(CellRendererTotal)
# Enable warnings related to invalid names
# pylint: enable-msg=C0103
