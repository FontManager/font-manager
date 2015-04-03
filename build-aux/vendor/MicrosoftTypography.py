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

import urllib.request

try:
    from bs4 import SoupStrainer
    from bs4 import BeautifulSoup
except ImportError:
    import __main__
    print("Error : {}\n".format(__main__.__file__))
    print("    This script depends on BeautifulSoup 4.")
    print("    http://www.crummy.com/software/BeautifulSoup/\n")
    exit(1)


CREDIT = """Courtesy of Microsoft Typography"""
URL = "http://www.microsoft.com/typography/links/vendorlist.aspx"


def list_vendors () :
    req = urllib.request.Request(URL)
    req.remove_header("User-agent")
    req.add_header("User-agent", "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:36.0) Gecko/20100101 Firefox/36.0")
    with urllib.request.urlopen(req) as raw_data:
        raw_html = raw_data.read()
    vendor_list = SoupStrainer(id = "VendorList")
    # Certain versions of the default parser (lxml) choke here...
    vendor_table = BeautifulSoup(raw_html, "html.parser", parse_only = vendor_list, from_encoding = "utf-8")
    for anchor in vendor_table("a"):
        anchor.replaceWith("")
    for row in vendor_table("tr"):
        entry = row.find("td")
        vendor_id = entry.get_text(strip = True).encode("utf-8")
        vendor = entry.find_next("td").get_text(strip = True).encode("utf-8")
        yield (vendor_id, vendor)
    return
