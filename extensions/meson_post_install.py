#!/usr/bin/env python3

import os
import subprocess

base_dir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share')
if os.environ.get('DESTDIR'):
    base_dir = os.path.join(os.environ['DESTDIR'], base_dir)

print('Compiling python extensions...')

nautilus_extensions_dir = os.path.join(base_dir, 'nautilus-python', 'extensions')
thunarx_extensions_dir = os.path.join(base_dir, 'thunarx-python', 'extensions')
nemo_extensions_dir = os.path.join(base_dir, 'nemo-python', 'extensions')

for d in [nautilus_extensions_dir, thunarx_extensions_dir, nemo_extensions_dir]:
    subprocess.call(['python', '-m', 'compileall', d])
    subprocess.call(['python', '-O', '-m', 'compileall', d])
