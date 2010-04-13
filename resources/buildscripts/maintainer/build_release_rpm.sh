#!/bin/sh

su -c 'yum update -y && yum groupinstall "Development Tools" "Fedora Packager" -y'

echo
echo 'Fetching source'
echo
svn co http://font-manager.googlecode.com/svn/trunk/ font-manager
cd font-manager
find . -name '.svn' -print | xargs rm -rf
. ./release
echo
echo 'Preparing source'
echo
./configure
make dist-bzip2
rpmdev-setuptree
cp -f fedora/$PACKAGE.spec ~/rpmbuild/SPECS/
cp $PACKAGE-$VERSION.tar.bz2 ~/rpmbuild/SOURCES/
rpmbuild -bs ~/rpmbuild/SPECS/$PACKAGE.spec
echo
echo 'Building package'
echo
rm -rf RESULTS
mkdir RESULTS
mock --resultdir=./RESULTS/ -r fedora-12-i386 ~/rpmbuild/SRPMS/$PACKAGE*.src.rpm
echo 'Now running cleanup'
rm -f ~/rpmbuild/SRPMS/$PACKAGE*
rm -f ~/rpmbuild/SPECS/$PACKAGE*
rm -f ~/rpmbuild/SOURCES/$PACKAGE*
rm -f $PACKAGE-$VERSION.tar.bz2
rm -rf ~/rpmbuild
echo
echo 'Done!'

