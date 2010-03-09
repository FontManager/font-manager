"""
Font Manager, a font management application for the GNOME desktop
.
"""
#
# Copyright (C) 2009, 2010 Jerry Casiano
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
# Suppress messages related to missing docstrings
# pylint: disable-msg=C0111


AUTHORS = ['\nJerry Casiano\n', _('\nSpecial thanks to:\n'),
'  Karl Pickett',
_('\tFont Manager is based on Karl\'s work'),
'\t< http://fontmanager.blogspot.com >\n',
'  Wouter Bolsterlee',
_('\tFont Manager\'s compare mode is modeled after,'),
_('\tand uses portions of gnome-specimen'),
'\t< https://launchpad.net/gnome-specimen >\n']


import os
import gtk
import gobject
import logging
import subprocess
import ConfigParser
import webbrowser

import loader
import managed
import xmlutils

from common import have_bin
from config import INI, PACKAGE, PACKAGE_DIR, VERSION, USER_FONT_DIR

# Show notifications, if available
MESSAGE = None
try:
    import pynotify
    if not pynotify.init('font-manager'):
        pass
    else:
        MESSAGE = pynotify.Notification
except ImportError:
    pass


class FontManager:
    """
    Font Manager, a font management application for the GNOME desktop
    """
    builder = gtk.Builder()
    builder.set_translation_domain('font-manager')
    def __init__(self):
        # Make sure all needed files are present in users home folder
        xmlutils.check_install()
        # Disable blacklist so all fonts are returned by fc-list
        xmlutils.BlackList.disable_blacklist()
        # Load ui file
        self.builder.add_from_file(os.path.join(PACKAGE_DIR, 'ui/main.ui'))
        get = self.builder.get_object
        self.mainwindow = get("fm_mainwindow")
        about = get('about_button')
        refresh = get('refresh')
        fmhelp = get('help')
        prefs = get('app_prefs')
        self.manage_fonts = get('manage_fonts')
        font_prefs = get("font_preferences")
        export = get("export")
        # Find and set up icon for use throughout app windows
        icon_theme = gtk.icon_theme_get_default()
        try:
            app_icon = icon_theme.load_icon("preferences-desktop-font", 48, 0)
            gtk.window_set_default_icon_list(app_icon)
        except gobject.GError, exc:
            logging.warn("Could not find preferences-desktop-font icon", exc)
            app_icon = None
        # Font preferences, at least for GNOME
        if have_bin('gnome-appearance-properties'):
            font_prefs.set_sensitive(True)
            self.fprefs = True
        else:
            font_prefs.set_sensitive(False)
            self.fprefs = False
            font_prefs.set_tooltip_text\
            (_('This feature requires gnome-appearance-properties'))
        # Export and install_fonts require file-roller
        if have_bin('file-roller'):
            export.set_sensitive(True)
            self.froller = True
        else:
            export.set_sensitive(False)
            self.froller = False
            export.set_tooltip_text(_('This feature requires file-roller'))
        # Connect handlers
        handlers = {
        about : on_about,
        refresh : self.refresh,
        fmhelp : on_help,
        prefs : self.on_prefs,
        export : self.on_export,
        font_prefs : on_font_preferences
        }
        for widget, function in handlers.iteritems():
            widget.connect('clicked', function)
        self.manage_fonts.connect('button-press-event', self.on_manage_fonts)
        # Showtime
        self.mainwindow.set_title(PACKAGE)
        self.mainwindow.set_size_request(800, 500)
        # Find out if user wants window closed or sent to tray
        config = ConfigParser.ConfigParser()
        config.read(INI)
        try:
            tray = config.getboolean('General', 'minimizeonclose')
        except ConfigParser.NoSectionError:
            tray = True
        if tray:
            self.mainwindow.connect('delete-event', delete_handler)
        else:
            self.mainwindow.connect('destroy', self.quit)
        # Find out if user wants the window shown at startup or not
        try:
            hidden = config.getboolean('General', 'minimizeonstart')
        except ConfigParser.NoSectionError:
            hidden = False
        if not hidden:
            self.mainwindow.show()
            while gtk.events_pending():
                gtk.main_iteration()
        # Load fonts, collections, setup treeviews, etc
        self.loader = loader.Load(self.mainwindow, self.builder, app_icon)
        self.loader.initialize(MESSAGE, hidden)
        # Tray icon
        self.tray_icon = \
        gtk.status_icon_new_from_icon_name('preferences-desktop-font')
        self.tray_icon.set_tooltip(_('Font Manager'))
        self.tray_icon.connect('activate', self.tray_icon_clicked)
        self.tray_icon.connect('popup-menu', self.tray_icon_menu)
        return

    def refresh(self, unused_widget):
        self.loader.reboot(MESSAGE)
        return

    def tray_icon_menu(self, unused_widget, button, event_time):
        """
        Popup menu for the tray icon.

        Provides quick access to common functions
        """
        icon_size = gtk.ICON_SIZE_MENU
        imageitem = gtk.ImageMenuItem
        separator = gtk.SeparatorMenuItem
        new_icon = gtk.image_new_from_icon_name
        popup_menu = gtk.Menu()
        sep = separator()
        sep1 = separator()
        sep2 = separator()
        install = imageitem(_('Install fonts'))
        remove = imageitem(_('Remove fonts'))
        font_prefs = imageitem(_('Font Preferences'))
        char_map = imageitem(_('Character Map'))
        prefs = imageitem(_('Preferences'))
        yelp = imageitem(_('Help'))
        about = imageitem(_('About'))
        quit_app = imageitem(_('Quit'))
        install_image = new_icon('gtk-add', icon_size)
        remove_image = new_icon('gtk-remove', icon_size)
        font_prefs_image = new_icon('preferences-desktop-font', icon_size)
        char_map_image = new_icon('accessories-character-map', icon_size)
        prefs_image = new_icon('gtk-preferences', icon_size)
        help_image = new_icon('help-contents', icon_size)
        about_image = new_icon('help-about', icon_size)
        quit_image = new_icon('application-exit', icon_size)
        widgets = {
        install : install_image,
        remove : remove_image,
        font_prefs : font_prefs_image,
        char_map : char_map_image,
        prefs : prefs_image,
        yelp : help_image,
        about : about_image,
        quit_app : quit_image
        }
        for widget, image in widgets.iteritems():
            widget.set_image(image)
        install.connect('activate', managed.InstallFonts,
                    self.mainwindow, self.loader, self.builder, MESSAGE)
        remove.connect('activate', managed.RemoveFonts,
                    self.mainwindow, self.loader, self.builder, MESSAGE)
        font_prefs.connect('activate', on_font_preferences)
        char_map.connect('activate', self.loader.fontviews.on_char_map)
        prefs.connect('activate', self.on_prefs)
        yelp.connect('activate', on_help)
        about.connect('activate', on_about)
        quit_app.connect('activate', self.quit)
        if self.froller:
            for entry in install, remove, sep:
                popup_menu.append(entry)
        if self.fprefs:
            popup_menu.append(font_prefs)
        if self.loader.fontviews.charmap:
            popup_menu.append(char_map)
        for entry in sep1, prefs, yelp, about, sep2, quit_app:
            popup_menu.append(entry)
        popup_menu.show_all()
        popup_menu.popup(None, None, None, button, event_time)

    def tray_icon_clicked(self, unused_widget):
        """
        Show or hide application when tray icon is clicked
        """
        if not self.mainwindow.get_property('visible'):
            self.mainwindow.set_skip_taskbar_hint(False)
            self.mainwindow.present()
        else:
            self.mainwindow.set_skip_taskbar_hint(True)
            self.mainwindow.hide()
        return

    def on_manage_fonts(self, unused_widget, event):
        if event.button != 1:
            return
        icon_size = gtk.ICON_SIZE_MENU
        imageitem = gtk.ImageMenuItem
        new_icon = gtk.image_new_from_icon_name
        popup_menu = gtk.Menu()
        separator = gtk.SeparatorMenuItem()
        install = imageitem(_('Install fonts'))
        remove = imageitem(_('Remove fonts'))
        open_font_folder = imageitem(_('Open fonts folder'))
        install_image = new_icon('gtk-add', icon_size)
        remove_image = new_icon('gtk-remove', icon_size)
        open_image = new_icon('folder-open', icon_size)
        install.set_image(install_image)
        remove.set_image(remove_image)
        open_font_folder.set_image(open_image)
        if self.froller:
            popup_menu.append(install)
            popup_menu.append(remove)
        popup_menu.append(separator)
        popup_menu.append(open_font_folder)
        install.connect('activate', managed.InstallFonts,
                    self.mainwindow, self.loader, self.builder, MESSAGE)
        remove.connect('activate', managed.RemoveFonts,
                    self.mainwindow, self.loader, self.builder, MESSAGE)
        open_font_folder.connect('activate', _open_font_folder)
        popup_menu.show_all()
        popup_menu.attach_to_widget(self.manage_fonts, popup_menu.destroy)
        popup_menu.popup(None, None, None, event.button, event.time)

    def on_prefs(self, unused_widget):
        """
        Displays applications preferences dialog
        """
        from preferences import Preferences
        Preferences(self.mainwindow, self.builder, self.loader, MESSAGE).run()

    def on_export(self, unused_widget):
        """
        Exports selected collection
        """
        from export import Export
        collection = self.loader.treeviews.current_collection
        Export(collection, self.builder)

    def quit(self, unused_widget):
        """
        Saves collection information before exiting
        """
        logging.info("Saving configuration")
        self.loader.treeviews.save()
        xmlutils.check_libxml2_leak()
        logging.info("Exiting...")
        gtk.main_quit()


def on_about(unused_widget):
    """
    Displays about dialog
    """
    gtk.about_dialog_set_url_hook(homepage)
    dialog = gtk.AboutDialog()
    dialog.set_name(PACKAGE)
    dialog.set_version(VERSION)
    dialog.set_comments(_("Font management for the GNOME Desktop"))
    dialog.set_copyright(u"Copyright \u00A9 2009, 2010 Jerry Casiano")
    dialog.set_authors(AUTHORS)
    dialog.set_website('http://font-manager.googlecode.com')
    dialog.set_website_label('Font Manager Homepage')
    dialog.set_license(LICENSE_TEXT)
    dialog.run()
    dialog.destroy()

def homepage(dialog, link):
    if webbrowser.open(link):
        return
    else:
        logging.warn("Could not find any suitable web browser")
    return

def on_help(unused_widget):
    """
    Opens users preferred browser to our help pages
    """
    lang = 'en_US'
    help_files = '%s/doc/%s.html' % (PACKAGE_DIR, lang)
    if webbrowser.open(help_files):
        logging.info("Launching Help browser")
    else:
        logging.warn("Could not find any suitable browser")
    return

def on_font_preferences(unused_widget):
    """
    Launches gnome-appearance-properties with the fonts tab active
    """
    try:
        logging.info("Launching font preferences dialog")
        subprocess.Popen(['gnome-appearance-properties', '--show-page=fonts'])
    except OSError, error:
        logging.error("Error: %s" % error)
    return

def _open_font_folder(unused_widget):
    """
    Opens users preferred file browser to the users default font folder
    """
    config = ConfigParser.ConfigParser()
    config.read(INI)
    try:
        default_dir = config.get('Font Folder', 'default')
        font_dir = default_dir
    except ConfigParser.NoSectionError:
        font_dir = USER_FONT_DIR
    # Try xdg-open first
    if have_bin('xdg-open'):
        try:
            logging.info('Opening font folder')
            subprocess.Popen(['xdg-open', font_dir])
            return
        except OSError, error:
            logging.error('xdg-open failed : %s' % error)
            pass
    else:
        logging.info('xdg-open is not available')
    logging.info('Looking for common file browsers')
    # Fallback to looking for specific file browsers
    file_browser = find_file_browser()
    launch_file_browser(file_browser, font_dir)
    return

def find_file_browser():
    """
    Looks for common file browsers, if xdg-open is unavailable
    """
    file_browser = None
    file_browsers = 'nautilus', 'thunar', 'dolphin', 'konqueror', 'pcmanfm'
    for browser in file_browsers:
        if have_bin(browser):
            logging.info("Found %s File Browser" % browser.capitalize())
            file_browser = browser
            break
    if not file_browser:
        logging.info("Could not find a supported File Browser")
    return file_browser

def launch_file_browser(file_browser, font_dir):
    """
    Launches file browser, displays a dialog if none was found
    """
    if file_browser:
        try:
            logging.info("Launching %s" % file_browser)
            subprocess.Popen([file_browser, font_dir])
        except OSError, error:
            logging.error("Error: %s" % error)
    else:
        dialog = gtk.MessageDialog(None,
        gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR,
        gtk.BUTTONS_CLOSE,
_("""Supported file browsers include :

- Nautilus
- Thunar
- Dolphin
- Konqueror
- PCManFM

If a supported file browser is installed,
please file a bug against Font Manager"""))
        dialog.set_title(_("Please install a supported file browser"))
        dialog.run()
        dialog.destroy()
        return
    return

def delete_handler(window, unused_event):
    """
    PyGTK destroys the window by default so returning True from this function
    tells PyGTK that no further action is needed.

    Returning False would tell PyGTK to perform these actions then go ahead and
    finish up, in other words go ahead and destroy the window after this.
    """
    window.set_skip_taskbar_hint(True)
    window.hide()
    return True

