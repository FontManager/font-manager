#!/bin/sh

sudo apt-get update -qq
sudo apt-get upgrade -qq
sudo apt-get install -y -q --install-recommends build-essential devscripts debhelper python2.6-dev libfreetype6-dev libglib2.0-dev libfontconfig1-dev intltool binutils pbuilder subversion
[ -e /var/cache/pbuilder/base.tgz ] || sudo pbuilder create --debootstrapopts --variant=buildd

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
rm -rf BUILD
mkdir BUILD
mv $PACKAGE-$VERSION.tar.gz BUILD/$PACKAGE\_$VERSION.orig.tar.gz
cd BUILD
tar -xvf $PACKAGE\_$VERSION.orig.tar.gz
cp -R ../debian $PACKAGE-$VERSION/
cd $PACKAGE-$VERSION
chmod +x debian/rules
mkdir debian/source
echo '3.0 (quilt)' > debian/source/format
echo
echo 'Doing initial source build'
echo
debuild -S -us -uc
echo
echo 'Building package'
echo
sudo pbuilder build ../*.dsc
cd ../../
rm -rf RESULTS
mkdir RESULTS
cp -f /var/cache/pbuilder/result/$PACKAGE* ./RESULTS/
echo 'Now running cleanup'
rm -rf BUILD
make distclean
echo
echo 'If the build was successful you will find a deb package in font-manager/RESULTS'
echo
