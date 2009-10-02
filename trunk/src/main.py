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
# Suppress messages related to missing docstrings
# pylint: disable-msg=C0111


AUTHORS = ['\nJerry Casiano\n', _('\nSpecial thanks to:\n'),
'  Karl Pickett',
_('\tFont Manager is based on Karl\'s work'),
'\t<http://fontmanager.blogspot.com/>\n',
'  Wouter Bolsterlee',
_('\tFont Manager\'s compare mode is modeled after,'),
_('\tand uses portions of gnome-specimen'),
'\t<https://launchpad.net/gnome-specimen>\n']

import os
import gtk
import gobject
import logging
import subprocess
import ConfigParser
import webbrowser

from os.path import exists, join

import loader
import managed
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
        # Disable blacklist so all fonts are returned by fc-list
        xmlutils.BlackList.disable_blacklist()
        # Load ui file
        self.builder.add_from_file(join(PACKAGE_DIR, 'ui/main.ui'))
        self.mainwindow = self.builder.get_object("window")
        # Find out if user wants window closed or sent to tray
        config = ConfigParser.ConfigParser()
        config.read(INI)
        try:
            tray = config.get('Delete Event', 'tray')
            if tray == 'True':
                tray = True
            elif tray == 'False':
                tray = False
        except ConfigParser.NoSectionError:
            tray = True
        #
        if tray:
            self.mainwindow.connect('delete-event', delete_handler)
        else:
            self.mainwindow.connect('destroy', self.quit)
        self.mainwindow.set_title(PACKAGE)
        self.mainwindow.set_size_request(800, 500)
        # Find and set up icon for use throughout app windows
        icon_theme = gtk.icon_theme_get_default()
        try:
            app_icon = icon_theme.load_icon("preferences-desktop-font", 48, 0)
        except gobject.GError, exc:
            logging.warn("Could not find preferences-desktop-font icon", exc)
        gtk.window_set_default_icon_list(app_icon)
        # Font preferences, at least for GNOME
        font_prefs = self.builder.get_object("font_preferences")
        font_prefs.connect('clicked', on_font_preferences)
        if exists('/usr/bin/gnome-appearance-properties') or \
        exists('/usr/local/bin/gnome-appearance-properties'):
            font_prefs.set_sensitive(True)
            self.fprefs = True
        else:
            font_prefs.set_sensitive(False)
            self.fprefs = False
            font_prefs.set_tooltip_text\
            (_('This feature requires gnome-appearance-properties'))
        # Export and install_fonts require file-roller
        export = self.builder.get_object("export")
        export.connect('clicked', self.on_export)
        if exists('/usr/bin/file-roller') or \
        exists('usr/local/bin/file-roller'):
            export.set_sensitive(True)
            self.froller = True
        else:
            export.set_sensitive(False)
            self.froller = False
            export.set_tooltip_text(_('This feature requires file-roller'))
        # Connect handlers
        about = self.builder.get_object('about_button')
        about.connect('clicked', on_about)
        refresh = self.builder.get_object('refresh')
        refresh.connect('clicked', self.refresh)
        fmhelp = self.builder.get_object('help')
        fmhelp.connect('clicked', on_help)
        prefs = self.builder.get_object('app_prefs')
        prefs.connect('clicked', self.on_prefs)
        self.manage_fonts = self.builder.get_object('manage_fonts')
        self.manage_fonts.connect('button-press-event', self.on_manage_fonts)
        # Showtime
        self.mainwindow.show()
        while gtk.events_pending():
            gtk.main_iteration()
        # Load fonts, collections, setup treeviews, etc
        self.loader = loader.Ui(parent=self.mainwindow, builder=self.builder)
        self.loader.initialize()
        # Tray icon
        self.tray_icon = \
        gtk.status_icon_new_from_icon_name('preferences-desktop-font')
        self.tray_icon.set_tooltip(_('Font Manager'))
        self.tray_icon.connect('activate', self.tray_icon_clicked)
        self.tray_icon.connect('popup-menu', self.tray_icon_menu)

    def refresh(self, unused_widget):
        self.loader.reboot()
        return

    def tray_icon_menu(self, unused_widget, button, event_time):
        """
        Popup menu for the tray icon.

        Provides quick access to common functions
        """
        popup_menu = gtk.Menu()
        separator = gtk.SeparatorMenuItem()
        separator1 = gtk.SeparatorMenuItem()
        separator2 = gtk.SeparatorMenuItem()
        install = gtk.ImageMenuItem(_('Install fonts'))
        remove = gtk.ImageMenuItem(_('Remove fonts'))
        font_prefs = gtk.ImageMenuItem(_('Font Preferences'))
        char_map = gtk.ImageMenuItem(_('Character Map'))
        prefs = gtk.ImageMenuItem(_('Preferences'))
        yelp = gtk.ImageMenuItem(_('Help'))
        about = gtk.ImageMenuItem(_('About'))
        quit_app = gtk.ImageMenuItem(_('Quit'))
        install_image = gtk.image_new_from_icon_name('gtk-add',
                                                        gtk.ICON_SIZE_MENU)
        install.set_image(install_image)
        remove_image = gtk.image_new_from_icon_name('gtk-remove',
                                                        gtk.ICON_SIZE_MENU)
        remove.set_image(remove_image)
        font_prefs_image = gtk.image_new_from_icon_name(
                            'preferences-desktop-font', gtk.ICON_SIZE_MENU)
        font_prefs.set_image(font_prefs_image)
        char_map_image = gtk.image_new_from_icon_name(
                            'accessories-character-map', gtk.ICON_SIZE_MENU)
        char_map.set_image(char_map_image)
        prefs_image = gtk.image_new_from_icon_name('gtk-preferences',
                                                        gtk.ICON_SIZE_MENU)
        prefs.set_image(prefs_image)
        help_image = gtk.image_new_from_icon_name('help-contents',
                                                        gtk.ICON_SIZE_MENU)
        yelp.set_image(help_image)
        about_image = gtk.image_new_from_icon_name('help-about',
                                                        gtk.ICON_SIZE_MENU)
        about.set_image(about_image)
        quit_image = gtk.image_new_from_icon_name('application-exit',
                                                        gtk.ICON_SIZE_MENU)
        quit_app.set_image(quit_image)
        install.connect('activate', managed.InstallFonts,
                                self.mainwindow, self.loader, self.builder)
        remove.connect('activate', managed.RemoveFonts,
                                self.mainwindow, self.loader, self.builder)
        font_prefs.connect('activate', on_font_preferences)
        char_map.connect('activate', self.loader.fontviews.on_char_map)
        prefs.connect('activate', self.on_prefs)
        yelp.connect('activate', on_help)
        about.connect('activate', on_about)
        quit_app.connect('activate', self.quit)
        if self.froller:
            popup_menu.append(install)
            popup_menu.append(remove)
            popup_menu.append(separator)
        if self.fprefs:
            popup_menu.append(font_prefs)
        if self.loader.fontviews.charmap:
            popup_menu.append(char_map)
        popup_menu.append(separator1)
        popup_menu.append(prefs)
        popup_menu.append(yelp)
        popup_menu.append(about)
        popup_menu.append(separator2)
        popup_menu.append(quit_app)
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
        popup_menu = gtk.Menu()
        separator = gtk.SeparatorMenuItem()
        install = gtk.ImageMenuItem(_('Install fonts'))
        remove = gtk.ImageMenuItem(_('Remove fonts'))
        open_font_folder = gtk.ImageMenuItem(_('Open fonts folder'))
        install_image = gtk.image_new_from_icon_name('gtk-add',
                                                        gtk.ICON_SIZE_MENU)
        install.set_image(install_image)
        remove_image = gtk.image_new_from_icon_name('gtk-remove',
                                                        gtk.ICON_SIZE_MENU)
        remove.set_image(remove_image)
        open_image = gtk.image_new_from_icon_name('folder-open',
                                                        gtk.ICON_SIZE_MENU)
        open_font_folder.set_image(open_image)
        if self.froller:
            popup_menu.append(install)
            popup_menu.append(remove)
        popup_menu.append(separator)
        popup_menu.append(open_font_folder)
        install.connect('activate', managed.InstallFonts,
                                self.mainwindow, self.loader, self.builder)
        remove.connect('activate', managed.RemoveFonts,
                                self.mainwindow, self.loader, self.builder)
        open_font_folder.connect('activate', _open_font_folder)
        popup_menu.show_all()
        popup_menu.attach_to_widget(self.manage_fonts, detach_popup)
        popup_menu.popup(None, None, None, event.button, event.time)

    def on_prefs(self, unused_widget):
        """
        Displays applications preferences dialog
        """
        from preferences import Preferences
        Preferences(self.mainwindow, self.builder, self.loader).run()

    def on_export(self, unused_widget):
        """
        Exports selected collection
        """
        from export import Export
        collection = self.loader.treeviews.current_collection
        Export(collection)

    def quit(self, unused_widget):
        """
        Saves collection information before exiting
        """
        logging.info("Saving configuration")
        self.loader.treeviews.save()
        xmlutils.check_libxml2_leak()
        logging.info("Exiting...")
        gtk.main_quit()

def detach_popup(menu, unused_widget):
    menu.destroy()
    return

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
    if exists('/usr/bin/xdg-open') or exists('/usr/local/bin/xdg-open'):
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

def find_file_browser():
    """
    Looks for common file browsers, if xdg-open is unavailable
    """
    if exists("/usr/bin/nautilus") or \
    exists("/usr/local/bin/nautilus"):
        logging.info("Found Nautilus File Browser")
        file_browser = "nautilus"
    elif exists("/usr/bin/thunar") or \
    exists("/usr/local/bin/thunar"):
        logging.info("Found Thunar File Browser")
        file_browser = "thunar"
    elif exists("/usr/bin/dolphin") or \
    exists("/usr/local/bin/dolphin"):
        logging.info("Found Dolphin File Browser")
        file_browser = "dolphin"
    elif exists("/usr/bin/konqueror") or \
    exists("/usr/local/bin/konqueror"):
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

If a supported file browser is installed,
please file a bug against Font Manager"""))
        dialog.set_title(_("Please install a supported file browser"))
        dialog.run()
        dialog.destroy()
        return
    return

def delete_handler(window, unused_event):
    """
    This handler is required so that the window isn't actually destroyed when
    close button is pressed, just connecting it to hide_on_delete is not enough.

    PyGTK destroys the window by default so returning True from this function
    is necessary, it tells PyGTK that no further action is needed.

    Returning False would tell PyGTK to perform these actions then go ahead and
    finish up, in other words go ahead and destroy the window after this.
    """
    window.set_skip_taskbar_hint(True)
    window.hide()
    return True
