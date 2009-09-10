
font-manager: font-manager.in
	@sed \
		-e 's|@prefix[@]|$(prefix)|g'\
		< $< \
		> $@

rmconf:
	@rm -f config.py
	
config.py: config.py.in
	@sed \
		-e 's|@PACKAGE_NAME[@]|$(PACKAGE_NAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(PACKAGE_VERSION)|g' \
		-e 's|@LOCALEDIR[@]|$(datadir)/locale|g' \
		< $< \
		> $@

all: rmconf config.py font-manager
	@if [ -e FontManager.py ]; then mv 'FontManager.py' 'Font Manager'; fi
	@python -m compileall .
	@python -OO -m compileall .
	@rm -f static.py[co]

install: make-install-dirs
	install -m 644 'Font Manager' $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 *.py[co] $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 ui/*.ui $(DESTDIR)$(prefix)/share/font-manager/ui/
	install -m 755 font-manager.desktop $(DESTDIR)$(prefix)/share/applications/
	install -m 755 font-manager $(DESTDIR)$(prefix)/bin/

make-install-dirs:
	@mkdir -p $(DESTDIR)$(prefix)/share/applications
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/ui
	@mkdir -p $(DESTDIR)$(prefix)/bin

uninstall:
	@rm -rfv $(DESTDIR)$(prefix)/share/font-manager
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-manager.desktop
	@rm -fv $(DESTDIR)$(prefix)/bin/font-manager

clean:
	@if [ -e 'Font Manager' ]; then mv 'Font Manager' 'FontManager.py'; fi
	@rm -f *.py[co] config.py font-manager
	@if [ -e 'static.py' ]; then cp -f 'static.py' 'config.py'; fi

distclean: clean
	@rm -f Makefile config.py.in font-manager.in




