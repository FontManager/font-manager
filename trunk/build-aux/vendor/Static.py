#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright © 2009 - 2013 Jerry Casiano
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author:
#  Jerry Casiano <JerryCasiano@gmail.com>

# Will be inserted as a comment above the vendor list
CREDIT = """Various Sources"""

# Expected to return [(id, name), ...]
# id is the unique vendor id to match against
# name is the full vendor name
def list_vendors () :
    return [
    (b"ACG", b"Monotype Imaging"),
    (b"B?", b"Bigelow & Holmes"),
    (b"FJ", b"Fujitsu"),
    (b"RICO", b"Ricoh")
    ]
