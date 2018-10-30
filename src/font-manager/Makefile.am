
include $(top_srcdir)/Flags.mk
include ValaSources.mk

font_manager_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	$(HAVE_FILE_ROLLER)

font_manager_CFLAGS = \
	$(AM_VALA_CFLAGS) \
	-I$(top_srcdir)/lib/vala

font_manager_LDADD = \
	$(AM_LDADD) \
	$(top_builddir)/lib/libfontmanager.la

font_manager_SOURCES = \
	$(font_manager_VALASOURCES) \
	$(top_srcdir)/config.vapi \
	$(top_srcdir)/lib/vala/FontManagerVala.vapi \
	$(top_srcdir)/lib/common/FontManager.vapi \
	$(top_srcdir)/lib/unicode/Unicode.vapi

bin_PROGRAMS = font-manager

MAINTAINERCLEANFILES = Makefile.in
