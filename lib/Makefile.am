
include $(top_srcdir)/Flags.mk
include ValaSources.mk

SUBDIRS = \
	Glue

DATA_DIR = $(top_srcdir)/data

GLIB_COMPILE_RESOURCES = \
`$(PKG_CONFIG) --variable=glib_compile_resources gio-2.0`

FontManagerGResource.c :
	$(GLIB_COMPILE_RESOURCES) \
	--sourcedir=$(DATA_DIR) \
	--generate-source \
	--target=$@ \
	$(DATA_DIR)/FontManagerGResource.xml

BUILT_SOURCES = \
	FontManagerGResource.c \
	fontmanager.h

libfontmanager_la_CFLAGS = \
	$(AM_CFLAGS) \
	-fPIC \
	-shared

libfontmanager_la_LIBADD = \
	$(AM_LDADD)

libfontmanager_la_LDFLAGS = \
	-shared \
	-release @PACKAGE_VERSION@

libfontmanager_la_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	$(HAVE_FILE_ROLLER) \
	--gresources $(DATA_DIR)/FontManagerGResource.xml \
	--library fontmanager \
	-H fontmanager.h

libfontmanager_la_SOURCES = \
	$(libfontmanager_la_VALASOURCES) \
	$(BUILT_SOURCES) \
	FontConfig/_Common_.c \
	Glue/_Glue_.c \
	Glue/_Glue_.h \
	Glue/License.c \
	Glue/License.h \
	Glue/Vendor.c \
	Glue/Vendor.h

pkglib_LTLIBRARIES = libfontmanager.la

EXTRA_DIST = \
	ValaSources.mk

CLEANFILES = \
	$(BUILT_SOURCES) \
	*.stamp* \
	fontmanager.vapi

MAINTAINERCLEANFILES = \
	Makefile.in

dist-hook:
	cd $(distdir) && rm -f $(libfontmanager_la_VALASOURCES:.vala=.c) $(CLEANFILES)
