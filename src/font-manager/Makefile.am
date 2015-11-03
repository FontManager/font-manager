include ValaSources.mk
include ${abs_top_builddir}/Flags.mk

font_manager_VALAFLAGS = \
	${AM_VALAFLAGS} \
	${abs_top_builddir}/lib/fontmanager.vapi

font_manager_CPPFLAGS = \
	${AM_CPPFLAGS} \
	-I${abs_top_builddir}/lib/

font_manager_LDADD = \
	${AM_LDADD} \
	${abs_top_builddir}/lib/libfontmanager.la

font_manager_SOURCES = \
	$(font_manager_VALASOURCES)

EXTRA_DIST = \
	ValaSources.mk

bin_PROGRAMS = font-manager

CLEANFILES = \
	*.stamp*

MAINTAINERCLEANFILES = \
	./Makefile.in

dist-hook:
	cd $(distdir) && \
	rm -f $(font_manager_VALASOURCES:.vala=.c) \
	*.stamp*
