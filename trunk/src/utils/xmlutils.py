"""
This module is used to group any functions which make use of libxml2.
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


import os
import glib
import libxml2
import logging

from os.path import exists

from constants import USER_FONT_DIR, USER_FONT_CONFIG_DIRS, \
                        USER_FONT_CONFIG_SELECT, USER_FONT_CONFIG_DESELECT, \
                        USER_FONT_COLLECTIONS, USER_FONT_COLLECTIONS_BAK


def add_patelt_node(node_ref, node_value, pat_name='family', val_type='string'):
    """
    Write a valid fontconfig patelt node.

    node_ref -- parent node
    node_value -- value to match

    Keyword arguments:

    pat_name -- a valid fontconfig font property
    val_type -- value type

    <parent>
        <patelt name=pat_name>
            <val_type>node_value</val_type>
        </patelt>
    </parent>
    """
    if pat_name == 'family':
        val = glib.markup_escape_text(node_value)
    else:
        val = node_value
    parent = node_ref.newChild(None, "pattern", None)
    child = parent.newChild(None, "patelt", None)
    child.setProp("name", pat_name)
    child.newChild(None, val_type, val)
    return

def check_libxml2_leak():
    """
    Cleanup function, it should be called before the application exits
    but after saving any xml configuration files.
    """
    libxml2.cleanupParser()
    leak = libxml2.debugMemory(1)
    if leak > 0:
        logging.debug("libxml2 --> memory leak %s bytes" % (leak))
    return

def get_blacklisted():
    """
    Return list of disabled fonts
    """
    rejects_file = USER_FONT_CONFIG_SELECT
    if not exists(rejects_file):
        if exists(USER_FONT_CONFIG_DESELECT):
            rejects_file = USER_FONT_CONFIG_DESELECT
        else:
            return
    try:
        doc = libxml2.parseFile(rejects_file)
    except libxml2.parserError:
        logging.warn('Failed to parse blacklist!')
        return
    families = []
    rejects = doc.xpathEval('//rejectfont')
    for reject in rejects:
        _get_fc_families(reject, families)
    doc.freeDoc()
    return families

def _get_fc_families(node, families):
    """
    Process a given node looking for patelt nodes named "family",
    if found retrieve value and append it to supplied list.

    Keyword arguments:

    node -- node to search
    patterns -- list to append retrieved values to

    """
    for pattern in node.xpathEval('pattern'):
        for entry in pattern.xpathEval('patelt'):
            name = entry.prop("name")
            if name == "family":
                family = entry.xpathEval('string')[0].content
            if family:
                families.append(family)
    return

def load_directories():
    """
    Load user specified directories from configuration file
    """
    if not exists(USER_FONT_CONFIG_DIRS):
        return
    try:
        doc = libxml2.parseFile(USER_FONT_CONFIG_DIRS)
    except libxml2.parserError:
        logging.warn("Failed to parse user directories configuration!")
        return
    directories = doc.xpathEval('//dir')
    if len(directories) == 0:
        doc.freeDoc()
        return
    for directory in directories:
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

def save_blacklist(families):
    """
    Save list of disabled fonts to configuration file.
    """
    doc = libxml2.newDoc('1.0')
    root = doc.newChild(None, 'fontconfig', None)
    node = root.newChild(None, 'selectfont', None)
    node = node.newChild(None, 'rejectfont', None)
    for family in families:
        add_patelt_node(node, family)
    doc.saveFormatFile(USER_FONT_CONFIG_SELECT, format=1)
    doc.freeDoc()
    logging.info('Changes applied')
    return

def save_directories(directories):
    """
    Save user specified directories to configuration file.
    """
    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "fontconfig", None)
    # don't save, it's always added
    for directory in directories:
        if directory == USER_FONT_DIR:
            directories.remove(directory)
    for path in set(directories):
        root.newChild(None, 'dir', path)
    doc.saveFormatFile(USER_FONT_CONFIG_DIRS, format=1)
    doc.freeDoc()
    logging.info("Changes applied")
    return


def load_collections(fontmanager):
    """
    Load saved collections from an xml file.

    fontmanager - a FontManager instance
    """
    if not exists(USER_FONT_COLLECTIONS):
        if exists(USER_FONT_COLLECTIONS_BAK):
            os.rename(USER_FONT_COLLECTIONS_BAK, USER_FONT_COLLECTIONS)
        else:
            return
    try:
        doc = libxml2.parseFile(USER_FONT_COLLECTIONS)
    except:
        logging.warn("Failed to parse collection configuration")
        return
    order = []
    nodes = doc.xpathEval('//fontcollection')
    for node in nodes:
        families = []
        name = node.prop("name")
        comment = node.prop("comment")
        _get_fc_families(node, families)
        fontmanager.create_collection(name, comment, list(set(families)))
        logging.info('Loaded user collection %s' % name)
        order.append(name)
    doc.freeDoc()
    return order

def save_collections(objects):
    """
    Save user defined collections to an xml file.

    objects -- an ObjectContainer instance
    """
    if exists(USER_FONT_COLLECTIONS):
        if exists(USER_FONT_COLLECTIONS_BAK):
            os.unlink(USER_FONT_COLLECTIONS_BAK)
        os.rename(USER_FONT_COLLECTIONS, USER_FONT_COLLECTIONS_BAK)
    order = _get_collection_order(objects)
    printed = []
    # Start "printing"
    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "fontmanager", None)
    collections = objects['FontManager'].list_collections()
    try:
        while len(order) != 0:
            name = order[0]
            for collection in collections:
                collection = objects['FontManager'].collections[name]
                if collection.name == name and name not in printed:
                    node = root.newChild(None, "fontcollection", None)
                    node.setProp("name", collection.name)
                    node.setProp("comment", collection.comment)
                    for family in collection.families:
                        add_patelt_node(node, family)
                    printed.append(name)
            order.pop(0)
    except:
        doc.freeDoc()
        logging.warn("There was a problem saving collection information")
        logging.info("Attempting to restore previous configuration")
        if exists(USER_FONT_COLLECTIONS_BAK):
            os.rename(USER_FONT_COLLECTIONS_BAK, USER_FONT_COLLECTIONS)
        else:
            logging.info("Nothing to restore...")
        return
    doc.saveFormatFile(USER_FONT_COLLECTIONS, format=1)
    doc.freeDoc()
    return

def _get_collection_order(objects):
    """
    Returns a list of user collections in order

    objects -- an ObjectContainer instance
    """
    order = []
    model = objects['CollectionTree'].get_model()
    parent = model.get_iter_root()
    item = model.iter_children(parent)
    while ( item != None ):
        order.append(model.get_value(item, 0))
        item = model.iter_next(item)
    return order
