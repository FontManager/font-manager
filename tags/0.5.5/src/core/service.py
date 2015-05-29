"""
This module allows other applications to control Font Manager via DBus.
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


import dbus
import dbus.service
import gobject

from dbus.mainloop.glib import DBusGMainLoop


class FontService(dbus.service.Object):

    def __init__(self, manager):
        self.manager = manager
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.session_bus = dbus.SessionBus()
        self.name = dbus.service.BusName('com.fonts.manage', self.session_bus,
                            allow_replacement=True, replace_existing=True)
        self.mainloop = gobject.MainLoop()
        dbus.service.Object.__init__(self, self.session_bus, '/fontmanager')

    @dbus.service.method('com.fonts.manage')
    def quit(self):
        """
        Stop DBus service.
        """
        self.remove_from_connection(self.session_bus, '/fontmanager')
        self.mainloop.quit()

    @dbus.service.method('com.fonts.manage', 'sas')
    def add_families_to(self, collection, families):
        """
        Add families to an existing collection.
        """
        valid_list = []
        for family in families:
            valid_list.append(str(family))
        self.manager.add_families_to(str(collection), valid_list)
        return

    @dbus.service.method('com.fonts.manage', 'ssas')
    def create_collection(self, collection, comment, families):
        """
        Create and add a category object.

        name -- collection name
        comment -- comment to display in tooltips
        families -- a list of families to add
        """
        valid_list = []
        for family in families:
            valid_list.append(str(family))
        self.manager.create_collection(str(collection), str(comment), valid_list)
        return

    @dbus.service.method('com.fonts.manage', 's')
    def disable_collection(self, collection):
        """
        Disable collection.
        """
        self.manager.disable_collection(str(collection))
        return

    @dbus.service.method('com.fonts.manage', 's')
    def enable_collection(self, collection):
        """
        Enable collection.
        """
        self.manager.enable_collection(str(collection))
        return

    @dbus.service.method('com.fonts.manage', 's', 'ssas')
    def get_collection_details(self, collection):
        """
        Return collection details. Name, comment and list of families.
        """
        return self.manager.get_collection_details(str(collection))

    @dbus.service.method('com.fonts.manage', None, 'as')
    def list_categories(self):
        """
        Return a sorted list of available categories.
        """
        return self.manager.list_categories()

    @dbus.service.method('com.fonts.manage', None, 'as')
    def list_collections(self):
        """
        Return a sorted list of available collections.
        """
        return self.manager.list_collections()

    @dbus.service.method('com.fonts.manage', None, 'as')
    def list_disabled(self):
        """
        Return a sorted list of disabled families.
        """
        return self.manager.list_disabled()

    @dbus.service.method('com.fonts.manage', None, 'as')
    def list_enabled(self):
        """
        Return a sorted list of enabled families.
        """
        return self.manager.list_enabled()

    @dbus.service.method('com.fonts.manage', None, 'as')
    def list_families(self):
        """
        Return a sorted list of all available families.
        """
        return self.manager.list_families()

    @dbus.service.method('com.fonts.manage', 's', 'as')
    def list_families_in(self, collection):
        """
        Return a sorted list of families in collection.
        """
        return self.manager.list_families_in(str(collection))

    @dbus.service.method('com.fonts.manage', 's')
    def remove_collection(self, collection):
        """
        Remove an existing collection.
        """
        self.manager.remove_collection(str(collection))
        return

    @dbus.service.method('com.fonts.manage', 'sas')
    def remove_families_from(self, collection, families):
        """
        Add families to an existing collection.
        """
        valid_list = []
        for family in families:
            valid_list.append(str(family))
        self.manager.remove_families_from(str(collection), valid_list)
        return

    @dbus.service.method('com.fonts.manage', 'as')
    def set_disabled(self, families):
        """
        Disable a list  of families.
        """
        valid_list = []
        for family in families:
            valid_list.append(str(family))
        self.manager.set_disabled(valid_list)
        return

    @dbus.service.method('com.fonts.manage', 'as')
    def set_enabled(self, families):
        """
        Enable a list of families.
        """
        valid_list = []
        for family in families:
            valid_list.append(str(family))
        self.manager.set_enabled(valid_list)
        return
