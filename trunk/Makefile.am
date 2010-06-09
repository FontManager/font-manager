
PKGNAME = @PACKAGE_NAME@
VERSION = @PACKAGE_VERSION@

FLAGS = -fPIC -shared -D_REENTRANT
LIBS = $(fontconfig_LIBS)$(freetype2_LIBS)$(glib_LIBS)
INCLUDES = $(fontconfig_CFLAGS)$(freetype2_CFLAGS)$(glib_CFLAGS)
PyInclude = `python -c 'import distutils.sysconfig; print "-I%s" % distutils.sysconfig.get_python_inc()'`
PyLibs = `python -c 'import distutils.sysconfig; print "-L%s -lpython%s" % (distutils.sysconfig.get_config_var("LIBPL"), distutils.sysconfig.get_python_version())'`

if WINLIB
  BUILD_LIB = $(CC) src/_fontutils.c $(CFLAGS) $(FLAGS) $(PyInclude) $(INCLUDES)$(LIBS) $(PyLibs) -o src/_fontutils.dll
  INSTALL_LIB = install -m 644 src/_fontutils.dll $(DESTDIR)$(libdir)/font-manager/
else
  BUILD_LIB = $(CC) src/_fontutils.c $(CFLAGS) $(FLAGS) $(PyInclude) $(INCLUDES)$(LIBS) $(PyLibs) -o src/_fontutils.so
  INSTALL_LIB = install -m 644 src/_fontutils.so $(DESTDIR)$(libdir)/font-manager/
endif

if DEBUGINFO
  STRIP_LIB = @echo
else
  STRIP_LIB = $(STRIP) --strip-unneeded src/_fontutils.so
endif

default: all

src/fontutils:
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

all: src/constants.py src/fontutils src/font-manager src/font-sampler
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
	@rm -rfv $(DESTDIR)$(libdir)/font-manager
	@rm -rfv $(DESTDIR)$(prefix)/share/font-manager
	@rm -fv $(DESTDIR)$(prefix)/share/applications/font-manager.desktop
	@rm -rfv $(DESTDIR)$(prefix)/share/gnome/help/font-manager

clean:
	@rm -f src/font-manager src/font-sampler src/_fontutils.so
	@find src/ -type f -name '*.py[co]' -exec rm -f '{}' \;

distclean: clean
	@rm -f src/font-manager src/_fontutils.so
	@rm -f src/constants.py src/constants.py.in
	@rm -f src/main.py src/core/__init__.py src/ui/export.py
	@rm -f config.log config.status Makefile

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
