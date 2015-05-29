"""
For now this module only exports collections to an archive.
.
"""
#!/usr/bin/env python
#
# Copyright 2009 Jerry Casiano
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
# along with this program; if not, write to: Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Suppress errors related to gettext
# pylint: disable-msg=E0602

import os
import gtk
import shutil
import subprocess

from os.path import exists, join

from config import INI, HOME

class Export:
    """
    Export collections to an archive.
    """
    font_list = []
    file_list = []
    # fonts for which filepath is ?
    no_info = []
    def __init__(self, collection, archive = 1, pdf = 0):
        self.collection = collection
        self.file_list = []
        self.no_info = []
        tmpdir = "/tmp/%s" % self.collection.name
        for font in self.collection.fonts:
            file_path = font.filelist.itervalues()
            if file_path:
                for path in file_path:
                    # grab the real file, not a symlink
                    path = os.path.realpath(path)
                    if exists(path):
                        self.file_list.append(path)
                    # Try to catch 'broken' fonts...
                    # at this point this rarely works,
                    # it just tends to fail silently :-\
                    else:
                        self.no_info.append(font)
            else:
                self.no_info.append(font)
        if len(self.no_info) > 0:
            if self.export_anyways():
                pass
            else:
                return
        if archive:
            self.archive(tmpdir)
        elif pdf:
            return
        return

    def export_anyways(self):
        """
        If any filepaths were not found ask for confirmation before continuing.
        """
        dialog = gtk.Dialog(_('Missing information'), None, 0,
                                    (_('Cancel'), gtk.RESPONSE_CANCEL,
                                    _('Continue'), gtk.RESPONSE_OK),)
        dialog.set_default_response(gtk.RESPONSE_OK)
        dialog.set_size_request(450, 325)
        box = dialog.get_content_area()
        scrolled = gtk.ScrolledWindow()
        scrolled.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        view = gtk.TextView()
        view.set_left_margin(5)
        view.set_right_margin(5)
        view.set_cursor_visible(False)
        view.set_editable(False)
        t_buffer = view.get_buffer()
        t_buffer.insert_at_cursor\
        (_("\nFilepaths for the following fonts could not be determined.\n"))
        t_buffer.insert_at_cursor(_("\nThese fonts will not be included :\n\n"))
        for i in set(self.no_info):
            t_buffer.insert_at_cursor("\t" + i.get_name() + "\n")
        scrolled.add(view)
        box.pack_start(scrolled, True, True, 0)
        box.show_all()
        response = dialog.run()
        if response == gtk.RESPONSE_OK:
            dialog.destroy()
            return True
        else:
            dialog.destroy()
            return False

    def archive(self, tmpdir):
        """
        Produces an archive from the selected collection

        Requires file-roller to be installed
        """
        import ConfigParser
        config = ConfigParser.ConfigParser()
        config.read(INI)
        try:
            arch_type = config.get('Archive Type' , 'default')
        except ConfigParser.NoSectionError:
            arch_type = 'zip'
        if exists(tmpdir):
            shutil.rmtree(tmpdir)
        os.mkdir(tmpdir)
        for path in set(self.file_list):
            shutil.copy(path, tmpdir)
        os.chdir(join(HOME, "Desktop"))
        cmd = "file-roller -a '%s.%s' '%s'" % \
        (self.collection.name, arch_type, tmpdir)
        subprocess.call(cmd, shell=True)
        shutil.rmtree(tmpdir)
        return
