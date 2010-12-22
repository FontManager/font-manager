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

import os
import gtk
import glib
import glob
import cPickle
import shelve
import pango
import tempfile
import shutil
import sqlite3
import subprocess

from os.path import basename, exists, join, splitext

import core.database
import fontutils

from constants import ALIAS_FAMILIES, CACHE_FILE, USER, USER_LIBRARY_DIR, \
                        T1_EXTS, FONT_EXTS
from utils.common import delete_cache, delete_database, natural_sort, \
                            strip_archive_ext
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
            ('Expected a string, tuple or list but got {0!s} instead'.format(
            type(families[0])))
        self.families = list(set(self.families))
        return

    def contains(self, family):
        """
        Return True if family is already in collection.
        """
        return (family in self.families)

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
            ('Expected a string, tuple or list but got {0!s} instead'.format(
            type(families[0])))
        return

    def set_comment(self, comment):
        """
        Set a comment for this collection.

        The comment will be used for tooltips in the interface.
        """
        if isinstance(comment, str):
            self.comment = comment
        else:
            raise TypeError('Expected a string but got {0!s} instead'.format(
                            type(comment)))


class Face(object):
    """
    This class holds details about a face.

    Provides an equivalent to pango.FontFace that can be pickled.
    """
    __slots__ = ('name', 'description')
    def __init__(self, face):
        self.name = face.get_face_name()
        self.description = face.describe().to_string()

    def describe(self):
        """
        Return a pango.FontDescription for this face.
        """
        return pango.FontDescription(self.description)

    def get_face_name(self):
        """
        Return the face name for the face.
        """
        return self.name

    @staticmethod
    def list_sizes():
        """
        This always returns None for scalable fonts which is pretty much
        the only kind we care about.
        """
        return None


class Family(object):
    """
    This class holds details about a font family.
    """
    __slots__ = ('name', 'user', 'enabled', 'pango_family', 'styles', 'version')
    def __init__(self, family):
        self.name = family
        self.user = False
        self.enabled = True
        self.pango_family = None
        self.styles = {}
        self.version = 1

    def get_count(self, display = True):
        """
        Return the number of styles.

        If display is True, return a string suitable for display, i.e '5 Fonts'
        """
        count = len(self.styles)
        if display:
            if count > 1:
                return _('{0} Fonts').format(count)
            else:
                return _('{0} Font').format(count)
        else:
            return count

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


class FileDetails(object):
    """
    This class holds file details about a particular style.
    """
    __slots__ = ('filepath', 'filetype', 'filesize', 'psname')
    def __init__(self, sqlite_row):
        self.filepath = sqlite_row['filepath']
        self.filetype = sqlite_row['filetype']
        self.filesize = sqlite_row['filesize']
        self.psname = sqlite_row['psname']

    def __getitem__(self, key):
        return getattr(self, key)


class PangoFamily(object):
    """
    This class holds details about a pango family.

    Provides an equivalent to pango.FontFamily that can be pickled.
    """
    __slots__ = ('name', 'faces', 'mono')
    def __init__(self, family):
        self.name = family.get_name()
        self.faces = self._get_faces(family)
        self.mono = family.is_monospace()

    @staticmethod
    def _get_faces(family):
        faces = {}
        for face in family.list_faces():
            faces[face.get_face_name()] = Face(face)
        return faces

    def list_faces(self):
        """
        Return a sorted list of pango.FontFaces
        """
        return [self.faces[face] for face in natural_sort(self.faces.keys())]

    def get_name(self):
        """
        Return the name of the family.
        """
        return self.name

    def is_monospace(self):
        """
        True if the font family is monospace.
        """
        return self.mono


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
    def __init__(self, fontmanager, progress_callback = None, parent = None):
        self.total = 0
        self.processed = 0
        self.progress_callback = progress_callback
        # To get a valid Pango context we need a widget...
        if parent:
            self.widget = parent
        else:
            self.widget = gtk.Window()
        self.manager = fontmanager
        self.cache = None
        self._check_cache()
        self._check_db()
        fontutils.set_progress_callback(progress_callback)
        fontutils.sync_font_database(_('Querying installed files...'))
        self.table = core.database.Table('Fonts')
        # List of all indexed families
        self.indexed = []
        self._get_indexed()
        # List of actually available families
        self.available = []
        self.pango_families = []
        self._get_available()
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
        if not parent:
            self.widget.destroy()

    def _check_db(self):
        """
        Delete database if it's in an outdated format.
        """
        try:
            test = core.database.Table('Fonts')['pstyle']
        except sqlite3.ProgrammingError:
            delete_database()
            self._load_new_cache()
        test = None
        return

    def _check_cache(self):
        """
        Delete cache if it's in an outdated format.
        """
        try:
            self.cache = shelve.open(CACHE_FILE,
                                        protocol=cPickle.HIGHEST_PROTOCOL)
            test = self.cache[self.cache.keys()[0]]
            assert (test.version == 1)
        except (AssertionError, AttributeError,
                    IndexError, cPickle.UnpicklingError):
            self._load_new_cache()
        test = None
        return

    def _disable_rejects(self):
        """
        Disable famililes based on user preferences.
        """
        rejects = get_blacklisted()
        if rejects:
            families = self.manager.list_families()
            valid_rejects = [f for f in rejects if f in families]
            self.manager.set_disabled(valid_rejects)
        return

    def _get_available(self):
        """
        Get a list of actually available font families.
        """
        context = self.widget.get_pango_context()
        pango_families = context.list_families()
        self.total = len(pango_families)
        for family in pango_families:
            name = family.get_name()
            if name in ALIAS_FAMILIES:
                continue
            if name in self.indexed:
                self.available.append(name)
                self.pango_families.append(family)
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
            if row[0] in self.available:
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
            comment = _('Fonts available only to {0}'.format(USER.capitalize())))
        self.manager.create_category(_('Orphans'), families = self.orphans,
                            comment = _('Fonts not present in any collection'))
        return

    def _load_new_cache(self):
        self.cache.close()
        delete_cache()
        self.cache = shelve.open(CACHE_FILE, protocol=cPickle.HIGHEST_PROTOCOL)
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
        for family in self.pango_families:
            name = family.get_name()
            if self.cache.has_key(name):
                obj = self.cache[name]
            else:
                obj = Family(name)
                obj.pango_family = PangoFamily(family)
                if name in self.user:
                    obj.user = True
                rows = self.table.get('*', 'family="{0}"'.format(name))
                for face in obj.pango_family.list_faces():
                    for row in rows:
                        if row['pdescr'] == face.description:
                            obj.styles[face.get_face_name()] = FileDetails(row)
                            break
                self.cache[name] = obj
            self.manager[name] = obj
            self.processed += 1
            if self.progress_callback:
                self.progress_callback(_("Loading available fonts..."),
                                        self.total, self.processed)
        return


def _on(name):
    """
    Return a label suitable for display in a gtk.TreeView.
    """
    label = glib.markup_escape_text(name)
    return '<span weight="heavy">{0}</span>'.format(label)

def _off(name, strike = True):
    """
    Return a label suitable for display in a gtk.TreeView.
    """
    label = glib.markup_escape_text(name)
    if strike:
        return \
        '<span weight="ultralight" strikethrough="true">{0}</span>'.format(label)
    else:
        return '<span weight="ultralight">{0}</span>'.format(label)


def _set_library_permissions(library = USER_LIBRARY_DIR):
    # Make sure we don't have any executables among our 'managed' files
    # and make sure others have read-only access, apparently this can be
    # an issue for some programs
    for root, dirs, files in os.walk(library):
        for directory in dirs:
            os.chmod(join(root, directory), 0755)
        for filename in files:
            os.chmod(join(root, filename), 0644)
    return

def _mkfontdirs(library = USER_LIBRARY_DIR):
    """
    Recursively generate fonts.scale and fonts.dir for folders containing
    font files.

    Not sure these files are even necessary but it doesn't hurt anything.
    """
    for root, dirs, files in os.walk(library):
        if not len(dirs) > 0 and root != library:
            if len(files) > 0:
                for filename in files:
                    if filename.endswith(FONT_EXTS):
                        try:
                            subprocess.call(['mkfontscale', root])
                            subprocess.call(['mkfontdir', root])
                        except Exception:
                            pass
                        break
    return

def do_font_install(filepath, library = USER_LIBRARY_DIR, cleanup = False):
    """
    Install given font file.
    """
    name = basename(filepath)
    newpath = join(library, name[0].upper())
    exists(newpath) or os.mkdir(newpath)
    shutil.copy(filepath, newpath)
    if filepath.endswith(T1_EXTS):
        metrics = splitext(filepath)[0] + '.*'
        for path in glob.glob(metrics):
            shutil.copy(path, newpath)
    if cleanup:
        do_library_cleanup(library)
    return

def install_font_archive(filepath, library = USER_LIBRARY_DIR, cleanup = False):
    """
    Install given font archive.
    """
    dir_name = strip_archive_ext(basename(filepath))
    tmp_dir = tempfile.mkdtemp(suffix='-font-manager', prefix='tmp-')
    arch_dir = join(tmp_dir, dir_name)
    os.mkdir(arch_dir)
    subprocess.call(['file-roller', '-e', arch_dir, filepath])
    # Todo: Need to check whether archive actually contained any fonts
    # if user_is_stupid:
    #     self.notify()
    # ;-p
    newpath = join(library, dir_name[0].upper())
    exists(newpath) or os.mkdir(newpath)
    shutil.move(arch_dir, newpath)
    shutil.rmtree(tmp_dir)
    if cleanup:
        do_library_cleanup(library)
    return

def do_library_cleanup(library = USER_LIBRARY_DIR):
    """
    Removes empty leftover directories and ensures correct permissions.
    """
    # Two passes here to get rid of empty top level directories
    passes = 0
    while passes <= 1:
        for root, dirs, files in os.walk(library):
            if not len(dirs) > 0 and root != library:
                keep = False
                for filename in files:
                    if filename.endswith(FONT_EXTS):
                        keep = True
                        break
                if not keep:
                    shutil.rmtree(root)
        passes += 1
    _set_library_permissions(library)
    _mkfontdirs(library)
    return
