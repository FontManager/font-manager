#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2009 - 2016 Jerry Casiano
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

import io
import os
import json
import sys

from glob import glob

NOTICE = """/* Do not edit directly. See build-aux directory */"""

HEADER = """
#ifndef __LICENSE_H__
#define __LICENSE_H__

#include <glib.h>

G_BEGIN_DECLS

#define MAX_KEYWORD_ENTRIES 25

static const struct
{
    const gchar *license;
    const gchar *license_url;
    const gchar *keywords[MAX_KEYWORD_ENTRIES];
}
LicenseData[] =
{
"""

FOOTER = """
};

#define LICENSE_ENTRIES G_N_ELEMENTS(LicenseData)

G_END_DECLS

#endif /* __LICENSE_H__ */

"""


def write_license_entry (tmp, val) :
    if val is None:
        tmp.write("        NULL,\n")
    else:
        tmp.write("        \"{0}\",\n".format(val))

def get_license_entries () :
    license_dir = os.path.dirname(os.path.realpath(__file__))
    tmp = io.StringIO()
    filelist = os.listdir(license_dir)
    filelist.sort()
    for filename in glob("*.json"):
        filepath = os.path.join(license_dir, filename)
        try:
            with open(filepath) as raw:
                obj = json.load(raw)
                for l in obj["License"]:
                    tmp.write("\n    {\n")
                    write_license_entry(tmp, l["Name"])
                    write_license_entry(tmp, l["URL"])
                    tmp.write("        {\n")
                    for k in l["Keywords"]:
                        if k is None:
                            tmp.write("            NULL\n")
                            break
                        else:
                            tmp.write("    ")
                            write_license_entry(tmp, k)
                    tmp.write("        }\n    },\n")
        except:
            print("Failed to load license : {0} : Skipping...".format(filepath))
    contents = tmp.getvalue()
    tmp.close()
    return contents


if __name__ == "__main__":
    with open(os.path.join(sys.argv[1], "license.h"), "w") as header_file:
        header_file.write(NOTICE)
        header_file.write(HEADER)
        header_file.write(get_license_entries())
        header_file.write(FOOTER)
