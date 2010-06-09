# -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.65])
AC_INIT([font-manager], [0.5.4])
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

# Optional arguments

AC_ARG_WITH([debuginfo],
[AS_HELP_STRING([--with-debuginfo], [Do not run strip on libraries])],
[case "${withval}" in
  yes) debuginfo=true ;;
  no)  debuginfo=false ;;
  *) AC_MSG_ERROR([bad value ${withval} for --with-debuginfo]) ;;
esac],
[debuginfo=false])
AM_CONDITIONAL([DEBUGINFO], [test x$debuginfo = xtrue])

AC_ARG_WITH([winlib],
[AS_HELP_STRING([--with-winlib], [Install .dll instead of .so])],
[case "${withval}" in
  yes) winlib=true ;;
  no)  winlib=false ;;
  *) AC_MSG_ERROR([bad value ${withval} for --with-winlib]) ;;
esac],
[winlib=false])
AM_CONDITIONAL([WINLIB], [test x$winlib = xtrue])


AC_CONFIG_FILES([
	Makefile
	src/constants.py.in
	src/main.py
	src/core/__init__.py
	src/ui/export.py
])

AC_OUTPUT
