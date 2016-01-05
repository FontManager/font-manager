#!/bin/sh
# Run this to generate all the initial makefiles, etc.

PKG_NAME=font-manager

srcdir=`dirname $0`
[ -z "$srcdir" ] && srcdir=.

# default version requirements ...
test "$REQUIRED_AUTOMAKE_VERSION" || REQUIRED_AUTOMAKE_VERSION=1.11.2
test "$REQUIRED_AUTORECONF_VERSION" || REQUIRED_AUTORECONF_VERSION=2.53
test "$REQUIRED_GLIB_GETTEXT_VERSION" || REQUIRED_GLIB_GETTEXT_VERSION=2.2.0
test "$REQUIRED_INTLTOOL_VERSION" || REQUIRED_INTLTOOL_VERSION=0.25
test "$REQUIRED_PKG_CONFIG_VERSION" || REQUIRED_PKG_CONFIG_VERSION=0.14.0
test "$REQUIRED_GTK_DOC_VERSION" || REQUIRED_GTK_DOC_VERSION=1.0

# a list of required m4 macros.  Package can set an initial value
test "$REQUIRED_M4MACROS" || REQUIRED_M4MACROS=

# Not all echo versions allow -n, so we check what is possible. This test is
# based on the one in autoconf.
ECHO_C=
ECHO_N=
case `echo -n x` in
-n*)
  case `echo 'x\c'` in
  *c*) ;;
  *)   ECHO_C='\c';;
  esac;;
*)
  ECHO_N='-n';;
esac

# some terminal codes ...
if tty 1>/dev/null 2>&1; then
    boldface="`tput bold 2>/dev/null`"
    normal="`tput sgr0 2>/dev/null`"
else
    boldface=
    normal=
fi

printbold() {
    echo $ECHO_N "$boldface" $ECHO_C
    echo "$@"
    echo $ECHO_N "$normal" $ECHO_C
}

printerr() {
    echo "$@" >&2
}

# Usage:
#     compare_versions MIN_VERSION ACTUAL_VERSION
# returns true if ACTUAL_VERSION >= MIN_VERSION
compare_versions() {
    ch_min_version=$1
    ch_actual_version=$2
    ch_status=0
    IFS="${IFS=  }"; ch_save_IFS="$IFS"; IFS="."
    set $ch_actual_version
    for ch_min in $ch_min_version; do
        ch_cur=`echo $1 | sed 's/[^0-9].*$//'`; shift # remove letter suffixes
        if [ -z "$ch_min" ]; then break; fi
        if [ -z "$ch_cur" ]; then ch_status=1; break; fi
        if [ $ch_cur -gt $ch_min ]; then break; fi
        if [ $ch_cur -lt $ch_min ]; then ch_status=1; break; fi
    done
    IFS="$ch_save_IFS"
    return $ch_status
}

# Usage:
#     version_check PACKAGE VARIABLE CHECKPROGS MIN_VERSION SOURCE
# checks to see if the package is available
version_check() {
    vc_package=$1
    vc_variable=$2
    vc_checkprogs=$3
    vc_min_version=$4
    vc_source=$5
    vc_status=1
    local ${vc_variable}_VERSION

    vc_checkprog=`eval echo "\\$$vc_variable"`
    if [ -n "$vc_checkprog" ]; then
    printbold "using $vc_checkprog for $vc_package"
    return 0
    fi

    printbold "checking for $vc_package >= $vc_min_version..."
    for vc_checkprog in $vc_checkprogs; do
    echo $ECHO_N "  testing $vc_checkprog... " $ECHO_C
    if $vc_checkprog --version < /dev/null > /dev/null 2>&1; then
        vc_actual_version=`$vc_checkprog --version | head -n 1 | \
                               sed 's/^.*[  ]\([0-9.]*[a-z]*\).*$/\1/'`
        if compare_versions $vc_min_version $vc_actual_version; then
        echo "found $vc_actual_version"
        # set variables
        eval "$vc_variable=$vc_checkprog; \
            ${vc_variable}_VERSION=$vc_actual_version"
        vc_status=0
        break
        else
        echo "too old (found version $vc_actual_version)"
        fi
    else
        echo "not found."
    fi
    done
    if [ "$vc_status" != 0 ]; then
    printerr "***Error***: You must have $vc_package >= $vc_min_version installed"
    printerr "  to build $PKG_NAME.  Download the appropriate package for"
    printerr "  from your distribution or get the source tarball at"
        printerr "    $vc_source"
    printerr
    exit $vc_status
    fi
    return $vc_status
}

# Usage:
#     require_m4macro filename.m4
# adds filename.m4 to the list of required macros
require_m4macro() {
    case "$REQUIRED_M4MACROS" in
    $1\ * | *\ $1\ * | *\ $1) ;;
    *) REQUIRED_M4MACROS="$REQUIRED_M4MACROS $1" ;;
    esac
}

# Usage:
#     add_to_cm_macrodirs dirname
# Adds the dir to $cm_macrodirs, if it's not there yet.
add_to_cm_macrodirs() {
    case $cm_macrodirs in
    "$1 "* | *" $1 "* | *" $1") ;;
    *) cm_macrodirs="$cm_macrodirs $1";;
    esac
}

# Usage:
#     print_m4macros_error
# Prints an error message saying that autoconf macros were misused
print_m4macros_error() {
    printerr "***Error***: some autoconf macros required to build $PKG_NAME"
    printerr "  were not found in your aclocal path, or some forbidden"
    printerr "  macros were found.  Perhaps you need to adjust your"
    printerr "  ACLOCAL_PATH?"
    printerr
}

# Usage:
#     check_m4macros
# Checks that all the requested macro files are in the aclocal macro path
# Uses REQUIRED_M4MACROS and ACLOCAL_PATH variables.
check_m4macros() {
    # construct list of macro directories
    cm_macrodirs=`aclocal --print-ac-dir`
    # aclocal also searches a version specific dir, eg. /usr/share/aclocal-1.9
    # but it contains only Automake's own macros, so we can ignore it.

    # Read the dirlist file
    if [ -s $cm_macrodirs/dirlist ]; then
    cm_dirlist=`sed 's/[    ]*#.*//;/^$/d' $cm_macrodirs/dirlist`
    if [ -n "$cm_dirlist" ] ; then
        for cm_dir in $cm_dirlist; do
        if [ -d $cm_dir ]; then
            add_to_cm_macrodirs $cm_dir
        fi
        done
    fi
    fi

    # Parse $ACLOCAL_PATH
    IFS="${IFS=  }"; save_IFS="$IFS"; IFS=":"
    for dir in ${ACLOCAL_PATH}; do
    add_to_cm_macrodirs "$dir"
    done
    IFS="$save_IFS"

    cm_status=0
    if [ -n "$REQUIRED_M4MACROS" ]; then
    printbold "Checking for required M4 macros..."
    # check that each macro file is in one of the macro dirs
    for cm_macro in $REQUIRED_M4MACROS; do
        cm_macrofound=false
        for cm_dir in $cm_macrodirs; do
        if [ -f "$cm_dir/$cm_macro" ]; then
            cm_macrofound=true
            break
        fi
        # The macro dir in Cygwin environments may contain a file
        # called dirlist containing other directories to look in.
        if [ -f "$cm_dir/dirlist" ]; then
            for cm_otherdir in `cat $cm_dir/dirlist`; do
            if [ -f "$cm_otherdir/$cm_macro" ]; then
                cm_macrofound=true
                    break
            fi
            done
        fi
        done
        if $cm_macrofound; then
        :
        else
        printerr "  $cm_macro not found"
        cm_status=1
        fi
    done
    fi
    if [ "$cm_status" != 0 ]; then
        print_m4macros_error
        exit $cm_status
    fi
}

want_glib_gettext=false
want_intltool=false
want_pkg_config=false
want_gtk_doc=false
want_maintainer_mode=false

version_check automake AUTOMAKE automake $REQUIRED_AUTOMAKE_VERSION \
    "http://ftp.gnu.org/pub/gnu/automake/automake-$REQUIRED_AUTOMAKE_VERSION.tar.xz"

version_check autoreconf AUTORECONF autoreconf $REQUIRED_AUTORECONF_VERSION \
    "http://ftp.gnu.org/pub/gnu/autoconf/autoconf-$REQUIRED_AUTORECONF_VERSION.tar.xz"

find_configure_files() {
    configure_ac=
    if test -f "$1/configure.ac"; then
    configure_ac="$1/configure.ac"
    elif test -f "$1/configure.in"; then
    configure_ac="$1/configure.in"
    fi
    if test "x$configure_ac" != x; then
    echo "$configure_ac"
    autoconf -t 'AC_CONFIG_SUBDIRS:$1' "$configure_ac" | while read dir; do
        find_configure_files "$1/$dir"
    done
    fi
}

configure_files="`find_configure_files $srcdir`"

for configure_ac in $configure_files; do
    dirname=`dirname $configure_ac`
    if [ -f $dirname/NO-AUTO-GEN ]; then
        echo skipping $dirname -- flagged as no auto-gen
        continue
    fi
    if grep "^AM_GLIB_GNU_GETTEXT" $configure_ac >/dev/null; then
        want_glib_gettext=true
    fi
    if grep "^AC_PROG_INTLTOOL" $configure_ac >/dev/null ||
       grep "^IT_PROG_INTLTOOL" $configure_ac >/dev/null; then
        want_intltool=true
    fi
    if grep "^PKG_CHECK_MODULES" $configure_ac >/dev/null; then
        want_pkg_config=true
    fi
    if grep "^GTK_DOC_CHECK" $configure_ac >/dev/null; then
        want_gtk_doc=true
    fi

    # check that AM_MAINTAINER_MODE is used
    if grep "^AM_MAINTAINER_MODE" $configure_ac >/dev/null; then
        want_maintainer_mode=true
    fi

    if grep "^YELP_HELP_INIT" $configure_ac >/dev/null; then
        require_m4macro yelp.m4
    fi

    if grep "^APPDATA_XML" $configure_ac >/dev/null; then
        require_m4macro appdata-xml.m4
    fi

    if grep "^APPSTREAM_XML" $configure_ac >/dev/null; then
        require_m4macro appstream-xml.m4
    fi

done

if $want_glib_gettext; then
    version_check glib-gettext GLIB_GETTEXTIZE glib-gettextize $REQUIRED_GLIB_GETTEXT_VERSION \
        "ftp://ftp.gtk.org/pub/gtk/v2.2/glib-$REQUIRED_GLIB_GETTEXT_VERSION.tar.gz"
    require_m4macro glib-gettext.m4
fi

if $want_intltool; then
    version_check intltool INTLTOOLIZE intltoolize $REQUIRED_INTLTOOL_VERSION \
        "http://ftp.gnome.org/pub/GNOME/sources/intltool/"
    require_m4macro intltool.m4
fi

if $want_pkg_config; then
    version_check pkg-config PKG_CONFIG pkg-config $REQUIRED_PKG_CONFIG_VERSION \
        "'http://www.freedesktop.org/software/pkgconfig/releases/pkgconfig-$REQUIRED_PKG_CONFIG_VERSION.tar.gz"
    require_m4macro pkg.m4
fi

if $want_gtk_doc; then
    version_check gtk-doc GTKDOCIZE gtkdocize $REQUIRED_GTK_DOC_VERSION \
        "http://ftp.gnome.org/pub/GNOME/sources/gtk-doc/"
    require_m4macro gtk-doc.m4
fi

check_m4macros

topdir=`pwd`
for configure_ac in $configure_files; do
    dirname=`dirname $configure_ac`
    basename=`basename $configure_ac`
    if [ -f $dirname/NO-AUTO-GEN ]; then
        echo skipping $dirname -- flagged as no auto-gen
    elif [ ! -w $dirname ]; then
        echo skipping $dirname -- directory is read only
    else
    printbold "Processing $configure_ac"
    cd $dirname

    # if the AC_CONFIG_MACRO_DIR() macro is used, create that directory
    # This is a automake bug fixed in automake 1.13.2
    # See http://debbugs.gnu.org/cgi/bugreport.cgi?bug=13514
    m4dir=`autoconf --trace 'AC_CONFIG_MACRO_DIR:$1'`
    if [ -n "$m4dir" ]; then
        mkdir -p $m4dir
    fi

    if grep "^AM_GLIB_GNU_GETTEXT" $basename >/dev/null; then
       printbold "Running $GLIB_GETTEXTIZE... Ignore non-fatal messages."
       echo "no" | $GLIB_GETTEXTIZE --force --copy || exit 1
    fi

    if grep "^GTK_DOC_CHECK" $basename >/dev/null; then
        printbold "Running $GTKDOCIZE..."
        $GTKDOCIZE --copy || exit 1
    fi

    if grep "^AC_PROG_INTLTOOL" $basename >/dev/null ||
           grep "^IT_PROG_INTLTOOL" $basename >/dev/null; then
        printbold "Running $INTLTOOLIZE..."
        $INTLTOOLIZE --force --copy --automake || exit 1
    fi

    # Now that all the macros are sorted, run autoreconf ...
    printbold "Running autoreconf..."
    autoreconf --verbose --force --install -Wno-portability || exit 1

    cd "$topdir"
    fi
done

conf_flags=""

if $want_maintainer_mode; then
    conf_flags="--enable-maintainer-mode"
fi

if test x$NOCONFIGURE = x; then

    if [ "$#" = 0 ]; then
        printerr
        printerr "**Warning**: I am going to run \`configure' with no arguments."
        printerr "If you wish to pass any to it, please specify them on the"
        printerr \`$0\'" command line."
        printerr
    fi

    printbold Running $srcdir/configure $conf_flags "$@" ...
    $srcdir/configure $conf_flags "$@" \
    && echo Now type \`make\' to compile $PKG_NAME || exit 1
else
    echo Skipping configure process.
fi
