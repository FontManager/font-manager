#!/bin/sh
# This script *should* produce a deb package, at least on Ubuntu anyway

# If this is NOT the first run on this system comment or remove the following lines
echo
echo "This script will need superuser access to install required development packages"
echo
echo
sudo apt-get update -qq
sudo apt-get install -y -q --install-recommends build-essential devscripts debhelper python2.6-dev libfreetype6-dev libglib2.0-dev libfontconfig1-dev libpango1.0-dev intltool binutils subversion python-support autotools-dev
#

echo
echo 'Fetching source'
echo
[ ! -e font-manager ] || rm -rf font-manager
svn co http://font-manager.googlecode.com/svn/trunk/ font-manager
cd font-manager
find . -name '.svn' -print | xargs rm -rf
. ./release
echo
echo 'Preparing source'
echo
./configure
make dist-gzip
[ ! -e BUILD ] || rm -rf BUILD
mkdir BUILD
mv $PACKAGE-$VERSION.tar.gz BUILD/$PACKAGE\_$VERSION.orig.tar.gz
cd BUILD
tar -xvf $PACKAGE\_$VERSION.orig.tar.gz
cd $PACKAGE-$VERSION
echo 'Fetching debian folder'
wget http://font-manager.googlecode.com/svn/resources/buildscripts/debian.tar.gz
tar -xvf debian.tar.gz
chmod +x debian/rules
echo
echo 'Building package'
echo
debuild -us -uc
cd ../../
rm -rf RESULTS
mkdir RESULTS
cp -f BUILD/$PACKAGE*deb ./RESULTS/
echo 'Now running cleanup'
rm -rf BUILD
echo
echo 'If the build was successful you will find a deb package in font-manager/RESULTS'
echo
