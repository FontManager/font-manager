"""
This module allows users to export "collections".
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
import glib
import gtk
import logging
import shutil
import subprocess

from os.path import exists, join, realpath

from constants import HOME, DESKTOP_DIR, TMP_DIR
from utils.common import finish_font_install, create_archive_from_folder
try:
    from sampler import BuildSample, Config
except ImportError:
    pass

class Export(object):
    """
    Export a collection.
    """
    def __init__(self, objects):
        self.objects = objects
        self.dialog = self.objects['ExportDialog']
        self.manager = self.objects['FontManager']
        self.outdir = DESKTOP_DIR
        self.current_collection = None
        self.workdir = None
        try:
            import reportlab
            logging.info\
            ('Found ReportLab Toolkit Version %s' % reportlab.Version)
            reportlab = True
        except ImportError:
            reportlab = False
        self.objects['IncludeSampler'].set_sensitive(reportlab)
        self.objects['ExportAsPDF'].set_sensitive(reportlab)
        if not reportlab:
            tooltip = _('This feature requires the Report Lab Toolkit')
            self.objects['IncludeSampler'].set_tooltip_text(tooltip)
            self.objects['ExportAsPDF'].set_tooltip_text(tooltip)
        self.objects['ExportFileChooser'].connect('current-folder-changed',
                                                        self._on_dest_set)
        self.objects['ExportFileChooser'].set_current_folder(DESKTOP_DIR)

    def run(self):
        """
        Show export dialog.
        """
        self.current_collection = self.objects['Treeviews'].current_collection
        self.archtype = self.objects['Preferences'].archivetype
        self.pangram = self.objects['Preferences'].pangram
        self.fontsize = self.objects['Preferences'].fontsize
        response = self.dialog.run()
        self.dialog.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if response:
            self.process_export()
            pass

    def _on_dest_set(self, widget):
        """
        Check if folder selection is valid, display a warning if it's not.
        """
        new_folder = self.objects['ExportFileChooser'].get_current_folder()
        if os.access(new_folder, os.W_OK):
            self.outdir = new_folder
        else:
            markup = '<span weight="light" size="small" foreground="red"><tt>' \
            + _('Selected folder must be writeable') + '</tt></span>'
            self.objects['ExportPermissionsWarning'].set_markup(markup)
            glib.timeout_add_seconds(3, self._reset_filechooser, widget)
            glib.timeout_add_seconds(6, self._dismiss_warning)
        return

    def _reset_filechooser(self, widget):
        """
        Reset filechooser to default folder.
        """
        widget.set_current_folder(join(HOME, "Desktop"))
        return False

    def _dismiss_warning(self):
        """
        Hide warning.
        """
        self.objects['ExportPermissionsWarning'].set_text('')
        return False

    def process_export(self):
        """
        Export selected collection.
        """
        self.workdir = join(TMP_DIR, self.current_collection)
        if exists(TMP_DIR):
            finish_font_install()
        if exists(self.workdir):
            shutil.rmtree(self.workdir, ignore_errors=True)
        os.mkdir(TMP_DIR)
        os.mkdir(self.workdir)
        if self.objects['ExportAsArchive'].get_active():
            self._do_work_copy(self._get_filelist())
            if self.objects['IncludeSampler'].get_active():
                self.do_pdf_setup()
            create_archive_from_folder(self.current_collection, self.archtype,
                                                    self.outdir, self.workdir)
            self._do_cleanup()
        elif self.objects['ExportAsPDF'].get_active():
            self._do_pdf_setup(self._get_filelist(), output = self.outdir)
            self._do_cleanup()
        elif self.objects['ExportTo'].get_active():
            self._do_direct_copy(self._get_filelist())
        if exists(TMP_DIR):
            shutil.rmtree(TMP_DIR, ignore_errors=True)
        os.chdir(HOME)
        return

    def _get_filelist(self):
        """
        Return a list of filepaths for currently selected collection.
        """
        filelist = []
        for family in self.manager.list_families_in(self.current_collection):
            for val in self.manager[family].styles.itervalues():
                filelist.append(realpath(val['filepath']))
        return filelist

    def _do_cleanup(self):
        """
        Remove temporary directory.
        """
        if exists(self.workdir):
            shutil.rmtree(self.workdir, ignore_errors=True)
            self.workdir = None
        return

    def _do_work_copy(self, filelist):
        """
        Copy files to a temporary directory.
        """
        total = len(filelist)
        progress = 0
        self.objects.set_sensitive(False)
        self.objects['ProgressBar'].set_text(_('Copying files...'))
        for path in set(filelist):
            shutil.copy(path, self.workdir)
            # Try to include .afm, .pfm files for Type 1 fonts
            if path.endswith('.pfb'):
                self._get_pfb_files(path)
            elif path.endswith('.pfa'):
                self._get_pfa_files(path)
            progress += 1
            self.objects.progress_callback(None, total, progress)
        self.objects['ProgressBar'].set_text('')
        self.objects.set_sensitive(True)
        return

    def _do_direct_copy(self, filelist):
        """
        Copy files directly to selected folder.
        """
        total = len(filelist)
        progress = 0
        self.objects.set_sensitive(False)
        self.objects['ProgressBar'].set_text(_('Copying files...'))
        self.workdir = join(self.outdir, self.current_collection)
        if not exists(self.workdir):
            os.mkdir(self.workdir)
        for path in set(filelist):
            shutil.copy(path, self.workdir)
            # Try to include .afm, .pfm files for Type 1 fonts
            if path.endswith('.pfb'):
                self._get_pfb_files(path)
            elif path.endswith('.pfa'):
                self._get_pfa_files(path)
                progress += 1
            self.objects.progress_callback(None, total, progress)
        self.objects['ProgressBar'].set_text('')
        self.objects.set_sensitive(True)
        return

    def _do_pdf_setup(self, input = None, output = None):
        """
        Build PDF sample sheet from given files.

        Keyword Arguments

        input -- a python list of filepaths or a folder containing font files
        output -- folder to store reulting pdf in
        """
        if input is None:
            input = self.workdir
        if output is None:
            output = self.workdir
        config = Config()
        config.fontsize = self.fontsize
        config.pangram = self.pangram
        buildsample = BuildSample(self.objects, config, self.current_collection,
                        input, join(output, '%s.pdf' % self.current_collection))
        if not buildsample.basic():
            return False
        else:
            return True

    def _get_pfb_files(self, path):
        """
        Try to include extra PostScript font files.
        """
        try:
            afm_path = path.replace('.pfb', '.afm')
            if not exists(afm_path):
                afm_path = path.replace('afm', 'AFM')
            if exists(afm_path):
                shutil.copy(afm_path, self.workdir)
            pfm_path = path.replace('.pfb', '.pfm')
            if not exists(pfm_path):
                pfm_path = path.replace('pfm', 'PFM')
            if exists(pfm_path):
                shutil.copy(pfm_path, self.workdir)
        except OSError:
            pass
        return

    def _get_pfa_files(self, path):
        """
        Try to include extra PostScript font files.
        """
        try:
            afm_path = path.replace('.pfa', '.afm')
            if not exists(afm_path):
                afm_path = path.replace('afm', 'AFM')
            if exists(afm_path):
                shutil.copy(afm_path, self.workdir)
            pfm_path = path.replace('.pfa', '.pfm')
            if not exists(pfm_path):
                pfm_path = path.replace('pfm', 'PFM')
            if exists(pfm_path):
                shutil.copy(pfm_path, self.workdir)
        except OSError:
            pass
        return

