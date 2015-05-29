"""
This module ensures that all necessary python modules are available
before running the actual program, if any modules are missing the
program will exit and print the name of the missing module to stdout.
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
#
# Suppress warning due to except: pass
# pylint: disable-msg=W0704
# Suppress warnings due to unused variables when checking for modules
# pylint: disable-msg=W0612

import sys
import gettext
import locale

from config import LOCALEDIR

gettext.install('font-manager')
gettext.bindtextdomain('font-manager', LOCALEDIR)
gettext.textdomain('font-manager')
    
def _exit_with_error(msg, error):
    """
    Print an error message letting user know which python module is missing
    """
    sys.stderr.write('Error: %s (%s)\n' % (msg, str(error)))
    sys.exit(1)

def main():
    """
    Checks that necessary modules are available before running the program
    """
    try:
        import pygtk
        pygtk.require('2.0')
        import gtk
    except (ImportError, AssertionError), error:
        _exit_with_error('Importing pygtk and gtk modules failed',  error)

    try:
        import gobject
    except ImportError, error:
        _exit_with_error('Importing gobject module failed',  error)

    try:
        import libxml2
    except ImportError, error:
        _exit_with_error('Importing libxml2 module failed',  error)

    from main import FontManager

    FontManager()

    try:
        gtk.main()
    except (KeyboardInterrupt):
        pass


if __name__ == '__main__':
    main()
