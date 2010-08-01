## Process this file with automake to produce Makefile.in
PKGNAME = @PACKAGE_NAME@
VERSION = @PACKAGE_VERSION@

SRC_DIR = src
SRC_CORE_DIR = $(SRC_DIR)/core
SRC_DATA_DIR = $(SRC_DIR)/data
SRC_UI_DIR = $(SRC_DIR)/ui
SRC_UTILS_DIR = $(SRC_DIR)/utils
INST_BIN_DIR = $(DESTDIR)$(bindir)
INST_LIB_DIR = $(DESTDIR)$(libdir)/$(PKGNAME)
INST_DATA_ROOT = $(DESTDIR)$(datarootdir)
INST_DATA_DIR = $(INST_DATA_ROOT)/$(PKGNAME)
INST_APPS_DIR = $(INST_DATA_ROOT)/applications
PNG_FILES = *.png
UI_FILES = *.ui
DE_FILES = *.desktop
SAMPLER = font-sampler
FLAGS = -fPIC -shared -D_REENTRANT -fno-strict-aliasing
LIBS = $(fontconfig_LIBS)$(freetype2_LIBS)$(glib_LIBS)$(pango_LIBS)
INCLUDES = $(fontconfig_CFLAGS)$(freetype2_CFLAGS)$(glib_CFLAGS)$(pango_CFLAGS)
SYSCONFIG = distutils.sysconfig
PyInclude = `$(PYTHON) -c 'import $(SYSCONFIG); print "-I%s" % \
	$(SYSCONFIG).get_python_inc()'`
PyLibs = `$(PYTHON) -c 'import $(SYSCONFIG); print "-L%s -lpython%s" % \
	($(SYSCONFIG).get_config_var("LIBPL"), $(SYSCONFIG).get_python_version())'`
INSTALL_BIN = install -m 755
INSTALL_FILE = install -m 644
MKDIR = @mkdir -p
REMOVE = @rm -fv
RECURSIVE_REMOVE = @rm -rfv

if !BYTECODE
  Py_Compile = 
  Py_Optimize = 
  PyFiles = *.py
else
  Py_Compile = @$(PYTHON) -m compileall $(SRC_DIR)
  Py_Optimize = @$(PYTHON) -O -m compileall $(SRC_DIR)
  PyFiles = *.py{,c,o}
endif

if !WINLIB
  FONTUTILS = $(SRC_DIR)/_fontutils.so
else
  FONTUTILS = $(SRC_DIR)/_fontutils.dll
endif

if !DEBUGINFO
  STRIP_LIB = $(STRIP) --strip-unneeded $(FONTUTILS)
else
  STRIP_LIB = 
endif

BUILD_LIB = $(CC) $(SRC_DIR)/_fontutils.c $(CFLAGS) $(FLAGS) $(PyInclude) \
			$(INCLUDES)$(LIBS) $(PyLibs) -o $(FONTUTILS)
INSTALL_LIB = $(INSTALL_FILE) $(FONTUTILS) $(INST_LIB_DIR)/

default: all

fontutils:
	$(BUILD_LIB)
	$(STRIP_LIB)

$(SRC_DIR)/constants.py: $(SRC_DIR)/constants.py.in
	@sed \
		-e 's|@PACKAGE_NAME[@]|$(PKGNAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(VERSION)|g' \
		-e 's|@DATAROOTDIR[@]|$(prefix)/share|g' \
		-e 's|@LOCALEDIR[@]|$(prefix)/share/locale|g' \
		< $< \
		> $@

$(SRC_DIR)/$(PKGNAME): $(SRC_DIR)/$(PKGNAME).in
	@sed \
		-e 's|@PYTHON[@]|$(PYTHON)|g' \
		-e 's|@PREFIX[@]|$(prefix)|g' \
		-e 's|@LIBDIR[@]|$(prefix)/lib|g' \
		< $< \
		> $@

$(SRC_DIR)/$(SAMPLER): $(SRC_DIR)/$(SAMPLER).in
	@sed \
		-e 's|@PYTHON[@]|$(PYTHON)|g' \
		-e 's|@PREFIX[@]|$(prefix)|g' \
		-e 's|@LIBDIR[@]|$(prefix)/lib|g' \
		< $< \
		> $@

$(SRC_DIR)/main.py: $(SRC_DIR)/main.py.in
	@sed \
		-e 's|@BINDIR[@]|$(prefix)/bin|g' \
		-e 's|@DATAROOTDIR[@]|$(prefix)/share|g' \
		< $< \
		> $@

$(SRC_UI_DIR)/export.py: $(SRC_UI_DIR)/export.py.in
	@sed \
		-e 's|@BINDIR[@]|$(prefix)/bin|g' \
		< $< \
		> $@

all: fontutils $(SRC_DIR)/constants.py $(SRC_DIR)/$(PKGNAME) \
$(SRC_DIR)/$(SAMPLER) $(SRC_DIR)/main.py $(SRC_UI_DIR)/export.py
	$(Py_Compile)
	$(Py_Optimize)

make-install-dirs:
	$(MKDIR) $(INST_BIN_DIR)
	$(MKDIR) $(INST_LIB_DIR)
	$(MKDIR) $(INST_APPS_DIR)
	$(MKDIR) $(INST_DATA_DIR)
	$(MKDIR) $(INST_DATA_DIR)/core
	$(MKDIR) $(INST_DATA_DIR)/data
	$(MKDIR) $(INST_DATA_DIR)/ui
	$(MKDIR) $(INST_DATA_DIR)/utils

install: make-install-dirs
	@find . -type f -name 'font-manager*.pot' -exec rm -f '{}' \;
	$(INSTALL_LIB)
	$(INSTALL_BIN)   $(SRC_DIR)/$(PKGNAME)         $(INST_BIN_DIR)/
	$(INSTALL_BIN)   $(SRC_DIR)/$(SAMPLER)         $(INST_BIN_DIR)/
	$(INSTALL_FILE)  $(SRC_DIR)/$(DE_FILES)        $(INST_APPS_DIR)/
	$(INSTALL_FILE)  $(SRC_DIR)/$(PyFiles)         $(INST_DATA_DIR)/
	$(INSTALL_FILE)  $(SRC_CORE_DIR)/$(PyFiles)    $(INST_DATA_DIR)/core/
	$(INSTALL_FILE)  $(SRC_DATA_DIR)/$(PNG_FILES)  $(INST_DATA_DIR)/data/
	$(INSTALL_FILE)  $(SRC_DATA_DIR)/$(UI_FILES)   $(INST_DATA_DIR)/data/
	$(INSTALL_FILE)  $(SRC_UI_DIR)/$(PyFiles)      $(INST_DATA_DIR)/ui/
	$(INSTALL_FILE)  $(SRC_UTILS_DIR)/$(PyFiles)   $(INST_DATA_DIR)/utils/
	@find help -type f -exec chmod 644 '{}' \;
	@find help -type d -exec chmod 755 '{}' \;
	@cp -R help $(INST_DATA_DIR)/

uninstall:
	$(REMOVE) $(INST_BIN_DIR)/$(PKGNAME)
	$(REMOVE) $(INST_BIN_DIR)/$(SAMPLER)
	$(REMOVE) $(INST_APPS_DIR)/$(PKGNAME).desktop
	$(REMOVE) $(INST_APPS_DIR)/$(SAMPLER).desktop
	$(RECURSIVE_REMOVE) $(INST_LIB_DIR)
	$(RECURSIVE_REMOVE) $(INST_DATA_DIR)

clean:
	$(REMOVE)  $(SRC_DIR)/_fontutils.so $(SRC_DIR)/_fontutils.dll
	@find . -type f -name '*.py[co]' -exec rm -fv '{}' \;

distclean: clean
	$(REMOVE) $(SRC_DIR)/$(PKGNAME) $(SRC_DIR)/$(SAMPLER) \
		$(SRC_DIR)/constants.py $(SRC_DIR)/constants.py.in $(SRC_DIR)/main.py \
		$(SRC_CORE_DIR)/__init__.py $(SRC_UI_DIR)/export.py \
		config.log config.status Makefile
	$(RECURSIVE_REMOVE) autom4te.cache
	@find . -depth -type d -name '.svn' -exec rm -rf '{}' \;

EXTRA_DIST = help $(SRC_CORE_DIR) $(SRC_DATA_DIR) $(SRC_UI_DIR) $(SRC_UTILS_DIR) \
$(SRC_DIR)/*.py $(SRC_DIR)/*.c $(SRC_DIR)/*.in $(SRC_DIR)/$(DE_FILES) po

.PHONY: default all make-install-dirs install uninstall clean distclean \
		dist-hook fontutils
