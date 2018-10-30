
SUBDIRS = \
	unicode \
	common \
	orthographies \
	vala

libfontmanager_la_SOURCES =

libfontmanager_la_CFLAGS = $(AM_CFLAGS)

libfontmanager_la_LDFLAGS = \
	$(AM_LDADD) \
	-shared \
	-release @PACKAGE_VERSION@

libfontmanager_la_LIBADD = \
	$(AM_LDADD) \
	common/libfmcommon-@PACKAGE_VERSION@.la \
	unicode/libfmunicode-@PACKAGE_VERSION@.la \
	vala/libfmvala-@PACKAGE_VERSION@.la

pkglib_LTLIBRARIES = libfontmanager.la

MAINTAINERCLEANFILES = Makefile.in


