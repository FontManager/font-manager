#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2009-2022 Jerry Casiano
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

try:
    import pandas as pd
except ImportError:
    import __main__
    print("Error : {}\n".format(__main__.__file__))
    print("    This script depends on pandas.")
    print("    https://pandas.pydata.org/\n")
    exit(1)

# Microsoft Vendor Listing
# Excellent, only?!, source of font foundry information
URL = "https://docs.microsoft.com/en-us/typography/vendors/"
CREDIT = "Courtesy of Microsoft Typography - {}".format(URL)

INDEX = 0
ID = 1
NAME = 2

def list_vendors () :
    vendor_list = pd.read_html(URL)
    for entry in vendor_list:
        for vendor in entry.itertuples():
            yield (str(vendor[ID]), str(vendor[NAME]))
    return
