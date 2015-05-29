## Process this file with automake to produce Makefile.in

SRC_DIR = src
SRC_CORE_DIR = $(SRC_DIR)/core
SRC_DATA_DIR = $(SRC_DIR)/data
SRC_LIB_DIR = $(SRC_DIR)/lib
SRC_UI_DIR = $(SRC_DIR)/ui
SRC_UTILS_DIR = $(SRC_DIR)/utils
INST_BIN_DIR = $(DESTDIR)$(bindir)
INST_LIB_DIR = $(DESTDIR)$(libdir)/$(PACKAGE_NAME)
INST_DATA_ROOT = $(DESTDIR)$(datarootdir)
INST_DATA_DIR = $(INST_DATA_ROOT)/$(PACKAGE_NAME)
INST_APPS_DIR = $(INST_DATA_ROOT)/applications
INST_LOC_DIR = $(DESTDIR)$(localedir)
PNG_FILES = *.png
UI_FILES = *.ui
DE_FILES = *.desktop
SAMPLER = font-sampler
FLAGS = -fPIC -shared -D_REENTRANT -fno-strict-aliasing
LIBS = $(fontconfig_LIBS)$(freetype2_LIBS)$(glib_LIBS)\
		$(pango_LIBS)$(pangoft2_LIBS)$(sqlite_LIBS)
INCLUDES = $(fontconfig_CFLAGS)$(freetype2_CFLAGS)$(glib_CFLAGS)\
			$(pango_CFLAGS)$(pangoft2_CFLAGS)$(sqlite_CFLAGS)
SYSCONFIG = distutils.sysconfig
PyInclude = `$(PYTHON) -c 'import $(SYSCONFIG); print "-I%s" % \
	$(SYSCONFIG).get_python_inc()'`
PyLibs = `$(PYTHON) -c 'import $(SYSCONFIG); print "-L%s -lpython%s" % \
	($(SYSCONFIG).get_config_var("LIBPL"), $(SYSCONFIG).get_python_version())'`
INSTALL_BIN = $(INSTALL) -m 755
INSTALL_FILE = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL_BIN) -d
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
  FONTUTILS = $(SRC_LIB_DIR)/fontutils.so
else
  FONTUTILS = $(SRC_LIB_DIR)/fontutils.dll
endif

if !DEBUGINFO
  STRIP_LIB = $(STRIP) --strip-unneeded $(FONTUTILS)
else
  STRIP_LIB = 
endif

BUILD_LIB = $(CC) $(SRC_LIB_DIR)/fm-pyfontutils.c $(SRC_LIB_DIR)/fm-common.c \
			$(SRC_LIB_DIR)/fm-database.c $(SRC_LIB_DIR)/fm-fontutils.c \
			$(CFLAGS) $(FLAGS) $(PyInclude) $(INCLUDES)$(LIBS) \
			$(PyLibs) -o $(FONTUTILS)
INSTALL_LIB = $(INSTALL_FILE) $(FONTUTILS) $(INST_LIB_DIR)/

edit = 	sed \
		-e 's|@PACKAGE_NAME[@]|$(PACKAGE_NAME)|g' \
		-e 's|@PACKAGE_VERSION[@]|$(PACKAGE_VERSION)|g' \
		-e 's|@PYTHON[@]|$(PYTHON)|g' \
		-e 's|@PACKAGEDIR[@]|$(INST_DATA_DIR)|g' \
		-e 's|@LOCALEDIR[@]|$(INST_LOC_DIR)|g' \
		-e 's|@LIBDIR[@]|$(INST_LIB_DIR)|g' \
		-e 's|@BINDIR[@]|$(INST_BIN_DIR)|g' \
		< $< \
		> $@

$(SRC_DIR)/constants.py $(SRC_DIR)/$(PACKAGE_NAME) $(SRC_DIR)/$(SAMPLER) \
$(SRC_DIR)/main.py $(SRC_UI_DIR)/export.py $(SRC_CORE_DIR)/__init__.py:
	rm -f $@ $@.tmp
	$(edit) $${SRC_DIR}$@.in >$@.tmp
	mv $@.tmp $@

$(SRC_DIR)/constants.py: $(SRC_DIR)/constants.py.in
$(SRC_DIR)/$(PACKAGE_NAME): $(SRC_DIR)/$(PACKAGE_NAME).in
$(SRC_DIR)/$(SAMPLER): $(SRC_DIR)/$(SAMPLER).in
$(SRC_DIR)/main.py: $(SRC_DIR)/main.py.in
$(SRC_CORE_DIR)/__init__.py: $(SRC_CORE_DIR)/__init__.py.in
$(SRC_UI_DIR)/export.py: $(SRC_UI_DIR)/export.py.in

default: all

fontutils:
	$(BUILD_LIB)
	$(STRIP_LIB)

compile_po:
	@cd po && $(SH) ./pogen.sh && cd ..
	for p in `ls po|grep .po|grep -v $(PACKAGE_NAME)`; \
	do \
		lang=$${p%.po}; \
		langdir=$$lang/LC_MESSAGES; \
		$(INSTALL_DIR) po/$$langdir; \
		msgmerge -o - po/$$p po/$(PACKAGE_NAME).pot | \
		msgfmt -c -o po/$$langdir/$(PACKAGE_NAME).mo -; \
	done

install_mo:
	for mo in `$(FIND) po -name $(PACKAGE_NAME).mo`; \
	do \
		newpath=$${mo/#po\//$(INST_LOC_DIR)\/}; \
		langdir=$${newpath/%$(PACKAGE_NAME).mo//}; \
		$(INSTALL_DIR) $$langdir; \
		$(INSTALL_FILE) $$mo $$langdir; \
	done

if NLS
  all: fontutils $(SRC_DIR)/constants.py $(SRC_DIR)/$(PACKAGE_NAME) \
  $(SRC_DIR)/$(SAMPLER) $(SRC_DIR)/main.py $(SRC_UI_DIR)/export.py \
  $(SRC_CORE_DIR)/__init__.py compile_po
else
  all: fontutils $(SRC_DIR)/constants.py $(SRC_DIR)/$(PACKAGE_NAME) \
  $(SRC_DIR)/$(SAMPLER) $(SRC_DIR)/main.py $(SRC_UI_DIR)/export.py \
  $(SRC_CORE_DIR)/__init__.py
endif
	$(Py_Compile)
	$(Py_Optimize)

make-install-dirs:
	$(INSTALL_DIR) $(INST_BIN_DIR)
	$(INSTALL_DIR) $(INST_LIB_DIR)
	$(INSTALL_DIR) $(INST_APPS_DIR)
	$(INSTALL_DIR) $(INST_DATA_DIR)
	$(INSTALL_DIR) $(INST_DATA_DIR)/core
	$(INSTALL_DIR) $(INST_DATA_DIR)/data
	$(INSTALL_DIR) $(INST_DATA_DIR)/ui
	$(INSTALL_DIR) $(INST_DATA_DIR)/utils

if NLS
  install: make-install-dirs install_mo
else
  install: make-install-dirs
endif
	$(INSTALL_LIB)
	$(INSTALL_BIN)   $(SRC_DIR)/$(PACKAGE_NAME)    $(INST_BIN_DIR)/
	$(INSTALL_BIN)   $(SRC_DIR)/$(SAMPLER)         $(INST_BIN_DIR)/
	$(INSTALL_FILE)  $(SRC_DIR)/$(DE_FILES)        $(INST_APPS_DIR)/
	$(INSTALL_FILE)  $(SRC_DIR)/$(PyFiles)         $(INST_DATA_DIR)/
	$(INSTALL_FILE)  $(SRC_CORE_DIR)/$(PyFiles)    $(INST_DATA_DIR)/core/
	$(INSTALL_FILE)  $(SRC_DATA_DIR)/$(PNG_FILES)  $(INST_DATA_DIR)/data/
	$(INSTALL_FILE)  $(SRC_DATA_DIR)/$(UI_FILES)   $(INST_DATA_DIR)/data/
	$(INSTALL_FILE)  $(SRC_UI_DIR)/$(PyFiles)      $(INST_DATA_DIR)/ui/
	$(INSTALL_FILE)  $(SRC_UTILS_DIR)/$(PyFiles)   $(INST_DATA_DIR)/utils/
	@$(FIND) help -type f -exec chmod 644 '{}' \;
	@$(FIND) help -type d -exec chmod 755 '{}' \;
	cp -Rv help $(INST_DATA_DIR)/

uninstall:
	$(REMOVE) $(INST_BIN_DIR)/$(PACKAGE_NAME)
	$(REMOVE) $(INST_BIN_DIR)/$(SAMPLER)
	$(REMOVE) $(INST_APPS_DIR)/$(PACKAGE_NAME).desktop
	$(REMOVE) $(INST_APPS_DIR)/$(SAMPLER).desktop
	$(RECURSIVE_REMOVE) $(INST_LIB_DIR)
	$(RECURSIVE_REMOVE) $(INST_DATA_DIR)
	$(FIND) $(INST_LOC_DIR) -name $(PACKAGE_NAME).mo -exec rm -f '{}' \;

clean:
	$(REMOVE)  $(SRC_LIB_DIR)/fontutils.so $(SRC_LIB_DIR)/fontutils.dll
	@$(FIND) . -type f -name '*.py[co]' -exec rm -f '{}' \;
	for p in `ls po|grep .po|grep -v $(PACKAGE_NAME)`; \
	do \
		langdir=$${p%.po}; \
		rm -rf po/$$langdir; \
	done

distclean: clean
	$(REMOVE) $(SRC_DIR)/$(PACKAGE_NAME) $(SRC_DIR)/$(SAMPLER) \
		$(SRC_DIR)/constants.py $(SRC_DIR)/main.py $(SRC_CORE_DIR)/__init__.py \
		$(SRC_UI_DIR)/export.py config.log config.status Makefile \
		po/$(PACKAGE_NAME).pot po/$(PACKAGE_NAME)-help.pot 
	$(RECURSIVE_REMOVE) autom4te.cache
	@$(FIND) . -depth -type d -name '.svn' -exec rm -rf '{}' \;

EXTRA_DIST = help $(SRC_CORE_DIR) $(SRC_DATA_DIR) $(SRC_UI_DIR) \
			$(SRC_UTILS_DIR) $(SRC_DIR)/*.py $(SRC_LIB_DIR) $(SRC_DIR)/*.in \
			$(SRC_DIR)/$(DE_FILES) po

.PHONY: default all make-install-dirs install uninstall clean distclean fontutils

