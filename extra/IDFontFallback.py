#!/usr/bin/env python3
#
# Copyright (C) 2019-2022 Jerry Casiano
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.
#
# If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

'''
IDFontFallback.py

Identifies the actual fonts used in rendering the characters of a given string.
Any substitutions will be listed first. Useful to quickly determine whether or
not a specific font contains all necessary characters.
'''

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Pango', '1.0')
from gi.repository import Gtk, Pango

class MainWindow (Gtk.ApplicationWindow):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.text = None
        self.set_icon_name('preferences-desktop-font')
        self.selected_font = Pango.FontDescription.from_string('Sans 36')
        entry = Gtk.Entry()
        entry.set_placeholder_text('Enter text to identify the font used to render each character')
        self.model = Gtk.ListStore(str, str)
        self.treeview = Gtk.TreeView()
        r0 = Gtk.CellRendererText()
        c0 = Gtk.TreeViewColumn('Glyph', r0, markup = 0)
        c0.set_expand(True)
        r1 = Gtk.CellRendererText()
        c1 = Gtk.TreeViewColumn('Font Description', r1, text = 1)
        c1.set_expand(True)
        self.treeview.append_column(c0)
        self.treeview.append_column(c1)
        self.treeview.set_model(self.model)
        self.treeview.set_grid_lines(Gtk.TreeViewGridLines.HORIZONTAL)
        self.treeview.get_selection().set_mode(Gtk.SelectionMode.NONE)
        self.on_entry_changed(entry)
        entry.connect('changed', self.on_entry_changed)
        entry.connect('icon-press', self.on_entry_icon_press)
        separator = Gtk.Separator()
        scroll = Gtk.ScrolledWindow()
        contents = Gtk.Box(orientation = Gtk.Orientation.VERTICAL)
        contents.get_style_context().add_class('view')
        for widget in entry, separator, scroll:
            widget.set_margin_start(12)
            widget.set_margin_end(12)
        contents.show()
        entry.show()
        self.treeview.show()
        separator.show()
        scroll.show();
        scroll.add(self.treeview)
        contents.pack_start(entry, False, False, 12)
        contents.pack_start(separator, False, False, 1)
        contents.pack_end(scroll, True, True, 12)
        self.add(contents)
        self.set_default_size(600, 300)
        title = Gtk.HeaderBar()
        title.set_show_close_button(True)
        font_chooser = Gtk.FontButton()
        font_chooser.connect('font-set', self.update_font_description)
        font_chooser.set_font_desc(self.selected_font)
        title.set_custom_title(font_chooser)
        icon = Gtk.Image.new_from_icon_name('preferences-desktop-font', Gtk.IconSize.LARGE_TOOLBAR)
        icon.show()
        title.pack_start(icon)
        font_chooser.show()
        title.show()
        self.set_titlebar(title)
        font_chooser.grab_focus()

    def update_font_description (self, widget):
        self.selected_font = Pango.FontDescription.from_string(widget.get_font())
        self.update_model()
        return

    def get_actual_font_description (self, char):
        layout = Pango.Layout(self.get_pango_context())
        layout.set_font_description(self.selected_font)
        layout.set_text(char, -1)
        line = layout.get_line_readonly(0)
        glyph_item = line.runs[0]
        pango_font = glyph_item.item.analysis.font
        return pango_font.describe().to_string()

    def update_model (self):
        self.model.clear()
        for char in sorted(set(self.text)):
            if char == ' ':
                continue
            font = self.selected_font.to_string()
            _markup = '<span font="{0}">{1}</span>'.format(font, char)
            _description = self.get_actual_font_description(char)
            if _description != font:
                self.model.prepend([_markup, _description])
            else:
                self.model.append([_markup, _description])
        self.treeview.queue_draw()
        return

    def on_entry_icon_press (self, entry, icon_pos, event):
        if (icon_pos == Gtk.EntryIconPosition.SECONDARY):
            entry.set_text('')
        return

    def on_entry_changed (self, entry):
        self.text = entry.get_text()
        self.update_model()
        empty = (self.text == '')
        entry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, (not empty))
        if (empty):
            entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, 'document-edit-symbolic')
        else:
            entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, 'edit-clear-symbolic')
        return

class Application(Gtk.Application):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.window = None

    def do_activate(self):
        if not self.window:
            self.window = MainWindow(application=self)
        self.window.present()
        return

if __name__ == "__main__": Application().run()
