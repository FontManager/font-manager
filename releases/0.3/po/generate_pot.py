#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Generate POT
    ~~~~~~~~~~~~

    Original script by Armin Ronacher.
    http://lucumr.pocoo.org/2007/6/10/internationalized-pygtk-applications2
    
    Modified by Jerry Casiano to match the output provided by
    
    intltool-update --pot --gettext-package=messages
    
    and also give line numbers for glade/ui files.
"""
import os
import sys
import subprocess
from xml.dom import minidom
from compiler import parse, ast
from datetime import datetime

APP_NAME = 'Font Manager'
APP_VERSION = '0.3'
BASEPATH = '../src/'

PO_HEADER = """# %(name)s
# Copyright (C) 2009 Jerry Casiano
# This file is distributed under the same license as the %(name)s package.
# Jerry Casiano <none@nospam4me.com>, 2009
#
msgid ""
msgstr ""
"Project-Id-Version: %(name)s %(version)s\\n"
"POT-Creation-Date: %(time)s\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: UTF-8\\n"
"Generated-By: %(filename)s\\n"\
"""

EMPTY_STRING = ''
EMPTY_LINE = ['""\n']
LINE_SHIFT = ['\\n"\n"']

class StringCollection(object):
    """Class for collecting strings."""

    def __init__(self, basename):
        self.db = {}
        self.order = []
        self.offset = len(basename)

    def feed(self, file, line, string):
        name = file[self.offset:].lstrip('/')
        if string not in self.db:
            self.db[string] = [(name, line)]
            self.order.append(string)
        else:
            self.db[string].append((name, line))

    def __iter__(self):
        for string in self.order:
            yield string, self.db[string]

def quote(s):
    """Quotes a given string so that it is useable in a .po file."""
    result = ['"']
    firstmatch = True
    for char in s:
        if char == '\n':
            if firstmatch:
                result = EMPTY_LINE + result
                firstmatch = False
            result += LINE_SHIFT
            continue
        if char in '\t"':
            result.append('\\')
        result.append(char)
    result.append('"')
    return EMPTY_STRING.join(result)

def scan_python_file(filename, calls):
    """Scan a python file for gettext calls."""
    def scan(nodelist):
        for node in nodelist:
            if isinstance(node, ast.CallFunc):
                handle = False
                for pos, n in enumerate(node):
                    if pos == 0:
                        if isinstance(n, ast.Name) and n.name in calls:
                            handle = True
                    elif pos == 1:
                        if handle:
                            if n.__class__ is ast.Const and \
                               isinstance(n.value, basestring):
                                yield n.lineno, n.value
                            break
                        else:
                            for line in scan([n]):
                                yield line
            elif hasattr(node, '__iter__'):
                for n in scan(node):
                    yield n

    fp = file(filename)
    try:
        try:
            return scan(parse(fp.read()))
        except:
            print >> sys.stderr, 'Syntax Error in file %r' % filename
    finally:
        fp.close()

def scan_ui_file(filename):
    """Scan a glade or gtk.Builder file for translatable strings."""
    try:
        doc = minidom.parse(filename)
    except:
        print >> sys.stderr, 'Syntax Error in file %r' % filename
    for element in doc.getElementsByTagName('property'):
        if element.getAttribute('translatable') == 'yes':
            data = element.firstChild.nodeValue
            if data and not data.startswith('gtk-'):
                yield data

def scan_tree(pathname, calls=['_']):
    """Scans a tree for translatable strings."""
    out = StringCollection(pathname)
    for folder, _, files in os.walk(pathname):
        for filename in files:
            filename = os.path.join(folder, filename)
            if filename.endswith('.py'):
                result = scan_python_file(filename, calls)
                if result is not None:
                    for lineno, string in result:
                        out.feed(filename, lineno, string)
            elif filename.endswith('.glade') or filename.endswith('.ui'):
                result = scan_ui_file(filename)
                if result is not None:
                    for string in result:
                        cmd = 'grep -nrHIF \'%s\' %s' % (string, BASEPATH)
                        for line in get_cli_output(cmd):
                            unused_file, line = line.split(':', 1)
                            line, unused_contents = line.split(':', 1)
                            out.feed(filename, line, string)
    for line in out:
        yield line

def get_cli_output(cmd):
    result = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, shell=True)
    while True:
        line = result.stdout.readline()
        if not line:
            break
        yield line

def run():

    os.chdir('po')
    
    outfile = open(os.getcwd() + '/messages.pot', 'w')
    outfile.write( PO_HEADER % {
        'time':     datetime.now(),
        'filename': sys.argv[0],
        'name':     APP_NAME,   
        'version':  APP_VERSION} + '\n' )

    for string, occurrences in scan_tree(BASEPATH):
        outfile.write('\n')
        for path, lineno in occurrences:
            outfile.write('#: %s%s:%s\n' % (BASEPATH, path, lineno))
        outfile.write('msgid %s\n' % quote(string))
        outfile.write('msgstr ""\n')
    outfile.close()
    print 'Wrote: messages.pot'
    
    os.chdir('..')
    
if __name__ == '__main__':
    run()
