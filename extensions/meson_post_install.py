#!/usr/bin/env python3

from os import environ, path
from subprocess import call

base_dir = path.join(environ['MESON_INSTALL_PREFIX'], 'share')
if environ.get('DESTDIR'):
    base_dir = path.join(environ['DESTDIR'], base_dir)

print('Compiling python extensions...')

nautilus_extensions_dir = path.join(base_dir, 'nautilus-python', 'extensions')
thunarx_extensions_dir = path.join(base_dir, 'thunarx-python', 'extensions')
nemo_extensions_dir = path.join(base_dir, 'nemo-python', 'extensions')

for d in [nautilus_extensions_dir, thunarx_extensions_dir, nemo_extensions_dir]:
    call(['python', '-m', 'compileall', d])
    call(['python', '-O', '-m', 'compileall', d])
