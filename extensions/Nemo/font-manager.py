# -*- coding: utf-8 -*-
#
# Copyright (C) 2009 - 2015 Jerry Casiano
#
# This file is part of Font Manager.
#
# Font Manager is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Font Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
#
# Author:
#        Jerry Casiano <JerryCasiano@gmail.com>

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GObject, Nemo

SupportedMimeTypes = [
    "application/x-font-ttf",
    "application/x-font-ttc",
    "application/x-font-otf",
    "application/x-font-type1"
]

def is_font_file (f):
    return f.get_mime_type() in SupportedMimeTypes


class FontViewer (GObject.GObject, Nemo.MenuProvider):

    Active = False

    def __init__ (self):
        DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SessionBus()
        self.bus.watch_name_owner('org.gnome.FontManager', FontViewer.set_state)

    def get_file_items (self, window, files):
        if FontViewer.Active and len(files) == 1:
            selected_file = files[0]
            if is_font_file(selected_file):
                try:
                    proxy = self.bus.get_object('org.gnome.FontManager', '/org/gnome/FontManager/FontViewer')
                    ready = proxy.get_dbus_method('Ready', 'org.gnome.FontManager.FontViewer')
                    if ready():
                        show_uri = proxy.get_dbus_method('ShowUri', 'org.gnome.FontManager.FontViewer')
                        show_uri('{0}'.format(selected_file.get_activation_uri()))
                except:
                    pass
        return

    def get_background_items (self, window, folder):
        return

    @staticmethod
    def set_state (s):
        if s.strip() != '':
            FontViewer.Active = True
        else:
            FontViewer.Active = False
        return

