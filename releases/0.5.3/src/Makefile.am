
CC = @CC@
FLAGS = -fPIC -shared -D_REENTRANT
LIBS = $(fontconfig_LIBS)$(freetype2_LIBS)$(glib_LIBS)
INCLUDES = $(fontconfig_CFLAGS)$(freetype2_CFLAGS)$(glib_CFLAGS)
PyInclude = -I`python -c 'import distutils.sysconfig; print "%s" % distutils.sysconfig.get_python_inc()'`

default: all

fontutils:
	$(CC) _fontutils.c $(FLAGS) $(PyInclude) $(INCLUDES)$(LIBS)-o _fontutils.so
	$(STRIP) --strip-unneeded _fontutils.so

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
	@mkdir -p $(DESTDIR)$(prefix)/bin
	@mkdir -p $(DESTDIR)$(prefix)/lib/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/share/applications
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/core
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/data
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/ui
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/utils


install: all make-install-dirs
	install -m 755 font-manager $(DESTDIR)$(prefix)/bin/
	install -m 755 font-sampler $(DESTDIR)$(prefix)/bin/
	install -m 644 *.so $(DESTDIR)$(prefix)/lib/font-manager/
	@find doc -type f -exec chmod 644 '{}' \;
	@cp -R doc $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 *.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 core/*.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/core/
	install -m 644 data/* $(DESTDIR)$(prefix)/share/font-manager/data/
	install -m 644 ui/*.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/ui/
	install -m 644 utils/* $(DESTDIR)$(prefix)/share/font-manager/utils/
	install -m 644 *.desktop $(DESTDIR)$(prefix)/share/applications/


uninstall:
	@rm -fv $(DESTDIR)$(prefix)/bin/font-manager
	@rm -rfv $(DESTDIR)$(prefix)/lib/font-manager
	@rm -rfv $(DESTDIR)$(prefix)/share/font-manager
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-manager.desktop

clean:
	@rm -f font-manager font-sampler _fontutils.so
	@find . -type f -name '*.py[co]' -exec rm -f '{}' \;

distclean: clean
	@rm -f font-manager _fontutils.so
	@rm -f constants.py constants.py.in
	@rm -f main.py
	@rm -f core/__init__.py
	@rm -f Makefile

