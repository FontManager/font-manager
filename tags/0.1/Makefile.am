PKGNAME=@PACKAGE_NAME@
VERSION=@PACKAGE_VERSION@

default: all

all:
	$(MAKE) -C src
	python po/createpot.py compile

clean:
	$(MAKE) -C src clean
	find po -maxdepth 1 -regextype posix-basic -regex "po/[^.]*" -type d -exec rm -rf {} \;

distclean:
	$(MAKE) -C src distclean
	-rm -f po/messages.pot	
	find po -maxdepth 1 -regextype posix-basic -regex "po/[^.]*" -type d -exec rm -rf {} \;

install: all
	$(MAKE) -C src install
	cp -rf doc $(DESTDIR)$(prefix)/share/font-manager/
	for f in `find po -name font-manager.mo` ; do \
	  install -d -m 755 \
	    `echo $$f | sed "s|^po|$(DESTDIR)$(prefix)/share/locale|" | \
	      xargs dirname` && \
	  install -m 644 $$f \
	    `echo $$f | sed "s|^po|$(DESTDIR)$(prefix)/share/locale|"` ; \
	  done

uninstall:
	$(MAKE) -C src uninstall
	find $(DESTDIR)$(prefix)/share/locale -name font-manager.mo -exec rm -f {} \;

EXTRA_DIST = doc po src/config.py.in.in src/*.py src/font-manager.in.in\
			 src/font-manager.desktop src/Makefile.in src/Makefile.am

dist-hook:
	@if [ -e 'src/Font Manager' ]; then mv 'src/Font Manager' 'src/FontManager.py'; fi
	-rm -f po/messages.pot	
	find po -maxdepth 1 -regextype posix-basic -regex "po/[^.]*" -type d -exec rm -rf {} \;

.PHONY: check clean install uninstall
