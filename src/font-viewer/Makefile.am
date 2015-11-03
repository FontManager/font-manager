
include ${abs_top_builddir}/Flags.mk

font_viewer_VALAFLAGS = \
	${AM_VALAFLAGS} \
	${abs_top_builddir}/lib/fontmanager.vapi

font_viewer_CPPFLAGS = \
	${AM_CPPFLAGS} \
	-I${abs_top_builddir}/lib/

font_viewer_LDADD = \
	${AM_LDADD} \
	${abs_top_builddir}/lib/libfontmanager.la

font_viewer_SOURCES = \
	Application.vala \
	MainWindow.vala \
	State.vala

pkglibexec_PROGRAMS = font-viewer

CLEANFILES = \
	*.stamp*

MAINTAINERCLEANFILES = \
	./Makefile.in

dist-hook:
	cd $(distdir) && \
	rm -f $(font_viewer_SOURCES:.vala=.c) \
	*.stamp*
