"""
This module handles UI initialization, font loading, treeview setup, etc.

It also restarts the application when changes require it.
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

import gtk
import time
import shutil
import subprocess

import fontload
import fontviews
import treeviews
import xmlutils

from config import DB_DIR
from common import reset_fontconfig_cache


class Ui:
    fontload = None
    fontviews = None
    treeviews = None
    def __init__(self, parent=None, builder=None):
        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder
        self.parent = parent
        # "statusbar" is just a label...
        self.status_bar = self.builder.get_object("total_fonts")

    def initialize(self):
        self.fontload = fontload.FontLoad(parent=self.parent,
                                                    builder=self.builder)
        self.fontviews = fontviews.Views(parent=self.parent,
                                                    builder=self.builder)
        self.treeviews = treeviews.Trees(parent=self.parent,
                                                    builder=self.builder)
        self.status_bar.set_text(_("Fonts : %s") %
                                        self.fontload.total_fonts)
        return self.treeviews

    def reboot(self):
        """
        Attempts to reload all font information and refreshes treeviews,
        so that restarting the application is not necessary after installing,
        removing fonts, or changing preferences.
        """
        import logging
        self.parent.hide()
        shutil.rmtree(DB_DIR, ignore_errors=True)
        # Save any changes to collections before reloading
        self.treeviews.save()
        # Disable blacklist so all fonts are returned by fc-list
        xmlutils.BlackList.disable_blacklist()
        # Stall so fontconfig returns up to date results
        # Hopefully this is enough on most systems
        reset_fontconfig_cache()
        time.sleep(3)
        xmlutils.check_libxml2_leak()
        logging.info("Restarting...")
        subprocess.Popen(['font-manager'])
        gtk.main_quit()
        return
