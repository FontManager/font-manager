SUBDIRS = \
	help \
	po \
	resources \
	src

ACLOCAL_AMFLAGS = -I m4

pot:
	@find $(srcdir)/src/ -name "*.vala" -print | sort > $(srcdir)/po/POTFILES.in ; \
	echo "resources/font-manager.desktop.in" >> $(srcdir)/po/POTFILES.in ; \
	cd $(srcdir)/po && $(MAKE) $(AM_MAKEFLAGS) update-po
	cd $(srcdir)/po && sed -f insert-header.sin -i font-manager.pot
	cd $(srcdir)/help && $(MAKE) $(AM_MAKEFLAGS) pot
	cd $(srcdir)/help && sed -f insert-header.sin -i font-manager.pot

.PHONY: pot

