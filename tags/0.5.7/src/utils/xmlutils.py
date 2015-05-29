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

# Disable warnings related to gettext
# pylint: disable-msg=E0602
# Disable warnings related to missing docstrings, for now...
# pylint: disable-msg=C0111

import os
import glib
import libxml2
import logging
import time

from os.path import exists, join

from constants import USER_FONT_DIR, USER_FONT_CONFIG_DIR, \
                        USER_FONT_CONFIG_DIRS, USER_FONT_CONFIG_SELECT, \
                        USER_FONT_CONFIG_DESELECT, USER_FONT_COLLECTIONS, \
                        USER_FONT_COLLECTIONS_BAK, USER_ACTIONS_CONFIG, \
                        COMPAT_COLLECTIONS
from constants import FC_CHECKBUTTONS, FC_CONSTS, FC_CONSTS_MAP, FC_DEFAULTS, \
                        FC_SKIP, PSLANT, PWEIGHT, FC_WIDGETMAP, PWIDTH

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
        logging.debug("libxml2 --> memory leak {0} bytes".format(leak))
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
                family = _unescape_markup(entry.xpathEval('string')[0].content)
            if family:
                families.append(family)
    return

def load_actions():
    """
    Load any user-configured actions from file.
    """
    results = {}
    if not exists(USER_ACTIONS_CONFIG):
        return results
    try:
        doc = libxml2.parseFile(USER_ACTIONS_CONFIG)
    except libxml2.parserError:
        logging.warn("Failed to parse user actions configuration!")
        return results
    actions = doc.xpathEval('//action')
    if len(actions) == 0:
        doc.freeDoc()
        return results
    for entry in actions:
        action = {}
        action['name'] = _unescape_markup(entry.prop('name'))
        action['comment'] = _unescape_markup(entry.prop('comment'))
        action['executable'] = \
        _unescape_markup(entry.xpathEval('executable')[0].content)
        action['arguments'] = \
        _unescape_markup(entry.xpathEval('arguments')[0].content)
        action['terminal'] = _tobool(entry.xpathEval('terminal')[0].content)
        action['block'] = _tobool(entry.xpathEval('block')[0].content)
        action['restart'] = _tobool(entry.xpathEval('restart')[0].content)
        results[action['name']] = action
    doc.freeDoc()
    return results

def load_alias_settings():
    """
    Load any user-configured aliases from file.
    """
    if not exists(join(USER_FONT_CONFIG_DIR, '35-aliases.conf')):
        return
    try:
        doc = libxml2.parseFile(join(USER_FONT_CONFIG_DIR, '35-aliases.conf'))
    except libxml2.parserError:
        logging.warn("Failed to parse user aliases configuration!")
        return
    aliases = doc.xpathEval('//alias')
    if len(aliases) == 0:
        doc.freeDoc()
        return
    results = {}
    for alias in aliases:
        family = _unescape_markup(alias.xpathEval('family')[0].content)
        results[family] = []
        for prefer in alias.xpathEval('prefer'):
            results[family].append(
                        _unescape_markup(prefer.xpathEval('family')[0].content))
    doc.freeDoc()
    return results

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
            yield content
    doc.freeDoc()
    return

def save_actions(actions):
    """
    Save user-configured "actions" to a file.
    """
    doc = libxml2.newDoc('1.0')
    root = doc.newChild(None, 'actions', None)
    escape = glib.markup_escape_text
    for entry in actions.iterkeys():
        action = actions[entry]
        node = root.newChild(None, 'action', None)
        node.setProp('name', escape(action['name']))
        node.setProp('comment', escape(action['comment']))
        node.newChild(None, 'executable', escape(action['executable']))
        node.newChild(None, 'arguments', escape(action['arguments']))
        node.newChild(None, 'terminal', str(action['terminal']))
        node.newChild(None, 'block', str(action['block']))
        node.newChild(None, 'restart', str(action['restart']))
    doc.saveFormatFile(USER_ACTIONS_CONFIG, format=1)
    doc.freeDoc()
    return

def save_alias_settings(tree):
    """
    Save user-configured aliases to a file.
    """
    escape = glib.markup_escape_text
    model = tree.get_model()
    doc = libxml2.newDoc('1.0')
    root = doc.newChild(None, 'fontconfig', None)
    while model.get_iter_first():
        rootiter = model.get_iter_first()
        node = root.newChild(None, 'alias', None)
        node.setProp('binding', 'strong')
        node.newChild(None, 'family', escape(model.get_value(rootiter, 0)))
        while model.iter_children(rootiter):
            child = model.iter_children(rootiter)
            prefer = node.newChild(None, 'prefer', None)
            prefer.newChild(None, 'family', escape(model.get_value(child, 0)))
            model.remove(child)
        model.remove(rootiter)
    doc.saveFormatFile(join(USER_FONT_CONFIG_DIR, '35-aliases.conf'), format=1)
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
            order = []
            load_compat_collections(fontmanager, order)
            return order
    try:
        doc = libxml2.parseFile(USER_FONT_COLLECTIONS)
    except Exception:
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
        logging.info('Loaded user collection {0}'.format(name))
        order.append(name)
    doc.freeDoc()
    load_compat_collections(fontmanager, order)
    return order

def load_compat_collections(fontmanager, order):
    """
    If ~/.config/fontgroups.xml exists load any collections defined there.

    For compatibility with KDE font manager and any other programs which might
    make use of that file.
    """
    if not exists(COMPAT_COLLECTIONS):
        return
    try:
        doc = libxml2.parseFile(COMPAT_COLLECTIONS)
    except Exception:
        logging.warn("Failed to parse collection configuration")
        return
    nodes = doc.xpathEval('//group')
    for node in nodes:
        name = node.prop("name")
        if name in order:
            continue
        comment = _('Created on {0}').format(
                time.strftime('%A, %B %d, %Y, at %I:%M %p', time.localtime()))
        families = []
        for family in node.xpathEval('family'):
            families.append(family.content)
        fontmanager.create_collection(name, comment, list(set(families)))
        logging.info('Imported user collection {0}'.format(name))
        order.append(name)
    doc.freeDoc()
    return

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
    try:
        while len(order) != 0:
            name = order[0]
            if name not in printed:
                collection = objects['FontManager'].collections[name]
                node = root.newChild(None, "fontcollection", None)
                node.setProp("name", collection.name)
                node.setProp("comment", collection.comment)
                for family in collection.families:
                    add_patelt_node(node, family)
                printed.append(name)
            order.pop(0)
    except Exception:
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
    save_compat_collections(objects)
    return

def save_compat_collections(objects):
    """
    Save user defined collections to ~/.config/fontgroups.xml.

    For compatibility with KDE font manager and any other programs which might
    make use of that file.
    """
    not exists(COMPAT_COLLECTIONS) or os.unlink(COMPAT_COLLECTIONS)
    order = _get_collection_order(objects)
    printed = []
    # Start "printing"
    doc = libxml2.newDoc("1.0")
    root = doc.newChild(None, "groups", None)
    try:
        while len(order) != 0:
            name = order.pop(0)
            if name not in printed:
                collection = objects['FontManager'].collections[name]
                node = root.newChild(None, "group", None)
                node.setProp("name", collection.name)
                for family in collection.families:
                    node.newChild(None, 'family', family)
                printed.append(name)
    except:
        doc.freeDoc()
        return
    doc.saveFormatFile(COMPAT_COLLECTIONS, format=1)
    doc.freeDoc()
    return

def save_fontconfig_settings(settings):
    """
    Save user-configured settings to a file.
    """
    doc = libxml2.newDoc('1.0')
    root = doc.newChild(None, 'fontconfig', None)
    for style in sorted(settings.faces.iterkeys()):
        dirty = False
        for setting in FC_CHECKBUTTONS.keys():
            attribute = FC_WIDGETMAP[setting]
            default_val = FC_DEFAULTS[FC_WIDGETMAP[setting]]
            if getattr(settings.faces[style], attribute, default_val):
                dirty = True
                break
        if not dirty:
            continue
        node = _add_standard_match_targets(doc, root, style, settings)
        less_eq = FC_WIDGETMAP['Smaller than']
        more_eq = FC_WIDGETMAP['Larger than']
        less = getattr(settings.faces[style], less_eq, FC_DEFAULTS[less_eq])
        more = getattr(settings.faces[style], more_eq, FC_DEFAULTS[more_eq])
        if less:
            test = node.newChild(None, 'test', None)
            test.setProp('name', 'size')
            test.setProp('compare', 'less')
            attribute = 'min_size'
            default_val = FC_DEFAULTS[attribute]
            val = int(getattr(settings.faces[style], attribute, default_val))
            test.newChild(None, 'double', str(val))
            _add_assignments(node, style, settings)
        if less and more:
            node = _add_standard_match_targets(doc, root, style, settings)
        if more:
            test = node.newChild(None, 'test', None)
            test.setProp('name', 'size')
            test.setProp('compare', 'more')
            attribute = 'max_size'
            default_val = FC_DEFAULTS[attribute]
            val = int(getattr(settings.faces[style], attribute, default_val))
            test.newChild(None, 'double', str(val))
            _add_assignments(node, style, settings)
        if not less and not more:
            _add_assignments(node, style, settings)
    doc.saveFormatFile(join(USER_FONT_CONFIG_DIR,
                    '25-{0}.conf'.format(settings.family.get_name())), format=1)
    doc.freeDoc()
    return

def _add_standard_match_targets(doc, root, style, settings):
    escape = glib.markup_escape_text
    comment = (settings.family.get_name(), style)
    root.addChild(doc.newDocComment(' {0} {1} '.format(*comment)))
    node = root.newChild(None, 'match', None)
    node.setProp('target', 'font')
    test = node.newChild(None, 'test', None)
    test.setProp('name', 'family')
    test.newChild(None, 'string', escape(settings.family.get_name()))
    _guess_style_values(node, settings, style)
    return node

def _guess_style_values(node, settings, style):
    descr = settings.faces[style].descr
    test = node.newChild(None, 'test', None)
    test.setProp('name', 'slant')
    test.setProp('compare', 'eq')
    test.newChild(None, 'const', PSLANT[descr.get_style()])
    test = node.newChild(None, 'test', None)
    test.setProp('name', 'weight')
    test.setProp('compare', 'more_eq')
    test.newChild(None, 'int', PWEIGHT[descr.get_weight()].split(':')[0])
    test = node.newChild(None, 'test', None)
    test.setProp('name', 'weight')
    test.setProp('compare', 'less_eq')
    test.newChild(None, 'int', PWEIGHT[descr.get_weight()].split(':')[1])
    test = node.newChild(None, 'test', None)
    test.setProp('name', 'width')
    test.setProp('compare', 'eq')
    test.newChild(None, 'const', PWIDTH[descr.get_stretch()])
    return

def _add_assignments(node, style, settings):
    for setting in FC_CHECKBUTTONS.keys():
        attribute = FC_WIDGETMAP[setting]
        default_val = FC_DEFAULTS[FC_WIDGETMAP[setting]]
        val = getattr(settings.faces[style], attribute, default_val)
        if setting not in FC_SKIP:
            edit = node.newChild(None, 'edit', None)
            edit.setProp('name', attribute)
            edit.setProp('mode', 'assign')
            edit.newChild(None, 'bool', str(val))
        if val and attribute in FC_CONSTS_MAP:
            attribute = FC_CONSTS_MAP[attribute]
            default_val = FC_DEFAULTS[attribute]
            raw_val = getattr(settings.faces[style], attribute, default_val)
            val = str(raw_val).split('.')[1][:1]
            edit = node.newChild(None, 'edit', None)
            edit.setProp('name', attribute)
            edit.setProp('mode', 'assign')
            edit.newChild(None, 'const', FC_CONSTS[attribute][val])
        if val and attribute == 'disablergba':
            edit = node.newChild(None, 'edit', None)
            edit.setProp('name', 'rgba')
            edit.setProp('mode', 'assign')
            edit.newChild(None, 'const', 'none')
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

def _tobool(val):
    """
    Convert from string to boolean.
    """
    return (val != 'False' and val != 'false' and val != '0')

def _unescape_markup(val):
    """
    Replace escape characters with normal characters.
    """
    _illegal = {
                '<' :   '&lt;',
                '>' :   '&gt;',
                '&' :   '&amp;',
                "'" :   '&apos;',
                '"' :   '&quot;'
                }
    for illegal, legal in _illegal.iteritems():
        val = val.replace(legal, illegal)
    return val

