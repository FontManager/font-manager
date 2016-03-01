dnl
dnl Font Manager
dnl
dnl Simple font management for Gtk+ desktops
dnl
dnl Copyright (C) 2009 - 2016 Jerry Casiano
dnl
dnl
dnl Initialize autoconf
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
dnl
dnl Initialize automake
    AM_INIT_AUTOMAKE([1.11 foreign subdir-objects dist-bzip2])
    AM_SILENT_RULES([yes])
dnl
dnl Check for basics
    AC_PROG_CC()
    AM_PROG_LIBTOOL
    dnl Gtk.TextBuffer API break
    AM_PROG_VALAC([0.28])
    C_PROG_INSTALL()
    AC_PROG_MKDIR_P()
    AC_PROG_SED()
dnl
dnl i18n
dnl
    AM_GLIB_GNU_GETTEXT()
    GETTEXT_PACKAGE=AC_PACKAGE_NAME
    AC_SUBST([GETTEXT_PACKAGE])
    AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])
dnl
dnl Call to intltoolize chokes on indentation
IT_PROG_INTLTOOL()
dnl
dnl Initialize libtool
    LT_INIT()
dnl
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
    PKG_CHECK_MODULES(GTK_316, gtk+-3.0 >= 3.16)
    PKG_CHECK_MODULES(PANGO, pango >= 1.3)
    PKG_CHECK_MODULES(PANGOCAIRO, pangocairo >= 1.3)
    PKG_CHECK_MODULES(PANGOFT2, pangoft2 >= 1.3)
    PKG_CHECK_MODULES(GEE, gee-0.8 >= 0.14)
    PKG_CHECK_MODULES(GUCHARMAP, gucharmap-2.90 >= 3.12)
    PKG_CHECK_MODULES(SQLITE3, sqlite3 >= 3.8)
dnl
dnl GSettings support
    GLIB_GSETTINGS()
dnl
dnl Check for yelp-tools
    AC_CHECK_PROG(YELP_TOOLS, "yelp-build", yes)
    if test "x$YELP_TOOLS" != "xyes";
        then
            AC_MSG_ERROR([

            Application requirements (yelp-tools) were not met:

            Please install yelp-tools and try again.

            https://wiki.gnome.org/Apps/Yelp/Tools

        ])
    fi
dnl
dnl Initialize yelp support
    YELP_HELP_INIT()
dnl
dnl Check for supporting applications
    AC_CHECK_PROG(FILE_ROLLER, file-roller, yes)
    AS_IF([test "x$FILE_ROLLER" = "xyes"], [
      AC_SUBST(HAVE_FILE_ROLLER, [" -D HAVE_FILE_ROLLER"])
    ])
dnl
dnl Optional Extensions
dnl
    AM_CONDITIONAL(COMPILE_PYTHON_EXTENSIONS, [test ''])
    AM_CONDITIONAL(INSTALL_NAUTILUS_EXTENSION, [test ''])
    AM_CONDITIONAL(INSTALL_NEMO_EXTENSION, [test ''])
    AM_CONDITIONAL(INSTALL_THUNAR_EXTENSION, [test ''])
    file_browser_support="no"
dnl
dnl Debian policy discourages shipping compiled python files.
dnl Red Hat policy encourages shipping compiled python files.
dnl Others, who knows?
dnl
    AC_ARG_ENABLE([pycompile], AS_HELP_STRING([--disable-pycompile], [Disable compilation of Python extensions]))
    AS_IF([test "x$enable_pycompile" != "xno"], [
      AM_PATH_PYTHON
      AM_CONDITIONAL([COMPILE_PYTHON_EXTENSIONS], [test "x$enable_pycompile" != "xno"])
    ])
dnl
    AC_ARG_WITH([nautilus], AS_HELP_STRING([--with-nautilus], [Install Nautilus extension]))
    AS_IF([test "x$with_nautilus" = "xyes"], [
        file_browser_support="yes"
        PKG_CHECK_MODULES(NAUTILUS_PYTHON, nautilus-python, [AM_CONDITIONAL([INSTALL_NAUTILUS_EXTENSION],[test "x$with_nautilus" = "xyes"])])
    ])
dnl
    AC_ARG_WITH([nemo], AS_HELP_STRING([--with-nemo], [Install Nemo extension]))
    AS_IF([test "x$with_nemo" = "xyes"], [
        file_browser_support="yes"
        PKG_CHECK_MODULES(NEMO_PYTHON, nemo-python, [AM_CONDITIONAL([INSTALL_NEMO_EXTENSION],[test "x$with_nemo" = "xyes"])])
    ])
dnl
# Doesn't install pc file. For now just install if requested.
# TODO : Check if thunarx-python is actually installed.
    AC_ARG_WITH([thunar], AS_HELP_STRING([--with-thunar], [Install Thunar extension]))
    AS_IF([test "x$with_thunar" = "xyes"], [
        file_browser_support="yes"
        AM_CONDITIONAL([INSTALL_THUNAR_EXTENSION], [test "x$with_thunar" = "xyes"])
    ])
dnl
dnl Output files
    AC_CONFIG_FILES([
        Makefile
        extensions/Makefile
        help/Makefile
        lib/Makefile
        lib/Common/About.vala
        lib/Common/Collections.vala
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
        src/Makefile
        src/font-manager/Makefile
        src/font-manager/Application.vala
        src/font-manager/Main.vala
        src/font-manager/Migration.vala
        src/font-viewer/Makefile
        src/font-viewer/Application.vala
    ])
dnl Process input files
    AC_OUTPUT
dnl
dnl Useful? information
    echo "
        Font Manager $PACKAGE_VERSION

        C compiler:             ${CC}
        Vala compiler:          ${VALAC}
        Installation prefix:    ${prefix}
        Archive Support:        ${FILE_ROLLER}
        File Browser Support:   $file_browser_support
    "
dnl
