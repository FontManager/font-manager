dnl
dnl Font Manager
dnl
dnl Simple font management for Gtk+ desktops
dnl
dnl Copyright © 2009 - 2014 Jerry Casiano
dnl

dnl Initialize autoconf
AC_PREREQ([2.69])
AC_INIT([font-manager], [0.7.2], [https://code.google.com/p/font-manager/issues/list])
AC_CONFIG_MACRO_DIR([m4])
AC_SUBST([ACLOCAL_AMFLAGS], ["-I $ac_macro_dir \${ACLOCAL_FLAGS}"])

dnl Initialize automake
AM_INIT_AUTOMAKE([1.11 foreign subdir-objects dist-bzip2])
AM_SILENT_RULES([yes])

dnl Initialize libtool
LT_INIT()

dnl Check for basics
AC_PROG_CC()
AM_PROG_VALAC([0.24])
AC_PROG_INSTALL()
AC_PROG_MKDIR_P()
AC_PROG_SED()

dnl i18n
IT_PROG_INTLTOOL()
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST([GETTEXT_PACKAGE])
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])

dnl Check for libraries.
PKG_PROG_PKG_CONFIG()
PKG_CHECK_MODULES(XML, libxml-2.0 >= 2.9)
PKG_CHECK_MODULES(FREETYPE, freetype2 >= 2.5)
PKG_CHECK_MODULES(FONTCONFIG, fontconfig >= 2.1)
PKG_CHECK_MODULES(GOBJECT, gobject-2.0 >= 2.4)
PKG_CHECK_MODULES(GLIB, glib-2.0 >= 2.4)
PKG_CHECK_MODULES(JSONGLIB, json-glib-1.0 >= 0.15)
PKG_CHECK_MODULES(GMODULE, gmodule-2.0 >= 2.4)
PKG_CHECK_MODULES(GIO, gio-2.0 >= 2.4)
PKG_CHECK_MODULES(CAIRO, cairo >= 1.1)
PKG_CHECK_MODULES(GTK_312, gtk+-3.0 >= 3.12)
PKG_CHECK_MODULES(GTK_314, gtk+-3.0 >= 3.14, [AC_SUBST(GTK_314, [" -D GTK_314"])], [:])
PKG_CHECK_MODULES(GTK_316, gtk+-3.0 >= 3.16, [AC_SUBST(GTK_316, [" -D GTK_316"])], [:])
PKG_CHECK_MODULES(PANGO, pango >= 1.3)
PKG_CHECK_MODULES(PANGOCAIRO, pangocairo >= 1.3)
PKG_CHECK_MODULES(PANGOFT2, pangoft2 >= 1.3)
PKG_CHECK_MODULES(GEE, gee-0.8 >= 0.14)
PKG_CHECK_MODULES(GUCHARMAP, gucharmap-2.90 >= 3.12)
PKG_CHECK_MODULES(SQLITE3, sqlite3 >= 3.8)

dnl i18n
AM_GLIB_GNU_GETTEXT

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

dnl Optional Extensions

AM_CONDITIONAL(COMPILE_PYTHON_EXTENSIONS, [test ''])
AM_CONDITIONAL(INSTALL_NAUTILUS_EXTENSION, [test ''])
AM_CONDITIONAL(INSTALL_NEMO_EXTENSION, [test ''])

dnl Debian policy discourages shipping compiled python files.
dnl Red Hat policy encourages shipping compiled python files.
dnl Others, who knows?

AC_ARG_ENABLE([pycompile], AS_HELP_STRING([--enable-pycompile], [Enable compilation of Python extensions]))
AS_IF([test "x$enable_pycompile" = "xyes"], [
  AM_PATH_PYTHON
  AM_CONDITIONAL([COMPILE_PYTHON_EXTENSIONS], [test "x$enable_pycompile" = "xyes"])
])

AC_ARG_WITH([nautilus], AS_HELP_STRING([--with-nautilus], [Install Nautilus extension]))
AS_IF([test "x$with_nautilus" = "xyes"], [
    PKG_CHECK_MODULES(NAUTILUS_PYTHON, nautilus-python, [AM_CONDITIONAL([INSTALL_NAUTILUS_EXTENSION],[test "x$with_nautilus" = "xyes"])])
])

AC_ARG_WITH([nemo], AS_HELP_STRING([--with-nemo], [Install Nemo extension]))
AS_IF([test "x$with_nemo" = "xyes"], [
    PKG_CHECK_MODULES(NEMO_PYTHON, nemo-python, [AM_CONDITIONAL([INSTALL_NEMO_EXTENSION],[test "x$with_nemo" = "xyes"])])
])

# Doesn't install pc file. For now just install if requested.
# TODO : Check if thunarx-python is actually installed.
AC_ARG_WITH([thunar], AS_HELP_STRING([--with-thunar], [Install Thunar extension]))
AM_CONDITIONAL([INSTALL_THUNAR_EXTENSION], [test "x$with_thunar" = "xyes"])


dnl Output files
AC_CONFIG_FILES([
    Makefile
    extensions/Makefile
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


