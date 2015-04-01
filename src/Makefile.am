include Flags.mk
include ValaSources.mk

resource_dir = ${abs_top_builddir}/resources
GLIB_COMPILE_RESOURCES = \
`$(PKG_CONFIG) --variable=glib_compile_resources gio-2.0`

FontManagerGResource.c :
	$(GLIB_COMPILE_RESOURCES) \
	--sourcedir=$(resource_dir) \
	--generate-source \
	--target=$@ \
	$(resource_dir)/FontManagerGResource.xml

BUILT_SOURCES = FontManagerGResource.c

font_manager_SOURCES = \
	$(font_manager_VALASOURCES) \
	Glue/_Glue_.c \
	Glue/Private.h \
	$(BUILT_SOURCES)

bin_PROGRAMS = font-manager

EXTRA_DIST = $(font_manager_VALASOURCES)

dist-hook:
	cd $(distdir) && \
	rm -f $(font_manager_VALASOURCES:.vala=.c) \
	$(BUILT_SOURCES) \
	font_manager_vala.stamp

clean-local:
	rm -f $(font_manager_VALASOURCES:.vala=.c) \
	$(BUILT_SOURCES) \
	font_manager_vala.stamp
