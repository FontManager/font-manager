#!/usr/bin/env python3

from glob import glob
from os import chdir, environ, remove
from shutil import rmtree

chdir(environ['MESON_DIST_ROOT'])

# Directories which shouldn't be included in a release
excluded_dirs = {
    'build-aux',
    'debian',
    'fedora',
    '.github'
}

excluded_files = {
    '.gitattributes',
    '.gitignore'
}

for d in excluded_dirs:
    try:
        rmtree(d)
    except FileNotFoundError:
        pass

for f in excluded_files:
    try:
        remove(f)
    except FileNotFoundError:
        pass

# Remove README translations to minimize archive size
for f in glob("README.*.md"):
    try:
        remove(f)
    except FileNotFoundError:
        pass

