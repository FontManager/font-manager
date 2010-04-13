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

class Collection(object):
    __slots__ = ("name", "fonts", "builtin", "enabled")

    def __init__(self, name):
        self.name = name
        self.fonts = []
        self.builtin = True
        self.enabled = True

    def get_label(self):
        if self.enabled: return on(self.name)
        else: return off(self.name)

    def obj_exists(self, obj):
        for f in self.fonts:
            if f is obj:
                return True
        return False
        
    def add(self, obj):
        # check duplicate reference
        if self.obj_exists(obj):
            return
        self.fonts.append(obj)

    def get_text(self):
        return self.name
            
    def num_fonts_enabled(self):
        ret = 0
        for f in self.fonts:
            if f.enabled:
                ret += 1
        return ret

    def set_enabled(self, enabled):
        for f in self.fonts:
            f.enabled = enabled

    def set_enabled_from_fonts(self):
        self.enabled = (self.num_fonts_enabled() > 0)

    def remove(self, font):
        self.fonts.remove(font)


class Family(object):
    __slots__ = ("family", "user", "enabled", "pango_family")

    def __init__(self, family):
        self.family = family
        self.user = False
        self.enabled = True
        self.pango_family = None

    def get_label(self):
        if self.enabled: return on(self.family)
        else: return off(self.family)

class Pattern(object):
    __slots__ = ("family", "style")

    def __init__(self):
        self.family = self.style = None

def cmp_family(lhs, rhs):
    return cmp(lhs.family, rhs.family)

def gtk_markup_escape(str):
    str = str.replace("&", "&amp;")
    str = str.replace("<", "&lt;")
    str = str.replace(">", "&gt;")
    return str

def on(str):
    str = gtk_markup_escape(str)
    return "<span weight='heavy'>%s</span>" % str

def off(str):
    str = gtk_markup_escape(str)
    return "<span weight='ultralight'>%s Off</span>" % str
