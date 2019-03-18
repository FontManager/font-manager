#!/usr/bin/env python3

import os
import glob
import shutil

os.chdir(os.environ['MESON_DIST_ROOT'])

excluded_dirs = {
    'build-aux',
    'debian',
    'fedora',
    'tests'
}

excluded_patterns = {
    '**/*.am',
    '**/*.ac',
    '**/*.mk',
    '**/*.sh',
    '**/*.sin',
    '**/HEADER',
    '**/Makevars.in',
    'INSTALL'
}

for d in excluded_dirs:
    shutil.rmtree(d)

for pat in excluded_patterns:
    paths = glob.glob(pat, recursive=True)
    for p in paths:
        os.remove(p)

