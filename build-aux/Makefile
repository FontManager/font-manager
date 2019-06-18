
PACKAGE_NAME = font-manager
PACKAGE_VERSION = 0.7.5

ABS_TOP_SRCDIR = $(shell realpath ../)
ABS_SRCDIR = $(shell realpath .)
UNICODE_DATA_DIR = $(ABS_SRCDIR)/unicode/
PKG_LIB_DIR = $(ABS_TOP_SRCDIR)/lib

UNICODE_URL = http://www.unicode.org/Public
UNICODE_VERSION = 12.0.0
WGET = $(shell which wget)
WGETFLAGS = -np -nd -rc -P $(UNICODE_DATA_DIR)
UNZIP = $(shell which unzip)

UNICODE_FILES = \
	Blocks.txt \
	DerivedAge.txt \
	NamesList.txt \
	Scripts.txt \
	UnicodeData.txt \
	Unihan.zip \
	$(NULL)

UNICODE_SOURCES = \
	unicode-blocks.h \
	unicode-categories.h \
	unicode-names.h \
	unicode-nameslist.h \
	unicode-scripts.h \
	unicode-unihan.h \
	unicode-versions.h \
	$(NULL)

download-unicode-data:
	[ -e $(UNICODE_DATA_DIR) ] || mkdir -p $(UNICODE_DATA_DIR); \
	for f in $(UNICODE_FILES); \
	do \
		[ -e $(UNICODE_DATA_DIR)$${f} ] || \
		$(WGET) $(WGETFLAGS) "$(UNICODE_URL)/$(UNICODE_VERSION)/ucd/$${f}"; \
	done

unicode-headers: download-unicode-data
	PROG_UNZIP=$(UNZIP) ./gen-unicode-headers.pl $(UNICODE_VERSION) $(UNICODE_DATA_DIR) && \
	for f in $(UNICODE_SOURCES); \
	do \
		mv $${f} $(PKG_LIB_DIR)/unicode/; \
	done && \
	rm -rf $(UNICODE_DATA_DIR)

$(PACKAGE_NAME).pot:
	cd $(ABS_TOP_SRCDIR)  && \
	meson build && \
	ninja -C build font-manager-pot && \
	ninja -C build help-font-manager-pot && \
	cd $(ABS_SRCDIR)

$(PACKAGE_NAME)-license.h:
	cd license && \
	./genheader.py $(PKG_LIB_DIR)/common && \
	cd ..

$(PACKAGE_NAME)-vendor.h:
	cd vendor && \
	./genheader.py $(PKG_LIB_DIR)/common && \
	cd ..

update-headers: $(PACKAGE_NAME)-license.h $(PACKAGE_NAME)-vendor.h unicode-headers
update: update-headers $(PACKAGE_NAME).pot

rpm:
	@echo -e "\n**** Need to ensure build dependencies are installed\n";
	pkexec dnf install rpmdevtools
	pkexec dnf builddep $(ABS_TOP_SRCDIR)/fedora/$(PACKAGE_NAME).spec
	rpmdev-setuptree
	cp $(ABS_TOP_SRCDIR)/fedora/$(PACKAGE_NAME).spec ~/rpmbuild/SPECS/
	cd ~/rpmbuild/SPECS/ || exit && \
	spectool -g -R $(PACKAGE_NAME).spec && \
	rpmbuild -ba $(PACKAGE_NAME).spec

BUILD_DEPENDS = \
	build-essential \
	debhelper \
	valac \
	meson \
	libxml2-dev \
	libfreetype6-dev \
	libfontconfig1-dev \
	libglib2.0-dev \
	libjson-glib-dev \
	libcairo2-dev \
	libgtk-3-dev \
	libpango1.0-dev \
	libsqlite3-dev \
	libgirepository1.0-dev \
	yelp-tools \
	python \
	python-gobject \
	python-nautilus

deb:
	@echo -e '\n*** Need to ensure build dependencies are installed ***\n\n'
	pkexec apt install $(BUILD_DEPENDS)
	cd $(ABS_TOP_SRCDIR) || exit && \
	meson build && \
	ninja -C build dist && \
	cd build/meson-dist/ || exit && \
	tar -xvf $(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.xz && \
	mv $(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.xz \
	./$(PACKAGE_NAME)_$(PACKAGE_VERSION).orig.tar.xz && \
	cd $(PACKAGE_NAME)-$(PACKAGE_VERSION) || exit && \
	cp -R ../../../debian . && \
	dpkg-buildpackage -us -uc && \
	cd $(ABS_SRCDIR) || exit && \
	xdg-open ../build/meson-dist/

