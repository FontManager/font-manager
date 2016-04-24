
include $(top_srcdir)/Flags.mk

font_viewer_VALAFLAGS = \
	${AM_VALAFLAGS} \
	$(top_srcdir)/lib/fontmanager.vapi

font_viewer_CFLAGS = \
	${AM_CFLAGS} \
	-I$(top_srcdir)/lib/

font_viewer_LDADD = \
	${AM_LDADD} \
	$(top_srcdir)/lib/libfontmanager.la

font_viewer_SOURCES = \
	Application.vala \
	MainWindow.vala \
	State.vala

pkglibexec_PROGRAMS = font-viewer

CLEANFILES = \
	*.stamp*

MAINTAINERCLEANFILES = \
	Makefile.in

dist-hook:
	cd $(distdir) && rm -f $(font_viewer_SOURCES:.vala=.c) $(CLEANFILES)
