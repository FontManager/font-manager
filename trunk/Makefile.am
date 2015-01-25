SUBDIRS = \
	extensions \
	help \
	po \
	resources \
	src

ACLOCAL_AMFLAGS = -I m4

POTFILES.readme:
	@echo "POTFILES.* generated from the top level Makefile" > $(srcdir)/po/POTFILES.readme

POTFILES.in:
	@find src/ -name "*.vala" -print | sort > $(srcdir)/po/POTFILES.in ;
	@echo "[type: gettext/glade]resources/ApplicationMenu.ui" >> $(srcdir)/po/POTFILES.in ;
	@echo "resources/$(PACKAGE_NAME).appdata.xml.in" >> $(srcdir)/po/POTFILES.in ;
	@echo "resources/org.gnome.FontManager.desktop.in" >> $(srcdir)/po/POTFILES.in ;
	@echo "" >> $(srcdir)/po/POTFILES.in ;

POTFILES.skip:
	@find $(srcdir)/src/ -name "*.vala" -print | sort | $(SED) 's/.vala/.c/g' > $(srcdir)/po/POTFILES.skip ;

pot: POTFILES.readme POTFILES.in POTFILES.skip
	cd $(srcdir)/po && $(MAKE) $(AM_MAKEFLAGS) update-po
	cd $(srcdir)/po && $(SED) -f insert-header.sin -i $(PACKAGE_NAME).pot
	cd $(srcdir)/help && rm -f $(PACKAGE_NAME).pot
	cd $(srcdir)/help && $(MAKE) $(AM_MAKEFLAGS) pot
	cd $(srcdir)/help && $(SED) -f insert-header.sin -i $(PACKAGE_NAME).pot
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

.PHONY: pot POTFILES.readme POTFILES.in POTFILES.skip

all: pot
