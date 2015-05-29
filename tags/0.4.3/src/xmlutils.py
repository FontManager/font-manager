"""
This module is used to group any functions which make use of libxml2.
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


import os
import gtk
import libxml2
import logging
import shutil

from os.path import exists, join

from config import *
from common import install_readme
from managed import finish_install


INCLUDE_LINE = """<!-- Added by Font Manager -->
<include ignore_missing=\"yes\">%s</include>
<include ignore_missing=\"yes\">%s</include>
<include ignore_missing=\"yes\">%s</include>
<!-- ~~~~~~~~~~~~~~~~~~~~~ -->""" % \
(DIRS_CONF, FM_BLOCK_CONF, RENDER_CONF)

VALID_CONFIG = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
%s
</fontconfig>
""" % INCLUDE_LINE

FILE_EXTS = ('.ttf', '.ttc', '.otf', '.TTF', '.TTC', '.OTF')


def add_patelt_node(parent, pat_type, val):
    """
    Writes a valid fontconfig patelt node.

    Keyword arguments:
    parent -- parent node
    type -- patelt name
    val -- string value

    <parent>
        <patelt name=type>
            <string>val</string>
        </patelt>
    </parent>
    """
    par = parent.newChild(None, "patelt", None)
    par.setProp("name", pat_type)
    par.newChild(None, "string", val)
    return

def add_valid_node(node_ref, node_value):
    """
    Replaces characters that are illegal or discouraged in xml,
    then calls add_patelt_node.

    Keyword arguments:
    node_ref -- parent node
    node value -- family / font name
    """
    node = node_ref
    family = node_value
    family = family.replace('&', '&amp;')
    family = family.replace('&', '&lt;')
    family = family.replace('&', '&gt;')
    family = family.replace("'", '&apos;')
    family = family.replace('"', '&quot;')
    parent = node.newChild(None, "pattern", None)
    add_patelt_node(parent, "family", family)
    return

def check_libxml2_leak():
    """
    This is a cleanup function, it should be called before the
    application exits but after saving any xml configuration files.
    """
    libxml2.cleanupParser()
    leak = libxml2.debugMemory(1)
    if leak > 0:
        logging.debug("libxml2 --> memory leak %s bytes" % (leak))

def get_fc_patterns(node, fam_list):
    """
    Processes a given node looking for patelt nodes named
    "family", if found retrieves value and appends it to
    supplied list.

    Keyword arguments:
    node -- node to search
    fam_list -- list to append retrieved values to
    """
    for node in node.xpathEval('pattern'):
        for collection in node.xpathEval('patelt'):
            name = collection.prop("name")
            if name == "family":
                family = collection.xpathEval('string')[0].content
                family = family.replace('&amp;', '&')
                family = family.replace('&lt;', '<')
                family = family.replace('&gt;', '>')
                family = family.replace('&apos;', "'")
                family = family.replace('&quot;', '"')
            if family:
                fam_list.append(family)
    return

def load_directories():
    """
    Load user specified directories from configuration file
    """
    if not exists(DIRS_CONF) \
    and not exists(DIRS_CONF_BACKUP):
        return
    try:
        doc = libxml2.parseFile(DIRS_CONF)
    except libxml2.parserError:
        logging.warn("Failed to parse user directories configuration!")
        return
    dirs = doc.xpathEval('//dir')
    if len(dirs) < 1:
        doc.freeDoc()
        return
    for directory in dirs:
        content = directory.getContent()
        if os.path.isdir(content):
            logging.info('Found user specified directory %s' % content)
            yield content
        else:
            logging.warn\
            ('User specified directory %s not found on disk' % content)
            logging.info('Skipping...')
    doc.freeDoc()
    return

def save_directories(dirs):
    """
    Save user specified directories to configuration file
    """
    directories = dirs
    if exists(DIRS_CONF):
        os.unlink(DIRS_CONF)
    if exists(DIRS_CONF_BACKUP):
        os.unlink(DIRS_CONF_BACKUP)
    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "fontconfig", None)
    # don't save, it's always added
    for directory in directories:
        if directory == USER_FONT_DIR:
            directories.remove(directory)
    if len(set(directories)) < 1:
        doc.saveFormatFile(DIRS_CONF, format=1)
        doc.freeDoc()
        return
    for path in set(directories):
        root.newChild(None, 'dir', path)
    doc.saveFormatFile(DIRS_CONF, format=1)
    doc.freeDoc()
    logging.info("Changes applied")


class BlackList:
    """
    Disable or enable fonts.

    Keyword Arguments:
    fc_fonts -- a dictionary, see fontload
    """
    def __init__(self, parent=None, fc_fonts=None):
        self.fc_fonts = fc_fonts
        self.parent = parent

    def save(self):
        """
        Saves list of disabled fonts
        """
        doc = libxml2.newDoc("1.0")
        root = doc.newChild(None, "fontconfig", None)
        node = root.newChild(None, "selectfont", None)
        node = node.newChild(None, "rejectfont", None)
        for font in self.fc_fonts.itervalues():
            if not font.enabled:
                add_valid_node(node, font.family)
        doc.saveFormatFile(FM_BLOCK_CONF, format=1)
        doc.freeDoc()
        logging.info("Changes applied")
        while gtk.events_pending():
            gtk.main_iteration()
        return

    @staticmethod
    def load():
        """
        Loads list of disabled fonts
        """
        filename = FM_BLOCK_CONF_TMP
        if not exists(filename):
            return
        try:
            doc = libxml2.parseFile(filename)
        except:
            logging.warn("Failed to parse blacklist!")
            return
        patterns = []
        rejects = doc.xpathEval('//rejectfont')
        for reject in rejects:
            get_fc_patterns(reject, patterns)
        doc.freeDoc()
        return patterns

    @staticmethod
    def enable_blacklist():
        """
        Enable blacklist
        """
        if exists(FM_BLOCK_CONF_TMP):
            if exists(FM_BLOCK_CONF):
                os.unlink(FM_BLOCK_CONF)
            os.rename(FM_BLOCK_CONF_TMP, FM_BLOCK_CONF)

    @staticmethod
    def disable_blacklist():
        """
        Disable blacklist
        """
        if exists(FM_BLOCK_CONF):
            if exists(FM_BLOCK_CONF_TMP):
                os.unlink(FM_BLOCK_CONF_TMP)
            os.rename(FM_BLOCK_CONF, FM_BLOCK_CONF_TMP)

class Groups:
    """
    Saves or loads user defined collections.

    Keyword arguments:
    clist -- list of available collections
    cmodel -- related gtk.ListStore
    cobject -- a collection object, see fontload.Collection
    fc_fonts -- a dictionary, see fontload.Families
    """
    def __init__(self, clist, cmodel, cobject, fc_fonts):
        self.collections = clist
        self.collection_ls = cmodel
        self.collection = cobject
        self.fc_fonts = fc_fonts

    def load(self):
        """
        Loads saved collections from an xml file.
        """
        if not exists(FM_GROUP_CONF):
            if exists(FM_GROUP_CONF_BACKUP):
                os.rename(FM_GROUP_CONF_BACKUP, FM_GROUP_CONF)
            else: return
        try:
            doc = libxml2.parseFile(FM_GROUP_CONF)
        except:
            logging.warn("Failed to parse collection configuration")
            return
        nodes = doc.xpathEval('//fontcollection')
        for node in nodes:
            patterns = []
            family = []
            name = node.prop("name")
            get_fc_patterns(node, patterns)
            collection = self.collection(name)
            collection.builtin = False
            for family in set(patterns):
                font = self.fc_fonts.get(family)
                if font:
                    collection.fonts.append(font)
            yield collection
        doc.freeDoc()
        return

    def save(self):
        """
        Saves user defined collections to an xml file.
        """
        if exists(FM_GROUP_CONF):
            if exists(FM_GROUP_CONF_BACKUP):
                os.unlink(FM_GROUP_CONF_BACKUP)
            os.rename(FM_GROUP_CONF, FM_GROUP_CONF_BACKUP)
        order = self._get_collection_order()
        printed = []
        # Start "printing"
        doc = libxml2.newDoc("1.0")
        root = doc.newChild(None, "fontmanager", None)
        try:
            while len(order) != 0:
                name = order[0]
                for collection in self.collections:
                    if collection.name == name and name not in printed:
                        node = root.newChild(None, "fontcollection", None)
                        node.setProp("name", collection.name)
                        for font in collection.fonts:
                            add_valid_node(node, font.family)
                        printed.append(name)
                order.pop(0)
        except:
            doc.freeDoc()
            logging.warn("There was a problem saving collection information")
            logging.info("Attempting to restore previous configuration")
            if exists(FM_GROUP_CONF_BACKUP):
                os.rename(FM_GROUP_CONF_BACKUP, FM_GROUP_CONF)
            else:
                logging.info("Nothing to restore...")
            return
        doc.saveFormatFile(FM_GROUP_CONF, format=1)
        doc.freeDoc()

    def _get_collection_order(self):
        """
        Returns a list of user collections in order
        """
        order = []
        item = self.collection_ls.get_iter_first()
        while ( item != None ):
            order.append(self.collection_ls.get_value(item, 2))
            item = self.collection_ls.iter_next(item)
        return order


def check_install():
    """
    This is meant to run before the application starts, it ensures
    required files are valid and present in users home directory.

    Also sets up logging for the application.
    """
    check_for_fm_req_dir()
    check_version()
    setup_logging()
    logging.info("Font Manager is now starting")
    validate_config()
    if fm_included():
        return
    else:
        fm_include()
    return

def check_for_fm_req_dir():
    """
    Checks if required application directory exists, creates it if not
    """
    if not exists(FM_DIR):
        print "This appears to be the first run"
        print "Creating %s" % FM_DIR
        os.mkdir(FM_DIR)
    for DIR in CONF_DIR, GROUPS_DIR, LOG_DIR, DB_DIR, INSTALL_DIRECTORY:
        if not exists(DIR):
            os.mkdir(DIR)
    if not exists(USER_FONT_DIR):
        print "No font directory found for %s" % USER
        print "Creating font directory"
        os.mkdir(USER_FONT_DIR)
        install_readme()
    if not exists(join(USER_FONT_DIR, 'Library')):
        os.symlink(INSTALL_DIRECTORY, join(USER_FONT_DIR, 'Library'))
    # Make sure we have reasonable permissions on anything we own
    DIRS = FM_DIR, CONF_DIR, GROUPS_DIR, LOG_DIR, DB_DIR, \
    INSTALL_DIRECTORY, USER_FONT_DIR, TMP_DIR
    for DIR in DIRS:
        if exists(DIR):
            os.chmod(DIR, 0744)
    # Check for newly installed fonts
    if exists(TMP_DIR):
        finish_install()
    if exists(WORK_DIR):
        shutil.rmtree(WORK_DIR)
    return

def check_version():
    """
    Check version, update application folder
    """
    # Clean up app folder
    if exists(join(FM_DIR, 'temp')):
        shutil.rmtree(join(FM_DIR, 'temp'))
    obsolete = '1', '2', '3'
    for version in obsolete:
        if exists(join(FM_DIR, '0.%s' % version)):
            os.unlink(join(FM_DIR, '0.%s' % version))
            # FIXME: just deleting a config is not cool,
            # but it'll have to do for now
            if exists(USER_FONT_CONF):
                os.unlink(USER_FONT_CONF)
            if version == '1':
                if exists(OLD_FM_BLOCK_CONF):
                    os.renames(OLD_FM_BLOCK_CONF, FM_BLOCK_CONF)
                if exists(OLD_FM_GROUP_CONF):
                    os.renames(OLD_FM_GROUP_CONF, FM_GROUP_CONF)
                if exists(join(FM_DIR, 'groups.xml.bak')):
                    os.unlink(join(FM_DIR, 'groups.xml.bak'))
                if exists(OLD_LOG_FILE_BACKUP):
                    os.unlink(OLD_LOG_FILE_BACKUP)
                if exists(OLD_LOG_FILE):
                    shutil.move(OLD_LOG_FILE, LOG_DIR)
    with open(VER, 'w') as revfile:
        revfile.write('Font Manager %s' % VERSION)
    return

def validate_config():
    """
    Validates ~/.fonts.conf

    If we can't parse it, it's broken, replace it
    """
    # Todo: need this to be strict
    if exists(USER_FONT_CONF):
        try:
            logging.info("Validating %s" % USER_FONT_CONF)
            parser = libxml2.parseFile(USER_FONT_CONF)
            logging.info("Successfully parsed %s" % USER_FONT_CONF)
            parser.freeDoc()
        except libxml2.parserError:
            parse_file_failed()
        except UnboundLocalError:
            parse_file_failed()
        return
    else:
        logging.info\
        ("Could not find a font configuration file for %s" % USER)
        logging.info("Creating %s" % USER_FONT_CONF)
        write_valid_config()
        return

def parse_file_failed():
    """
    Moves invalid file to ~/ and generates a valid one
    """
    logging.warn("Parsing of %s failed !" % USER_FONT_CONF)
    # in case the user or another app has modified it
    # move it to users home directory for inspection
    logging.info\
    ("Moving invalid file to %s for inspection" \
    % USER_FONT_CONF_INVALID)
    logging.info("Replacing it with a valid file")
    os.rename(USER_FONT_CONF, USER_FONT_CONF_INVALID)
    logging.info("Creating %s" % USER_FONT_CONF)
    write_valid_config()

def write_valid_config():
    """
    Writes a valid .fonts.conf file to the users home directory.

    It will overwrite any existing conf file!
    """
    with open(USER_FONT_CONF, 'w') as conf:
        conf.write(VALID_CONFIG)
    logging.info("Wrote %s" % USER_FONT_CONF)

def fm_included():
    """
    Checks if Font Manager is listed in ~/.fonts.conf
    """
    doc = libxml2.parseFile(USER_FONT_CONF)
    includes = doc.xpathEval('//include')
    if len(includes) == 0:
        doc.freeDoc()
        return False
    for i in includes:
        included = i.getContent()
        if included == FM_BLOCK_CONF:
            doc.freeDoc()
            return True
    doc.freeDoc()
    return False

def fm_include():
    """
    Add our include lines to ~/.fonts.conf
    """
    import fileinput
    for line in fileinput.input(USER_FONT_CONF, inplace=1):
        print line[:-1]
        if line.startswith('<fontconfig>'):
            print INCLUDE_LINE

def setup_logging():
    """
    Ensure log exists and set logging options
    """
    try:
        if exists(LOG_FILE):
            os.rename(LOG_FILE, LOG_FILE_BACKUP)
        with open(LOG_FILE, 'w') as log:
            log.write('\n')
        # to send messages somewhere useful
        logging.basicConfig(filename=LOG_FILE,
                            format=\
                        '%(asctime)s - %(levelname)s - %(message)s',
                            datefmt='%b %d %Y %H:%M:%S',
                            level=logging.DEBUG,filemode='w')
        # send them to the console too
        console = logging.StreamHandler()
        console.setLevel(logging.DEBUG)
        formatter = logging.Formatter\
        ('%(levelname)-8s:  %(message)s')
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)
    except:
        print \
    "FontManagerError : failed to find/create log file, logging disabled"

