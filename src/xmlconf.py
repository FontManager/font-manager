# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2008 Karl Pickett <http://fontmanager.blogspot.com/>
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


import os
import logging
import libxml2

from os.path import exists

import config
from fontload import g_fonts, g_font_files
from stores import Pattern
from config import USER, USER_FONT_CONF, USER_FONT_CONF_BACKUP, \
USER_FONT_CONF_INVALID, FM_DIR, FM_BLOCK_CONF, FM_BLOCK_CONF_TMP, \
INCLUDE_LINE, LOG_FILE, LOG_FILE_BACKUP, valid_config


class CheckInstall:
    """ 
    Ensures required files are correct and present in users home directory. 
    """
    def __init__(self):

        if exists(LOG_FILE):
            os.rename(LOG_FILE, LOG_FILE_BACKUP)
            log = open(LOG_FILE, 'w')
            log.write('\n')
            log.close()            
            
        if not exists(FM_DIR):
            print "This appears to be the first run"
            print "Creating %s" % FM_DIR
            os.mkdir(FM_DIR)
            try:
                log = open(LOG_FILE, 'w')
                log.write('\n')
                log.close()
            except:
                print "Error creating log file, logging disabled"
                
        try:
            # to send messages somewhere useful
            logging.basicConfig(filename=LOG_FILE,
                                format='%(asctime)s - %(levelname)s - %(message)s',
                                datefmt='%b %d %Y %H:%M:%S',
                                level=logging.DEBUG,filemode='w')
            # send them to the console too
            console = logging.StreamHandler()
            console.setLevel(logging.DEBUG)
            formatter = logging.Formatter('%(levelname)-8s:  %(message)s')
            console.setFormatter(formatter)
            logging.getLogger('').addHandler(console)
        except:
            print "failed to find/create log file, logging disabled"
        
        logging.info("Font Manager is now starting")
            
        self.validate_config()
        
        if self.included(): pass
        else: self.include()
            
        
    def include(self):
        import fileinput
        for line in fileinput.input(USER_FONT_CONF, inplace=1):
            print line[:-1]
            if line.startswith('<fontconfig>'):
                print INCLUDE_LINE
        
    def included(self):
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
            else: 
                doc.freeDoc()
                return False
            
    def validate_config(self):
        # if we can't parse it, it's broken, replace it
        if exists(USER_FONT_CONF):
            try:
                logging.info("Validating %s" % USER_FONT_CONF)
                parser = libxml2.parseFile(USER_FONT_CONF)
                logging.info("Successfully parsed %s" % USER_FONT_CONF)
                parser.freeDoc()
            except UnboundLocalError:
                self.parse_file_failed()
                check_libxml2_leak()
            except libxml2.parserError:
                self.parse_file_failed()
                check_libxml2_leak()
            return 
        else:
            logging.info\
            ("Could not find a font configuration file for %s" % USER)
            logging.info("Creating %s" % USER_FONT_CONF)
            self.write_valid_config()
        check_libxml2_leak()
    
    
    def parse_file_failed(self):
        logging.warn("Parsing of %s failed !" % USER_FONT_CONF)
        # in case the user or another app has modified it
        # move it to users home directory for inspection
        logging.info\
        ("Moving invalid file to %s for inspection" % USER_FONT_CONF_INVALID)
        logging.info("Replacing it with a valid file")
        os.rename(USER_FONT_CONF, USER_FONT_CONF_INVALID)
        logging.info("Creating %s" % USER_FONT_CONF)
        self.write_valid_config()
        
        
    def write_valid_config(self):
        f = open(USER_FONT_CONF, 'w')
        f.write(valid_config)
        f.close()
        logging.info("Wrote %s" % USER_FONT_CONF)
    
    
def add_patelt_node(parent, type, val):
    pi = parent.newChild(None, "patelt", None)
    pi.setProp("name", type)
    str = pi.newChild(None, "string", val)

def get_fontconfig_patterns(node, patterns):
    for n in node.xpathEval('pattern'):
        p = Pattern()
        for c in n.xpathEval('patelt'):
            name = c.prop("name")
            if name == "family":
                p.family = c.xpathEval('string')[0].content
        if p.family:
            patterns.append(p)

def get_family_from_glob(reject, index, families):
    file_path = reject.xpathEval('//glob')[index].content
    for family, files in g_font_files.iteritems():
        for file in files:
            if file == file_path:
                families.append(family)

def save_blacklist():
    # XXX maybe use gobject.idle_add() to call this function so
    # it doesn't bring down the desktop if someone tries to 
    # save thousands of changes, split at 500 or 1000 rejects
    # and start a new .conf file ?
    import re
    
    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "fontconfig", None)
    n = root.newChild(None, "selectfont", None)
    n = n.newChild(None, "rejectfont", None)

    for font in g_fonts.itervalues():
        if not font.enabled:
            # check for ampersand in names, if found use glob
            # to avoid unterminated entity reference errors
            if re.search('&', font.family):
                glob = g_font_files.get(font.family, None)
                n.newChild(None, "glob", glob[0])
            else:
                p = n.newChild(None, "pattern", None)
                add_patelt_node(p, "family", font.family)

    doc.saveFormatFile(FM_BLOCK_CONF, format=1)
    doc.freeDoc()
    logging.info("Changes applied")
    check_libxml2_leak()   

def load_blacklist():
    
    filename = FM_BLOCK_CONF_TMP
    
    if not exists(filename):
        return 
    
    try:
        doc = libxml2.parseFile(filename)
    except:
        # XXX Need to log error here ? possibly empty or corrupt config
        # backup file, inform user, etc
        info.warn(_("Failed to parse blacklist!"))
        return
    
    # normal
    patterns = []
    rejects = doc.xpathEval('//rejectfont')
    for reject in rejects:
        get_fontconfig_patterns(reject, patterns)
    # now check for globs
    families = []
    rejects = doc.xpathEval('//glob')
    for reject in rejects:
        max = len(rejects)
        index = 0
        while index < max:
            get_family_from_glob(reject, index, families)
            index += 1
    
    doc.freeDoc()
    
    for p in patterns:
        font = g_fonts.get(p.family, None)
        if font:
            font.enabled = False
    for f in families:
        font = g_fonts.get(f, None)
        if font:
            font.enabled = False

    check_libxml2_leak()

def blacklist(pattern):
    font = g_fonts.get((pattern.family), None)
    if font:
        font.enabled = False

def enable_blacklist():
    if exists(FM_BLOCK_CONF_TMP):
        if exists(FM_BLOCK_CONF):
            os.unlink(FM_BLOCK_CONF)
        os.rename(FM_BLOCK_CONF_TMP, FM_BLOCK_CONF)

def disable_blacklist():
    if exists(FM_BLOCK_CONF):
        if exists(FM_BLOCK_CONF_TMP):
            os.unlink(FM_BLOCK_CONF_TMP)
        os.rename(FM_BLOCK_CONF, FM_BLOCK_CONF_TMP)

def check_libxml2_leak():
    libxml2.cleanupParser()
    leak = libxml2.debugMemory(1)
    
    if leak > 0:
        logging.debug("libxml2 --> memory leak %s bytes" % (leak))
        libxml2.dumpMemory()
    
def save_config():
    save_blacklist()
