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

import io
import os
import sys
import json
import shutil
import subprocess
import fileinput

from pprint import pprint

NOTICE = """/* Private.h
 *
 * Copyright © 2009 - 2014 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
"""

def generate_vendor_header () :

    vendor_dir = "vendor"
    header_file = os.path.join(vendor_dir, "HEADER")
    footer_file = os.path.join(vendor_dir, "FOOTER")
    sys.path.append(vendor_dir)
    module_names = [os.path.splitext(p)[0] for p in os.listdir(vendor_dir) if p.endswith(".py")]
    resources = map(__import__, module_names)

    h_file = io.StringIO()
    with open(header_file) as header:
        h_file.write(header.read())
    for module in resources:
        name = module.__name__
        try:
            if module.CREDIT is not None:
                h_file.write("\n    /* {} */\n".format(module.CREDIT))
            else:
                h_file.write("\n")
            vendor_list = list(module.list_vendors())
            if len(vendor_list) == 0:
                print("{} failed to list vendor information - checking for cache".format(name))
                with open(os.path.join(vendor_dir, "{}.cache".format(name))) as cache:
                    vendor_list = eval(cache.read())
                    print("Using cached vendor information for {}".format(name))
            for vendor_id, vendor in iter(vendor_list):
                if len(vendor) > 50:
                    vendor = "{}...".format(vendor[:47])
                h_file.write("    {{\"{0}\", \"{1}\"}},\n".format(vendor_id.decode("utf-8", "strict"), vendor.decode("utf-8", "strict")))
            h_file.write("\n")
            if name == "Static":
                continue
            try:
                with open(os.path.join(vendor_dir, "{}.cache".format(name)), "w") as cache:
                    pprint(list(vendor_list), cache)
            except:
                pass
        except:
            print("Failed to load vendor resource : {0} : Skipping...".format(name))
    with open(footer_file) as footer:
        h_file.write(footer.read())
    contents = h_file.getvalue()
    h_file.close()
    return contents


def generate_license_header () :

    license_dir = "license"
    credits_file = os.path.join(license_dir, "CREDITS")
    header_file = os.path.join(license_dir, "HEADER")
    footer_file = os.path.join(license_dir, "FOOTER")

    with open(credits_file) as creds:
        _credits_ = creds.read()

    def write_license_entry (h_file, val) :
        if val is None:
            h_file.write("        NULL,\n")
        else:
            h_file.write("        \"{0}\",\n".format(val))

    h_file = io.StringIO()
    with open(header_file) as header:
        h_file.write(header.read().format(_credits_))
    filelist = os.listdir(license_dir)
    filelist.sort()
    for path in filelist:
        if not path.endswith(".json"):
            continue
        try:
            with open(os.path.join(license_dir, path)) as raw:
                obj = json.load(raw)
                for l in obj["License"]:
                    h_file.write("\n    {\n")
                    write_license_entry(h_file, l["Name"])
                    write_license_entry(h_file, l["URL"])
                    h_file.write("        {\n")
                    for k in l["Keywords"]:
                        if k is None:
                            h_file.write("            NULL\n")
                            break
                        else:
                            h_file.write("    ")
                            write_license_entry(h_file, k)
                    h_file.write("        }\n    },\n")
        except:
            print("Failed to load license object : {0} : Skipping...".format(path))
    with open(footer_file) as footer:
        h_file.write(footer.read())
    contents = h_file.getvalue()
    h_file.close()
    return contents


if __name__ == "__main__":
    result = subprocess.call(["valac",
                               "-q",
                               "-C",
                               "-H",
                               "../src/Glue/Private.h",
                               "--pkg=pango",
                               "--pkg=gee-0.8",
                               "--pkg=json-glib-1.0",
                               "../src/Common/Constants.vala",
                               "../src/Common/FontInfo.vala",
                               "../src/Common/Utils.vala",
                               "../src/FontConfig/Font.vala",
                               "../src/FontConfig/Enums.vala",
                               "../src/Glue/Glue.vala",
                               "../src/Json/Cacheable.vala",
                               ])
    if (result != 0):
        print("Failed to generate base header file! Aborting...")
        exit(1)
    for f in os.listdir(os.getcwd()):
        if f.endswith(".c"):
            os.remove(f)
    license_header = generate_license_header()
    vendor_header = generate_vendor_header()
    if not license_header.startswith("/* Open source license information"):
        print("Failed to generate license header! Aborting...")
        exit(1)
    if not vendor_header.startswith("#define MAX_VENDOR_ID_LENGTH 5"):
        print("Failed to generate vendor header! Aborting...")
        exit(1)
    for line in fileinput.input("../src/Glue/Private.h", inplace=True):
        if line.startswith("/* Private.h generated by valac"):
            print(NOTICE)
        elif line.startswith("G_END_DECLS"):
            print(license_header)
            print(vendor_header)
            print(line, end='')
        else:
            print(line, end='')
    if os.path.exists("vendor/__pycache__"):
        shutil.rmtree("vendor/__pycache__")
