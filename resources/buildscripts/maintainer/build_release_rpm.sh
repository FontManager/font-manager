#!/bin/sh

su -c 'yum update -y && yum groupinstall "Development Tools" "Fedora Packager" -y && yum install fontconfig-devel freetype-devel glib2-devel python-devel -y'

clean='no'
if [ ! -e ~/rpmbuild ]
then
    rpmdev-setuptree
    clean='yes'
fi
echo
echo 'Fetching source'
echo
[ -e font-manager ] || svn co http://font-manager.googlecode.com/svn/trunk/ font-manager
cd font-manager
svn update
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
mock --resultdir=./RESULTS/ -r fedora-$(cat /etc/system-release | tr -cd '[[:digit:]]')-$(arch) ~/rpmbuild/SRPMS/$PACKAGE*.src.rpm
echo 'Now running cleanup'
if [ $clean = 'yes' ]
then
    rm -rf ~/rpmbuild
else
    rm -f ~/rpmbuild/SRPMS/$PACKAGE*
    rm -f ~/rpmbuild/SPECS/$PACKAGE*
    rm -f ~/rpmbuild/SOURCES/$PACKAGE*
fi
make distclean
rm -f $PACKAGE-$VERSION.tar.bz2
echo
echo 'Done!'

