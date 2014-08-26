# -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.65])
AC_INIT([font-manager], [0.5.7])
AM_INIT_AUTOMAKE

# Checks for programs.

AC_PROG_CC
AC_PROG_INSTALL
AC_PATH_PROG(PYTHON, python)
AC_PATH_PROG(STRIP, strip)
AC_PATH_PROG(FIND, find)

# Checks for libraries.

PKG_CHECK_MODULES([fontconfig], [fontconfig])
PKG_CHECK_MODULES([freetype2], [freetype2])
PKG_CHECK_MODULES([glib], [glib-2.0])
PKG_CHECK_MODULES([pango], [pango])
PKG_CHECK_MODULES([pangoft2], [pangoft2])
PKG_CHECK_MODULES([sqlite], [sqlite3])

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

# Optional arguments

AC_ARG_ENABLE([bytecode],
[AS_HELP_STRING([--enable-bytecode], [Compile python source code])],
[case "${enableval}" in
  yes) bytecode=true ;;
  no)  bytecode=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-bytecode]) ;;
esac],
[bytecode=true])
AM_CONDITIONAL([BYTECODE], [test x$bytecode = xtrue])

AC_ARG_ENABLE([nls],
[AS_HELP_STRING([--enable-nls], [Include translations])],
[case "${enableval}" in
  yes) nls=true ;;
  no)  nls=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-nls]) ;;
esac],
[nls=false])
AM_CONDITIONAL([NLS], [test x$nls = xtrue])

AC_ARG_ENABLE([debuginfo],
[AS_HELP_STRING([--enable-debuginfo], [Do not strip libraries])],
[case "${enableval}" in
  yes) debuginfo=true ;;
  no)  debuginfo=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-debuginfo]) ;;
esac],
[debuginfo=false])
AM_CONDITIONAL([DEBUGINFO], [test x$debuginfo = xtrue])

AC_ARG_ENABLE([winlib],
[AS_HELP_STRING([--enable-winlib], [Install .dll instead of .so (cygwin-ports)])],
[case "${enableval}" in
  yes) winlib=true ;;
  no)  winlib=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-winlib]) ;;
esac],
[winlib=false])
AM_CONDITIONAL([WINLIB], [test x$winlib = xtrue])

# Files that should be created by configure

AC_CONFIG_FILES([Makefile])

# Required

AC_OUTPUT
