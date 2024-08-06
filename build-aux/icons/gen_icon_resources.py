#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2009-2024 Jerry Casiano
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.
#
# If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

import os
import shutil

RESOURCE_PATH = '/com/github/FontManager/FontManager'

icon_categories = {

    'apps' : [
        'preferences-desktop-locale-symbolic.svg'
    ],

    'actions' : [
        'document-edit-symbolic.svg',
        'edit-find-symbolic.svg',
        'edit-select-all-symbolic.svg',
        'edit-undo-symbolic-rtl.svg',
        'edit-undo-symbolic.svg',
        'format-justify-center-symbolic.svg',
        'format-justify-fill-symbolic.svg',
        'format-justify-left-symbolic.svg',
        'format-justify-right-symbolic.svg',
        'go-previous-symbolic.svg',
        'list-add-symbolic.svg',
        'list-drag-handle-symbolic.svg',
        'list-remove-symbolic.svg',
        'open-menu-symbolic.svg',
        'panel-right-symbolic.svg',
        'panel-right-symbolic-rtl.svg',
        'system-run-symbolic.svg',
        'view-grid-symbolic.svg',
        'view-list-symbolic.svg',
        'view-more-symbolic.svg',
        'view-sort-descending-symbolic.svg',
        'zoom-in-symbolic.svg',
        'zoom-out-symbolic.svg'
    ],

    'devices' : [
        'computer-symbolic.svg'
    ],

    'places' : [
        'folder-symbolic.svg'
    ],

    'status' : [
        'avatar-default-symbolic.svg',
        'dialog-question-symbolic.svg',
        'folder-open-symbolic.svg'
    ]

}

os.makedirs('icons', exist_ok=True)

with open('icons/icon_gresources.xml', 'w') as resources:
    resources.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    resources.write('<gresources>\n')
    for category, icons in icon_categories.items():
        os.makedirs('icons/scalable/{}'.format(category), exist_ok=True)
        resources.write('  <gresource prefix="{}/icons">\n'.format(RESOURCE_PATH))
        for icon in icons:
            shutil.copy(icon, 'icons/scalable/{}/'.format(category))
            resources.write('    <file>scalable/{}/{}</file>\n'.format(category, icon))
        resources.write('  </gresource>\n')
    resources.write('</gresources>\n')

with open('icons/meson.build', 'w') as meson:
    meson.write('\nicon_gresources_xml_file = files(\'icon_gresources.xml\')\n')
    meson.write('\nicon_gresources = gnome.compile_resources(\'icon-gresources\', icon_gresources_xml_file)\n\n')

with open('icons/CREDITS', 'w') as credits:
    credits.write('\nIcons in this directory are sourced from the papirus-icon-theme\n')
    credits.write('\nSee https://github.com/PapirusDevelopmentTeam/papirus-icon-theme for more info')

