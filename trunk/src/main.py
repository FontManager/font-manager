"""
Font Manager, a font management application for the GNOME desktop
.
"""
#
# Copyright (C) 2009 Jerry Casiano
#
LICENSE_TEXT = _("""
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to: 

    Free Software Foundation, Inc. 
    51 Franklin Street, Fifth Floor 
    Boston, MA 02110-1301, USA.
""")
#
# Suppress errors related to gettext
# pylint: disable-msg=E0602

# Suppress warnings related to unused arguments
# pylint: disable-msg=W0613

AUTHORS = ['\nJerry Casiano\n', '\nSpecial thanks to:\n', 
'  Karl Pickett', 
_('\tFont Manager is based on Karl\'s work'),
'\t<fontmanager.blogspot.com>\n', 
'  Wouter Bolsterlee',
_('\tFont Manager\'s compare mode is modeled after,'), 
_('\tand uses portions of gnome-specimen'), 
'\t<launchpad.net/gnome-specimen>\n']
    
import os
import gtk
import gobject
import logging
import subprocess
import ConfigParser

import fontload
import fontviews
import treeviews
import xmlutils

from config import INI, PACKAGE, PACKAGE_DIR, VERSION, USER, USER_FONT_DIR


class FontManager:
    """
    Font Manager, a font management application for the GNOME desktop
    """
    builder = gtk.Builder()
    builder.set_translation_domain('font-manager')

    def __init__(self):
        # Make sure all needed files are present in users home folder
        xmlutils.check_install()
        # Disable blacklist so all fonts are returned by fc-config
        xmlutils.disable_blacklist()
        # Load ui file
        self.builder.add_from_file(PACKAGE_DIR  + '/ui/main.ui')
        self.mainwindow = self.builder.get_object("window")
        self.mainwindow.connect('destroy', self.quit)
        self.mainwindow.set_title(PACKAGE)
        self.mainwindow.set_size_request(850, 500)
        # Find and set up icon for use throughout app windows
        icon_theme = gtk.icon_theme_get_default()
        try:
            app_icon = icon_theme.load_icon("preferences-desktop-font", 48, 0)
        except gobject.GError, exc:
            logging.warn("Could not find preferences-desktop-font icon", exc)
        gtk.window_set_default_icon_list(app_icon)
        # Fill everything
        self.fontload = fontload.FontLoad(self.builder)
        self.fontload.load_fonts()
        # Need to load blacklist now before loading collections
        xmlutils.BlackList(self.fontload.fc_fonts).load()
        self.fontload.load_collections()
        self.fontview = fontviews.Views(parent=self.mainwindow,
                                                    builder=self.builder)
        self.treeviews = treeviews.Trees(self.fontload,
                            parent=self.mainwindow, builder=self.builder)
        # "statusbar" is just a label...
        self.status_bar = self.builder.get_object("total_fonts")
        self.status_bar.set_label(_("Fonts : %s") %
                                        self.fontload.total_fonts)
        # Font preferences, at least for GNOME
        font_prefs = self.builder.get_object("font_preferences")
        font_prefs.connect('clicked', on_font_preferences)
        if os.path.exists('/usr/bin/gnome-appearance-properties') or \
        os.path.exists('/usr/local/bin/gnome-appearance-properties'):
            font_prefs.set_sensitive(True)
        else:
            font_prefs.set_sensitive(False)
            font_prefs.set_tooltip_text\
            ('This feature requires gnome-appearance-properties')
            
        gucharmap = self.builder.get_object("gucharmap")
        if os.path.exists('/usr/bin/gucharmap') or \
        os.path.exists('/usr/local/bin/gucharmap'):
            gucharmap.connect('clicked', self.fontview.on_char_map)
        else:
            gucharmap.set_sensitive(False)
            gucharmap.hide()

        # Export requires file-roller
        export = self.builder.get_object("export")
        export.connect('clicked', self.on_export)
        if os.path.exists('/usr/bin/file-roller') or \
        os.path.exists('usr/local/bin/file-roller'):
            export.set_sensitive(True)
        else:
            export.set_sensitive(False)
            export.set_tooltip_text\
            ('This feature requires file-roller')

        # Connect handlers
        about = self.builder.get_object('about_button')
        about.connect('clicked', on_about)
        fmhelp = self.builder.get_object('help')
        fmhelp.connect('clicked', on_help)
        prefs = self.builder.get_object('app_prefs')
        prefs.connect('clicked', self.on_prefs)
        manage_fonts = self.builder.get_object('manage_fonts')
        manage_fonts.connect('clicked', on_manage_fonts)
        # Showtime
        self.mainwindow.show()
        xmlutils.enable_blacklist()

    def on_prefs(self, unused_widget):
        """
        Displays applications preferences dialog
        """
        from preferences import Preferences
        Preferences(parent=self.mainwindow, builder=self.builder).run()

    def on_export(self, unused_widget):
        """
        Exports selected collection
        """
        from export import Export
        collection = self.treeviews.get_current_collection()
        Export(collection)

    def quit(self, unused_widget):
        """
        Saves collection information before exiting
        """
        logging.info("Saving configuration")
        self.treeviews.save()
        xmlutils.check_libxml2_leak()
        logging.info("Exiting...")
        gtk.main_quit()

def on_about(unused_widget):
    """
    Displays about dialog
    """
    dialog = gtk.AboutDialog()
    dialog.set_name(PACKAGE)
    dialog.set_version(VERSION)
    dialog.set_comments(_("Font management for the GNOME Desktop"))
    dialog.set_copyright(u"Copyright \u00A9 2009 Jerry Casiano")
    dialog.set_authors(AUTHORS)
    dialog.set_website('font-manager.googlecode.com')
    dialog.set_license(LICENSE_TEXT)
    dialog.run()
    dialog.destroy()

def on_help(unused_widget):
    """
    Opens users preferred browser to our help pages
    """
    help_files = "'%s/doc/en_US.html'" % PACKAGE_DIR
    xdg = '/usr/bin/xdg-open'
    lxdg = '/usr/local/bin/xdg-open'
    fire = '/usr/bin/firefox'
    lfire = '/usr/local/bin/firefox'
    # Try xdg first
    if os.path.exists(xdg) or os.path.exists(lxdg):
        cmd = 'xdg-open %s' % help_files
        try:
            logging.info("Launching Help browser")
            subprocess.call(cmd, shell=True)
        except OSError, error:
            logging.error("Error: %s" % error)
    # Fall back to firefox or nothing
    elif os.path.exists(fire) or os.path.exists(lfire):
        cmd = 'firefox %s' % help_files
        try:
            logging.info("Launching Help browser")
            subprocess.call(cmd, shell=True)
        except OSError, error:
            logging.error("Error: %s" % error)
    else:
        logging.warn("Could not find any suitable browser")
    return

def on_font_preferences(unused_widget):
    """
    Launches gnome-appearance-properties with the fonts tab active
    """
    try:
        cmd = "gnome-appearance-properties --show-page=fonts &"
        logging.info("Launching font preferences dialog")
        subprocess.call(cmd, shell=True)
    except OSError, error:
        logging.error("Error: %s" % error)
    return

def on_manage_fonts(unused_widget):
    """
    Opens users preferred file browser to the users default font folder
    """
    if not os.path.exists(USER_FONT_DIR):
        logging.warn("No font directory found for " + USER)
        logging.info("Creating font directory")
        os.mkdir(USER_FONT_DIR, 0775)
        install_readme()
    else:
        logging.info("Found font directory for " + USER)

    config = ConfigParser.ConfigParser()
    config.read(INI)
    try:
        default_dir = config.get('Font Folder', 'default')
        font_dir = default_dir
    except ConfigParser.NoSectionError:
        font_dir = USER_FONT_DIR

    xdg = '/usr/bin/xdg-open'
    lxdg = '/usr/local/bin/xdg-open'
    # Try xdg-open first
    if os.path.exists(xdg) or os.path.exists(lxdg):
        try:
            logging.info('Opening font folder')
            subprocess.Popen(['xdg-open', font_dir])
            return
        except OSError:
            logging.info(' xdg-open is not available? ')
            logging.info('Looking for common file browsers')
    else:
        # Fallback to looking for specific file browsers
        file_browser = find_file_browser()
        launch_file_browser(file_browser, font_dir)
    return

README =_("""* This file was placed here by Font Manager because this directory 
did not exist, feel free to delete, it will not be generated again.


This is a per-user font directory.


Any fonts ( or folders containing fonts ) present in this directory are 
automatically picked up by the system and available, but only to you.


Please note that not only can you specify other directories to scan for 
fonts from the applications preferences dialog, but you can also set the 
default folder that's opened when 'Manage Fonts' is selected.


If you wish to make fonts available to everyone using the system they will 
need to be placed in /usr/share/fonts

""")

def install_readme():
    RM = os.path.join(USER_FONT_DIR, 'Read Me.txt')
    readme = open(RM, 'w')
    readme.write(README)
    readme.close()

def find_file_browser():
    """
    Looks for common file browsers, if xdg-open is unavailable
    """
    if os.path.exists("/usr/bin/nautilus") or \
    os.path.exists("/usr/local/bin/nautilus"):
        logging.info("Found Nautilus File Browser")
        file_browser = "nautilus"
    elif os.path.exists("/usr/bin/thunar") or \
    os.path.exists("/usr/local/bin/thunar"):
        logging.info("Found Thunar File Browser")
        file_browser = "thunar"
    elif os.path.exists("/usr/bin/dolphin") or \
    os.path.exists("/usr/local/bin/dolphin"):
        logging.info("Found Dolphin File Browser")
        file_browser = "dolphin"
    elif os.path.exists("/usr/bin/konqueror") or \
    os.path.exists("/usr/local/bin/konqueror"):
        logging.info("Found Konqueror File Browser")
        file_browser = "konqueror"
    else:
        logging.info("Could not find a supported File Browser")
        file_browser = None
    return file_browser

def launch_file_browser(file_browser, font_dir):
    """
    Launches file browser, displays a dialog if none was found
    """
    if file_browser is None:
        dialog = gtk.MessageDialog(None,
        gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR,
        gtk.BUTTONS_CLOSE,
_("""Supported file browsers include :

- Nautilus
- Thunar
- Dolphin
- Konqueror

If a supported file browser is installed,
please file a bug against Font Manager"""))
        dialog.set_title(_("Please install a supported file browser"))
        dialog.run()
        dialog.destroy()
        return

    if file_browser == "nautilus":
        try:
            logging.info("Launching Nautilus")
            subprocess.Popen([file_browser, "--no-desktop", font_dir])
        except OSError, error:
            logging.error("Error: %s" % error)
    elif file_browser == "thunar":
        try:
            logging.info("Launching Thunar")
            subprocess.Popen([file_browser, font_dir])
        except OSError, error:
            logging.error("Error: %s" % error)
    elif file_browser == "dolphin":
        try:
            logging.info("Launching Dolphin")
            subprocess.Popen([file_browser, font_dir])
        except OSError, error:
            logging.error("Error: %s" % error)
    elif file_browser == "konqueror":
        try:
            logging.info("Launching Konqueror")
            subprocess.Popen([file_browser, font_dir])
        except OSError, error:
            logging.error("Error: %s" % error)
    return
