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


import os
import ConfigParser
import gtk
import gobject
import logging
import cPickle
import time

import xmlutils

from common import get_cli_output, shell_escape, strip_fc_family
from config import INI, PACKAGE_DIR, DB_DIR, INSTALL_DIRECTORY, USER_FONT_DIR

# Dictionary --> 'family' : 'Family object'
fc_fonts = {}
# Default categories
categories = []
# User collections
collections = []

category_ls = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
                                                        gobject.TYPE_STRING)
collection_ls = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
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

    def get_name(self):
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
        self.filelist = {}
        self.pango_family = None
        
    def get_name(self):
        return self.family
        
    def get_label(self):
        if self.enabled:
            return _on(self.family)
        else:
            return _off(self.family)


class FontLoad:
    # Fonts present in user collections
    collected = []
    # All fonts
    available = []
    # Difference between collected and available
    orphans = []
    # List of system families
    fc_sys_fams = []
    # List of user families
    fc_user_fams = []
    # List of all available families
    fc_fams = []
    # 'statusbar'
    total_fonts = 0
    def __init__(self, parent=None, builder=None):
        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder
        self.parent = parent
        self.show_orphans = False
        self.installed_fonts = {}
        self.load_fonts()
        
    def load_fonts(self, reboot=False):
        """
        Get all font families and styles recognized by Fontconfig

        Parse, count and store, then return the results
        """
        if reboot:
            category_ls.clear()
            collection_ls.clear()
            self.total_fonts = 0
            categories = []
            collections = []
            self.collected = []
            self.available = []
            self.orphans = []
            self.fc_sys_fams = []
            self.fc_user_fams = []
            self.fc_fams = []
            fc_fonts.clear()
            self.installed_fonts.clear()
        self._load_fc_sys_fams()
        self._load_fc_fams()
        self._load_fonts(reboot)
        self._count_fonts()
        # Need to load blacklist now before loading collections
        patterns = xmlutils.BlackList(fc_fonts=fc_fonts).load()
        self.disable_rejects(patterns)
        self.load_collections()
        xmlutils.BlackList.enable_blacklist()
        return

    def _load_fc_sys_fams(self):
        cmd = 'HOME= fc-list : family | sort'
        for line in get_cli_output(cmd):
            family = strip_fc_family(line)
            self.fc_sys_fams.append(family)
        return

    def _load_fc_fams(self):
        cmd = 'fc-list : family | sort'
        for line in get_cli_output(cmd):
            family = strip_fc_family(line)
            self.fc_fams.append(family)
        # Populate user families
        self.fc_user_fams = \
        [ font for font in self.fc_fams if font not in self.fc_sys_fams]
        return

    def _load_fonts(self, reboot):
        if not reboot:
            self.builder.add_from_file(PACKAGE_DIR  + '/ui/splash.ui')
            splash = self.builder.get_object('splash')
            progress = self.builder.get_object('progress')
            splash.show_all()
        else:
            load_label = self.builder.get_object('loading_label')
            progress = self.builder.get_object('progress_label')
            load_label.show()
            progress.show()
        # Ensure update
        while gtk.events_pending():
            gtk.main_iteration()
        ctx = self.parent.create_pango_context()
        families = ctx.list_families()
        psuedo_fams = 'Monospace', 'Sans', 'Serif'
        for family in families:
            styles = {}
            name = family.get_name()
            if name in psuedo_fams:
                continue
            progress.set_text('%s' % name)
            # Same here
            while gtk.events_pending():
                gtk.main_iteration()
            obj = Family(name)
            obj.pango_family = family
            if strip_fc_family(name) in self.fc_user_fams:
                obj.user = True
            dbname = shell_escape(name)
            if os.path.exists\
            (os.path.join(DB_DIR, '%s.db' % dbname)):
                loadobj = open\
                (os.path.join(DB_DIR, '%s.db' % dbname), 'r')
                obj.filelist = cPickle.load(loadobj)
                loadobj.close()
            else:
                cmd = 'fc-list "%s" file style fullname' % dbname
                for line in get_cli_output(cmd):
                    filepath = line.split(':')[0]
                    try:
                        style = line.split(':style=')[1]
                        style = style.split(':fullname=')[0]
                        if style.find(','):
                            style = style.split(',')[0]
                        style = style.strip()
                    except IndexError:
                        style = None
                    if not style:
                        try:
                            fullname = line.split(':fullname=')[1]
                            if fullname:
                                fullname = fullname.replace(name, '')
                                if fullname.find(','):
                                    fullname = fullname.split(',')[0]
                                fullname = fullname.strip()
                                style = fullname 
                        except IndexError:
                            logging.warn('%s is missing required information')
                    styles[style] = filepath
                obj.filelist = styles
                if not os.path.exists(DB_DIR):
                    os.mkdir(DB_DIR)
                saveobj = open\
                (os.path.join(DB_DIR, '%s.db' % dbname), 'w')
                cPickle.dump(styles, saveobj, cPickle.HIGHEST_PROTOCOL)
                saveobj.close()
                for path in styles.itervalues():
                    if path.startswith(INSTALL_DIRECTORY) or \
                    path.startswith(USER_FONT_DIR):
                        if dbname in self.installed_fonts:
                            del self.installed_fonts[dbname]
                        self.installed_fonts[dbname] = styles
            fc_fonts[name] = obj
        if os.path.exists(os.path.join(DB_DIR, 'installed_fonts.db')):
            os.unlink(os.path.join(DB_DIR, 'installed_fonts.db'))
        saveobj = open\
        (os.path.join(DB_DIR, 'installed_fonts.db'), 'w')
        cPickle.dump(self.installed_fonts, saveobj, cPickle.HIGHEST_PROTOCOL)
        saveobj.close()
        if not reboot:
            splash.destroy()
            return
        else:
            progress.hide()
            load_label.hide()
            return
         
    def _count_fonts(self):
        for unused_i in self.fc_fams:
            self.total_fonts += 1
        return
    
    @staticmethod
    def add_collection(collection):
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
        lstore.set(treeiter, 2, collection.get_name())
        collections.append(collection)
        return
    
    @staticmethod
    def disable_rejects(patterns):
        if patterns:
            for family in patterns:
                font = fc_fonts.get(family, None)
                if font:
                    font.enabled = False
        return
        
    def load_collections(self):
        """
        Set up default categories and load any saved user collections
        """
        collection = Collection(_('All Fonts'))
        for font in sorted(fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            collection.fonts.append(font)
        collection.set_enabled_from_fonts()
        lstore = category_ls
        treeiter = lstore.append()    
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_name())
        categories.append(collection)

        collection = Collection(_('System'))
        for font in sorted(fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            if not font.user:
                collection.fonts.append(font)
        collection.set_enabled_from_fonts()
        lstore = category_ls
        treeiter = lstore.append()    
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_name())
        categories.append(collection)

        collection = Collection(_('User'))
        for font in sorted(fc_fonts.itervalues(),
                        cmp=lambda x, y: cmp(x.family, y.family)):
            if font.user:
                collection.fonts.append(font)
        collection.set_enabled_from_fonts()
        lstore = category_ls
        treeiter = lstore.append()    
        lstore.set(treeiter, 0, collection.get_label())
        lstore.set(treeiter, 1, collection)
        lstore.set(treeiter, 2, collection.get_name())
        categories.append(collection)

        self._load_user_collections()
        return

    def _load_user_collections(self):
        groups = xmlutils.Groups(collections, collection_ls,
                                Collection, fc_fonts)
        user_collections = groups.load()
        for collection in user_collections:
            # This should never happen but...
            if collection not in collections:
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
        Add a category containing any fonts not present in
        user collections
        """
        for collection in collections:
            for font in collection.fonts:
                self.collected.append(font)
        for font in sorted(fc_fonts.itervalues(),
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
            lstore = category_ls
            treeiter = lstore.insert(3)
            lstore.set(treeiter, 0, collection.get_label())
            lstore.set(treeiter, 1, collection)
            lstore.set(treeiter, 2, collection.get_name())
            categories.append(collection)
        return


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

