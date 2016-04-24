
include $(top_srcdir)/Flags.mk
include ValaSources.mk

font_manager_VALAFLAGS = \
	${AM_VALAFLAGS} \
	$(HAVE_FILE_ROLLER) \
	$(top_srcdir)/lib/fontmanager.vapi

font_manager_CFLAGS = \
	${AM_CFLAGS} \
	-I$(top_srcdir)/lib/

font_manager_LDADD = \
	${AM_LDADD} \
	$(top_srcdir)/lib/libfontmanager.la

font_manager_SOURCES = \
	$(font_manager_VALASOURCES)

EXTRA_DIST = \
	ValaSources.mk

bin_PROGRAMS = font-manager

CLEANFILES = \
	*.stamp*

MAINTAINERCLEANFILES = \
	Makefile.in

dist-hook:
	cd $(distdir) && rm -f $(font_manager_VALASOURCES:.vala=.c) $(CLEANFILES)
