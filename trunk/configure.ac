# -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.65])
AC_INIT([font-manager], [0.5.1])
AM_INIT_AUTOMAKE

# Checks for programs.

AC_PROG_CC
AC_PROG_INSTALL
AC_PATH_PROG(PYTHON, python)

# Checks for libraries.

PKG_CHECK_MODULES([FontConfig], [fontconfig])
PKG_CHECK_MODULES([FreeType2], [freetype2])
PKG_CHECK_MODULES([Glib], [glib-2.0])

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([Makefile src/Makefile src/font-manager src/constants.py.in src/core/__init__.py])
AC_OUTPUT
