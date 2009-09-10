"""
This module uses fontconfig to find available fonts on a system.
.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009 Jerry Casiano
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
# along with this program; if not, write to:
#
# Free Software Foundation, Inc.
# 51 Franklin Street, Fifth Floor
# Boston, MA  02110-1301, USA.
#
# Suppress errors related to gettext
# pylint: disable-msg=E0602
# Suppress messages related to missing docstrings
# pylint: disable-msg=C0111
# Suppress warnings due to unused variables
# pylint: disable-msg=W0612

import os
import ConfigParser
import gtk
import gobject
import logging
import subprocess
import cPickle

import xmlutils

from config import INI, PACKAGE_DIR, DB_DIR


collection_ls = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
                                gobject.TYPE_STRING, gobject.TYPE_STRING)

family_ls = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
                                                    gobject.TYPE_STRING)

class Collection(object):
    __slots__ = ('name', 'fonts', 'builtin', 'enabled')

    def __init__(self, name):
        self.name = name
        self.fonts = []
        self.builtin = True
        self.enabled = True

    def get_label(self):
        if self.enabled:
            return _on(self.name)
        else:
            return _off(self.name)

    def obj_exists(self, obj):
        for font in self.fonts:
            if font is obj:
                return True
        return False

    def add(self, obj):
        # check duplicate reference
        if self.obj_exists(obj):
            return
        self.fonts.append(obj)

    def get_text(self):
        return self.name

    def _num_fonts_enabled(self):
        ret = 0
        for font in self.fonts:
            if font.enabled:
                ret += 1
        return ret

    def set_enabled(self, enabled):
        for font in self.fonts:
            font.enabled = enabled

    def set_enabled_from_fonts(self):
        self.enabled = (self._num_fonts_enabled() > 0)

    def remove(self, font):
        self.fonts.remove(font)


class Family(object):
    __slots__ = ('family', 'user', 'enabled', 'pango_family', 'filelist')

    def __init__(self, family):
        self.family = family
        self.user = False
        self.enabled = True
        self.pango_family = None
        self.filelist = {}
        
    def get_label(self):
        if self.enabled:
            return _on(self.family)
        else:
            return _off(self.family)


class FontLoad:

    collections = []
    collected = []
    available = []
    orphans = []

    # List of system families
    fc_sys_fams = []
    # List of user families
    fc_user_fams = []
    # List of all available families
    fc_fams = []
    # Dictionary --> 'family' : 'Family object'
    fc_fonts = {}

    total_fonts = 0

    def __init__(self, builder=None):

        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder

        self.show_orphans = False

    def add_collection(self, collection):
        """
        Add a collection object

        Keyword arguments:
        collection -- collection object to add
        """
        collection.set_enabled_from_fonts()
        lstore = collection_ls
        treeiter = lstore.append()
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_text())
        lstore.set(treeiter, 3, 'None')
        self.collections.append(collection)
        return

    def load_collections(self):
        """
        Set up default collections and load any saved user collections
        """

        collection = Collection(_('All Fonts'))
        for font in sorted(self.fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            collection.fonts.append(font)
        collection.set_enabled_from_fonts()
        lstore = collection_ls
        treeiter = lstore.append()    
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_text())
        lstore.set(treeiter, 3, 'All Fonts')
        self.collections.append(collection)


        collection = Collection(_('System'))
        for font in sorted(self.fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            if not font.user:
                collection.fonts.append(font)
        collection.set_enabled_from_fonts()
        lstore = collection_ls
        treeiter = lstore.append()    
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_text())
        lstore.set(treeiter, 3, 'System')
        self.collections.append(collection)


        collection = Collection(_('User'))
        for font in sorted(self.fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            if font.user:
                collection.fonts.append(font)
        collection.set_enabled_from_fonts()
        lstore = collection_ls
        treeiter = lstore.append()    
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_text())
        lstore.set(treeiter, 3, 'User')
        self.collections.append(collection)


        self._load_user_collections()

        return

    def _load_user_collections(self):
        # Add a separator between builtins and user collections
        lstore = collection_ls
        treeiter = lstore.append()
        lstore.set(treeiter, 1, None)

        groups = xmlutils.Groups(self.collections, collection_ls,
                                Collection, self.fc_fonts)
        user_collections = groups.load()

        for collection in user_collections:
            self.add_collection(collection)
            logging.info\
            ('Loaded user collection %s' % collection.name)
        # Show orphans if requested
        config = ConfigParser.ConfigParser()
        config.read(INI)
        try:
            self.show_orphans = config.get('Orphans', 'show')
        except ConfigParser.NoSectionError:
            self.show_orphans = 'False'

        if self.show_orphans == 'True':
            self._add_orphans()
        return

    def _add_orphans(self):
        """
        Add a collection containing any fonts not present in
        user collections
        """
        for collection in self.collections:
            if not collection.builtin:
                for font in collection.fonts:
                    self.collected.append(font)
        for font in sorted(self.fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            self.available.append(font)
        self.orphans = \
        [font for font in self.available if font not in self.collected]
        if len(self.orphans) > 0:
            collection = Collection(_('Orphans'))
            for font in sorted(set(self.orphans),
                        cmp=lambda x, y: cmp(x.family, y.family)):
                collection.fonts.append(font)
            collection.set_enabled_from_fonts()
            lstore = collection_ls
            treeiter = lstore.insert(3)
            lstore.set(treeiter, 0, collection.get_label())
            lstore.set(treeiter, 1, collection)
            lstore.set(treeiter, 2, collection.get_text())
            lstore.set(treeiter, 3, 'Orphans')
            self.collections.append(collection)
        return

    def load_fonts(self):
        """
        Get all font families and styles recognized by Fontconfig

        Parse, count and store, then return the results
        """
        self._load_fc_sys_fams()
        self._load_fc_fams()
        self._load_fonts()
        self._count_fonts()
        return

    def _load_fc_sys_fams(self):
        cmd = 'HOME= fc-list : family'
        for line in get_cli_output(cmd):
            family = shell_escape(line)
            family = strip_fc_family(family)
            self.fc_sys_fams.append(family)

    def _load_fc_fams(self):
        cmd = 'fc-list : family'
        for line in get_cli_output(cmd):
            family = shell_escape(line)
            family = strip_fc_family(family)
            self.fc_fams.append(family)
        # Populate user families
        self.fc_user_fams = \
        [ font for font in self.fc_fams if font not in self.fc_sys_fams]

    def _load_fonts(self):
        no_info = []
        self.builder.add_from_file(PACKAGE_DIR  + '/ui/splash.ui')
        splash = self.builder.get_object('splash')
        progress = self.builder.get_object('progress')
        splash.show_all()
        # Ensure update
        while gtk.events_pending():
            gtk.main_iteration()
            
        widget = self.builder.get_object('window')
        ctx = widget.get_pango_context()
        families = ctx.list_families()
        for family in families:
            name = family.get_name()
            progress.set_text('%s' % name)
            # Same here
            while gtk.events_pending():
                gtk.main_iteration()
                
            obj = Family(name)
            obj.pango_family = family
            fam = strip_fc_family(name)
            if fam in self.fc_user_fams:
                obj.user = True
                
            dbname = shell_escape(strip_fc_family(name))
            if os.path.exists\
            (os.path.join(DB_DIR, '%s.db' % dbname)):
                loadobj = open\
                (os.path.join(DB_DIR, '%s.db' % dbname), 'r')
                obj.filelist = cPickle.load(loadobj)
                loadobj.close()
                
            else:
                styles = {}   
                cmd = "fc-list \"%s\" file style" % shell_escape(name)
                for line in get_cli_output(cmd):
                    try:
                        filepath, style = line.split(': :style=')
                    except ValueError:
                        no_info.append(line)
                        continue
                    if style.find(','):
                        try:
                            style, unused_langs = style.split(',', 1)
                        except ValueError:
                            style = style.strip(',')
                    filepath = filepath.strip()
                    style = style.strip()
                    styles[style] = filepath
                obj.filelist = styles
                
                saveobj = open\
                (os.path.join(DB_DIR, '%s.db' % dbname), 'w')
                cPickle.dump(styles, saveobj, cPickle.HIGHEST_PROTOCOL)
                saveobj.close()
            
            self.fc_fonts[name] = obj
        splash.destroy()
        if len(no_info) > 0:
            print ''
            print '%s' % ('-' * 80)
            print \
'*-        The following font files failed to provide style information        -*'
            print '%s' % ('-' * 80)
            for i in no_info:
                print '-----> %s' % i
        return
         
    def _count_fonts(self):
        for unused_i in self.fc_fams:
            self.total_fonts += 1


def _gtk_markup_escape(name):
    name = name.replace('&', '&amp;')
    name = name.replace('<', '&lt;')
    name = name.replace('>', '&gt;')
    name = name.replace("'", '&apos;')
    name = name.replace('"', '&quot;')
    return name

def _on(name):
    name = _gtk_markup_escape(name)
    return '<span weight="heavy">%s</span>' % name

def _off(name):
    name = _gtk_markup_escape(name)
    return '<span weight="ultralight">%s Off</span>' % name

def shell_escape(family):
    if family.find("'"):
        family = family.replace("'", "\'")
    if family.find('"'):
        family = family.replace('"', '\"')
    if family.find('/'):
        family = family.replace('/', ' ')
    if family.find('$'):
        family = family.replace('$', '\$')
    return family

def strip_fc_family(family):
    """
    Remove alt name, get rid of escape characters
    """
    comma = family.find(',')
    if comma > 0:
        family = family[:comma]
    family = family.replace("\\", "")
    family = family.strip()
    return family

def get_cli_output(cmd):
    """
    os.popen is deprecated.

    This replaces os.popen(cmd).readline()
    """
    result = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, shell=True)
    while True:
        line = result.stdout.readline()
        if not line:
            break
        yield line

