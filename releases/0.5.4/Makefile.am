
PKGNAME = @PACKAGE_NAME@
VERSION = @PACKAGE_VERSION@

all: default

default:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean

distclean: clean
	$(MAKE) -C src distclean
	-rm -f config.log config.status Makefile

install:
	$(MAKE) -C src install
	@find help -type f -exec chmod 644 '{}' \;
	@cp -R help $(DESTDIR)$(prefix)/share/font-manager/

uninstall:
	$(MAKE) -C src uninstall
	@rm -rfv $(DESTDIR)$(prefix)/share/gnome/help/font-manager

EXTRA_DIST = help src/core src/data src/ui src/utils src/*.py src/*.c \
src/*.in src/font-manager.in src/font-manager.desktop src/Makefile.in \
src/Makefile.am po

dist-hook: 
	-find $(distdir) -name '.svn' -exec rm -rf '{}' \;
	@find $(distdir) -name '.svn' -exec rm -rf '{}' \;
	@rm -f $(distdir)/src/font-manager $(distdir)/src/_fontutils.so
	@rm -f $(distdir)/src/constants.py $(distdir)/src/constants.py.in
	@rm -f $(distdir)/src/main.py
	@rm -f $(distdir)/src/core/__init__.py

.PHONY: check clean install uninstall
