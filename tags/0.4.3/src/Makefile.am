
config.py: config.py.in
	@sed \
		-e 's|@PACKAGE_NAME[@]|$(PACKAGE_NAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(PACKAGE_VERSION)|g' \
		-e 's|@LOCALEDIR[@]|$(datadir)/locale|g' \
		< $< \
		> $@

all: config.py
	@python -m compileall .
	@python -OO -m compileall .

install: make-install-dirs
	install -m 644 *.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 ui/*.ui $(DESTDIR)$(prefix)/share/font-manager/ui/
	install -m 644 ui/Throbber* $(DESTDIR)$(prefix)/share/font-manager/ui/
	install -m 644 font-manager.desktop $(DESTDIR)$(prefix)/share/applications/
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
	@rm -f *.py[co] font-manager

distclean: clean
	@rm -f Makefile config.py.in




