"""
This module handles installation and removal of fonts
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


import os
import gtk
import glob
import gobject
import logging
import shutil

from os.path import basename, exists, join, isdir, splitext

import _fontutils

from core import database
from constants import HOME, TMP_DIR, USER_LIBRARY_DIR, FONT_EXTS, T1_EXTS, \
                        ARCH_EXTS, FONT_GLOBS, ARCH_GLOBS
from utils.common import finish_font_install, install_font_archive, \
                            mkfontdirs, natural_sort, do_library_cleanup


class InstallFonts(object):
    """
    Bring up a dialog where user is allowed to select font files or archives
    """
    def __init__(self, objects):
        self.objects = objects
        self.dupes = None
        self.dialog = self.objects['FontInstallDialog']
        self.dialog.set_current_folder(HOME)
        # I can't seem to find an option in Glade to get this behavior?
        self.dialog.connect('file-activated', lambda widget: widget.response(1))
        filefilter = gtk.FileFilter()
        filefilter.set_name(_('Font Manager supported types'))
        for extension in FONT_GLOBS:
            filefilter.add_pattern(extension)
        if 'file-roller' in self.objects['AvailableApps']:
            for extension in ARCH_GLOBS:
                filefilter.add_pattern(extension)
        self.dialog.add_filter(filefilter)

    def _check_dupes(self):
        """
        Check for duplicates
        """
        if not self.dupes:
            self.dupes = []
        new_hash = {}
        known_hash = []
        found_dupes = False
        for root, unused_dirs, files in os.walk(TMP_DIR):
            for filename in files:
                if filename.endswith(FONT_EXTS):
                    fileinfo = _fontutils.FT_Get_File_Info(join(root, filename))
                    ash = fileinfo['checksum']
                    new_hash[ash] = fileinfo
        for family in self.objects['FontManager'].iterkeys():
            fonts = self.objects['FontManager'][family].styles
            for font in fonts.itervalues():
                known_hash.append(font['checksum'])
        dupes = [ f for f in new_hash.iterkeys() if f in known_hash]
        for k, v in new_hash.iteritems():
            if k in dupes:
                self.dupes.append(v['filepath'])
        if len(self.dupes) > 0:
            found_dupes = True
        return found_dupes

    def _install_mad_fonts(self):
        dialog = self.objects['MadFontsWarning']
        result = dialog.run()
        dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        return result

    def process_install(self, filelist):
        """
        Sort chosen files and copy them to an appropriate directory
        """
        no_such_file = []
        total = len(filelist)
        if not exists(TMP_DIR):
            os.mkdir(TMP_DIR)
        if total > 1000 and not self._install_mad_fonts():
            return
        processed = 0
        self.objects.set_sensitive(False)
        for filepath in filelist:
            if isdir(filepath):
                continue
            filename = filepath.rsplit('/', 1)[1]
            if filepath.endswith(ARCH_EXTS):
                # There is a slim possibility that a file gets changed
                # between being selected in the filechooser and getting here
                if not exists(filepath):
                    no_such_file.append(filepath)
                    continue
                install_font_archive(filepath)
            elif filepath.endswith(FONT_EXTS):
                if not exists(filepath):
                    no_such_file.append(filepath)
                    continue
                shutil.copy(filepath, TMP_DIR)
                if filepath.endswith(T1_EXTS):
                    metrics = splitext(filepath)[0] + '.*'
                    for path in glob.glob(metrics):
                        shutil.copy(path, TMP_DIR)
            processed += 1
            self.objects.progress_callback(filename, total, processed)
        self.objects.set_sensitive(True)
        if len(no_such_file) > 0:
            self._show_missing_files(no_such_file)
        if filelist == no_such_file or total < 1:
            logging.error('No files to process...')
            return
        if self._check_dupes():
            self._show_dupes(self.dupes)
            del self.dupes[:]
        finish_font_install()
        # Are fonts.scale and fonts.dir even necessary anymore?
        mkfontdirs()
        # Reload
        self.objects.reload()
        return

    def run(self):
        """
        Display dialog.
        """
        filelist = None
        response = self.dialog.run()
        if response:
            filelist = self.dialog.get_filenames()
            # or this behavior...
            if len(filelist) == 1 and isdir(filelist[0]):
                self.dialog.set_current_folder(filelist[0])
                self.run()
        self.dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if filelist:
            self.process_install(filelist)
        return

    @staticmethod
    def skip_dupes(filelist):
        """
        Delete duplicate files.
        """
        for filepath in filelist:
            os.unlink(filepath)
        return

    def _show_dupes(self, filelist):
        """
        Present a dialog showing duplicate files
        """
        dialog = self.objects['DuplicatesWarning']
        view = self.objects['DuplicatesView']
        t_buffer = view.get_buffer()
        t_buffer.set_text('')
        for filepath in filelist:
            t_buffer.insert_at_cursor(basename(filepath) + '\n')
        response = dialog.run()
        dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if response:
            self.skip_dupes(filelist)
        return

    def _show_missing_files(self, filelist):
        """
        Present a dialog showing which files could not be located
        """
        dialog = self.objects['FileMissingDialog']
        view = self.objects['FileMissingView']
        t_buffer = view.get_buffer()
        t_buffer.set_text('')
        for filepath in filelist:
            t_buffer.insert_at_cursor(filepath + '\n')
        dialog.run()
        dialog.hide()
        return


class RemoveFonts(object):
    """
    Display a dialog where user can select which fonts to delete.
    """
    def __init__(self, objects):
        self.objects = objects
        self.remove_list = gtk.ListStore(gobject.TYPE_STRING)
        self.dialog = self.objects['FontRemovalDialog']
        self.dialog.connect('delete-event', self._on_quit)
        self.remove_tree = self.objects['RemoveFontsTree']
        self.remove_search = self.objects['RemoveSearchEntry']
        self.remove_fonts = self.objects['RemoveFontsButton']
        self.remove_fonts.connect('clicked', self._on_remove_fonts)
        self.families = set()
        self.update_required = False
        self.column = gtk.TreeViewColumn(None, gtk.CellRendererText(), text=0)
        self.remove_tree.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        self.column.set_sort_column_id(0)
        self.remove_tree.append_column(self.column)
        self.remove_tree.set_search_entry(self.remove_search)
        self.remove_search.connect('icon-press', self._on_clear_icon)

    def do_delete(self, selected_paths):
        """
        Delete files.
        """
        for filepath in selected_paths:
            if exists(filepath):
                try:
                    os.unlink(filepath)
                except OSError, error:
                    logging.error('Error : %s' % error)
        self.update_required = True
        return

    def _on_clear_icon(self, unused_widget, unused_x, unused_y):
        """
        Clear search entry.
        """
        self.remove_search.set_text('')
        self.remove_tree.scroll_to_point(0, 0)
        return

    def _on_remove_fonts(self, unused_widget):
        """
        Remove selected fonts from filesystem.
        """
        selected_paths = []
        selected_fams = {}
        model, selected = self.remove_tree.get_selection().get_selected_rows()
        fonts = database.Table('Fonts')
        for path in selected:
            treeiter = model.get_iter(path)
            val = model.get_value(treeiter, 0)
            filepaths = fonts.get('*', 'family="%s"' % val)
            filelist = []
            for row in filepaths:
                filelist.append(row['filepath'])
            selected_fams[val] = treeiter
            for filepath in filelist:
                selected_paths.append(filepath)
        self.do_delete(selected_paths)
        fonts.close()
        for treeiter in selected_fams.itervalues():
            self.remove_list.remove(treeiter)
        still_valid = None
        for treeiter in selected_fams.itervalues():
            still_valid = self.remove_list.iter_is_valid(treeiter)
            if still_valid:
                break
        if still_valid:
            new_path = self.remove_list.get_path(treeiter)
            if (new_path[0] >= 0):
                self.remove_tree.get_selection().select_path(new_path)
        else:
            path_to_select = self.remove_list.iter_n_children(None) - 1
            if (path_to_select >= 0):
                self.remove_tree.get_selection().select_path(path_to_select)
        return

    def _on_quit(self, unused_widget, unused_event):
        """
        Do cleanup actions after hiding the dialog.
        """
        self.dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if self.update_required:
            mkfontdirs()
            do_library_cleanup(USER_LIBRARY_DIR)
            # Reload
            self.objects.reload()
        return True

    def run(self):
        """
        Show dialog.
        """
        self.update_required = False
        self.families.clear()
        self.remove_tree.set_model(None)
        self.remove_list.clear()
        fonts = database.Table('Fonts')
        families = fonts.get('*', 'filepath LIKE "/home%"')
        fontdirs = tuple(self.objects['Preferences'].fontdirs)
        active = self.objects['FontManager'].list_families()
        for result in families:
            if result['filepath'].startswith(fontdirs):
                continue
            elif result['family'] in active:
                self.families.add(result['family'])
        fonts.close()
        for family in natural_sort(list(self.families)):
            self.remove_list.append([family])
        self.remove_tree.set_model(self.remove_list)
        self.remove_tree.grab_focus()
        self.dialog.show()
        return

