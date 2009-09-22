"""
This module handles installation and removal of fonts
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
import shutil
import subprocess
import cPickle

from common import Throbber
from config import HOME, FM_DIR, INSTALL_DIRECTORY, DB_DIR, USER_FONT_DIR

TMP_DIR = os.path.join(FM_DIR, 'temp')

FILE_EXTS = ('.ttf', '.ttc', '.otf', '.TTF', '.TTC', '.OTF')
ARCH_EXTS = ('.zip', '.tar', '.tar.gz', '.tar.bz2',
               '.ZIP', '.TAR', '.TAR.GZ', '.TAR.BZ2' )
F_EXTS = ['*.ttf', '*.ttc', '*.otf', '*.TTF', '*.TTC', '*.OTF']
A_EXTS = ['*.zip', '*.tar*', '*.ZIP', '*.TAR*']


def setup_install_directories():
    if not os.path.exists(INSTALL_DIRECTORY):
        os.mkdir(INSTALL_DIRECTORY)
    if not os.path.exists(TMP_DIR):
        os.mkdir(TMP_DIR)
    if not os.path.exists(os.path.join(USER_FONT_DIR, 'Library')):
        os.symlink(INSTALL_DIRECTORY, os.path.join(USER_FONT_DIR, 'Library'))
    return
    
class InstallFonts:
    """
    Bring up a dialog where user is allowed to select font files or archives
    """
    def __init__(self, unused_widget, parent, loader, builder):
        setup_install_directories()
        self.filelist = []
        self.installed = []
        self.pending = []
        self.dupes = []
        self.need_2_remove = []
        self.parent = parent
        self.loader = loader
        self.builder = builder
        self.progress = self.builder.get_object('progressbar')
        dialog = gtk.FileChooserDialog(_('Select File'), self.parent,
                                        gtk.FILE_CHOOSER_ACTION_OPEN,
                                    (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                                            gtk.STOCK_OK, gtk.RESPONSE_OK))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        dialog.set_current_folder(HOME)
        fmfilter = gtk.FileFilter()
        fmfilter.set_name(_('Font Manager supported types'))
        for extension in F_EXTS:
            fmfilter.add_pattern(extension)
        for extension in A_EXTS:
            fmfilter.add_pattern(extension)
        dialog.add_filter(fmfilter)
        dialog.set_select_multiple(True)
        response = dialog.run()
        if response == gtk.RESPONSE_OK:
            self.filelist = dialog.get_filenames()
            dialog.destroy()
            while gtk.events_pending():
                gtk.main_iteration()
            if self.filelist:
                self.process_install()
            return
        dialog.destroy()

    def process_install(self):
        """
        Sort chosen files and copy them to an appropriate directory
        """
        no_such_file = []
        allfiles = len(self.filelist)
        if allfiles > 1000 and not self._install_mad_fonts(allfiles):
            return
        processed = 0
        self.progress.show()
        # Ensure update
        while gtk.events_pending():
            gtk.main_iteration()
        for filepath in self.filelist:
            filename = filepath.rsplit('/', 1)[1]
            if filepath.endswith(ARCH_EXTS):
                # There is a slim possibility that a file gets changed
                # between being selected in the filechooser and getting here
                if os.path.exists(filepath):
                    self.install_archive(filepath)
                else:
                    no_such_file.append(filepath)
                    continue
            elif filepath.endswith(FILE_EXTS):
                if os.path.exists(filepath):
                    shutil.copy(filepath, TMP_DIR)
                else:
                    no_such_file.append(filepath)
                    continue
                progress = float(processed)/float(allfiles)
                self.progress.set_fraction(progress)
                self.progress.set_text(_('Installing') + '  ' + filename)
                while gtk.events_pending():
                    gtk.main_iteration()
            processed += 1
        self.progress.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if len(no_such_file) > 0:
            show_problem_files(no_such_file)
        if len(no_such_file) == len(self.filelist) or len(self.filelist) < 1:
            return
        if self._check_dupes():
            self._show_dupes(self.dupes)
        self.finish_install()
        # Are fonts.scale and fonts.dir even necessary anymore?
        mkfontdirs()
        self.loader.reboot()
        do_cleanup(TMP_DIR)
        return

    @staticmethod
    def install_archive(filepath):
        dir_name = strip_archive_name(filepath)
        arch_dir = os.path.join(TMP_DIR, dir_name)
        if os.path.exists(arch_dir):
            i = 0
            while os.path.exists(arch_dir):
                arch_dir = arch_dir + str(i)
                i += 1
        os.mkdir(arch_dir)
        subprocess.call(['file-roller', '-e', arch_dir, filepath])
        # Todo: Need to check whether archive actually contained any fonts
        # if user_is_stupid:
        #     self.notify()
        # ;-p 
        return
    
    @staticmethod
    def finish_install():
        """
        Organize fonts alphabetically
        """
        for root, dirs, files in os.walk(TMP_DIR):
            for directory in dirs:
                fullpath = os.path.join(root, directory)
                new = directory[0]
                new = new.upper()
                newpath = os.path.join(INSTALL_DIRECTORY, new)
                if not os.path.exists(newpath):
                    os.mkdir(newpath)
                newname = os.path.join(newpath, directory)
                shutil.move(fullpath, newname)
        for root, dirs, files in os.walk(TMP_DIR):
            for name in files:
                if name.endswith(FILE_EXTS):
                    oldpath = os.path.join(root, name)
                    truename = name.split('.')[0]
                    truename = name.strip()
                    new = truename[0]
                    new = new.upper()
                    newpath = os.path.join(INSTALL_DIRECTORY, new)
                    if not os.path.exists(newpath):
                        os.mkdir(newpath)
                    newname = os.path.join(newpath, name)
                    shutil.move(oldpath, newname)
        return
        
    def _check_dupes(self):
        """
        Check for duplicates
        """
        found_dupes = False
        for root, dirs, files in os.walk(INSTALL_DIRECTORY):
            for name in files:
                if name.endswith(FILE_EXTS):
                    self.installed.append(name)
        for root, dirs, files in os.walk(TMP_DIR):
            for name in files:
                if name.endswith(FILE_EXTS):
                    self.pending.append(name)
                    self.need_2_remove.append(os.path.join(root, name))
        self.dupes = [ f for f in self.pending if f in self.installed]
        if len(self.dupes) > 0:
            found_dupes = True
        if found_dupes:
            return True
        else:
            return False
            
    def skip_dupes(self):
        for filepath in self.need_2_remove:
            os.unlink(filepath)
        return
    
    def _show_dupes(self, filelist):
        """
        Presents a dialog showing duplicate files
        """
        dialog = gtk.Dialog(_('Duplicates'), self.parent, 0,
                        (_("Don't install duplicates"), gtk.RESPONSE_CANCEL,
                                    _('Install anyways'), gtk.RESPONSE_OK))
        dialog.set_default_response(gtk.RESPONSE_OK)
        dialog.set_size_request(450, 325)
        box = dialog.get_content_area()
        scrolled = gtk.ScrolledWindow()
        scrolled.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        scrolled.set_shadow_type(gtk.SHADOW_ETCHED_IN)
        view = gtk.TextView()
        view.set_left_margin(5)
        view.set_right_margin(5)
        view.set_cursor_visible(False)
        view.set_editable(False)
        t_buffer = view.get_buffer()
        t_buffer.insert_at_cursor\
        (_('\nThe following files appear to be duplicates :\n\n'))
        for filename in filelist:
            t_buffer.insert_at_cursor('\t' + filename + '\n')
        scrolled.add(view)
        box.pack_start(scrolled, True, True, 0)
        box.show_all()
        response = dialog.run()
        if response == gtk.RESPONSE_CANCEL:
            dialog.destroy()
            while gtk.events_pending():
                gtk.main_iteration()
            self.skip_dupes()
            return
        dialog.destroy()
        while gtk.events_pending():
            gtk.main_iteration()
        return
        
    def _install_mad_fonts(self, how_many):
        dialog = gtk.Dialog(_("Confirm Action"),
        self.parent, gtk.DIALOG_MODAL,
        (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                gtk.STOCK_YES, gtk.RESPONSE_YES))
        dialog.set_default_response(gtk.RESPONSE_CANCEL)
        message = _("""
Installing large amounts of fonts at once can have quite an impact on the desktop.
If you choose to continue, it is suggested that you close all open applications
and be patient should your desktop become unresponsive for a bit.

Really install %s files?
        """) % how_many
        text = gtk.Label()
        text.set_padding(15, 0)
        text.set_text(message)
        dialog.vbox.pack_start(text, padding=10)
        text.show()
        ret = dialog.run()
        dialog.destroy()
        while gtk.events_pending():
            gtk.main_iteration()
        return (ret == gtk.RESPONSE_YES)


class RemoveFonts:
    """
    Displays a treeview where user can select which fonts to delete
    """
    remove_ls =  gtk.ListStore(gobject.TYPE_STRING)
    def __init__(self, unused_widget, parent=None, loader=None, builder=None):
        setup_install_directories()
        if not builder:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder
        self.loader = loader
        self.parent = parent
        self.families = []
        self.families_at_start = []
        self.installed_fonts = None
        self.builder.add_from_file('ui/remove.ui')
        self.window = self.builder.get_object('window')
        self.window.set_title(_('Remove Fonts'))
        self.window.set_transient_for(self.parent)
        self.window.connect('destroy', self.quit)
        self.remove_tree = self.builder.get_object('remove_tree')
        self.remove_search = self.builder.get_object('remove_search')
        self.delete_font = self.builder.get_object('delete_font')
        self.delete_font.connect('clicked', self.delete_selected)
        self.init_tree()
        self.load()
        self.window.show()
    
    def init_tree(self):
        self.remove_tree.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        cell_render = gtk.CellRendererText()
        column = gtk.TreeViewColumn(None, cell_render, text=0)
        column.set_sort_column_id(0)
        self.remove_tree.append_column(column)
        self.remove_tree.set_search_entry(self.remove_search)
        self.remove_search.connect('icon-press', self._on_clear_icon)

    def _on_clear_icon(self, unused_widget, unused_x, unused_y):
        self.remove_search.set_text('')
        self.remove_tree.scroll_to_point(0, 0)
        return
        
    def load(self):
        throbber = Throbber(self.builder)
        throbber.start()
        while gtk.events_pending():
            gtk.main_iteration()
        self.remove_tree.set_model(None)
        self.remove_ls.clear()
        if os.path.exists\
        (os.path.join(DB_DIR, 'installed_fonts.db')):
            loadobj = open\
            (os.path.join(DB_DIR, 'installed_fonts.db'), 'r')
            self.installed_fonts = cPickle.load(loadobj)
            loadobj.close()
        for font in self.installed_fonts.iterkeys():
            self.remove_ls.append([font])
            self.families_at_start.append(font)
        self.families = self.families_at_start[:]
        self.remove_tree.set_model(self.remove_ls)
        if len(self.families) > 0:
            self.remove_tree.get_selection().select_path(0)
        throbber.stop()
        while gtk.events_pending():
            gtk.main_iteration()
        return
        
    def delete_selected(self, unused_widget):
        selected_paths = []
        selected_fams = {}
        selected_db = []
        model, selected = self.remove_tree.get_selection().get_selected_rows()
        for path in selected:
            treeiter = model.get_iter(path)
            val = model.get_value(treeiter, 0)
            selected_db.append(val)
            selected_fams[val] = treeiter
            filelist = self.installed_fonts.get(val, None)
            for filepath in filelist.itervalues():
                selected_paths.append(filepath)
        self.do_delete(selected_paths, selected_db)
        for treeiter in selected_fams.itervalues():
            self.remove_ls.remove(treeiter)
        return
            
    def do_delete(self, selected_paths, selected_db):
        for filepath in selected_paths:
            if os.path.exists(filepath):
                os.unlink(filepath)
        for db in selected_db:
            if os.path.exists(os.path.join(DB_DIR, '%s.db' % db)):
                os.unlink(os.path.join(DB_DIR, '%s.db' % db))
            self.installed_fonts.pop(db)
            self.families.remove(db)
        return
        
    def quit(self, unused_widget):
        """
        Does some cleanup actions after hiding the dialog
        """
        self.window.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if self.families_at_start != self.families:
            self.families = []
            self.families_at_start = []
            mkfontdirs()
            self.loader.reboot()
            self.installed_fonts.clear()
            do_cleanup(INSTALL_DIRECTORY)
            # Second call to remove empty toplevel directories
            do_cleanup(INSTALL_DIRECTORY)
    
def mkfontdirs():
    """
    Generates fonts.scale and fonts.dir files for all 'managed' fonts
    
    Not sure these files are even necessary but it doesn't hurt anything.
    """
    for root, dirs, files in os.walk(INSTALL_DIRECTORY):
        if root == INSTALL_DIRECTORY or len(dirs) > 0:
            pass
        else:
            fdir = False
            if len(files) > 0:
                for filename in files:
                    if filename.endswith(FILE_EXTS):
                        fdir = True
                        break
            if fdir:
                try:
                    subprocess.call(['mkfontscale', root])
                    subprocess.call(['mkfontdir', root])
                except:
                    pass
    return

def do_cleanup(directory):
    """
    Removes empty leftover directories
    """
    for root, dirs, files in os.walk(directory):
        if root == directory or len(dirs) > 0:
            pass
        else:
            keep = False
            if len(files) > 0:
                for filename in files:
                    if filename.endswith(FILE_EXTS):
                        keep = True
                        break
            if not keep:
                shutil.rmtree(root)
    return
        
def strip_archive_name(name):
    for i in '.zip', '.tar', '.bz2', '.gz':
        name = name.replace(i, '')
    dir_name = name.rsplit('/', 1)[1]
    return dir_name

def show_problem_files(filelist):
    """
    Presents a dialog showing which files could not be located
    """
    dialog = gtk.Dialog(_('IO Error'), None, 0,
                                (gtk.STOCK_OK, gtk.RESPONSE_OK))
    dialog.set_default_response(gtk.RESPONSE_OK)
    dialog.set_size_request(450, 325)
    box = dialog.get_content_area()
    scrolled = gtk.ScrolledWindow()
    scrolled.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
    scrolled.set_shadow_type(gtk.SHADOW_ETCHED_IN)
    view = gtk.TextView()
    view.set_left_margin(5)
    view.set_right_margin(5)
    view.set_cursor_visible(False)
    view.set_editable(False)
    t_buffer = view.get_buffer()
    t_buffer.insert_at_cursor\
    (_('\nThe following files were not found :\n\n'))
    for path in filelist:
        t_buffer.insert_at_cursor('\t' + path + '\n')
    t_buffer.insert_at_cursor\
(_('\nIt is possible these files were modified before they were processed\n\n'))
    scrolled.add(view)
    box.pack_start(scrolled, True, True, 0)
    box.show_all()
    dialog.run()
    dialog.destroy()
    return
    
