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

.PHONY: pot

all: pot
