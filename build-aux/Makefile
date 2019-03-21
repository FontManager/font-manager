
PACKAGE_NAME = font-manager
PACKAGE_VERSION = 0.7.4

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
	unicode-i18n.h \
	unicode-names.h \
	unicode-nameslist.h \
	unicode-scripts.h \
	unicode-unihan.h \
	unicode-versions.h \
	$(NULL)

download-unicode-data:
	for f in $(UNICODE_FILES); \
	do \
		[ -e $(UNICODE_DATA_DIR)$${f} ] || \
		$(WGET) $(WGETFLAGS) "$(UNICODE_URL)/$(UNICODE_VERSION)/ucd/$${f}"; \
	done

unicode-headers: download-unicode-data
	PROG_UNZIP=$(UNZIP) ./gen-unicode-headers.pl $(UNICODE_VERSION) $(UNICODE_DATA_DIR) && \
	./gen-unicode-headers.pl $(UNICODE_VERSION) $(UNICODE_DATA_DIR) --i18n && \
	for f in $(UNICODE_SOURCES); \
	do \
		mv $${f} $(PKG_LIB_DIR)/unicode/; \
	done

$(PACKAGE_NAME).pot:
	cd $(ABS_TOP_SRCDIR)  && \
	meson build && \
	ninja -C build font-manager-pot && \
	ninja -C build help-font-manager-pot && \
	cd $(ABS_SRCDIR)

license.h:
	cd license && \
	./genheader.py $(PKG_LIB_DIR)/common && \
	cd ..

vendor.h:
	cd vendor && \
	./genheader.py $(PKG_LIB_DIR)/common && \
	cd ..

update-headers: license.h vendor.h unicode-headers
update: update-headers $(PACKAGE_NAME).pot

