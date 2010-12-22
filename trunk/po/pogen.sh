#/bin/sh
test ! -e font-manager.pot || exit 0
cat >> POTFILES.in << EOF
[encoding: UTF-8]
[type: gettext/glade]src/data/actions.ui
[type: gettext/glade]src/data/font-information.ui
[type: gettext/glade]src/data/font-manager.ui
[type: gettext/glade]src/data/font-sampler.ui
[type: gettext/glade]src/data/font-janitor.ui
[type: gettext/glade]src/data/menus.ui
src/constants.py
src/font-sampler.py
src/main.py
src/core/fonts.py
src/core/__init__.py
src/ui/actions.py
src/ui/export.py
src/ui/fontconfig.py
src/ui/janitor.py
src/ui/library.py
src/ui/preferences.py
src/ui/previews.py
src/ui/treeviews.py
src/utils/common.py
src/utils/xmlutils.py
EOF
cat >> header << EOF
# Copyright (C) 2009, 2010 Jerry Casiano
#
# This file is distributed under the same license as the font-manager package.

EOF
cp ../src/font-sampler ../src/font-sampler.py
intltool-update -p -x -g messages
cd ../help
xml2po -o ../po/yelp.pot C/*.page
cd ../po
sed -i '1,5d' messages.pot
cat header > font-manager.pot
cat header > font-manager-help.pot
cat messages.pot >> font-manager.pot
cat yelp.pot >> font-manager-help.pot
URL="http://code.google.com/p/font-manager/issues/list"
sed -i  -e "s#PACKAGE\ VERSION#${VERSION}\ #g" \
-e "s#Report-Msgid-Bugs-To\:#Report-Msgid-Bugs-To\:\ ${URL}#g" *.pot
rm -f POTFILES.in header messages.pot yelp.pot ../src/font-sampler.py

