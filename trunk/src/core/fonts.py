"""
This module sorts individual font files into their respective families
and groups those families into default categories, it also loads any
user specified collections.
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

# Disable warnings related to gettext
# pylint: disable-msg=E0602

import gtk
import glib
import cPickle
import shelve

import database

from constants import CACHE_FILE, USER
from utils.xmlutils import get_blacklisted, load_collections


class Collection(object):
    """
    This class provides a way to group font families.
    """
    __slots__ = ('name', 'families', 'builtin', 'enabled', 'comment')
    def __init__(self, name):
        self.name = name
        self.families = []
        self.builtin = False
        self.enabled = True
        self.comment = None

    def add(self, *families):
        """
        Add a family, a tuple or list of families to the collection.
        """
        if isinstance(families[0], str):
            self.families.append(families[0])
        elif isinstance(families[0], (tuple, list)):
            for family in families[0]:
                self.families.append(family)
        else:
            raise TypeError\
            ('Expected a string, tuple or list but got %s instead' % \
            type(families[0]))
        self.families = list(set(self.families))
        return

    def contains(self, family):
        """
        Return True if family is already in collection.
        """
        if family in self.families:
            return True
        return False

    def get_label(self):
        """
        Return a label suitable for display in a gtk.TreeView.
        """
        if self.enabled:
            return _on(self.name)
        else:
            return _off(self.name, False)

    def get_name(self):
        """
        Return collection name.
        """
        return self.name

    def remove(self, *families):
        """
        Remove a family, a tuple or list of families from the collection.
        """
        if isinstance(families[0], str):
            if self.contains(families[0]):
                self.families.remove(families[0])
        elif isinstance(families[0], (tuple, list)):
            for family in families[0]:
                while self.contains(family):
                    self.families.remove(family)
        else:
            raise TypeError\
            ('Expected a string, tuple or list but got %s instead' % \
            type(families[0]))
        return

    def set_comment(self, comment):
        """
        Set a comment for this collection.

        The comment will be used for tooltips in the interface.
        """
        if isinstance(comment, str):
            self.comment = comment
        else:
            raise TypeError('Expected a string but got %s instead' \
                                                        % type(comment))

class Family(object):
    """
    This class holds details about a font family.
    """
    __slots__ = ('name', 'user', 'enabled', 'pango_family', 'styles')
    def __init__(self, family):
        self.name = family
        self.user = False
        self.enabled = True
        self.pango_family = None
        self.styles = {}

    def __getstate__(self):
        """
        Values to save when pickling object.

        Note: Pango objects cannot be pickled, must be restored separately.
        """
        return (self.name, self.user, self.enabled, self.styles)

    def __setstate__(self, state):
        """
        Values to restore when unpickling this object.
        """
        self.name, self.user, self.enabled, self.styles = state

    def get_count(self, format = True):
        """
        Return the number of styles.
        
        If format is True, return a string suitable for display, i.e '5 Fonts'
        """
        count = len(self.styles)
        if not format:
            return count
        else:
            if count > 1:
                return _('%s Fonts') % count
            else:
                return _('%s Font') % count

    def get_label(self):
        """
        Return a label suitable for display in a gtk.TreeView.
        """
        if self.enabled:
            return _on(self.name)
        else:
            return _off(self.name)

    def get_name(self):
        """
        Return family name.
        """
        return self.name


class Sort(object):
    """
    This class sorts individual font files into their respective families
    and determines whether they are owned by the system or the user. It then
    creates default categories and loads any user defined collections.

    It also enables or disables families based on user preferences.

    fontmanager -- a FontManager instance to store information in

    Keyword Arguments:

    progress_callback -- a function to call, it will be called everytime
                        a family is processed with the name of the family,
                        the total number of families to be processed and
                        the number of families processed so far.
    """
    def __init__(self, fontmanager, progress_callback = None):
        self.total = 0
        self.processed = 0
        self.progress_callback = progress_callback
        # To get a valid Pango context we need a widget...
        self.widget = gtk.Window()
        self.manager = fontmanager
        database.sync()
        self.table = database.Table('Fonts')
        self.cachefile = CACHE_FILE
        self.cache = shelve.open(self.cachefile,
                                    protocol=cPickle.HIGHEST_PROTOCOL)
        self.file_total = len(self.table)
        # List of all indexed families
        self.indexed = []
        self._get_indexed()
        # List of actually available families
        self.all_available = []
        self._get_available()
        self.available = [f for f in self.all_available if f in self.indexed]
        # List of system families
        self.system = []
        self._get_system_families()
        # List of user families
        self.user = [f for f in self.available if f not in self.system]
        # Now we can sort
        self._sort()
        self.cache.close()
        self.table.close()
        # Load user collections
        self._load_user_collections()
        # List of families present in user collections
        self.collected = []
        for collection in self.manager.collections.iterkeys():
            for family in self.manager.collections[collection].families:
                self.collected.append(family)
        # List of families NOT present in user collections
        self.orphans = [f for f in self.available if f not in self.collected]
        # Set up default categories
        self._load_default_categories()
        self._disable_rejects()
        self.widget.destroy()

    def _build_styles_dict(self, family):
        """
        Return a dictionary holding details for all files belonging to family.
        """
        styles = {}
        for row in self.table.get('*', 'family="%s"' % family):
            # Too bad sqlite rows don't survive a pickle...
            keys = row.keys()
            face = {}
            for i in range(15):
                face[keys[i]] = row[i]
            styles[row['style']] = face
        return styles

    def _disable_rejects(self):
        """
        Disable famililes based on user preferences.
        """
        rejects = get_blacklisted()
        if rejects:
            valid_rejects = [f for f in rejects if f in self.manager.iterkeys()]
            self.manager.set_disabled(valid_rejects)
        return

    def _get_available(self):
        """
        Get a list of actually available font families.
        """
        context = self.widget.get_pango_context()
        pango_families = context.list_families()
        psuedo_families = 'Monospace', 'Sans', 'Serif'
        self.total = len(pango_families)
        for family in pango_families:
            name = family.get_name()
            if name in psuedo_families:
                continue
            self.all_available.append(name)
        return

    def _get_indexed(self):
        """
        Get a list of all available font families.
        """
        for row in set(self.table.get('family')):
            self.indexed.append(row[0])
        return

    def _get_system_families(self):
        """
        Get a list of font families which belong to the "System".
        """
        for row in set(self.table.get('family', 'owner="System"')):
            if row[0] in self.all_available:
                self.system.append(row[0])
        return

    def _load_default_categories(self):
        """
        Set up default categories.
        """
        self.manager.create_category(_('All'),
                                        families = self.available,
                                        comment = _('All available fonts'))
        self.manager.create_category(_('System'), families = self.system,
                                    comment = _('Fonts available to all users'))
        self.manager.create_category(_('User'), families = self.user,
                comment = _('Fonts available only to %s' % USER.capitalize()))
        self.manager.create_category(_('Orphans'), families = self.orphans,
                            comment = _('Fonts not present in any collection'))
        return

    def _load_user_collections(self):
        """
        Load any saved user collections
        """
        self.manager.initial_collection_order = load_collections(self.manager)
        return

    def _sort(self):
        """
        Load details for all available font families as reported by Pango.
        """
        context = self.widget.get_pango_context()
        pango_families = context.list_families()
        psuedo_families = 'Monospace', 'Sans', 'Serif'
        self.total = len(pango_families)
        for family in pango_families:
            name = family.get_name()
            if name in psuedo_families:
                continue
            if self.cache.has_key(name):
                obj = self.cache[name]
            else:
                obj = Family(name)
                if name in self.user:
                    obj.user = True
                obj.styles = self._build_styles_dict(name)
                self.cache[name] = obj
            obj.pango_family = family
            self.manager[name] = obj
            self.processed += 1
            if self.progress_callback:
                self.progress_callback(name, self.total, self.processed)
        return

    def total_families(self):
        """
        Total number of font families.
        """
        return len(self.available)

    def total_files(self):
        """
        Total number of font files in database.
        """
        return self.file_total


def _on(name):
    """
    Return a label suitable for display in a gtk.TreeView.
    """
    label = glib.markup_escape_text(name)
    return '<span weight="heavy">%s</span>' % label

def _off(name, strike = True):
    """
    Return a label suitable for display in a gtk.TreeView.
    """
    label = glib.markup_escape_text(name)
    if strike:
        return '<span weight="ultralight" strikethrough="true">%s</span>' % label
    else:
        return '<span weight="ultralight">%s</span>' % label

