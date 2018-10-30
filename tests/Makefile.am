
include $(top_srcdir)/Flags.mk

noinst_PROGRAMS = FontManagerTestSuite

#TEST_PROGS = $(noinst_PROGRAMS)

FontManagerTestSuite_SOURCES = \
	TestUtils.vala \
	TestCase.vala \
	TestMain.vala \
	TestFontConfig.vala

FontManagerTestSuite_VALAFLAGS = \
	${AM_VALAFLAGS} \
	$(HAVE_FILE_ROLLER) \
	$(top_srcdir)/lib/unicode/Unicode.vapi \
	$(top_srcdir)/lib/common/FontManager.vapi \
	$(top_srcdir)/lib/vala/FontManagerVala.vapi

FontManagerTestSuite_CFLAGS = \
	${AM_VALA_CFLAGS} \
	-I$(top_srcdir)/lib/vala/

FontManagerTestSuite_LDADD = \
	${AM_LDADD} \
	$(top_builddir)/lib/libfontmanager.la

EXTRA_DIST = fonts.dtd

CLEANFILES = \
	results.xml \
	*.stamp*

MAINTAINERCLEANFILES = \
	Makefile.in

#check-local:
#	@echo
#	@gtester -o results.xml --verbose FontManagerTestSuite
#	@echo
