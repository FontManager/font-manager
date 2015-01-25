# -*- coding: utf-8 -*-
#
# Copyright © 2009 - 2014 Jerry Casiano
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author:
#  Jerry Casiano <JerryCasiano@gmail.com>

import dbus
import thunarx
from dbus.mainloop.glib import DBusGMainLoop

SupportedMimeTypes = [
    "application/x-font-ttf",
    "application/x-font-ttc",
    "application/x-font-otf",
    "application/x-font-type1"
]

def is_font_file (f):
    return f.get_mime_type() in SupportedMimeTypes


class FontViewer (thunarx.MenuProvider):

    Active = False

    def __init__ (self):
        DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SessionBus()
        self.bus.watch_name_owner('org.gnome.FontManager', FontViewer.set_state)

    def get_file_actions (self, window, files):
        if FontViewer.Active and len(files) == 1:
            selected_file = files[0]
            if is_font_file(selected_file):
                try:
                    proxy = self.bus.get_object('org.gnome.FontManager', '/org/gnome/FontManager/FontViewer')
                    ready = proxy.get_dbus_method('Ready', 'org.gnome.FontManager.FontViewer')
                    if ready():
                        show_uri = proxy.get_dbus_method('ShowUri', 'org.gnome.FontManager.FontViewer')
                        show_uri('{0}'.format(selected_file.get_uri()))
                except:
                    pass
        return

    def get_folder_actions (self, window, folder):
        return

    @staticmethod
    def set_state (s):
        if s.strip() != '':
            FontViewer.Active = True
        else:
            FontViewer.Active = False
        return

