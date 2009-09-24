#!/bin/sh
# This script *should* produce a deb package, at least on Ubuntu anyway

# If this is NOT the first run on this system comment or remove the following lines
echo
echo "This script will need superuser access to install required development packages"
echo
echo
sudo apt-get update -qq
sudo apt-get install -y -q --install-recommends build-essential devscripts debhelper subversion
#

echo
echo 'Fetching source'
echo
svn co http://font-manager.googlecode.com/svn/trunk/ font-manager
cd font-manager
. ./release
echo
echo 'Preparing source'
echo
./configure
make dist-zip
rm -rf BUILD
mkdir BUILD
cd BUILD
unzip -q ../$PACKAGE-$VERSION.zip
cp -R ../debian $PACKAGE-$VERSION/
cp -R $PACKAGE-$VERSION $PACKAGE-$VERSION.orig
cd $PACKAGE-$VERSION
echo
echo 'Building package'
echo
debuild -us -uc
cd ../../
rm -rf RESULTS
mkdir RESULTS
cp -f BUILD/$PACKAGE*deb ./RESULTS/
echo 'Now running cleanup'
rm -f $PACKAGE-$VERSION.zip
rm -rf BUILD
echo
echo 'If the build was successful you will find a deb package in font-manager/RESULTS'


