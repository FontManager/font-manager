include ValaSources.mk
include ${abs_top_builddir}/Flags.mk

SUBDIRS = \
	Glue

data_dir = ${abs_top_builddir}/data

GLIB_COMPILE_RESOURCES = \
`$(PKG_CONFIG) --variable=glib_compile_resources gio-2.0`

FontManagerGResource.c :
	$(GLIB_COMPILE_RESOURCES) \
	--sourcedir=$(data_dir) \
	--generate-source \
	--target=$@ \
	$(data_dir)/FontManagerGResource.xml

BUILT_SOURCES = \
	FontManagerGResource.c \
	fontmanager.h

libfontmanager_la_CPPFLAGS = \
	$(AM_CPPFLAGS) \
	-fPIC \
	-shared

libfontmanager_la_LIBADD = \
	$(AM_LDADD)

libfontmanager_la_LDFLAGS = \
	-shared \
	-release @PACKAGE_VERSION@

libfontmanager_la_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	$(GTK_314_OR_LATER) \
	$(GTK_316_OR_LATER) \
	$(VALA_0271_OR_LATER) \
	$(HAVE_FILE_ROLLER) \
	--gresources $(data_dir)/FontManagerGResource.xml \
	--library fontmanager \
	-H fontmanager.h

libfontmanager_la_SOURCES = \
	$(libfontmanager_la_VALASOURCES) \
	$(BUILT_SOURCES) \
	./FontConfig/_Common_.c \
	./Glue/_Glue_.c \
	./Glue/_Glue_.h \
	./Glue/License.c \
	./Glue/License.h \
	./Glue/Vendor.c \
	./Glue/Vendor.h

pkglib_LTLIBRARIES = libfontmanager.la

EXTRA_DIST = \
	ValaSources.mk

CLEANFILES = \
	$(BUILT_SOURCES) \
	./*.stamp* \
	./fontmanager.vapi

MAINTAINERCLEANFILES = \
	./Makefile.in

dist-hook:
	cd $(distdir) && \
	rm -f $(libfontmanager_la_VALASOURCES:.vala=.c) \
	$(BUILT_SOURCES) \
	*.stamp*
