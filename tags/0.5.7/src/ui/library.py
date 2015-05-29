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

# Disable warnings related to gettext
# pylint: disable-msg=E0602

import gtk
import gobject
import logging

from os.path import isdir

from core import database
from constants import HOME, USER_LIBRARY_DIR, FONT_GLOBS, ARCH_GLOBS, \
                        USER_FONT_DIR
from utils.common import natural_sort, run_dialog


class InstallFonts(object):
    """
    Bring up a dialog where user is allowed to select font files or archives
    """
    def __init__(self, objects):
        self.objects = objects
        self.dialog = self.objects['FontInstallDialog']
        self.dialog.set_current_folder(HOME)
        # I can't seem to find an option in Glade to get this behavior?
        self.dialog.connect('file-activated', lambda widget: widget.response(1))
        filefilter = gtk.FileFilter()
        filefilter.set_name(_('Font Manager supported types'))
        for extension in FONT_GLOBS:
            filefilter.add_pattern(extension)
        if 'file-roller' in self.objects['AppCache']:
            for extension in ARCH_GLOBS:
                filefilter.add_pattern(extension)
        self.dialog.add_filter(filefilter)

    def _install_mad_fonts(self):
        """
        Display a warning dialog.
        """
        return run_dialog(dialog = self.objects['MadFontsWarning'])

    def _show_missing_files(self, filelist):
        """
        Present a dialog showing which files could not be located
        """
        t_buffer = self.objects['FileMissingView'].get_buffer()
        t_buffer.set_text('')
        for filepath in filelist:
            t_buffer.insert_at_cursor(filepath + '\n')
        run_dialog(dialog = self.objects['FileMissingDialog'])
        return

    def process_install(self, filelist, library = USER_LIBRARY_DIR):
        """
        Sort chosen files and copy them to an appropriate directory
        """
        total = len(filelist)
        if total < 1:
            logging.error('No files to process...')
            return
        if total > 1000 and not self._install_mad_fonts():
            return
        self.objects.set_sensitive(False)
        missing = self.objects['FontManager'].install_fonts(filelist, library,
                                                self.objects.progress_callback)
        self.objects.set_sensitive(True)
        if missing and len(missing) > 0:
            self._show_missing_files(missing)
        self.objects.reload(True)
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
        self.column = gtk.TreeViewColumn(None, gtk.CellRendererText(), text=0)
        self.remove_tree.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
        self.column.set_sort_column_id(0)
        self.remove_tree.append_column(self.column)
        self.remove_tree.set_search_entry(self.remove_search)
        self.remove_search.connect('icon-press', self._on_clear_icon)

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
        selected_iters = []
        selected_fonts = []
        model, selected = self.remove_tree.get_selection().get_selected_rows()
        for path in selected:
            treeiter = model.get_iter(path)
            val = model.get_value(treeiter, 0)
            selected_iters.append(treeiter)
            selected_fonts.append(val)
        self.objects['FontManager'].remove_fonts(selected_fonts)
        for treeiter in selected_iters:
            self.remove_list.remove(treeiter)
            while gtk.events_pending():
                gtk.main_iteration()
        # If someone chooses to remove a bunch of fonts all at once,
        # this can hang the interface as it searches for the right row to select.
        if len(selected_iters) <= 10:
            still_valid = None
            for treeiter in selected_iters:
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
        self.objects.update_family_total()
        self.objects['Treeviews'].update_views()
        self.objects['Main'].dirty = True
        return

    def _on_quit(self, unused_widget, unused_event):
        """
        Hide the dialog.
        """
        self.dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        return True

    def run(self):
        """
        Show dialog.
        """
        self.families.clear()
        self.remove_tree.set_model(None)
        self.remove_list.clear()
        fonts = database.Table('Fonts')
        families = fonts.get('*',
                'owner="User" AND filepath LIKE "{0}%"'.format(USER_FONT_DIR))
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
