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
# Suppress 5 warnings due to catch all exceptions
# pylint: disable-msg=W0702

import os
import libxml2
import logging
import shutil

from config import *
from common import match, search


INCLUDE_LINE = """<!-- Added by Font Manager -->
    <include ignore_missing=\"yes\">%s</include>
    <include ignore_missing=\"yes\">%s</include>
<!-- ~~~~~~~~~~~~~~~~~~~~~ -->""" % (FM_BLOCK_CONF, DIRS_CONF)


VALID_CONFIG = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
%s
</fontconfig>""" % INCLUDE_LINE


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
    Searches given value for characters that are illegal or
    discouraged in xml and replaces them, then calls add_patelt_node.

    Keyword arguments:
    node_ref -- parent node
    node value -- family / font name
    """
    node = node_ref
    family = node_value
    if family.find('&'):
        family = family.replace('&', '&amp;')
    if family.find('<'):
        family = family.replace('&', '&lt;')
    if family.find('>'):
        family = family.replace('&', '&gt;')
    if family.find("'"):
        family = family.replace("'", '&apos;')
    if family.find('"'):
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
            if family.find('&amp;'):
                family = family.replace('&amp;', '&')
            if family.find('&lt;'):
                family = family.replace('&lt;', '<')
            if family.find('&gt;'):
                family = family.replace('&gt;', '>')
            if family.find('&apos;'):
                family = family.replace('&apos;', "'")
            if family.find('&quot;'):
                family = family.replace('&quot;', '"')

            if family:
                fam_list.append(family)
    return

def load_directories():
    """
    Load user specified directories from configuration file
    """
    if not os.path.exists(DIRS_CONF) \
    and not os.path.exists(DIRS_CONF_BACKUP):
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

    if os.path.exists(DIRS_CONF):
        if os.path.exists(DIRS_CONF_BACKUP):
            os.unlink(DIRS_CONF_BACKUP)
        os.rename(DIRS_CONF, DIRS_CONF_BACKUP)

    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "fontconfig", None)
    # don't save, it's always added
    for directory in directories:
        if directory == os.path.join(HOME, '.fonts'):
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
    fc_fonts -- a dictionary, see fontload.FontLoad
    """
    def __init__(self, fc_fonts):
        self.fc_fonts = fc_fonts

    def save(self):
        """
        Save list of disabled fonts
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

    def load(self):
        """
        Load list of disabled fonts
        """
        filename = FM_BLOCK_CONF_TMP
        if not os.path.exists(filename):
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
        for family in patterns:
            font = self.fc_fonts.get(family, None)
            if font:
                font.enabled = False


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
        if not os.path.exists(FM_GROUP_CONF):
            if os.path.exists(FM_GROUP_CONF_BACKUP):
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

    def save(self, ctree):
        """
        Saves user defined collections in the right order to an xml file.
        """
        if os.path.exists(FM_GROUP_CONF):
            if os.path.exists(FM_GROUP_CONF_BACKUP):
                os.unlink(FM_GROUP_CONF_BACKUP)
            os.rename(FM_GROUP_CONF, FM_GROUP_CONF_BACKUP)
        # Disconnect the model so the user doesn't see what comes next
        collection_tv = ctree
        collection_tv.set_model(None)
        # _drop_defaults removes any builtin collections from the model
        # and returns an ordered list of user collections.
        order = self._drop_defaults()
        # Start "printing"
        doc = libxml2.newDoc("1.0")
        root = doc.newChild(None, "fontmanager", None)
        try:
            while len(order) != 0:
                name = order[0]
                order.pop(0)
                for collection in self.collections:
                    if collection.name == name:
                        node = root.newChild(None, "fontcollection", None)
                        node.setProp("name", collection.name)
                        for font in collection.fonts:
                            add_valid_node(node, font.family)
        except:
            doc.freeDoc()
            logging.warn("There was a problem saving collection information")
            logging.info("Attempting to restore previous configuration")
            if os.path.exists(FM_GROUP_CONF_BACKUP):
                os.rename(FM_GROUP_CONF_BACKUP, FM_GROUP_CONF)
            else: logging.info("Nothing to restore...")
            return
        doc.saveFormatFile(FM_GROUP_CONF, format=1)
        doc.freeDoc()

    def _drop_defaults(self):
        """
        Drop our default collections from the model
        """
        # Seek and destroy
        allfonts = search(self.collection_ls,
        self.collection_ls.iter_children(None), match, (3, 'All Fonts'))
        if allfonts is not None and self.collection_ls.iter_is_valid(allfonts):
            self.collection_ls.remove(allfonts)       
        
        system = search(self.collection_ls,
        self.collection_ls.iter_children(None), match, (3, 'System'))
        if system is not None and self.collection_ls.iter_is_valid(system):
            self.collection_ls.remove(system)
        
        user = search(self.collection_ls,
        self.collection_ls.iter_children(None), match, (3, 'User'))
        if user is not None and self.collection_ls.iter_is_valid(user):
            self.collection_ls.remove(user)
                
        orphans = search(self.collection_ls,
        self.collection_ls.iter_children(None), match, (3, 'Orphans'))
        if orphans is not None and self.collection_ls.iter_is_valid(orphans):
            self.collection_ls.remove(orphans)
                
        while True:
            separator = search(self.collection_ls,
            self.collection_ls.iter_children(None), match, (1, None))
            if separator is not None and \
            self.collection_ls.iter_is_valid(separator):
                self.collection_ls.remove(separator)
            if separator is None:
                break

        # Get the order of the remaining collections
        order = []
        item = self.collection_ls.get_iter_first()
        while ( item != None ):
            order.append(self.collection_ls.get_value(item, 2))
            item = self.collection_ls.iter_next(item)
        return order


def enable_blacklist():
    """
    Enable blacklist
    """
    if os.path.exists(FM_BLOCK_CONF_TMP):
        if os.path.exists(FM_BLOCK_CONF):
            os.unlink(FM_BLOCK_CONF)
        os.rename(FM_BLOCK_CONF_TMP, FM_BLOCK_CONF)

def disable_blacklist():
    """
    Disable blacklist
    """
    if os.path.exists(FM_BLOCK_CONF):
        if os.path.exists(FM_BLOCK_CONF_TMP):
            os.unlink(FM_BLOCK_CONF_TMP)
        os.rename(FM_BLOCK_CONF, FM_BLOCK_CONF_TMP)


def check_install():
    """
    This is meant to run before the application starts, it ensures
    required files are valid and present in users home directory.

    Also sets up logging for the application.
    """
    check_for_fm_req_dir()
    check_version()
    check_for_logfile()
    setup_logging()
    logging.info("Font Manager is now starting")
    validate_config()
    if fm_included():
        return
    else:
        fm_include()
    return

def check_for_logfile():
    """
    Ensures logfile is present
    """
    if os.path.exists(LOG_FILE):
        os.rename(LOG_FILE, LOG_FILE_BACKUP)
        log = open(LOG_FILE, 'w')
        log.write(' ')
        log.close()
    return

def check_for_fm_req_dir():
    """
    Checks if required application directory exists, creates it if not
    """
    if not os.path.exists(FM_DIR):
        print "This appears to be the first run"
        print "Creating %s" % FM_DIR
        os.mkdir(FM_DIR)
        os.mkdir(CONF_DIR)
        os.mkdir(GROUPS_DIR)
        os.mkdir(LOG_DIR)
        os.mkdir(DB_DIR)
        ver = open(VER, 'w')
        ver.write(' ')
        ver.close()
        log = open(LOG_FILE, 'w')
        log.write(' ')
        log.close()
        
    if not os.path.exists(CONF_DIR):
        os.mkdir(CONF_DIR)
    if not os.path.exists(GROUPS_DIR):
        os.mkdir(GROUPS_DIR)  
    if not os.path.exists(LOG_DIR):
        os.mkdir(LOG_DIR)
        log = open(LOG_FILE, 'w')
        log.write(' ')
        log.close()
    if not os.path.exists(DB_DIR):
        os.mkdir(DB_DIR) 
        
    return

def check_version():
    """
    Check version, update application folder
    """
    if os.path.exists(REV):
        os.unlink(REV)
        os.unlink(USER_FONT_CONF)
        
    if not os.path.exists(VER):
        if not os.path.exists(CONF_DIR):
            os.mkdir(CONF_DIR)
        if not os.path.exists(GROUPS_DIR):
            os.mkdir(GROUPS_DIR)
        if not os.path.exists(LOG_DIR):
            os.mkdir(LOG_DIR)
        if not os.path.exists(DB_DIR):
            os.mkdir(DB_DIR)
        if os.path.exists(OLD_FM_BLOCK_CONF):
            os.renames(OLD_FM_BLOCK_CONF, FM_BLOCK_CONF)
        if os.path.exists(OLD_FM_GROUP_CONF):
            os.renames(OLD_FM_GROUP_CONF, FM_GROUP_CONF)
        if os.path.exists(os.path.join(FM_DIR, 'groups.xml.bak')):
            os.unlink(os.path.join(FM_DIR, 'groups.xml.bak'))
        if os.path.exists(OLD_LOG_FILE_BACKUP):
            os.unlink(OLD_LOG_FILE_BACKUP)
        if os.path.exists(OLD_LOG_FILE):
            shutil.move(OLD_LOG_FILE, LOG_DIR)
        rev = open(VER, 'w')
        rev.write(' ')
        rev.close()
    return

def validate_config():
    """
    Validates ~/.fonts.conf

    If we can't parse it, it's broken, replace it
    """
    if os.path.exists(USER_FONT_CONF):
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
    conf = open(USER_FONT_CONF, 'w')
    conf.write(VALID_CONFIG)
    conf.close()
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
        elif included == FM_CONF:
            i.unlinkNode()
            i.freeNode()
            doc.saveFormatFile(USER_FONT_CONF, format=1)
            doc.freeDoc()
            update_config()
            return True
        else:
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

def update_config():
    """
    Swap our old include line with new ones
    """
    import fileinput
    for line in fileinput.input(USER_FONT_CONF, inplace=1):
        if not line.startswith('<!-- Added by Font Manager -->'):
            print line[:-1]
        if line.startswith('<!-- Added by Font Manager -->'):
            print INCLUDE_LINE

def setup_logging():
    """
    Set logging options
    """
    try:
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
        print "failed to find/create log file, logging disabled"
