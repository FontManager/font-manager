#!/usr/bin/env python

import os.path

from glob import glob
from os import remove, walk

application_icons = [
    'action-unavailable-symbolic',
    'action-unavailable-symbolic',
    'avatar-default',
    'computer',
    'dialog-error-symbolic"',
    'edit-clear-symbolic',
    'edit-find-symbolic',
    'edit-symbolic',
    'emblem-documents',
    'emblem-synchronizing-symbolic',
    'folder',
    'folder-open',
    'folder-symbolic',
    'font-x-generic-symbolic',
    'format-text-bold',
    'go-next-symbolic',
    'go-previous-symbolic',
    'go-previous-symbolic',
    'list-add-symbolic',
    'list-add-symbolic',
    'list-remove-all-symbolic',
    'list-remove-symbolic',
    'list-remove-symbolic',
    'network-error-symbolic',
    'network-offline-symbolic',
    'preferences-desktop-font',
    'preferences-desktop-locale-symbolic',
    'system-run-symbolic',
    'view-grid-symbolic',
    'view-list-symbolic',
    'view-more-symbolic',
    'view-restore-symbolic',
    'window-close-symbolic'
]

required_icons = []

for filepath in glob('icons/**', recursive=True):
    required = False
    for entry in application_icons:
        required = entry in filepath
        if required:
            required_icons.append(filepath)
            break;
    if not required and os.path.isfile(filepath):
        remove(filepath)

for r, d, f in walk('.', topdown=False):
    for n in d:
        try:
            os.rmdir(os.path.join(r, n))
        except:
            pass

required_icons.sort()
for icon in required_icons:
    print('        <file>{}</file>'.format(icon))
