dnl ***********************************************************************
dnl
dnl Font Manager
dnl
dnl Simple font management for Gtk+ desktops
dnl
dnl Copyright (C) 2009 - 2016 Jerry Casiano
dnl
dnl ***********************************************************************

dnl ***********************************************************************
dnl Initialize autoconf
dnl ***********************************************************************

AC_PREREQ([2.69])
AC_INIT(
    [font-manager],
    [0.7.3],
    [https://github.com/FontManager/master/issues],
    [font-manager],
    [http://fontmanager.github.io/],
)
AC_CONFIG_MACRO_DIR([m4])
AC_SUBST([ACLOCAL_AMFLAGS], ["-I $ac_macro_dir \${ACLOCAL_FLAGS}"])

dnl ***********************************************************************
dnl Initialize automake
dnl ***********************************************************************

AM_INIT_AUTOMAKE([1.11 foreign subdir-objects dist-bzip2])
AM_SILENT_RULES([yes])

dnl ***********************************************************************
dnl Check for basics
dnl ***********************************************************************

AC_PROG_CC()
AM_PROG_LIBTOOL
dnl 0.36 -> incompatible changes in Gtk.ListStore remove method
dnl 0.34 -> incompatible changes in json-glib vapi
dnl 0.28 -> incompatible changes in Gtk.TextBuffer API
AM_PROG_VALAC(
    [0.28],
    [:],
    AC_MSG_ERROR([

    Build requirements (valac) were not met:

    Please install Vala >= 0.28 and try again.

    https://wiki.gnome.org/Projects/Vala

    ])
)
C_PROG_INSTALL()
AC_PROG_MKDIR_P()
AC_PROG_SED()

dnl ***********************************************************************
dnl i18n
dnl ***********************************************************************

AM_GLIB_GNU_GETTEXT()
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST([GETTEXT_PACKAGE])
AC_DEFINE_UNQUOTED(
    GETTEXT_PACKAGE,
    "$GETTEXT_PACKAGE",
    [The name of the gettext domain]
)
IT_PROG_INTLTOOL()

dnl ***********************************************************************
dnl Initialize libtool
dnl ***********************************************************************

LT_INIT()

dnl ***********************************************************************
dnl Check for libraries.
dnl ***********************************************************************

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
PKG_CHECK_MODULES(GTK_316, gtk+-3.0 >= 3.16)
PKG_CHECK_MODULES(PANGO, pango >= 1.3)
PKG_CHECK_MODULES(PANGOCAIRO, pangocairo >= 1.3)
PKG_CHECK_MODULES(PANGOFT2, pangoft2 >= 1.3)
PKG_CHECK_MODULES(GEE, gee-0.8 >= 0.14)
PKG_CHECK_MODULES(GUCHARMAP, gucharmap-2.90 >= 3.12)
PKG_CHECK_MODULES(SQLITE3, sqlite3 >= 3.8)

dnl ***********************************************************************
dnl GSettings support
dnl ***********************************************************************

GLIB_GSETTINGS()

dnl ***********************************************************************
dnl Check for yelp-tools
dnl ***********************************************************************

AC_CHECK_PROG(YELP_TOOLS, "yelp-build", yes)
if test "x$YELP_TOOLS" != "xyes";
    then
        AC_MSG_ERROR([

        Application requirements (yelp-tools) were not met:

        Please install yelp-tools and try again.

        https://wiki.gnome.org/Apps/Yelp/Tools

    ])
fi

dnl ***********************************************************************
dnl Initialize yelp support
dnl ***********************************************************************

YELP_HELP_INIT()

dnl ***********************************************************************
dnl Check for supporting applications
dnl ***********************************************************************

file_roller_support="no"
AC_ARG_WITH(
    [file-roller],
    AS_HELP_STRING([--with-file-roller], [file-roller support])
)
AS_IF([test "x$with_file_roller" = "xyes"], [
  AC_SUBST(HAVE_FILE_ROLLER, [" -D HAVE_FILE_ROLLER"]),
  file_roller_support="yes"
])

dnl ***********************************************************************
dnl Optional Extensions
dnl ***********************************************************************

# Don't check for extension requirements to avoid build deps.
AC_ARG_WITH([nautilus], AS_HELP_STRING([--with-nautilus], [Install Nautilus extension]))
AC_ARG_WITH([nemo], AS_HELP_STRING([--with-nemo], [Install Nemo extension]))
AC_ARG_WITH([thunarx], AS_HELP_STRING([--with-thunarx], [Install Thunar extension]))
AM_CONDITIONAL(COMPILE_PYTHON_EXTENSIONS, [test ''])
AM_CONDITIONAL(INSTALL_NAUTILUS_EXTENSION, [test ''])
AM_CONDITIONAL(INSTALL_NEMO_EXTENSION, [test ''])
AM_CONDITIONAL(INSTALL_THUNAR_EXTENSION, [test ''])
file_browser_support="no"
AS_IF(
  [test "x$with_nautilus" = "xyes" -o "x$with_nemo" = "xyes" -o "x$with_thunarx" = "xyes"],
  [file_browser_support="yes"]
)

dnl ***********************************************************************
dnl Debian policy discourages shipping compiled python files.
dnl Red Hat policy encourages shipping compiled python files.
dnl Others, who knows?
dnl ***********************************************************************

AC_ARG_ENABLE(
    [pycompile],
    AS_HELP_STRING(
        [--disable-pycompile],
        [Disable compilation of Python extensions]
    )
)
AS_IF([test "x$file_browser_support" != "xno" -a "x$enable_pycompile" != "xno"], [
  AM_PATH_PYTHON
  AM_CONDITIONAL([COMPILE_PYTHON_EXTENSIONS], [test "x$enable_pycompile" != "xno"])
])
AM_CONDITIONAL([INSTALL_NAUTILUS_EXTENSION],[test "x$with_nautilus" = "xyes"])
AM_CONDITIONAL([INSTALL_NEMO_EXTENSION],[test "x$with_nemo" = "xyes"])
AM_CONDITIONAL([INSTALL_THUNAR_EXTENSION], [test "x$with_thunarx" = "xyes"])

dnl ***********************************************************************
dnl Output files
dnl ***********************************************************************

AC_CONFIG_FILES([
    Makefile
    extensions/Makefile
    help/Makefile
    lib/Makefile
    lib/Common/About.vala
    lib/Common/Collections.vala
    lib/Common/Constants.vala
    lib/Common/Database.vala
    lib/Common/Settings.vala
    lib/FontConfig/Sources.vala
    lib/Glue/Makefile
    lib/UX/Utils/Utils.vala
    po/Makefile.in
    data/Makefile
    data/org.gnome.FontManager.appdata.xml
    data/org.gnome.FontManager.desktop
    data/org.gnome.FontViewer.desktop
    help/font-manager.1
    src/Makefile
    src/font-manager/Makefile
    src/font-manager/Application.vala
    src/font-manager/Main.vala
    src/font-manager/Migration.vala
    src/font-viewer/Makefile
    src/font-viewer/Application.vala
    tests/Makefile
])
AC_OUTPUT

dnl ***********************************************************************
dnl Useful? information
dnl ***********************************************************************

echo "

    Font Manager $PACKAGE_VERSION

    C compiler:             ${CC}
    Vala compiler:          ${VALAC}
    Installation prefix:    ${prefix}
    Archive Support:        $file_roller_support
    File Browser Support:   $file_browser_support
"
AS_IF([test "x$with_nautilus" = "xyes"], [
    echo "

    The Nautilus file manager extension requires nautilus-python

    Nautilus python bindings are available on most distributions.

        https://wiki.gnome.org/Projects/NautilusPython

    "
])
AS_IF([test "x$with_nemo" = "xyes"], [
    echo "

    The Nemo file manager extension requires nemo-python

    https://github.com/linuxmint/nemo-extensions/tree/master/nemo-python

    "
])
AS_IF([test "x$with_thunarx" = "xyes"], [
    echo "

    The Thunar file manager extension requires thunarx-python

    http://goodies.xfce.org/projects/bindings/thunarx-python


    Ubuntu/Debian users should see README file in extensions/

    "
])
