# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009 Jerry Casiano
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

import sys

def exit_with_error(msg, err):
    sys.stderr.write('Error: %s (%s)\n' % (msg, str(err)))
    sys.exit(1)

def main():
    """
    Checks that necessary modules are available before running the program
    """ 
    try:
        import pygtk; pygtk.require('2.0')
        import gtk
    except (ImportError, AssertionError), e:
        exit_with_error('Importing pygtk and gtk modules failed',  e)

    try:
        import gobject
    except ImportError, e:
        exit_with_error('Importing gobject module failed',  e)

    try:
        import libxml2
    except ImportError, e:
        exit_with_error('Importing libxml2 module failed',  e)

    from fontmanager import FontManager
    from xmlconf import CheckInstall
    
    CheckInstall()
    f = FontManager()

    try: gtk.main()
    except (KeyboardInterrupt): pass


if __name__ == '__main__': main()
