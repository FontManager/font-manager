
font-manager: font-manager.in
	@sed \
		-e 's|@prefix[@]|$(prefix)|g'\
		< $< \
		> $@

config.py: config.py.in
	@sed \
		-e 's|@PACKAGE_NAME[@]|$(PACKAGE_NAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(PACKAGE_VERSION)|g' \
		-e 's|@LOCALEDIR[@]|$(datadir)/locale|g' \
		< $< \
		> $@

all: config.py font-manager
	@if [ -e FontManager.py ]; then mv 'FontManager.py' 'Font Manager'; fi
	@python -m compileall .
	@python -O -m compileall .

install: make-install-dirs
	install -m 644 'Font Manager' $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 *.py[co] $(DESTDIR)$(prefix)/share/font-manager/
	install -m 755 font-manager.desktop $(DESTDIR)$(prefix)/share/applications/
	install -m 755 font-manager $(DESTDIR)$(prefix)/bin/

make-install-dirs:
	@mkdir -p $(DESTDIR)$(prefix)/share/applications
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/bin

uninstall:
	@rm -rfv $(DESTDIR)$(prefix)/share/font-manager
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-manager.desktop
	@rm -fv $(DESTDIR)$(prefix)/bin/font-manager

clean:
	@rm -f *.py[co] config.py font-manager
	@if [ -e 'Font Manager' ]; then mv 'Font Manager' 'FontManager.py'; fi

distclean:
	@rm -f Makefile *.py[co] config.py font-manager config.py.in font-manager.in
	@if [ -e 'Font Manager' ]; then mv 'Font Manager' 'FontManager.py'; fi



