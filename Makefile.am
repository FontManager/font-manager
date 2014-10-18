SUBDIRS = \
	help \
	po \
	resources \
	src

ACLOCAL_AMFLAGS = -I m4

pot:
	@find $(srcdir)/src/ -name "*.vala" -print | sort > $(srcdir)/po/POTFILES.in ;
	@echo "resources/$(PACKAGE_NAME).desktop.in" >> $(srcdir)/po/POTFILES.in ;
	@echo "resources/$(PACKAGE_NAME).appdata.xml.in" >> $(srcdir)/po/POTFILES.in ;
	cd $(srcdir)/po && $(MAKE) $(AM_MAKEFLAGS) update-po
	cd $(srcdir)/po && sed -f insert-header.sin -i $(PACKAGE_NAME).pot
	cd $(srcdir)/help && rm -f $(PACKAGE_NAME).pot
	cd $(srcdir)/help && $(MAKE) $(AM_MAKEFLAGS) pot
	cd $(srcdir)/help && sed -f insert-header.sin -i $(PACKAGE_NAME).pot
	cd $(srcdir)/help && $(MAKE) $(AM_MAKEFLAGS) repo

EXTRA_DIST = \
	$(srcdir)/po/insert-header.sin \
	$(srcdir)/po/HEADER \
	$(srcdir)/help/insert-header.sin \
	$(srcdir)/help/HEADER

distclean-local:
	cd $(srcdir)
	-rm -rf autom4te.cache m4 aclocal.m4 compile config.guess config.sub configure depcomp install-sh ltmain.sh missing
	@find . -name "Makefile" -exec rm -f '{}' \;
	@find . -name "Makefile.in*" -exec rm -f '{}' \;

maintainer-clean-local:
	-rm -rf build-aux

.PHONY: pot

all: pot
