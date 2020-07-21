#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2009 - 2020 Jerry Casiano
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

import json
import sys

from glob import glob
from io import StringIO
from os import path

NOTICE = """/* Do not edit directly. See build-aux directory */"""

HEADER = """
#ifndef __FONT_MANAGER_LICENSE_H__
#define __FONT_MANAGER_LICENSE_H__

#include <glib.h>

G_BEGIN_DECLS

#ifndef __GTK_DOC_IGNORE__
#define FONT_MANAGER_MAX_KEYWORD_ENTRIES 25
#endif

static const struct
{
    const gchar *license;
    const gchar *license_url;
    const gchar *keywords[FONT_MANAGER_MAX_KEYWORD_ENTRIES];
}
FontManagerLicenseData[] =
{
"""

FOOTER = """
};

#ifndef __GTK_DOC_IGNORE__
#define FONT_MANAGER_LICENSE_ENTRIES G_N_ELEMENTS(FontManagerLicenseData)
#endif

G_END_DECLS

#endif /* __FONT_MANAGER_LICENSE_H__ */

"""


def write_license_entry (tmp, val) :
    if val is None:
        tmp.write("        NULL,\n")
    else:
        tmp.write("        \"{0}\",\n".format(val))

def get_license_entries () :
    license_dir = path.dirname(path.realpath(__file__))
    tmp = StringIO()
    for filename in sorted(glob("*.json")):
        filepath = path.join(license_dir, filename)
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
    with open(path.join(sys.argv[1], "font-manager-license.h"), "w") as header_file:
        header_file.write(NOTICE)
        header_file.write(HEADER)
        header_file.write(get_license_entries())
        header_file.write(FOOTER)
