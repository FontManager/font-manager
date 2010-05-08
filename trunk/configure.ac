# -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.65])
AC_INIT([font-manager], [0.5.2])
AM_INIT_AUTOMAKE

# Checks for programs.

AC_PROG_CC
AC_PROG_INSTALL
AC_PATH_PROG(PYTHON, python)
AC_PATH_PROG(STRIP, strip)

# Checks for libraries.

PKG_CHECK_MODULES([fontconfig], [fontconfig])
PKG_CHECK_MODULES([freetype2], [freetype2])
PKG_CHECK_MODULES([glib], [glib-2.0])

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([Makefile src/Makefile src/font-manager src/font-sampler src/constants.py.in src/main.py src/core/__init__.py src/ui/export.py])
AC_OUTPUT
