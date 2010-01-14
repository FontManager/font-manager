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

import os
import gtk
import gobject
import logging
import shutil
import ConfigParser

from os.path import exists, join

import xmlutils
from config import HOME, INI, PACKAGE_DIR, DB_DIR, USER_FONT_DIR
from common import match, search, autostart


EXTS = ('.ttf', '.ttc', '.otf', '.pfb', '.pfa', '.pfm', '.afm', '.bdf',
            '.TTF', '.TTC', '.OTF', '.PFB', '.PFA', '.PFM', '.AFM', '.BDF')
            
# http://code.google.com/p/font-manager/issues/detail?id=1
BAD_PATHS = ('/usr', '/bin', '/boot', '/dev', '/lost+found', '/proc',
             '/root', '/selinux', '/srv', '/sys', '/etc', '/lib',
             '/sbin', '/tmp', '/var')

INFO = _("""
The autoscan feature will look in:

%s

for any folders containing font files and add them to the list.

Please be patient, as this operation can take some time depending on filesystem size.

Autoscan will not follow symbolic links or add hidden directories. These will have to be added manually, if needed.

Autoscan is a new feature and has not been tested extensively, there is no progress reported and no way to abort for now, do not use it if you have network shares or extremely slow filesystems in the scanned paths. Instead add folders manually.

Adding system directories, or directories for which you don't have full access, is discouraged. The following directories are not allowed when manually adding directories:

/
/usr
/bin
/boot
/dev
/lost+found
/proc
/root
/selinux
/srv
/sys
/etc
/lib
/sbin
/tmp
/var

Also, any directories not found during startup of the preferences dialog will be automatically removed from the list.

""") % HOME


class Preferences:
    """
    Font Manager preferences dialog
    """
    def __init__(self, parent, builder, loader, MESSAGE):
        self.builder = builder
        self.parent = parent
        self.loader = loader
        self.MESSAGE = MESSAGE
        self.directories = []
        self.start_dirs = []
        self.font_size = 20
        self.builder.add_from_file(join(PACKAGE_DIR, 'ui/preferences.ui'))
        self.builder.connect_signals(self)
        if self.parent:
            self.builder.get_object('window').set_transient_for(self.parent)
        self.tree = self.builder.get_object('user_dir_treeview')
        self.dir_model = gtk.ListStore(gobject.TYPE_STRING)
        self.tree.set_model(self.dir_model)
        column = gtk.TreeViewColumn('Folders',
                                    gtk.CellRendererText(), markup=0)
        self.tree.append_column(column)
        self.tree.get_selection().set_mode(gtk.SELECTION_SINGLE)
        self.tree.get_selection().connect('changed', self.selection_changed)
        self.db_tree = self.builder.get_object('db_tree')
        self.db_search = self.builder.get_object('db_search')
        self.db_tree.set_search_entry(self.db_search)
        self.db_model = gtk.ListStore(gobject.TYPE_STRING)
        self.db_tree.set_model(self.db_model)
        db_column = gtk.TreeViewColumn(None, gtk.CellRendererText(), text=0)
        self.db_tree.append_column(db_column)
        db_column.set_sort_column_id(0)
        self.db_tree.get_selection().set_mode(gtk.SELECTION_SINGLE)
        self.db_list = []
        if exists(DB_DIR):
            for family in os.listdir(DB_DIR):
                if family != 'installed_fonts.db':
                    self.db_list.append(family)
        if len(self.db_list) > 0:
            db_store = self.db_model
            self.db_list.sort()
            for family in self.db_list:
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
        for ext in 'zip', 'tar.bz2', 'tar.gz':
            self.arch_combo.append_text(ext)
        self.load_directories()
        # take a count now, so we know if anything changed
        for directory in self.directories:
            self.start_dirs.append(directory)
        # always have the default user folder in list at the top
        store = self.dir_model
        treeiter = store.prepend()
        default_dir = join(HOME, '.fonts')
        store.set(treeiter, 0, default_dir)
        self.directories.insert(0, default_dir)
        self.tree.get_selection().select_path(0)
        self.font_size_adj = self.builder.get_object('font_size_adjustment')
        self.load_config()
        self.font_size_adj.set_value(self.font_size)
        db_column.clicked()

    def run(self):
        """
        Shows preferences dialog
        """
        logging.info('Loading preferences dialog')
        self.builder.get_object('window').show_all()
        
    def load_config(self):
        """
        Load user preferences
        """
        start_at_login = self.builder.get_object('start_at_login')
        start_minimized = self.builder.get_object('start_minimized')
        show_orphans = self.builder.get_object('show_orphans')
        to_tray = self.builder.get_object('to_tray')
        pangram = self.builder.get_object('pangram')
        
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
            AUTOSTART = config.getboolean('General', 'autostart')
        except ConfigParser.NoSectionError:
            AUTOSTART = False
        if not AUTOSTART:
            start_at_login.set_active(False)
        else:
            start_at_login.set_active(True)

        try:
            MINIMIZED = config.getboolean('General', 'minimizeonstart')
        except ConfigParser.NoSectionError:
            MINIMIZED = False
        if not MINIMIZED:
            start_minimized.set_active(False)
        else:
            start_minimized.set_active(True)
            
        try:
            TRAY = config.getboolean('General', 'minimizeonclose')
        except ConfigParser.NoSectionError:
            TRAY = True
        if not TRAY:
            to_tray.set_active(False)
        else:
            to_tray.set_active(True)
        
        try:
            ORPHANS = config.getboolean('Categories', 'orphans')
        except ConfigParser.NoSectionError:
            ORPHANS = False
        if not ORPHANS:
            show_orphans.set_active(False)
        else:
            show_orphans.set_active(True)

        try:
            arch_type = config.get('Export Options', 'archivetype')
            if arch_type == 'zip':
                self.arch_combo.set_active(0)
            elif arch_type == 'tar.bz2':
                self.arch_combo.set_active(1)
            elif arch_type == 'tar.gz':
                self.arch_combo.set_active(2)
        except ConfigParser.NoSectionError:
            self.arch_combo.set_active(0)
        
        try:
            PANGRAM = config.getboolean('Export Options', 'pangram')
        except ConfigParser.NoSectionError:
            PANGRAM = False
        if not PANGRAM:
            pangram.set_active(False)
        else:
            pangram.set_active(True)
        
        try:
            self.font_size = float(config.get('Export Options', 'fontsize'))
        except ConfigParser.NoSectionError:
            pass
        
        return

    def save_config(self, unused_widget):
        """
        Saves user preferences
        """
        start_at_login = self.builder.get_object('start_at_login')
        start_minimized = self.builder.get_object('start_minimized')
        show_orphans = self.builder.get_object('show_orphans')
        to_tray = self.builder.get_object('to_tray')
        pangram = self.builder.get_object('pangram')
        AUTOSTART = start_at_login.get_active()
        MINIMIZED = start_minimized.get_active()
        ORPHANS = show_orphans.get_active()
        TRAY = to_tray.get_active()
        PANGRAM= pangram.get_active()
        treeiter = self.dir_combo.get_active_iter()
        
        if treeiter:
            font_folder = self.dir_model.get_value(treeiter, 0)
        else:
            font_folder = USER_FONT_DIR
        arch_type = self.arch_combo.get_active_text()
        
        config = ConfigParser.ConfigParser()
        config.read(INI)
        
        try:
            previous = config.get('Categories', 'orphans')
        except ConfigParser.NoSectionError:
            previous = 'False'
        
        sections = 'Font Folder', 'Orphans', 'General', 'Archive Type', \
                    'Categories', 'Export Options', 'Delete Event'
        for section in sections:
            if config.has_section(section):
                config.remove_section(section)
        config.add_section('Categories')
        config.add_section('Export Options')
        config.add_section('Font Folder')
        config.add_section('General')
        
        if font_folder:
            config.set('Font Folder', 'default', font_folder)
        if arch_type:
            config.set('Export Options', 'archivetype', arch_type)
        if AUTOSTART:
            autostart(True)
            config.set('General', 'autostart', 'True')
        else:
            autostart(False)
            config.set('General', 'autostart', 'False')
        if MINIMIZED:
            config.set('General', 'minimizeonstart', 'True')
        else:
            config.set('General', 'minimizeonstart', 'False')
        if TRAY:
            config.set('General', 'minimizeonclose', 'True')
        else:
            config.set('General', 'minimizeonclose', 'False')
        if PANGRAM:
            config.set('Export Options', 'pangram', 'True')
        else:
            config.set('Export Options', 'pangram', 'False')
        if ORPHANS:
            actual = 'True'
            config.set('Categories', 'orphans', 'True')
        else:
            actual = 'False'
            config.set('Categories', 'orphans', 'False')
        
        self.font_size = self.font_size_adj.get_value()
        config.set('Export Options', 'fontsize', self.font_size)
        
        with open(INI, 'wb') as ini:
            config.write(ini)
        self.start_dirs.sort()
        self.directories.sort()
        if set(self.start_dirs) != set(self.directories) \
        or actual != previous:
            self.loader.reboot(self.MESSAGE)
        return

    def on_autoscan_clicked(self, unused_widget):
        for root, dirs, files in os.walk(HOME):
            for name in files:
                if name.endswith(EXTS) and root.find('/.') == -1:
                    if root in self.directories:
                        continue
                    else:
                        self.add_directory(root)
                        # Ensure update
                        while gtk.events_pending():
                            gtk.main_iteration()
        return

    def on_info_clicked(self, unused_widget):
        dialog = gtk.MessageDialog(self.parent,
                                    gtk.DIALOG_DESTROY_WITH_PARENT,
                                    gtk.MESSAGE_INFO,
                                    gtk.BUTTONS_CLOSE)
        dialog.set_markup\
        (_('<b>Notes on adding directories to the search path</b>'))
        vbox = dialog.get_content_area()
        scroll = gtk.ScrolledWindow()
        scroll.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)
        scroll.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        textview = gtk.TextView()
        textview.set_editable(False)
        textview.set_size_request(500, 250)
        textview.set_cursor_visible(False)
        textview.set_left_margin(15)
        textview.set_right_margin(15)
        textview.set_wrap_mode(gtk.WRAP_WORD)
        buffer = textview.get_buffer()
        textiter = buffer.get_start_iter()
        buffer.insert_with_tags(textiter, INFO)
        buffer.set_text(INFO)
        scroll.add(textview)
        vbox.pack_start(scroll, True, True, 0)
        vbox.show_all()
        dialog.run()
        dialog.destroy()

    def _on_clear_icon(self, unused_widget, unused_x, unused_y):
        self.db_search.set_text('')
        self.db_tree.scroll_to_point(0, 0)
        return

    def remove_db_entry(self, unused_widget):
        try:
            treeiter = self.db_tree.get_selection().get_selected()[1]
            family = self.db_model.get_value(treeiter, 0)
        # Tried to delete something that wasn't there
        except TypeError:
            return
        try:
            os.remove(join(DB_DIR, family + '.db'))
            os.remove(join(DB_DIR, family + '.db'))
        except OSError:
            # FIXME
            pass
        try:
            self.db_list.remove(family + '.db')
        # No idea why this would happen...
        except ValueError:
            pass
        # This is a really nice touch - taken from gnome-specimen
        # Need to remember to use this whenever possible
        self.db_model.remove(treeiter)
        still_valid = self.db_model.iter_is_valid(treeiter)
        # Set the cursor to a remaining row instead of having the cursor
        # disappear. This allows for easy deletion of multiple rows by
        # hitting the Remove button repeatedly.  
        if still_valid:
            # The treeiter is still valid. This means that there's another
            # row has "shifted" to the location the deleted row occupied
            # before. Select that row.
            new_path = self.db_model.get_path(treeiter)
            if (new_path[0] >= 0):
                self.db_tree.get_selection().select_path(new_path)
        else:
            # It's no longer valid which means it was the last row that
            # was deleted, select the new last row.
            path_to_select = self.db_model.iter_n_children(None) - 1
            if (path_to_select >= 0):
                self.db_tree.get_selection().select_path(path_to_select)            
        self.db_tree.queue_draw()
        return

    def reset_db(self, unused_widget):
        shutil.rmtree(DB_DIR, ignore_errors=True)
        self.db_model.clear()
        self.db_tree.queue_draw()
        return

    def on_apply(self, unused_widget):
        widget = self.builder.get_object('window')
        self.on_window_destroy(widget)
        self.save_settings(widget)

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

    def load_directories(self):
        for directory in xmlutils.load_directories():
            self.add_directory(directory)
        return

    def add_directory(self, directory):
        """
        Adds directory to fontconfig search path
        """
        self.dir_model.append([directory])
        self.directories.append(directory)
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
                still_valid = self.dir_model.iter_is_valid(treeiter)
                # Set the cursor to a remaining row instead of having the cursor
                # disappear. This allows for easy deletion of multiple rows by
                # hitting the Remove button repeatedly.  
                if still_valid:
                    # The treeiter is still valid. This means that there's another
                    # row has "shifted" to the location the deleted row occupied
                    # before. Select that row.
                    new_path = self.dir_model.get_path(treeiter)
                    if (new_path[0] >= 0):
                        self.tree.get_selection().select_path(new_path)
                else:
                    # It's no longer valid which means it was the last row that
                    # was deleted, select the new last row.
                    path_to_select = self.dir_model.iter_n_children(None) - 1
                    if (path_to_select >= 0):
                        self.tree.get_selection().select_path(path_to_select)         
        return

    def get_new_dir(self):
        """
        Displays file chooser dialog so user can add new directories
        to fontconfig search path.
        """
        dialog = gtk.FileChooserDialog(_('Select Directory'), None,
                                    gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
                                    (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                                            gtk.STOCK_OK, gtk.RESPONSE_OK))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        dialog.set_current_folder(HOME)
        response = dialog.run()
        if response == gtk.RESPONSE_OK:
            directory = dialog.get_filename()
            dialog.destroy()
            if directory == '/' or directory.startswith(BAD_PATHS):
                self.bad_path(directory)
            else:
                return directory
        dialog.destroy()
        return

    def get_selected_dir(self):
        sel = self.tree.get_selection()
        model, treeiter = sel.get_selected()
        if not treeiter:
            return
        return treeiter, model.get(treeiter, 0)[0]

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

    def on_window_destroy(self, widget):
        """
        Hides preferences dialog
        """
        widget.hide()
        while gtk.events_pending():
            gtk.main_iteration()

    def bad_path(self, directory):
        dialog = gtk.Dialog(_("Invalid Selection"),
                                self.parent, gtk.DIALOG_MODAL,
                                    (gtk.STOCK_CLOSE, gtk.RESPONSE_CLOSE))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        message = _("""
%s

System paths are not allowed
        """) % directory
        text = gtk.Label()
        text.set_padding(25, 0)
        text.set_text(message)
        dialog.vbox.pack_start(text, padding=10)
        text.show()
        dialog.run()
        dialog.destroy()
        return

