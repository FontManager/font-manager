
PACKAGE_NAME = font-manager
PACKAGE_VERSION = 0.7.4.3

ABS_TOP_SRCDIR = $(shell realpath ../)
ABS_SRCDIR = $(shell realpath .)
UNICODE_DATA_DIR = $(ABS_SRCDIR)/unicode/
PKG_LIB_DIR = $(ABS_TOP_SRCDIR)/lib

UNICODE_URL = http://www.unicode.org/Public
UNICODE_VERSION = 12.0.0
SED = $(shell which sed)
WGET = $(shell which wget)
GREP = $(shell which grep)
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

POTFILES.readme:
	echo "Do not edit POTFILES.* directly. See build-aux directory" > $(ABS_TOP_SRCDIR)/po/$@

POTFILES.in:
	find $(ABS_TOP_SRCDIR) -name "*.vala*" -print | $(SED) -e 's|$(ABS_TOP_SRCDIR)/||g' -e 's/\.in//g' | sort | uniq > $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "lib/common/font-manager-source.c" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "lib/unicode/unicode-character-map.c" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "data/org.gnome.FontManager.appdata.xml.in.in" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "data/org.gnome.FontManager.desktop.in.in" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "data/org.gnome.FontViewer.appdata.xml.in.in" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "data/org.gnome.FontViewer.desktop.in.in" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	find $(ABS_TOP_SRCDIR)/data -name "*.ui" -print | $(SED) -e 's|$(ABS_TOP_SRCDIR)/||g' | sort | uniq >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	$(SED) -i '/.*-custom.vala/d' $(ABS_TOP_SRCDIR)/po/$@ ;
	$(SED) -i 's|\.\./||g' $(ABS_TOP_SRCDIR)/po/$@ ;
#find $(ABS_TOP_SRCDIR) -name "*i18n.h" -print | $(SED) -e 's|$(ABS_TOP_SRCDIR)/||g' >> $(ABS_TOP_SRCDIR)/po/$@ ;
#echo "lib/unicode/unicode-info.c" >> $(ABS_TOP_SRCDIR)/po/$@ ;

POTFILES.skip:
	find $(ABS_TOP_SRCDIR) -name "*.vala*" -print | $(SED) -e 's|$(ABS_TOP_SRCDIR)/||g' -e 's/\.in//g' | sort | uniq | $(SED) 's/\.vala/.c/g' > $(ABS_TOP_SRCDIR)/po/$@ ;
	$(SED) -i '/.*-custom.c/d' $(ABS_TOP_SRCDIR)/po/$@ ;
	$(SED) -i 's|\.\./||g' $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "data/org.gnome.FontManager.appdata.xml" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "data/org.gnome.FontViewer.appdata.xml" >> $(ABS_TOP_SRCDIR)/po/$@ ;
	echo "lib/unicode/unicode-info.c" >> $(ABS_TOP_SRCDIR)/po/$@ ;

update_pot_header = \
	$(SED) -f $(ABS_TOP_SRCDIR)/$2/insert-header.sin -i $1 && \
	$(SED) -i 's/PACKAGE/${PACKAGE_NAME}/g' $1 && \
	$(SED) -i 's/VERSION/${PACKAGE_VERSION}/g' $1

$(PACKAGE_NAME).pot:
	cd $(ABS_TOP_SRCDIR)  && \
	test -e Makefile || ./autogen.sh && \
	cd $(ABS_TOP_SRCDIR)/po/ && \
	rm -f $@  && \
	$(MAKE) update-po && \
	$(SED) '1,6 d' -i $@ && \
	$(call update_pot_header,$@,po) && \
	cd $(ABS_TOP_SRCDIR)/help && \
	rm -f $@  && \
	$(MAKE) pot && \
	$(call update_pot_header,$@,help) && \
	$(MAKE) repo && \
	cd $(ABS_SRCDIR)

write_sources = \
	for i in `find . -type f -name '*.vala*' -print | $(SED) 's/\.in//g' | sort | uniq`; \
	do \
		echo "$$i \\" >> $1  ; \
	done && \
	$(SED) -i -e 's/^\.\//	/g' -e '$$ s/\\//' $1

ValaSources.mk:
	cd $(ABS_TOP_SRCDIR)/lib/vala && \
	echo "# Do not edit directly. See build-aux directory" > $@ && \
	echo "" >> $@ && \
	echo "libfontmanager_la_VALASOURCES = \\" >> $@ && \
	$(call write_sources,$@) && \
	cd $(ABS_TOP_SRCDIR)/src/$(PACKAGE_NAME) && \
	echo "# Do not edit directly. See build-aux directory" > $@ && \
	echo "" >> $@ && \
	echo "font_manager_VALASOURCES = \\" >> $@ && \
	$(call write_sources,$@) && \
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
update-po: POTFILES.readme POTFILES.in POTFILES.skip $(PACKAGE_NAME).pot
update-sources: ValaSources.mk
update: update-headers update-po update-sources

# Fedora RPM packaging

rpm-prep:
	@echo -e "\n**** Need to ensure rpmdevtools are installed\n";
	pkexec dnf install rpmdevtools
	@echo -e "\n**** Need to ensure build dependencies are installed\n";
	pkexec dnf builddep $(ABS_TOP_SRCDIR)/fedora/$(PACKAGE_NAME).spec
	cd $(ABS_TOP_SRCDIR) && \
	test -e Makefile || ./autogen.sh && \
	make dist-bzip2 && \
	rpmdev-setuptree && \
	cp *.bz2 ~/rpmbuild/SOURCES/ && \
	cp fedora/$(PACKAGE_NAME).spec ~/rpmbuild/SPECS/ && \
	cd $(ABS_SRCDIR)
	rm -f ~/rpmbuild/SRPMS/$(PACKAGE_NAME)*.src.rpm

rpm: rpm-prep
	rpmbuild -bb ~/rpmbuild/SPECS/$(PACKAGE_NAME).spec

srpm: rpm-prep
	rpmbuild -bs ~/rpmbuild/SPECS/$(PACKAGE_NAME).spec

copr-build: srpm
	@echo -e "\n**** Need to ensure copr-cli is installed\n";
	pkexec dnf install copr-cli
	copr-cli build --nowait jerrycasiano/FontManager ~/rpmbuild/SRPMS/$(PACKAGE_NAME)*.src.rpm

# Debian? packaging
# Tested on Ubuntu

deb:
	@echo "\n**** Need to ensure build dependencies are installed\n";
	sudo apt-get install devscripts equivs
	cd $(ABS_TOP_SRCDIR) && \
	mk-build-deps $(ABS_TOP_SRCDIR)/debian/control && \
	sudo dpkg -i $(ABS_TOP_SRCDIR)/*.deb && rm $(ABS_TOP_SRCDIR)/*.deb && \
	test -e Makefile || ./autogen.sh && \
	make dist-bzip2 && \
	rm -rf BUILD && \
	mkdir BUILD && \
	mv $(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.bz2 BUILD/$(PACKAGE_NAME)_$(PACKAGE_VERSION).orig.tar.bz2 && \
	cd BUILD && \
	tar -xvf $(PACKAGE_NAME)_$(PACKAGE_VERSION).orig.tar.bz2 && \
	cp -Rpf ../debian $(PACKAGE_NAME)-$(PACKAGE_VERSION) && \
	cp -pf ../autogen.sh $(PACKAGE_NAME)-$(PACKAGE_VERSION) && \
	cd $(ABS_TOP_SRCDIR)/BUILD/$(PACKAGE_NAME)-$(PACKAGE_VERSION) && \
	debuild -us -uc && \
	cd $(ABS_SRCDIR)

