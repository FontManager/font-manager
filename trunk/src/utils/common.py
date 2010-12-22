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

from os.path import basename, exists, join, isdir, isfile

import fontutils

from constants import AUTOSTART_DIR, USER_FONT_DIR, HOME, README, CACHE_FILE, \
DATABASE_FILE, ARCH_EXTS, USER_FONT_CONFIG_DIR, USER_FONT_CONFIG_RENDER
from utils.xmlutils import load_directories

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

VALID_CHARS = frozenset(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K',
                        'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
                        'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
                        'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                        's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2',
                        '3', '4', '5', '6', '7', '8', '9', '.', '_', '-', ' ',
                        '(', ')'])


def autostart(startme=True):
    """
    Install or remove a .desktop file when requested
    """
    autostart_file = join(AUTOSTART_DIR, 'font-manager.desktop')
    if startme:
        exists(AUTOSTART_DIR) or os.makedirs(AUTOSTART_DIR, 0755)
        with open(autostart_file, 'w') as start:
            start.write(AUTOSTART)
        os.chmod(autostart_file, 0755)
    else:
        not exists(autostart_file) or os.unlink(autostart_file)
    return

# this is strictly cosmetic
# Todo: make this nice instead of just a stock icon
def begin_drag(widget, context):
    """
    Set custom drag icon.
    """
    context.set_icon_name('font-x-generic', 24, 24)
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

def filename_is_illegal(astring):
    if len(astring) > 255:
        return True
    chars = set([c for c in astring])
    if os.sep in chars or os.linesep in chars:
        return True
    else:
        return False

def filename_is_questionable(astring):
    if len(astring) > 255:
        return True
    chars = set([c for c in astring])
    if chars <= VALID_CHARS:
        return False
    else:
        return True

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
    archiver = """file-roller -a '{0}.{1}' '{2}'""".format(arch_name,
                                                            arch_type, folder)
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
    not exists(CACHE_FILE) or os.unlink(CACHE_FILE)
    return

def delete_database():
    """
    Remove stale cache file
    """
    not exists(DATABASE_FILE) or os.unlink(DATABASE_FILE)
    return

def display_warning(msg, sec_msg = None, parent = None):
    """
    Display a generic error dialog.
    """
    dialog = gtk.MessageDialog(parent, gtk.DIALOG_MODAL, gtk.MESSAGE_WARNING,
                                    gtk.BUTTONS_CLOSE, None)
    dialog.set_size_request(420, -1)
    dialog.set_markup('<b>{0}</b>'.format(msg))
    if sec_msg is not None:
        dialog.format_secondary_text(sec_msg)
    dialog.queue_resize()
    run_dialog(None, dialog, True)
    return

def fc_config_load_user_fonts():
    fontutils.FcClearAppFonts()
    user_dirs = [USER_FONT_DIR]
    for directory in load_directories():
        user_dirs.append(directory)
    fontutils.FcAddAppFontDirs(user_dirs)
    return

def fc_config_reload(*unused_args):
    """
    Work around pango/fontconfig updates breaking previews for disabled fonts.
    """
    fc_config_load_user_fonts()
    for config in os.listdir(USER_FONT_CONFIG_DIR):
        if config.endswith('.conf'):
            fontutils.FcParseConfigFile(join(USER_FONT_CONFIG_DIR, config))
    if exists(USER_FONT_CONFIG_RENDER):
        fontutils.FcParseConfigFile(USER_FONT_CONFIG_RENDER)
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

def open_folder(folder, objects):
    """
    Open given folder in file browser.
    """
    if 'xdg-open' in objects['AppCache']:
        try:
            logging.info('Opening folder : {0}'.format(folder))
            if subprocess.call(['xdg-open', folder]) == 0:
                return
        except OSError, error:
            logging.error('xdg-open failed : {0}'.format(error))
    else:
        logging.info('xdg-open is not available')
    logging.info('Looking for common file browsers')
    # Fallback to looking for specific file browsers
    file_browser = _find_file_browser(objects['AppCache'])
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
            logging.info("Found {0} File Browser".format(browser.capitalize()))
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
            logging.info("Launching {0}".format(file_browser.capitalize()))
            subprocess.Popen([file_browser, folder])
            return
        except OSError, error:
            logging.error("Error: {0}".format(error))
    else:
        display_warning(_("Please install a supported file browser"),
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

def run_dialog(unused_widget = None, dialog = None, destroy = False):
    result = dialog.run()
    if destroy:
        dialog.destroy()
    else:
        dialog.hide()
    while gtk.events_pending():
        gtk.main_iteration()
    return result

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
        for root, dirs, files in os.walk(filepath):
            for path in files:
                fullpath = join(root, path)
                with file(fullpath, 'a'):
                    os.utime(fullpath, tstamp)
    else:
        raise TypeError('Expected a valid file or directory path')
    return False
