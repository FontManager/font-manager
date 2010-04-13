# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2008 Karl Pickett <http://fontmanager.blogspot.com/>
# Copyright (C) 2009 Jerry Casiano
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

import os
import logging

from stores import Family

# Names of system font families as reported by fc-list
g_system_families = {}
# map of family to list of filenames
g_font_files = {}
# map of family name to Family object
g_fonts = {}

total_fonts = 0


class FontLoad:
    """ 
    Get all fonts recognized by Fontconfig
        
    Parse, count and store the results in a list
    """
    def __init__(self, widget):
        
        self.load_fontconfig_system_families()
        self.load_fontconfig_files()
        self.load_fonts(widget)
        self.total_fonts()
        
    def load_fontconfig_files(self):
        cmd = "fc-list : file family"
        for l in os.popen(cmd).readlines():
            l = l.strip()
            # let's stop at the first : 
            # so we don't crash on fonts with : in their name
            file, family = l.split(":", 1)
            family = self.strip_fontconfig_family(family)
            list = g_font_files.get(family, None)
            if not list:
                list = []
                g_font_files[family] = list
            list.append(file)

    def load_fontconfig_system_families(self):
        cmd = "HOME= fc-list : family"
        for l in os.popen(cmd).readlines():
            l = l.strip()
            family = self.strip_fontconfig_family(l)
            g_system_families[family] = 1

    def load_fonts(self, widget):
        ctx = widget.get_pango_context()
        families = ctx.list_families()
        for f in families:
            obj = Family(f.get_name())
            obj.pango_family = f
            if not g_system_families.has_key(f.get_name()):
                obj.user = True
            g_fonts[f.get_name()] = obj
        
    def strip_fontconfig_family(self, family):
        # remove alt name
        n = family.find(',')
        if n > 0:
            family = family[:n]
        family = family.replace("\\", "")
        family = family.strip()
        return family

    def total_fonts(self):
        fonts = 0
        for font in g_fonts.itervalues():
            fonts += 1
        global total_fonts
        logging.info("Found a total of %s fonts" % fonts)
        total_fonts = fonts
        
    def total_font_families(self):
        families = 0
        for family in g_font_files.itervalues():
            families += 1
        total_font_families = families
        
