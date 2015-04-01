#!/bin/bash

srcfile='ValaSources.mk'

if [ -z $1 ]; then
  srcdir='../src/'
else
  srcdir=$1
fi

if [ ! -d $srcdir ]; then
 echo "Source directory does not exist! Aborting." >&2
 exit 1
fi

cd $srcdir
echo "font_manager_VALASOURCES = \\" > $srcfile
for i in $(find . -type f -name '*.vala' -print | sort);
  do
    echo "$i \\" >> $srcfile;
done
sed -i '$ s/\\//' $srcfile


