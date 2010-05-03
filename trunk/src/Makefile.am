
CC = @CC@
FLAGS = -fPIC -shared
LIBS = $(FontConfig_LIBS)$(FreeType2_LIBS)$(Glib_LIBS)
INCLUDES = $(FontConfig_CFLAGS)$(FreeType2_CFLAGS)$(Glib_CFLAGS)
PyInclude = -I`python -c 'import distutils.sysconfig; print "%s" % distutils.sysconfig.get_python_inc()'`

fontutils:
	$(CC) utils/_fontutils.c $(FLAGS) $(PyInclude) $(INCLUDES)$(LIBS)-o utils/_fontutils.so

constants.py: constants.py.in
	@sed \
		-e 's|@PACKAGE_NAME[@]|$(PACKAGE_NAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(PACKAGE_VERSION)|g' \
		-e 's|@LOCALEDIR[@]|$(datadir)/locale|g' \
		< $< \
		> $@

all: constants.py fontutils
	@python -m compileall .
	@python -O -m compileall .

make-install-dirs:
	@mkdir -p $(DESTDIR)$(prefix)/share/applications
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/core
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/data
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/ui
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/utils
	@mkdir -p $(DESTDIR)$(prefix)/bin

install: all make-install-dirs
	install -m 644 *.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 core/*.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/core/
	install -m 644 data/* $(DESTDIR)$(prefix)/share/font-manager/data/
	install -m 644 ui/* $(DESTDIR)$(prefix)/share/font-manager/ui/
	install -m 644 utils/* $(DESTDIR)$(prefix)/share/font-manager/utils/
	@cp -R doc $(DESTDIR)$(prefix)/share/font-manager/
	@find doc -type f -exec chmod 644 '{}' \;
	install -m 644 font-manager.desktop $(DESTDIR)$(prefix)/share/applications/
	install -m 755 font-manager $(DESTDIR)$(prefix)/bin/

uninstall:
	@rm -rfv $(DESTDIR)$(prefix)/share/font-manager
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-manager.desktop
	@rm -fv $(DESTDIR)$(prefix)/bin/font-manager

clean:
	@rm -f font-manager utils/_fontutils.so
	@find . -type f -name '*.py[co]' -exec rm -f '{}' \;

distclean: clean
	@rm -f Makefile constants.py.in core/__init__.py
