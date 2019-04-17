#!/usr/bin/env python3

from os import environ, path
from subprocess import call

prefix = environ['MESON_INSTALL_PREFIX']
data_dir = path.join(prefix, 'share')
schema_dir = path.join(data_dir, 'glib-2.0', 'schemas')

if not environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    call(['glib-compile-schemas', schema_dir])
    print('Updating desktop database...')
    call(['update-desktop-database', '-q', path.join(data_dir, 'applications')])

