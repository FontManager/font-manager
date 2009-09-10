"""
This module provides a simple preferences dialog
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

# Suppress warnings related to unused arguments
# pylint: disable-msg=W0613

import os
import gtk
import gobject
import logging
import ConfigParser

import xmlutils
from config import HOME, INI, PACKAGE_DIR, DB_DIR
from common import match, search


class Preferences:
    """
    Font Manager preferences dialog
    """
    show_orphaned = None
    def __init__(self, parent=None, builder=None):

        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder
            
        self.directories = []
        self.start_dirs = []
        self.builder.add_from_file(PACKAGE_DIR  + '/ui/preferences.ui')
        self.builder.connect_signals(self)
        self.window = self.builder.get_object('window')
        self.window.connect('destroy', self.quit)
        self.window.set_size_request(375, 425)
        self.window.set_title(_('Preferences'))
        if parent is not None:
            self.window.set_transient_for(parent)
        self.tree = self.builder.get_object('user_dir_treeview')
        self.dir_model = gtk.ListStore(gobject.TYPE_STRING)
        self.tree.set_model(self.dir_model)
        column = gtk.TreeViewColumn('Folders',
                                    gtk.CellRendererText(), markup=0)
        self.tree.append_column(column)
        self.tree.get_selection().set_mode(gtk.SELECTION_SINGLE)
        self.tree.get_selection().connect('changed', self.selection_changed)
        
        self.db_tree = self.builder.get_object('db_tree')
        self.db_model = gtk.ListStore(gobject.TYPE_STRING)
        self.db_tree.set_model(self.db_model)
        column = gtk.TreeViewColumn('Families', 
                                        gtk.CellRendererText(), text=0)
        self.db_tree.append_column(column)
        self.db_tree.get_selection().set_mode(gtk.SELECTION_SINGLE)
        
        self.db_list = []
        for family in os.listdir(DB_DIR):
            self.db_list.append(family)
        db_store = self.db_model
        for family in sorted(self.db_list):
            family = family.strip('.db')
            db_store.append([family])
        
        self.dir_combo_box = self.builder.get_object('default_folder_box')
        self.dir_combo = gtk.ComboBox()
        self.dir_combo.set_model(self.dir_model)
        cell = gtk.CellRendererText()
        self.dir_combo.pack_start(cell, True)
        self.dir_combo.add_attribute(cell, 'text', 0)
        self.dir_combo_box.pack_start(self.dir_combo, False, True, 5)
        arch_box = self.builder.get_object('arch_box')
        self.arch_combo = gtk.combo_box_new_text()
        arch_box.pack_start(self.arch_combo, False, True, 5)
        arch_box.reorder_child(self.arch_combo, 1)
        self.arch_combo.append_text('zip')
        self.arch_combo.append_text('tar.bz2')
        self.arch_combo.append_text('tar.gz')
        self.show_orphans = self.builder.get_object('show_orphans')
        self.load_directories()
        # take a count now, so we know if anything changed
        for directory in self.directories:
            self.start_dirs.append(directory)
        # always have the default folder in list at the top
        store = self.dir_model
        treeiter = store.prepend()
        default_dir = os.path.join(HOME, '.fonts')
        store.set(treeiter, 0, default_dir)
        self.directories.insert(0, default_dir)
        self.tree.get_selection().select_path(0)
        self.load_config()
        
    def remove_db_entry(self, unused_widget):
        stor, treeiter = self.db_tree.get_selection().get_selected()
        family = self.db_model.get_value(treeiter, 0)
        try:
            os.remove(os.path.join(DB_DIR, family + '.db'))
        except OSError:
            return
        self.db_list.remove(family + '.db')
        self.db_model.remove(treeiter)
        self.db_tree.queue_draw()
        
    def reset_db(self, unused_widget):
        for i in self.db_list:
            try:
                os.remove(os.path.join(DB_DIR, i))
            except OSError:
                continue
        self.db_model.clear()
        self.db_tree.queue_draw()
        return

    def on_apply(self, widget):
        self.save_settings(widget)
        self.quit(widget)

    def restart_required(self, widget):
        dialog = gtk.Dialog(_('Restart Required'), self.window,
                    gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
                                    (gtk.STOCK_OK, gtk.RESPONSE_OK),)

        dialog.set_default_response(gtk.RESPONSE_OK)
        box = dialog.get_content_area()
        label = gtk.Label\
(_('Changes will not be reflected until Font Manager is restarted'))
        label.set_padding(15, 0)
        box.pack_start(label, True, True, 15)
        box.show_all()
        response = dialog.run()
        if response == gtk.RESPONSE_OK:
            self.quit(widget)
            dialog.destroy()
        elif response == gtk.RESPONSE_DELETE_EVENT:
            self.quit(widget)
            dialog.destroy()

    def on_add_dir(self, unused_widget):
        directory = self.get_new_dir()
        if directory:
            for i in self.directories:
                if directory == i:
                    return
            self.add_directory(directory)
        return

    def on_del_dir(self, unused_widget):
        self.remove_directory()
        return

    def load_config(self):
        config = ConfigParser.ConfigParser()
        config.read(INI)
        try:
            directory =  config.get('Font Folder', 'default')
            dir_iter = search(self.dir_model,
            self.dir_model.iter_children(None), match, (0, directory))
            try:
                if self.dir_model.iter_is_valid(dir_iter):
                    self.dir_combo.set_active_iter(dir_iter)
            except TypeError:
                self.dir_combo.set_active(0)
        except ConfigParser.NoSectionError:
            self.dir_combo.set_active(0)

        try:
            arch_type = config.get('Archive Type', 'default')
            if arch_type == 'zip':
                self.arch_combo.set_active(0)
            elif arch_type == 'tar.bz2':
                self.arch_combo.set_active(1)
            elif arch_type == 'tar.gz':
                self.arch_combo.set_active(2)
        except ConfigParser.NoSectionError:
            self.arch_combo.set_active(0)

        try:
            self.show_orphaned = config.get('Orphans', 'show')
        except ConfigParser.NoSectionError:
            self.show_orphaned = 'False'

        if self.show_orphaned == 'True':
            self.show_orphans.set_active(True)
        else:
            self.show_orphans.set_active(False)
        return

    def load_directories(self):
        for directory in xmlutils.load_directories():
            self.add_directory(directory)
        return

    def add_directory(self, directory):
        """
        Adds directory to fontconfig search path
        """
        lstore = self.dir_model
        treeiter = lstore.append()
        lstore.set(treeiter, 0, directory)
        self.directories.append(directory)
        xmlutils.save_directories(self.directories)
        return

    def remove_directory(self):
        """
        Removes directory from fontconfig search path
        """
        try:
            treeiter, directory = self.get_selected_dir()
        except TypeError:
            return
        for i in self.directories:
            if i == directory:
                self.directories.remove(i)
                self.dir_model.remove(treeiter)
        xmlutils.save_directories(self.directories)
        return

    def get_new_dir(self):
        """
        Displays file chooser dialog so user can add new directories 
        to fontconfig search path.
        """
        dialog = gtk.FileChooserDialog\
        (_('Select Directory'), self.window,
        gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
        (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                gtk.STOCK_OK, gtk.RESPONSE_OK))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        dialog.set_current_folder(HOME)
        response = dialog.run()
        if response == gtk.RESPONSE_OK:
            directory = dialog.get_filename()
            dialog.destroy()
            return directory
        dialog.destroy()
        return

    def get_selected_dir(self):
        sel = self.tree.get_selection()
        model, treeiter = sel.get_selected()
        if not treeiter:
            return
        return treeiter, model.get(treeiter, 0)[0]

    def save_config(self, widget):
        config = ConfigParser.ConfigParser()
        config.read(INI)
        try:
            previous = config.get('Orphans', 'show')
        except ConfigParser.NoSectionError:
            previous = 'False'

        treeiter = self.dir_combo.get_active_iter()
        if treeiter:
            font_folder = self.dir_model.get_value(treeiter, 0)

        arch_type = self.arch_combo.get_active_text()

        config = ConfigParser.RawConfigParser()
        if font_folder:
            config.add_section('Font Folder')
            config.set('Font Folder', 'default', font_folder)
        if arch_type:
            config.add_section('Archive Type')
            config.set('Archive Type', 'default', arch_type)
        if self.show_orphans.get_active():
            actual = 'True'
            config.add_section('Orphans')
            config.set('Orphans', 'show', 'True')
        else:
            actual = 'False'
            config.add_section('Orphans')
            config.set('Orphans', 'show', 'False')
        with open(INI, 'wb') as ini:
            config.write(ini)
            
        if sorted(set(self.start_dirs)) != sorted(set(self.directories)) \
        or actual != previous:
            self.restart_required(widget)
            
        return

    def save_settings(self, widget):
        """
        Saves all settings
        """
        xmlutils.save_directories(self.directories)
        self.save_config(widget)
        return

    def selection_changed(self, unused_widget):
        """
        Updates UI sensitivity
        """
        sel = self.tree.get_selection().path_is_selected(0)
        rem = self.builder.get_object('del_dir')
        # don't allow removal of default folder
        if sel:
            rem.set_sensitive(False)
        else:
            rem.set_sensitive(True)
        return

    def run(self):
        """
        Shows preferences dialog
        """
        logging.info('Loading preferences dialog')
        self.window.show_all()

    def quit(self, unused_widget):
        """
        Hides preferences dialog
        """
        self.window.hide()
