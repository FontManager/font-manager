"""
This module is just a convenient place to group re-usable functions.
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
# Disable warnings related to missing docstrings, for now...
# pylint: disable-msg=C0111

import os
import re
import gtk
import glob
import time
import logging
import shlex
import shutil
import subprocess

from os.path import basename, exists, join, isdir, isfile, splitext

import _fontutils

from constants import AUTOSTART_DIR, USER_FONT_DIR, HOME, README, \
USER_FONT_CONFIG_SELECT, USER_FONT_CONFIG_DESELECT, USER_LIBRARY_DIR, \
TMP_DIR, CACHE_FILE, DATABASE_FILE, FONT_EXTS, T1_EXTS, ARCH_EXTS, \
USER_FONT_CONFIG_DIR, USER_FONT_CONFIG_RENDER
from xmlutils import load_directories

AUTOSTART = \
"""[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Font Manager
Name[en_US]=Font Manager
Comment=Preview, compare and manage fonts
Type=Application
Exec=font-manager
Terminal=false
StartupNotify=false
Icon=preferences-desktop-font
Categories=Graphics;Viewer;GNOME;GTK;Publishing;
"""


class AvailableApps(list):
    """
    This class is a list of available applications.
    """
    _defaults = ('dolphin', 'file-roller', 'gnome-appearance-properties',
                'gucharmap', 'konqueror', 'nautilus', 'pcmanfm', 'thunar',
                'xdg-open', 'yelp')
    _dirs = os.getenv('PATH', '/usr/bin:/usr/local/bin').split(':')
    def __init__(self):
        list.__init__(self)
        self.update()

    def have(self, app):
        """
        Return True if app is installed.
        """
        if app in self:
            return True
        else:
            for appdir in self._dirs:
                if exists(join(appdir, app)):
                    return True
        return False

    def update(self, *apps):
        """
        Update self to include apps.

        apps -- an application, list or tuple of applications.
        """
        del self[:]
        for app in self._defaults:
            if self.have(app) and app not in self:
                self.append(app)
        if apps:
            if isinstance(apps[0], str):
                if self.have(apps[0]) and apps[0] not in self:
                    self.append(apps[0])
            elif isinstance(apps[0], (tuple, list)):
                for app in apps[0]:
                    if self.have(app) and app not in self:
                        self.append(app)
        return

    def add_bin_dir(self, dirpath):
        """
        Add a directory to search for installed programs.
        """
        if isdir(dirpath):
            self._dirs.append(dirpath)
            self.update()
            return
        else:
            raise TypeError('%s is not a valid directory path' % dirpath)


def autostart(startme=True):
    """
    Install or remove a .desktop file when requested
    """
    autostart_file = join(AUTOSTART_DIR, 'font-manager.desktop')
    if startme:
        if not exists(AUTOSTART_DIR):
            os.makedirs(AUTOSTART_DIR, 0755)
        with open(autostart_file, 'w') as start:
            start.write(AUTOSTART)
    else:
        if exists(autostart_file):
            os.unlink(autostart_file)
    return

def _convert(char):
    """
    Ensure certain characters don't affect sort order.

    So that a doesn't end up under a-a for example.

    """
    if char.isdigit():
        return int(char)
    else:
        char = char.replace('-', '')
        char = char.replace('_', '')
        return char.lower()

def correct_slider_behavior(widget, event, step = None):
    """
    Correct slider behavior so that up means up and down means down.
    """
    old_val = widget.get_value()
    if step is None:
        step = widget.get_adjustment().get_step_increment()
    if event.direction == gtk.gdk.SCROLL_UP:
        new_val = old_val + step
    else:
        new_val = old_val - step
    widget.set_value(new_val)
    return True

def create_archive_from_folder(arch_name, arch_type, destination,
                                                folder, delete = False):
    """
    Create an archive named arch_name of type arch_type in destination from
    the supplied folder.

    If delete is True, folder will be deleted afterwards
    """
    archiver = 'file-roller -a "%s.%s" "%s"' % (arch_name, arch_type, folder)
    os.chdir(destination)
    roller = subprocess.Popen(shlex.split(archiver))
    # Wait for file-roller to finish
    while roller.poll() is None:
        # Prevent loop from hogging cpu
        time.sleep(0.5)
        # Avoid the main window becoming unresponsive
        while gtk.events_pending():
            gtk.main_iteration()
        continue
    if delete:
        shutil.rmtree(folder, ignore_errors = True)
    os.chdir(HOME)
    return

def delete_cache():
    """
    Remove stale cache file
    """
    if exists(CACHE_FILE):
        os.unlink(CACHE_FILE)
    return

def delete_database():
    """
    Remove stale cache file
    """
    if exists(DATABASE_FILE):
        os.unlink(DATABASE_FILE)
    return

def display_error(msg, sec_msg = None, parent = None):
    """
    Display a generic error dialog.
    """
    dialog = gtk.MessageDialog(parent, gtk.DIALOG_MODAL, gtk.MESSAGE_ERROR,
                                    gtk.BUTTONS_CLOSE, None)
    dialog.set_size_request(420, -1)
    dialog.set_markup('<b>%s</b>' % msg)
    if sec_msg is not None:
        dialog.format_secondary_text(sec_msg)
    dialog.queue_resize()
    dialog.run()
    dialog.destroy()
    return

def do_library_cleanup(root_dir = None):
    """
    Removes empty leftover directories and ensures correct permissions.
    """
    if not root_dir:
        root_dir = USER_LIBRARY_DIR
    # Two passes here to get rid of empty top level directories
    passes = 0
    while passes <= 1:
        for root, dirs, files in os.walk(root_dir):
            if not len(dirs) > 0 and root != root_dir:
                keep = False
                for filename in files:
                    if filename.endswith(FONT_EXTS):
                        keep = True
                        break
                if not keep:
                    shutil.rmtree(root)
        passes += 1
    # Make sure we don't have any executables among our 'managed' files
    # and make sure others have read-only access, apparently this can be
    # an issue for some programs
    for root, dirs, files in os.walk(root_dir):
        for directory in dirs:
            os.chmod(join(root, directory), 0755)
        for filename in files:
            os.chmod(join(root, filename), 0644)
    return

def fc_config_load_user_dirs():
    _fontutils.FcClearAppFonts()
    _fontutils.FcAddAppFontDir(USER_FONT_DIR)
    for directory in load_directories():
        _fontutils.FcAddAppFontDir(directory)
    return

def fc_config_reload(*unused_args):
    """
    Work around pango/fontconfig updates breaking previews for disabled fonts.
    """
    fc_config_load_user_dirs()
    for config in os.listdir(USER_FONT_CONFIG_DIR):
        if config.endswith('.conf'):
            _fontutils.FcParseConfigFile(join(USER_FONT_CONFIG_DIR, config))
    if exists(USER_FONT_CONFIG_RENDER):
        _fontutils.FcParseConfigFile(USER_FONT_CONFIG_RENDER)
    return

def finish_font_install(library = None):
    """
    Organize fonts alphabetically and move them to library.
    """
    if not library:
        library = USER_LIBRARY_DIR
    for root, dirs, files in os.walk(TMP_DIR):
        for directory in dirs:
            fullpath = join(root, directory)
            new = directory[0]
            new = new.upper()
            newpath = join(library, new)
            if not exists(newpath):
                os.mkdir(newpath)
            newname = join(newpath, directory)
            if exists(newname):
                shutil.rmtree(newname, ignore_errors=True)
            shutil.move(fullpath, newname)
    for root, dirs, files in os.walk(TMP_DIR):
        for name in files:
            if name.endswith(FONT_EXTS):
                oldpath = join(root, name)
                truename = name.split('.')[0]
                truename = name.strip()
                new = truename[0]
                new = new.upper()
                newpath = join(library, new)
                if not exists(newpath):
                    os.mkdir(newpath)
                newname = join(newpath, name)
                if exists(newname):
                    shutil.rmtree(newname, ignore_errors=True)
                shutil.move(oldpath, newname)
                if oldpath.endswith(T1_EXTS):
                    metrics = splitext(oldpath)[0] + '.*'
                    for path in glob.glob(metrics):
                        shutil.move(path, newpath)
    do_library_cleanup(library)
    shutil.rmtree(TMP_DIR, ignore_errors=True)
    return

def install_font_archive(filepath):
    dir_name = strip_archive_ext(basename(filepath))
    arch_dir = join(TMP_DIR, dir_name)
    if exists(arch_dir):
        i = 0
        while exists(arch_dir):
            arch_dir = arch_dir + str(i)
            i += 1
    os.mkdir(arch_dir)
    subprocess.call(['file-roller', '-e', arch_dir, filepath])
    # Todo: Need to check whether archive actually contained any fonts
    # if user_is_stupid:
    #     self.notify()
    # ;-p
    return

def install_readme():
    """
    Install a readme into ~/.fonts if it didn't previously exist

    Really just intended for users new to linux ;-)
    """
    with open(join(USER_FONT_DIR, _('Read Me.txt')), 'w') as readme:
        readme.write(README)
    return

def match(model, treeiter, data):
    """
    Tries to match a value with those in the given treemodel
    """
    column, key = data
    value = model.get_value(treeiter, column)
    return value == key

def mkfontdirs(root_dir = USER_LIBRARY_DIR):
    """
    Recursively generate fonts.scale and fonts.dir for folders containing
    font files.
    Not sure these files are even necessary but it doesn't hurt anything.
    """
    for root, dirs, files in os.walk(root_dir):
        if not len(dirs) > 0 and root != root_dir:
            if len(files) > 0:
                for filename in files:
                    if filename.endswith(FONT_EXTS):
                        try:
                            subprocess.call(['mkfontscale', root])
                            subprocess.call(['mkfontdir', root])
                        except:
                            pass
                        break
    return

def natural_sort(alist):
    """
    Sort the given iterable in the way that humans expect.
    """
    alphanum = lambda key: [ _convert(c) for c in re.split('([0-9]+)', key) ]
    return sorted(alist, key=alphanum)

def natural_sort_pathlist(alist):
    """
    Sort the given list of filepaths in the way that humans expect.
    """
    alphanum = lambda key: [ _convert(c) for c in re.split('([0-9]+)',
                                                            basename(key)) ]
    return sorted(alist, key=alphanum)

def natural_size(size):
    """
    Return given size in a format suitable for display to users.
    """
    size = float(size)
    for unit in ('bytes', 'kB', 'MB', 'GB', 'TB'):
        if size < 1000.0:
            return "%3.1f %s" % (size, unit)
        size /= 1000.0

def open_folder(folder, objects = None):
    """
    Open given folder in file browser.
    """
    if objects:
        applist = objects['AvailableApps']
    else:
        applist = AvailableApps()
    if 'xdg-open' in applist:
        try:
            logging.info('Opening folder : %s' % folder)
            subprocess.Popen(['xdg-open', folder])
            return
        except OSError, error:
            logging.error('xdg-open failed : %s' % error)
    else:
        logging.info('xdg-open is not available')
    logging.info('Looking for common file browsers')
    # Fallback to looking for specific file browsers
    file_browser = _find_file_browser(applist)
    _launch_file_browser(file_browser, folder)
    return

def _find_file_browser(applist):
    """
    Look for common file browsers.
    """
    file_browser = None
    file_browsers = 'nautilus', 'thunar', 'dolphin', 'konqueror', 'pcmanfm'
    for browser in file_browsers:
        if browser in applist:
            logging.info("Found %s File Browser" % browser.capitalize())
            file_browser = browser
            break
    if not file_browser:
        logging.info("Could not find a supported File Browser")
    return file_browser

def _launch_file_browser(file_browser, folder):
    """
    Launches file browser, displays a dialog if none was found
    """
    if file_browser:
        try:
            logging.info("Launching %s" % file_browser)
            subprocess.Popen([file_browser, folder])
            return
        except OSError, error:
            logging.error("Error: %s" % error)
    else:
        display_error(_("Please install a supported file browser"),
    _("""    Supported file browsers include :
    
    - Nautilus
    - Thunar
    - Dolphin
    - Konqueror
    - PCManFM
    
    If a supported file browser is installed,
    please file a bug against Font Manager"""))
        return

def reset_fontconfig_cache():
    """
    Clear all fontconfig cache files in users home directory.
    """
    cache = join(HOME, '.fontconfig', '*.cache-*')
    for path in glob.glob(cache):
        try:
            os.unlink(path)
        except OSError:
            pass
    return

def search(model, treeiter, func, data):
    """
    Used in combination with match to find a particular value in a
    gtk.ListStore or gtk.TreeStore.

    Usage:
    search(liststore, liststore.iter_children(None), match, ('index', 'foo'))
    """
    while treeiter:
        if func(model, treeiter, data):
            return treeiter
        result = search(model, model.iter_children(treeiter), func, data)
        if result:
            return result
        treeiter = model.iter_next(treeiter)
    return None

def strip_archive_ext(filename):
    for ext in ARCH_EXTS:
        filename = filename.replace(ext, '')
    return filename

def touch(filepath, tstamp = None):
    if isfile(filepath):
        with file(filepath, 'a'):
            os.utime(filepath, tstamp)
    elif isdir(filepath):
        for root, dir, files in os.walk(filepath):
            for path in files:
                fullpath = join(root, path)
                with file(fullpath, 'a'):
                    os.utime(fullpath, tstamp)
    else:
        raise TypeError('Expected a valid file or directory path')
    return False
