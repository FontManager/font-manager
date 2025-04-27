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
RESOURCE_ID = 'com.github.FontManager.FontManager'
SVG_OPTIONS = 'preprocess="xml-stripblanks" compressed="true"'

icon_categories = {

    'apps' : [
        'preferences-desktop-locale-symbolic.svg'
    ],

    'actions' : [
        'action-unavailable-symbolic.svg',
        'application-preferences-symbolic.svg',
        'document-edit-symbolic.svg',
        'edit-clear-symbolic.svg',
        'edit-clear-symbolic-rtl.svg',
        'edit-find-symbolic.svg',
        'edit-select-all-symbolic.svg',
        'edit-undo-symbolic.svg',
        'edit-undo-symbolic-rtl.svg',
        'format-justify-center-symbolic.svg',
        'format-justify-fill-symbolic.svg',
        'format-justify-left-symbolic.svg',
        'format-justify-right-symbolic.svg',
        'go-home-symbolic.svg',
        'go-previous-symbolic.svg',
        'list-add-symbolic.svg',
        'list-drag-handle-symbolic.svg',
        'list-remove-all-symbolic.svg',
        'list-remove-symbolic.svg',
        'open-menu-symbolic.svg',
        'panel-right-symbolic.svg',
        'panel-right-symbolic-rtl.svg',
        'system-run-symbolic.svg',
        'view-grid-symbolic.svg',
        'view-list-symbolic.svg',
        'view-more-symbolic.svg',
        'view-sort-descending-symbolic.svg',
        'view-pin-symbolic.svg',
        'window-close-symbolic.svg',
        'zoom-in-symbolic.svg',
        'zoom-out-symbolic.svg'
    ],

    'devices' : [
        'computer-symbolic.svg'
    ],

    'emblems' : [
        'emblem-documents-symbolic.svg',
        'emblem-synchronizing-symbolic.svg'
    ],

    'places' : [
        'folder-symbolic.svg'
    ],

    'status' : [
        'avatar-default-symbolic.svg',
        'computer-fail-symbolic.svg',
        'dialog-question-symbolic.svg',
        'folder-open-symbolic.svg',
        'network-error-symbolic.svg',
        'network-offline-symbolic.svg',
        'google-fonts-symbolic.svg'
    ]

}

os.makedirs('ui/icons', exist_ok=True)

with open('ui/gresources.xml', 'w') as resources:
    resources.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    resources.write('<gresources>\n')
    os.makedirs('ui/icons/symbolic/apps', exist_ok=True)
    shutil.copy('com.github.FontManager.FontManager-symbolic.svg', 'ui/icons/symbolic/apps/')
    resources.write('  <gresource prefix="{}">\n'.format(RESOURCE_PATH))
    resources.write('    <file {}>icons/symbolic/apps/{}-symbolic.svg</file>\n'.format(SVG_OPTIONS, RESOURCE_ID))
    for category, icons in icon_categories.items():
        os.makedirs('ui/icons/scalable/{}'.format(category), exist_ok=True)
        for icon in icons:
            shutil.copy(icon, 'ui/icons/scalable/{}/'.format(category))
            resources.write('    <file {}>icons/scalable/{}/{}</file>\n'.format(SVG_OPTIONS, category, icon))
    resources.write('  </gresource>\n')
    resources.write('  <gresource prefix="{}/ui">\n'.format(RESOURCE_PATH))
    resources.write('    <file compressed="true">FontManager.css</file>\n')
    resources.write('  </gresource>\n')
    resources.write('</gresources>\n')

with open('ui/meson.build', 'w') as meson:
    meson.write('\ngresources_xml_file = files(\'gresources.xml\')\n')
    meson.write('\ngresources = gnome.compile_resources(\'ui-resources\', gresources_xml_file)\n\n')

with open('ui/icons/CREDITS', 'w') as credits:
    credits.write('\nIcons in the scalable directory are sourced from the papirus-icon-theme\n')
    credits.write('\nSee https://github.com/PapirusDevelopmentTeam/papirus-icon-theme for more info')

