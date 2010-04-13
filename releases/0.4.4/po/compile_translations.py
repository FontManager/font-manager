#!/usr/bin/env python

import os, sys, glob

os.chdir('po')
os.environ['XGETTEXT_ARGS'] = '--language=Python'
os.system('intltool-update --pot --gettext-package=messages --verbose')

files = glob.glob('*.po')
for f in files:
    l = os.path.splitext(f)
    os.system('mkdir -p -m 0777 %s/LC_MESSAGES' % l[0])

    print "Generating translation for %s locale" % l[0]
    os.system('msgmerge -o - %s messages.pot | msgfmt -c -o %s/LC_MESSAGES/font-manager.mo -' % (f, l[0]))

os.chdir('..')
