SUBDIRS = \
	data \
	lib \
	src \
	extensions \
	help \
	po

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = \
	$(srcdir)/po/insert-header.sin \
	$(srcdir)/po/Makefile.in.in \
	$(srcdir)/po/HEADER \
	$(srcdir)/po/POTFILES.in \
	$(srcdir)/po/POTFILES.readme \
	$(srcdir)/po/POTFILES.skip \
	$(srcdir)/help/insert-header.sin \
	$(srcdir)/help/HEADER \
	Flags.mk

DISTCLEANFILES = \
	po/Makefile \
	po/Makefile.in \
	po/POTFILES \
	po/*stamp*

MAINTAINERCLEANFILES = \
	aclocal.m4 \
	compile \
	config.guess \
	config.sub \
	configure \
	depcomp \
	install-sh \
	ltmain.sh \
	missing \
	py-compile \
	Makefile.in \
	po/Makefile* \
	po/POTFILES \
	po/*stamp*

pot:
	cd $(srcdir)/po && rm -f $(PACKAGE_NAME).pot
	cd $(srcdir)/po && $(MAKE) $(AM_MAKEFLAGS) update-po
	cd $(srcdir)/po && $(SED) -f insert-header.sin -i $(PACKAGE_NAME).pot
	cd $(srcdir)/help && rm -f $(PACKAGE_NAME).pot
	cd $(srcdir)/help && $(MAKE) $(AM_MAKEFLAGS) pot
	cd $(srcdir)/help && $(SED) -f insert-header.sin -i $(PACKAGE_NAME).pot
	cd $(srcdir)/help && $(MAKE) $(AM_MAKEFLAGS) repo
	cd $(srcdir)

maintainer-clean-local:
	-rm -rf m4 autom4te.cache
	find . -name .libs -exec rm -rf {} \;
	find . -name .deps -exec rm -rf {} \;

all: pot
.PHONY: pot
