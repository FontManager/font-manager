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

import sys

from glob import glob
from io import StringIO
from os import path, remove
from pprint import pprint

NOTICE = """/* Do not edit directly. See build-aux directory */"""

HEADER = """
#ifndef __FONT_MANAGER_VENDOR_H__
#define __FONT_MANAGER_VENDOR_H__

#include <glib.h>

G_BEGIN_DECLS

#ifndef __GTK_DOC_IGNORE__
#define FONT_MANAGER_MAX_VENDOR_ID_LENGTH 4
#define FONT_MANAGER_MAX_VENDOR_LENGTH 100
#endif

static const struct
{
    const gchar vendor[FONT_MANAGER_MAX_VENDOR_LENGTH];
    const gchar vendor_id[FONT_MANAGER_MAX_VENDOR_LENGTH];
}
/* Order is significant. */
FontManagerNoticeData [] =
{
    /* Notice data sourced from fcfreetype.c - http://www.freetype.org/ */
    {"Adobe", "adobe"},
    {"Adobe", "Adobe"},
    {"Bigelow & Holmes", "b&h"},
    {"Bigelow & Holmes", "Bigelow & Holmes"},
    {"Bitstream", "Bitstream"},
    {"Font21", "hwan"},
    {"Font21", "Hwan"},
    {"Gnat", "culmus"},
    {"HanYang System", "hanyang"},
    {"HanYang System", "HanYang Information & Communication"},
    {"IBM", "IBM"},
    {"ITC", "itc"},
    {"ITC", "ITC"},
    {"ITC", "International Typeface Corporation"},
    {"Larabiefonts", "Larabie"},
    {"Linotype", "linotype"},
    {"Linotype", "Linotype GmbH"},
    {"Linotype", "LINOTYPE-HELL"},
    {"Microsoft", "microsoft"},
    {"Microsoft", "Microsoft Corporation"},
    {"Monotype", "Monotype Imaging"},
    {"Monotype", "Monotype Corporation"},
    {"Monotype", "Monotype Typography"},
    {"Omega", "omega"},
    {"Omega", "Omega"},
    {"Tiro Typeworks", "Tiro Typeworks"},
    {"URW", "URW"},
    {"XFree86", "XFree86"},
    {"Xorg", "xorg"}
};

static const struct
{
    const gchar vendor_id[FONT_MANAGER_MAX_VENDOR_ID_LENGTH];
    const gchar vendor[FONT_MANAGER_MAX_VENDOR_LENGTH];
}
FontManagerVendorData[] =
{
"""

FOOTER = """};

#ifndef __GTK_DOC_IGNORE__
#define FONT_MANAGER_NOTICE_ENTRIES G_N_ELEMENTS(FontManagerNoticeData)
#define FONT_MANAGER_VENDOR_ENTRIES G_N_ELEMENTS(FontManagerVendorData)
#endif

G_END_DECLS

#endif /* __FONT_MANAGER_VENDOR_H__ */

"""

vendor_dir = path.dirname(path.realpath(__file__))

def get_vendor_entries () :
    sys.path.append(vendor_dir)
    module_names = [path.splitext(p)[0] for p in glob("*.py") if p != "genheader.py"]
    resources = map(__import__, module_names)
    tmp = StringIO()
    for module in resources:
        name = module.__name__
        try:
            if module.CREDIT is not None:
                tmp.write("\n    /* {} */\n".format(module.CREDIT))
            else:
                tmp.write("\n")
            try:
                vendor_list = list(module.list_vendors())
            except:
                vendor_list = []
            if len(vendor_list) == 0:
                with open(path.join(vendor_dir, "{}.cache".format(name))) as cache:
                    vendor_list = eval(cache.read())
                    print("Using cached vendor information for {}".format(name))
            for vendor_id, vendor in iter(vendor_list):
                if len(vendor) > 50:
                    vendor = "{}…".format(vendor[:47])
                tmp.write("    {{\"{0}\", \"{1}\"}},\n".format(vendor_id.replace('"', "'"), vendor.replace('"', "'")))
            tmp.write("\n")
            if name != "Example":
                try:
                    with open(path.join(vendor_dir, "{}.cache".format(name)), "w") as cache:
                        pprint(list(vendor_list), cache)
                except:
                    pass
        except:
            print("Failed to load vendor resource : {0} : Skipping...".format(name))
    contents = tmp.getvalue()
    tmp.close()
    return contents


if __name__ == "__main__":
    with open(path.join(sys.argv[1], "font-manager-vendor.h"), "w") as header_file:
        header_file.write(NOTICE)
        header_file.write(HEADER)
        header_file.write(get_vendor_entries())
        header_file.write(FOOTER)
    build_cache = path.join(vendor_dir, "__pycache__")
    if path.exists(build_cache):
        import shutil
        shutil.rmtree(build_cache)
    for f in glob("*.pyc"):
        remove(f)
