"""
This module provides a dialog which displays font information.
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

import os
import gtk
import glib
import logging
import webbrowser

from os.path import basename, dirname, join

from constants import PACKAGE_DATA_DIR
from utils.common import natural_size, open_folder


class FontInformation(object):
    """
    Dialog which displays font metadata.
    """
    _widgets = (
        'CopyrightView', 'CopyrightBox', 'DescriptionView', 'DescriptionBox',
        'TypeLogo', 'FamilyLabel', 'FamilyEntry', 'StyleEntry', 'TypeEntry',
        'SizeEntry', 'FileEntry', 'LicenseBox', 'LicenseView', 'LicenseLink',
        'Notebook', 'NoLicense', 'CloseFontInformation'
        )
    _types = {
                'TrueType'      :   'truetype.png',
                'Type 1'        :   'type1.png',
                'BDF'           :   'bitmap.png',
                'PCF'           :   'bitmap.png',
                'Type 42'       :   'type42.png',
                'CID Type 1'    :   'type1.png',
                'CFF'           :   'opentype.png',
                'PFR'           :   'bitmap.png',
                'Windows FNT'   :   'bitmap.png'
                }
    def __init__(self, objects):
        self.objects = objects
        self.builder = objects.builder
        self.builder.add_from_file(os.path.join(PACKAGE_DATA_DIR,
                                                    'font-information.ui'))
        self.window = self.builder.get_object('FontInformationDialog')
        self.window.set_transient_for(objects['MainWindow'])
        self.window.connect('delete-event', self._on_close)
        self.widgets = {}
        self.family = None
        self.style = None
        self.filename = None
        self.filedir = None
        self.typ = None
        for widget in self._widgets:
            self.widgets[widget] = self.builder.get_object(widget)
        # Load font type logos
        self.logos = {}
        pixbuf = gtk.gdk.pixbuf_new_from_file
        for typ in self._types.iterkeys():
            self.logos[typ] = pixbuf(join(PACKAGE_DATA_DIR, self._types[typ]))
        self.logos['blank'] = pixbuf(join(PACKAGE_DATA_DIR, 'blank.png'))
        # Connect handlers
        self.widgets['FileEntry'].connect('icon-press', self._open_folder)
        self.widgets['TypeEntry'].connect('icon-press',
                                            self._show_type_description)
        self.widgets['CloseFontInformation'].connect('clicked', self._on_close)

    def _on_close(self, unused_widget, possible_event = None):
        """
        Hide dialog and clear previous results.
        """
        self.window.hide()
        while gtk.events_pending:
            gtk.main_iteration()
        self._clear_previous_results()

    def _clear_previous_results(self):
        """
        Clear previous results.
        """
        self.family = None
        self.style = None
        self.filename = None
        self.filedir = None
        self.typ = None
        entries = ('FamilyLabel', 'FamilyEntry', 'StyleEntry', 'TypeEntry',
                    'SizeEntry', 'FileEntry')
        for widget in entries:
            self.widgets[widget].set_text('')
        for widget in 'CopyrightView', 'DescriptionView', 'LicenseView':
            view = self.widgets[widget]
            t_buffer = view.get_buffer()
            t_buffer.set_text('')
        self.widgets['TypeLogo'].set_from_pixbuf(self._get_blank_logo())
        return

    @staticmethod
    def _get_blank_logo():
        """
        Return a blank pixbuf.
        """
        return gtk.gdk.pixbuf_new_from_file(join(PACKAGE_DATA_DIR, 'blank.png'))

    def _get_filesize(self):
        """
        Return filesize in human-readable format.
        """
        return natural_size(self.family.styles[self.style]['filesize'])

    def _get_filename(self):
        """
        Return the base filename for selected font.
        """
        current_file = self.family.styles[self.style]['filepath']
        self.filename = basename(current_file)
        self.filedir = dirname(current_file)
        return self.filename

    def _get_logo(self, typ):
        """
        Return a pixbuf based on font type.
        """
        if typ == 'TrueType' and self.filename.endswith('.otf'):
            typ = 'CFF'
        if typ in self._types.iterkeys():
            return self.logos[typ]
        else:
            return self.logos['blank']

    def _open_folder(self, unused_widget, unused_icon_pos, unused_event):
        """
        Open containing folder.
        """
        open_folder(self.filedir, self.objects)
        return

    def show(self, family, descr, style):
        """
        Show information for the provided family object and style.
        """
        self.family = family
        self.style = style
        self.typ = family.styles[style]['filetype']
        famname = glib.markup_escape_text(family.get_name())
        markup = \
        '<span font_desc="%s" size="xx-large">%s</span>' % (descr, famname)
        self.widgets['FamilyLabel'].set_markup(markup)
        self.widgets['FamilyEntry'].set_text(family.get_name())
        self.widgets['StyleEntry'].set_text(style)
        self.widgets['TypeEntry'].set_text(self.typ)
        self.widgets['SizeEntry'].set_text(self._get_filesize())
        self.widgets['FileEntry'].set_text(self._get_filename())
        self.widgets['TypeLogo'].set_from_pixbuf(self._get_logo(self.typ))
        self._set_copyright()
        self._set_description()
        self._set_license()
        self.widgets['Notebook'].set_current_page(0)
        self.window.show()
        self.window.resize(1, 1)
        self.window.queue_draw()

    def _show_type_description(self, unused_widget,
                                unused_icon_pos, unused_event):
        """
        Open a link containing information about font format.
        """
        _pages = {
        'TrueType'   :   'http://en.wikipedia.org/wiki/TrueType',
        'Type 1'     :   'http://en.wikipedia.org/wiki/Type_1_Font#Type_1',
        'BDF'        :
        'http://en.wikipedia.org/wiki/Glyph_Bitmap_Distribution_Format',
        'PCF'        :
        'http://en.wikipedia.org/wiki/Portable_Compiled_Format',
        'Type 42'    :   'http://en.wikipedia.org/wiki/Type_1_Font#Type_42',
        'CID Type 1' :   'http://en.wikipedia.org/wiki/Compact_font_format#CID',
        'CFF'        :
        'http://en.wikipedia.org/wiki/Compact_Font_Format#Compact_Font_Format',
        'PFR'        :   'http://en.wikipedia.org/wiki/TrueDoc',
        'Windows FNT':   'http://support.microsoft.com/kb/65123'
                }
        if webbrowser.open(_pages[self.typ]):
            return
        else:
            logging.warn("Could not find any suitable web browser")
        return

    def _set_copyright(self):
        """
        Display copyright if available.
        """
        box = self.widgets['CopyrightBox']
        view = self.widgets['CopyrightView']
        t_buffer = view.get_buffer()
        copyrite = self.family.styles[self.style]['copyright']
        if copyrite != 'None':
            t_buffer.set_text(copyrite)
            box.show()
        else:
            box.hide()
        return

    def _set_description(self):
        """
        Display description if available.
        """
        box = self.widgets['DescriptionBox']
        view = self.widgets['DescriptionView']
        t_buffer = view.get_buffer()
        description = self.family.styles[self.style]['description']
        if description != 'None':
            t_buffer.set_text(description)
            box.show()
        else:
            box.hide()
        return

    def _set_license(self):
        """
        Display license if available.
        """
        nolicense = self.widgets['NoLicense']
        box = self.widgets['LicenseBox']
        view = self.widgets['LicenseView']
        t_buffer = view.get_buffer()
        licens = self.family.styles[self.style]['license']
        url = self.family.styles[self.style]['license_url']
        if licens != 'None':
            nolicense.hide()
            t_buffer.set_text(licens)
            box.show()
        else:
            box.hide()
            nolicense.show()
        if url != 'None':
            self.widgets['LicenseLink'].set_uri(url)
            self.widgets['LicenseLink'].set_label(url)
        return
