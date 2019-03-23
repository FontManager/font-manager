#!/usr/bin/env python3

from os import chdir, environ
from shutil import rmtree

chdir(environ['MESON_DIST_ROOT'])

excluded_dirs = {
    'build-aux',
    'debian',
    'fedora',
    'tests'
}

for d in excluded_dirs:
    rmtree(d)
