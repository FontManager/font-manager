
include ValaSources.mk
include $(top_srcdir)/Flags.mk

noinst_PROGRAMS = $(TEST_PROGS)

TEST_PROGS = FontManagerTestSuite

FontManagerTestSuite_SOURCES = \
	$(FontManagerTestSuite_VALASOURCES)

FontManagerTestSuite_VALAFLAGS = \
	${AM_VALAFLAGS} \
	$(HAVE_FILE_ROLLER) \
	$(top_srcdir)/lib/fontmanager.vapi

FontManagerTestSuite_CFLAGS = \
	${AM_CFLAGS}

FontManagerTestSuite_LDADD = \
	${AM_LDADD} \
	$(top_srcdir)/lib/libfontmanager.la

EXTRA_DIST = \
	fonts.dtd \
	sources.dtd \
	$(FontManagerTestSuite_VALASOURCES)

CLEANFILES = \
	results.xml \
	*.stamp*

MAINTAINERCLEANFILES = \
	Makefile.in

check-local:
	@echo
	@gtester -o results.xml --verbose FontManagerTestSuite
	@echo

dist-hook:
	cd $(distdir) && rm -f $(FontManagerTestSuite_SOURCES:.vala=.c) $(CLEANFILES)
