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

from config import DB_DIR, INI
from common import reset_fontconfig_cache


class Load:
    fontload = None
    fontviews = None
    treeviews = None
    def __init__(self, parent, builder, app_icon):
        self.builder = builder
        self.parent = parent
        # "statusbar" is just a label...
        self.status_bar = self.builder.get_object("total_fonts")
        self.app_icon = app_icon
        
    def initialize(self, MESSAGE, hidden):
        self.fontload = fontload.FontLoad(self.parent, self.builder)
        self.fontviews = fontviews.Views(self.parent, self.builder)
        self.treeviews = treeviews.Trees(self.parent, self.builder)
        self.status_bar.set_text\
        (_("Fonts : %s") % self.fontload.total_fonts)
        # If minimizeonstart is set, let's throw up a notification
        if hidden and MESSAGE is not None:
            notification = MESSAGE(_('Font Manager'), \
                                _('Finished loading %s fonts') % \
                            self.fontload.total_fonts, 'dialog-info')
            if self.app_icon is not None:
                notification.set_icon_from_pixbuf(self.app_icon)
            notification.show()
        return self.treeviews

    def reboot(self, MESSAGE):
        """
        Restarts the application when changes require it or user requests it.
        """
        import logging
        self.parent.hide()
        while gtk.events_pending():
            gtk.main_iteration()
        # If possible notify about impending restart
        if MESSAGE is not None:
            notification = MESSAGE(_('Font Manager'), \
                            _('Will restart in a moment'), 'dialog-info')
            if self.app_icon is not None:
                notification.set_icon_from_pixbuf(self.app_icon)
            notification.show()
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

