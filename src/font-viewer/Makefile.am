
include $(top_srcdir)/Flags.mk

font_viewer_VALAFLAGS = $(AM_VALAFLAGS)

font_viewer_CFLAGS = \
	$(AM_VALA_CFLAGS) \
	-I$(top_srcdir)/lib/vala

font_viewer_LDADD = \
	$(AM_LDADD) \
	$(top_builddir)/lib/libfontmanager.la

font_viewer_SOURCES = \
	Application.vala \
	MainWindow.vala \
	$(top_srcdir)/config.vapi \
	$(top_srcdir)/lib/vala/FontManagerVala.vapi \
	$(top_srcdir)/lib/common/FontManager.vapi \
	$(top_srcdir)/lib/unicode/Unicode.vapi

pkglibexec_PROGRAMS = font-viewer

MAINTAINERCLEANFILES = Makefile.in
