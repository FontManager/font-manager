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

from core import database
from constants import PACKAGE_DATA_DIR
from utils.common import open_folder


class FontInformation(object):
    """
    Dialog which displays font metadata.
    """
    _widgets = (
        'CopyrightView', 'CopyrightBox', 'DescriptionView', 'DescriptionBox',
        'TypeLogo', 'FamilyLabel', 'FamilyEntry', 'StyleEntry', 'TypeEntry',
        'SizeEntry', 'FileEntry', 'LicenseBox', 'LicenseView', 'LicenseLink',
        'Notebook', 'VersionEntry', 'InfoBox', 'NoInfo'
        )
    _types = {
                'TrueType'      :   'truetype.png',
                'Type 1'        :   'type1.png',
                'BDF'           :   'bdf.png',
                'PCF'           :   'pcf.png',
                'Type 42'       :   'type42.png',
                'CID Type 1'    :   'type1.png',
                'CFF'           :   'opentype.png',
                'PFR'           :   'pfr.png',
                'Windows FNT'   :   'fnt.png'
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
        self.filedir = None
        self.typ = None
        self.db_row = None
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
        self.filedir = self.typ = self.db_row = None
        entries = ('FamilyLabel', 'FamilyEntry', 'StyleEntry', 'TypeEntry',
                    'SizeEntry', 'FileEntry')
        for widget in entries:
            self.widgets[widget].set_text('')
        for widget in 'CopyrightView', 'DescriptionView', 'LicenseView':
            self.widgets[widget].get_buffer().set_text('')
        self.widgets['TypeLogo'].set_from_pixbuf(self.logos['blank'])
        return

    def _get_logo(self, typ, filepath):
        """
        Return a pixbuf based on font type.
        """
        if typ == 'TrueType' and filepath.endswith('.otf'):
            typ = 'CFF'
        if typ in self._types.iterkeys():
            return self.logos[typ]
        else:
            return self.logos['blank']

    def _open_folder(self, unused_widget, unused_icon_pos, unused_event):
        """
        Open containing folder.
        """
        return open_folder(self.filedir, self.objects)

    def show(self, filepath, descr):
        """
        Show information for the provided family object and style.
        """
        if filepath is None and descr is None:
            self.widgets['InfoBox'].hide()
            self.widgets['NoInfo'].show()
            self.widgets['Notebook'].set_show_tabs(False)
            self.window.show()
            self.window.resize(1, 1)
            self.window.queue_draw()
            return
        else:
            self.widgets['NoInfo'].hide()
            self.widgets['InfoBox'].show()
        table = database.Table('Fonts')
        self.db_row = table.get('*', 'filepath="{0}"'.format(filepath))[0]
        table.close()
        self.filedir = dirname(filepath)
        self.typ = self.db_row['filetype']
        famname = glib.markup_escape_text(self.db_row['family'])
        markup = \
        '<span font_desc="{0}" size="xx-large">{1}</span>'.format(descr, famname)
        self.widgets['FamilyLabel'].set_markup(markup)
        self.widgets['FamilyEntry'].set_text(self.db_row['family'])
        self.widgets['StyleEntry'].set_text(self.db_row['style'])
        self.widgets['TypeEntry'].set_text(self.typ)
        self.widgets['SizeEntry'].set_text(self.db_row['filesize'])
        self.widgets['FileEntry'].set_text(basename(filepath))
        version = self.db_row['version']
        if len(version) > 50:
            version = 'None'
        if version.find('ersion') != -1:
            version = version.replace('Version', '').replace('version', '')
        if version.find('Revision:') != -1:
            version = version.strip().strip('$').replace('Revision:', '')
        version = version.strip()
        self.widgets['VersionEntry'].set_text(version)
        logo = self._get_logo(self.typ, filepath)
        self.widgets['TypeLogo'].set_from_pixbuf(logo)
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
        if not webbrowser.open(_pages[self.typ]):
            logging.warn("Could not find any suitable web browser")
        return

    def _set_copyright(self):
        """
        Display copyright if available.
        """
        if self.db_row['copyright'] != 'None':
            t_buffer = self.widgets['CopyrightView'].get_buffer()
            t_buffer.set_text(self.db_row['copyright'])
            self.widgets['CopyrightBox'].show()
        else:
            self.widgets['CopyrightBox'].hide()
        return

    def _set_description(self):
        """
        Display description if available.
        """
        if self.db_row['description'] != 'None':
            t_buffer = self.widgets['DescriptionView'].get_buffer()
            t_buffer.set_text(self.db_row['description'])
            self.widgets['DescriptionBox'].show()
        else:
            self.widgets['DescriptionBox'].hide()
        return

    def _set_license(self):
        """
        Display license if available.
        """
        if self.db_row['license'] != 'None':
            t_buffer = self.widgets['LicenseView'].get_buffer()
            t_buffer.set_text(self.db_row['license'])
            self.widgets['LicenseBox'].show()
            self.widgets['Notebook'].set_show_tabs(True)
            if self.db_row['license_url'] != 'None':
                self.widgets['LicenseLink'].set_uri(self.db_row['license_url'])
                self.widgets['LicenseLink'].set_label(self.db_row['license_url'])
                self.widgets['LicenseLink'].show()
            else:
                self.widgets['LicenseLink'].hide()
        else:
            self.widgets['LicenseBox'].hide()
            self.widgets['Notebook'].set_show_tabs(False)
        return
