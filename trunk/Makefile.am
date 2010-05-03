
PKGNAME = @PACKAGE_NAME@
VERSION = @PACKAGE_VERSION@

default: all

all:
#	@cp -f src/data/font-manager.ui src/data/font-manager.glade
#	@cp -f src/data/font-information.ui src/data/font-information.glade
#	@cp -f src/data/menus.ui src/data/menus.glade
#	python po/compile_translations.py
#	-rm -f src/data/*.glade
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean
#	find po -maxdepth 1 -regextype posix-basic -regex "po/[^.]*" -type d -exec rm -rf {} \;

distclean: clean
	$(MAKE) -C src distclean
	-rm -f config.log config.status Makefile

install: all
	$(MAKE) -C src install
#	for f in `find po -name font-manager.mo` ; do \
#	  install -d -m 755 \
#		`echo $$f | sed "s|^po|$(DESTDIR)$(prefix)/share/locale|" | \
#		  xargs dirname` && \
#	  install -m 644 $$f \
#		`echo $$f | sed "s|^po|$(DESTDIR)$(prefix)/share/locale|"` ; \
#	  done

uninstall:
	$(MAKE) -C src uninstall
#	find $(DESTDIR)$(prefix)/share/locale -name font-manager.mo -exec rm -f {} \;

EXTRA_DIST = src/core src/data src/doc src/ui src/utils src/constants.py.in.in \
src/*.py src/font-manager.in src/font-manager.desktop src/Makefile.in \
src/Makefile.am po

dist-hook:
	-find . -name '.svn' -exec rm -rf '{}' \;
	-find . -name '.svn' -exec rm -rf '{}' \;
#	-rm -f po/messages.pot
#	find po -maxdepth 1 -regextype posix-basic -regex "po/[^.]*" -type d -exec rm -rf {} \;

.PHONY: check clean install uninstall
