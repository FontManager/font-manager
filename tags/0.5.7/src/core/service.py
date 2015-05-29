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

# Disable warnings related to Class in a try statement
# pylint: disable-msg=R0923

try:

    import dbus
    import dbus.service

    from dbus.mainloop.glib import DBusGMainLoop

    DBusGMainLoop(set_as_default = True)
    HAVE_DBUS = True


    class FontService(dbus.service.Object):

        def __init__(self, parent, bus_name, object_path = '/com/fonts/manage'):
            dbus.service.Object.__init__(self, bus_name, object_path)
            self.parent = parent
            self.manager = None

        @dbus.service.method('com.fonts.interface')
        def is_ready(self):
            return (self.manager is not None)

        @dbus.service.method('com.fonts.interface')
        def show(self):
            self.parent.main_window.present()
            return True

        @dbus.service.method('com.fonts.manage', 'sas')
        def add_families_to(self, collection, families):
            """
            Add families to an existing collection.
            """
            return self.manager.add_families_to(str(collection),
                                                    _valid_list(families))

        @dbus.service.method('com.fonts.manage', 'ssas')
        def create_collection(self, collection, comment, families):
            """
            Create and add a category object.

            name -- collection name
            comment -- comment to display in tooltips
            families -- a list of families to add
            """
            return self.manager.create_collection(str(collection),
                                            str(comment), _valid_list(families))

        @dbus.service.method('com.fonts.manage', 's')
        def disable_collection(self, collection):
            """
            Disable collection.
            """
            return self.manager.disable_collection(str(collection))

        @dbus.service.method('com.fonts.manage', 's')
        def enable_collection(self, collection):
            """
            Enable collection.
            """
            return self.manager.enable_collection(str(collection))

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
            return self.manager.remove_collection(str(collection))

        @dbus.service.method('com.fonts.manage', 'sas')
        def remove_families_from(self, collection, families):
            """
            Add families to an existing collection.
            """
            return self.manager.remove_families_from(str(collection),
                                                        _valid_list(families))

        @dbus.service.method('com.fonts.manage', 'as')
        def set_disabled(self, families):
            """
            Disable a list  of families.
            """
            return self.manager.set_disabled(_valid_list(families))

        @dbus.service.method('com.fonts.manage', 'as')
        def set_enabled(self, families):
            """
            Enable a list of families.
            """
            return self.manager.set_enabled(_valid_list(families))

except ImportError:
    HAVE_DBUS = False


def _valid_list(alist):
    return [str(f) for f in alist]
