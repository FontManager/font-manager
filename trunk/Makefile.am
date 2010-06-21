## Process this file with automake to produce Makefile.in
PKGNAME = @PACKAGE_NAME@
VERSION = @PACKAGE_VERSION@

FLAGS = -fPIC -shared -D_REENTRANT
LIBS = $(fontconfig_LIBS)$(freetype2_LIBS)$(glib_LIBS)
INCLUDES = $(fontconfig_CFLAGS)$(freetype2_CFLAGS)$(glib_CFLAGS)
PyInclude = `python -c 'import distutils.sysconfig; print "-I%s" % distutils.sysconfig.get_python_inc()'`
PyLibs = `python -c 'import distutils.sysconfig; print "-L%s -lpython%s" % (distutils.sysconfig.get_config_var("LIBPL"), distutils.sysconfig.get_python_version())'`

if !WINLIB
  FONTUTILS = src/_fontutils.so
else
  FONTUTILS = src/_fontutils.dll
endif

if !DEBUGINFO
  STRIP_LIB = $(STRIP) --strip-unneeded $(FONTUTILS)
else
  STRIP_LIB = @echo
endif

BUILD_LIB = $(CC) src/_fontutils.c $(CFLAGS) $(FLAGS) $(PyInclude) $(INCLUDES)$(LIBS) $(PyLibs) -o $(FONTUTILS)
INSTALL_LIB = install -m 644 $(FONTUTILS) $(DESTDIR)$(libdir)/font-manager/

default: all

fontutils:
	$(BUILD_LIB)
	$(STRIP_LIB)

src/constants.py: src/constants.py.in
	@sed \
		-e 's|@PACKAGE_NAME[@]|$(PKGNAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(VERSION)|g' \
		-e 's|@LOCALEDIR[@]|$(datadir)/locale|g' \
		< $< \
		> $@

src/font-manager: src/font-manager.in
	@sed \
		-e 's|@PYTHON[@]|$(PYTHON)|g' \
		-e 's|@PREFIX[@]|$(prefix)|g' \
		-e 's|@LIBDIR[@]|$(libdir)|g' \
		< $< \
		> $@

src/font-sampler: src/font-sampler.in
	@sed \
		-e 's|@PYTHON[@]|$(PYTHON)|g' \
		-e 's|@PREFIX[@]|$(prefix)|g' \
		-e 's|@LIBDIR[@]|$(libdir)|g' \
		< $< \
		> $@

all: fontutils src/constants.py src/font-manager src/font-sampler
	@python -m compileall src/
	@python -O -m compileall src/

make-install-dirs:
	@mkdir -p $(DESTDIR)$(prefix)/bin
	@mkdir -p $(DESTDIR)$(libdir)/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/share/applications
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/core
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/data
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/ui
	@mkdir -p $(DESTDIR)$(prefix)/share/font-manager/utils

install: make-install-dirs
	$(INSTALL_LIB)
	install -m 755 src/font-manager $(DESTDIR)$(prefix)/bin/
	install -m 755 src/font-sampler $(DESTDIR)$(prefix)/bin/
	install -m 644 src/*.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/
	install -m 644 src/core/*.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/core/
	install -m 644 src/data/* $(DESTDIR)$(prefix)/share/font-manager/data/
	install -m 644 src/ui/*.py{,c,o} $(DESTDIR)$(prefix)/share/font-manager/ui/
	install -m 644 src/utils/* $(DESTDIR)$(prefix)/share/font-manager/utils/
	install -m 644 src/*.desktop $(DESTDIR)$(prefix)/share/applications/
	@find help -type f -exec chmod 644 '{}' \;
	@cp -R help $(DESTDIR)$(prefix)/share/font-manager/

uninstall:
	@rm -fv $(DESTDIR)$(prefix)/bin/font-manager
	@rm -fv $(DESTDIR)$(prefix)/bin/font-sampler
	@rm -rfv $(DESTDIR)$(libdir)/font-manager
	@rm -rfv $(DESTDIR)$(prefix)/share/font-manager
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-manager.desktop
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-sampler.desktop

clean:
	@rm -f src/font-manager src/font-sampler src/_fontutils.so src/_fontutils.dll
	@find src/ -type f -name '*.py[co]' -exec rm -f '{}' \;

distclean: clean
	@rm -f src/constants.py src/constants.py.in
	@rm -f src/main.py src/core/__init__.py src/ui/export.py
	@rm -f config.log config.status Makefile

EXTRA_DIST = help src/core src/data src/ui src/utils src/*.py src/*.c src/*.in src/*.desktop po

dist-hook: distclean
	@find $(distdir) -name '.svn' -exec rm -rf '{}' \;
	@find $(distdir) -name '.svn' -exec rm -rf '{}' \;

.PHONY: default all make-install-dirs install uninstall clean distclean dist-hook fontutils
