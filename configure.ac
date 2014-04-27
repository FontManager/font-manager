dnl
dnl Font Manager
dnl
dnl Simple font management for Gtk+ desktops
dnl
dnl Copyright © 2009 - 2014 Jerry Casiano
dnl

dnl Initialize autoconf
AC_PREREQ([2.69])
AC_INIT([font-manager], [0.0], [https://code.google.com/p/font-manager/issues/list])
AC_CONFIG_MACRO_DIR([m4])

dnl Initialize automake
AM_INIT_AUTOMAKE([1.11 subdir-objects dist-bzip2])

dnl Initialize libtool
LT_INIT()

dnl Check for basics
AC_PROG_CC()
AM_PROG_VALAC()
AC_PROG_INSTALL()
AC_PROG_MKDIR_P()
IT_PROG_INTLTOOL()

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

dnl Check for supporting applications
AC_CHECK_PROG(HAVE_FILE_ROLLER, file-roller, yes)
if test "x$HAVE_FILE_ROLLER" != "xyes";
then
    AC_MSG_ERROR([Application requirements (file-roller) were not met:

    Please install File Roller and try again.

    https://wiki.gnome.org/Apps/FileRoller

])
fi

AC_CHECK_PROG(DESKTOP_FILE_UTILS, desktop-file-install, yes)
if test "x$DESKTOP_FILE_UTILS" != "xyes";
then
    AC_MSG_ERROR([Application requirements (desktop-file-utils) were not met:

    Please install desktop-file-utils and try again.

    http://freedesktop.org/wiki/Software/desktop-file-utils/

])
fi

dnl Output files
AC_OUTPUT([
	Makefile
	src/Makefile
	resources/Makefile
	po/Makefile.in
])


