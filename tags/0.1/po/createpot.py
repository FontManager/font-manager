#!/usr/bin/env python

import os, sys, glob

command = None
try:
    command = sys.argv[1]
except IndexError:
    pass

os.chdir('po')
os.system('intltool-update --pot --gettext-package=messages --verbose')

if command != 'compile':
	pass

else:

    files = glob.glob('*.po')
    for f in files:
        l = os.path.splitext(f)
        os.system('mkdir -p -m 0777 %s/LC_MESSAGES' % l[0])

        print "Generating translation for %s locale" % l[0]
        os.system('msgmerge -o - %s messages.pot | msgfmt -c -o %s/LC_MESSAGES/font-manager.mo -' % (f, l[0]))

os.chdir('..')
