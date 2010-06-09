#!/bin/sh
# This script *should* produce an rpm package, at least on Fedora anyway

# If this is NOT the first run on this system comment or remove the following lines
echo
echo "This script will need superuser access to install required development packages"
echo
echo
su -c 'yum install rpmdevtools subversion make fontconfig-devel freetype-devel glib2-devel -y'
#

clean='no'
if [ ! -e ~/rpmbuild ]
then
    rpmdev-setuptree
    clean='yes'
fi
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
cp -f fedora/$PACKAGE.spec ~/rpmbuild/SPECS/
cp $PACKAGE-$VERSION.tar.bz2 ~/rpmbuild/SOURCES/
echo
echo 'Building package'
echo
rpmbuild -bb ~/rpmbuild/SPECS/$PACKAGE.spec
rm -rf RESULTS
mkdir RESULTS
cp -f ~/rpmbuild/RPMS/$(arch)/$PACKAGE*rpm ./RESULTS/
echo 'Now running cleanup'
rm -f $PACKAGE-$VERSION.tar.bz2
make clean
if [ $clean = 'yes' ]
then
    rm -rf ~/rpmbuild
else
    rm -f ~/rpmbuild/RPMS/noarch/$PACKAGE*
    rm -f ~/rpmbuild/SPECS/$PACKAGE*
    rm -f ~/rpmbuild/SOURCES/$PACKAGE*
fi
echo
echo 'Done!'
echo
echo 'If the build was successful you will find an rpm package in font-manager/RESULTS'

