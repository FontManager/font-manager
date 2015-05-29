#/bin/sh
cd ..
[ ! -e Makefile ] || make distclean
. release
./configure
make
cd po
cat >> POTFILES.in << EOF
[encoding: UTF-8]
src/constants.py
src/font-sampler.py
src/main.py
src/core/fonts.py
src/core/__init__.py
[type: gettext/glade]src/data/actions.ui
[type: gettext/glade]src/data/font-information.ui
[type: gettext/glade]src/data/font-manager.ui
[type: gettext/glade]src/data/font-sampler.ui
[type: gettext/glade]src/data/menus.ui
src/ui/actions.py
src/ui/export.py
src/ui/library.py
src/ui/preferences.py
src/ui/previews.py
src/ui/sampler.py
src/ui/treeviews.py
src/utils/common.py
src/utils/xmlutils.py
EOF
cat >> header << EOF
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009, 2010 Jerry Casiano
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to:
#
# Free Software Foundation, Inc.
# 51 Franklin Street, Fifth Floor
# Boston, MA  02110-1301, USA.
#
EOF
cp ../src/font-sampler ../src/font-sampler.py
intltool-update -p -x -g app
cd ../help/C/
xml2po -o ../../po/help.pot ./*.page
cd ../../po/
sed -i '1,5d' app.pot
cat header > font-manager.pot
cat header > font-manager-help.pot
cat app.pot >> font-manager.pot
cat help.pot >> font-manager-help.pot
URL="http://code.google.com/p/font-manager/issues/list"
sed -i  -e "s#PACKAGE\ VERSION#${VERSION}\ #g" \
-e "s#Report-Msgid-Bugs-To\:#Report-Msgid-Bugs-To\:\ ${URL}#g" *.pot
rm -f POTFILES.in header app.pot help.pot ../src/font-sampler.py
