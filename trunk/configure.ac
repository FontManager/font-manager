dnl
dnl Font Manager
dnl
dnl Simple font management for Gtk+ desktops
dnl
dnl Copyright © 2009 - 2014 Jerry Casiano
dnl

dnl Initialize autoconf
AC_PREREQ([2.69])
AC_INIT([font-manager], [0.7], [https://code.google.com/p/font-manager/issues/list])
AC_CONFIG_MACRO_DIR([m4])
AC_SUBST([ACLOCAL_AMFLAGS], ["-I $ac_macro_dir \${ACLOCAL_FLAGS}"])

dnl Initialize automake
AM_INIT_AUTOMAKE([1.11 subdir-objects dist-bzip2])
AM_SILENT_RULES([yes])

dnl Initialize libtool
LT_INIT()

dnl Check for basics
AC_PROG_CC()
AM_PROG_VALAC([0.22])
AC_PROG_INSTALL()
AC_PROG_MKDIR_P()

dnl i18n
IT_PROG_INTLTOOL()
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST([GETTEXT_PACKAGE])
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])

dnl Check for libraries.
PKG_PROG_PKG_CONFIG()
PKG_CHECK_MODULES(XML, libxml-2.0 >= 2.4)
PKG_CHECK_MODULES(FREETYPE, freetype2 >= 2.5)
PKG_CHECK_MODULES(FONTCONFIG, fontconfig >= 2.1 )
PKG_CHECK_MODULES(GOBJECT, gobject-2.0 >= 2.4)
PKG_CHECK_MODULES(GLIB, glib-2.0 >= 2.4)
PKG_CHECK_MODULES(JSONGLIB, json-glib-1.0 >= 0.15)
PKG_CHECK_MODULES(GMODULE, gmodule-2.0 >= 2.4)
PKG_CHECK_MODULES(GIO, gio-2.0 >= 2.4)
PKG_CHECK_MODULES(CAIRO, cairo >= 1.1)
PKG_CHECK_MODULES(GTK, gtk+-3.0 >= 3.1)
PKG_CHECK_MODULES(PANGO, pango >= 1.3)
PKG_CHECK_MODULES(PANGOCAIRO, pangocairo >= 1.3)
PKG_CHECK_MODULES(PANGOFT2, pangoft2 >= 1.3)
PKG_CHECK_MODULES(GEE, gee-0.8 >= 0.1)
PKG_CHECK_MODULES(GUCHARMAP, gucharmap-2.90 >= 3.1)
PKG_CHECK_MODULES(SQLITE3, sqlite3 >= 3.8)

dnl GSettings support
GLIB_GSETTINGS()

dnl Check for yelp-tools
AC_CHECK_PROG(YELP_TOOLS, "yelp-build", yes)
if test "x$YELP_TOOLS" != "xyes";
then
    AC_MSG_ERROR([Application requirements (yelp-tools) were not met:

    Please install yelp-tools and try again.

    https://wiki.gnome.org/Apps/Yelp/Tools

])
fi

dnl Initialize yelp support
YELP_HELP_INIT()

dnl Check for supporting applications
AC_CHECK_PROG(HAVE_FILE_ROLLER, file-roller, yes)
if test "x$HAVE_FILE_ROLLER" != "xyes";
then
    AC_MSG_ERROR([Application requirements (file-roller) were not met:

    Please install File Roller and try again.

    https://wiki.gnome.org/Apps/FileRoller

])
fi

dnl Output files
AC_CONFIG_FILES([
    Makefile
    help/Makefile
    po/Makefile.in
    resources/Makefile
    src/Makefile
])

AC_OUTPUT


echo "
    Font Manager $VERSION

    C compiler: ${CC}
    Vala compiler: ${VALAC}
    Installation prefix: ${prefix}

"


