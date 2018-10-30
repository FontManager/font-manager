include $(top_srcdir)/Flags.mk
include ValaSources.mk

libfmvala_@PACKAGE_VERSION@_la_CFLAGS = $(AM_VALA_CFLAGS)

libfmvala_@PACKAGE_VERSION@_la_LDFLAGS = $(AM_LDADD)

libfmvala_@PACKAGE_VERSION@_la_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--library FontManager \
	--vapi FontManagerVala.vapi \
	-H FontManagerVala.h

libfmvala_@PACKAGE_VERSION@_la_SOURCES = \
	$(libfontmanager_la_VALASOURCES) \
	$(top_srcdir)/config.vapi \
	$(top_srcdir)/lib/common/FontManager.vapi \
	$(top_srcdir)/lib/unicode/Unicode.vapi

noinst_LTLIBRARIES = libfmvala-@PACKAGE_VERSION@.la

MAINTAINERCLEANFILES = Makefile.in *.stamp

EXTRA_DIST = \
	FontManagerVala.h \
	FontManagerVala.vapi
