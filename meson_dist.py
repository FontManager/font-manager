#!/usr/bin/env python3

import os
import shutil

os.chdir(os.environ['MESON_DIST_ROOT'])

excluded_dirs = {
    'build-aux',
    'debian',
    'fedora',
    'tests'
}

for d in excluded_dirs:
    shutil.rmtree(d)
