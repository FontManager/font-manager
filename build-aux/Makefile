
PACKAGE_NAME = font-manager
PACKAGE_VERSION = 0.7.4

abs_top_srcdir = $(shell realpath ../)
abs_srcdir = $(shell realpath .)
unicode_data_dir = $(abs_srcdir)/unicode/

UNICODE_VERSION = 10.0.0
SED = $(shell which sed)
WGET = $(shell which wget)
WGETFLAGS = -np -nd -rc -P $(unicode_data_dir)
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
		[ -e $(unicode_data_dir)$${f} ] || \
		$(WGET) $(WGETFLAGS) "http://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/$${f}"; \
	done

unicode-headers: download-unicode-data
	PROG_UNZIP=$(UNZIP) ./gen-unicode-headers.pl $(UNICODE_VERSION) $(unicode_data_dir) && \
	./gen-unicode-headers.pl $(UNICODE_VERSION) $(unicode_data_dir) --i18n && \
	for f in $(UNICODE_SOURCES); \
	do \
		mv $${f} $(abs_top_srcdir)/lib/Unicode/; \
	done

POTFILES.readme:
	echo "Do not edit POTFILES.* directly. See build-aux directory" > $(abs_top_srcdir)/po/$@

POTFILES.in:
	find $(abs_top_srcdir) -name "*.vala*" -print | $(SED) -e 's|$(abs_top_srcdir)/||g' -e 's/\.in//g' | sort | uniq > $(abs_top_srcdir)/po/$@ ;
	find $(abs_top_srcdir) -name "*i18n.h" -print | $(SED) -e 's|$(abs_top_srcdir)/||g' >> $(abs_top_srcdir)/po/$@ ;
	echo "[type: gettext/glade]data/ApplicationMenu.ui" >> $(abs_top_srcdir)/po/$@ ;
	echo "data/org.gnome.FontManager.appdata.xml.in" >> $(abs_top_srcdir)/po/$@ ;
	echo "data/org.gnome.FontManager.desktop.in" >> $(abs_top_srcdir)/po/$@ ;
	echo "" >> $(abs_top_srcdir)/po/$@ ;
	$(SED) -i 's|\.\./||g' $(abs_top_srcdir)/po/$@ ;

POTFILES.skip:
	find $(abs_top_srcdir) -name "*.vala*" -print | $(SED) -e 's|$(abs_top_srcdir)/||g' -e 's/\.in//g' | sort | uniq | $(SED) 's/.vala/.c/g' > $(abs_top_srcdir)/po/$@ ;
	$(SED) -i 's|\.\./||g' $(abs_top_srcdir)/po/$@ ;
	echo "lib/Glue/Enums.c" >> $(abs_top_srcdir)/po/$@ ;

POT:
	cd $(abs_top_srcdir) && \
	test -e Makefile || ./autogen.sh && \
	make $(PACKAGE_NAME).pot && \
	cd $(abs_srcdir)

write_sources = \
	for i in `find . -type f -name '*.vala*' -print | $(SED) 's/\.in//g' | sort | uniq`; \
	do \
		echo "$$i \\" >> $1  ; \
	done && \
	$(SED) -i -e 's/^\.\//	/g' -e '$$ s/\\//' $1

ValaSources.mk:
	cd $(abs_top_srcdir)/lib && \
	echo "# Do not edit directly. See build-aux directory" > $@ && \
	echo "" >> $@ && \
	echo "libfontmanager_la_VALASOURCES = \\" >> $@ && \
	$(call write_sources,$@) && \
	cd $(abs_top_srcdir)/src/$(PACKAGE_NAME) && \
	echo "# Do not edit directly. See build-aux directory" > $@ && \
	echo "" >> $@ && \
	echo "font_manager_VALASOURCES = \\" >> $@ && \
	$(call write_sources,$@) && \
	cd $(abs_srcdir)

License.h:
	license/genheader.py $(abs_top_srcdir)/lib/Glue

Vendor.h:
	vendor/genheader.py $(abs_top_srcdir)/lib/Glue

update-headers: License.h Vendor.h unicode-headers
update-po: POTFILES.readme POTFILES.in POTFILES.skip POT
update-sources: ValaSources.mk
update: update-headers update-po update-sources

# Fedora RPM packaging

rpm-prep:
	@echo -e "\n**** Need to ensure rpmdevtools are installed\n";
	pkexec dnf install rpmdevtools
	@echo -e "\n**** Need to ensure build dependencies are installed\n";
	pkexec dnf builddep $(abs_top_srcdir)/fedora/$(PACKAGE_NAME).spec
	cd $(abs_top_srcdir) && \
	test -e Makefile || ./autogen.sh && \
	make dist-bzip2 && \
	rpmdev-setuptree && \
	cp *.bz2 ~/rpmbuild/SOURCES/ && \
	cp fedora/$(PACKAGE_NAME).spec ~/rpmbuild/SPECS/ && \
	cd $(abs_srcdir)
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
	cd $(abs_top_srcdir) && \
	mk-build-deps $(abs_top_srcdir)/debian/control && \
	sudo dpkg -i $(abs_top_srcdir)/*.deb && rm $(abs_top_srcdir)/*.deb && \
	test -e Makefile || ./autogen.sh && \
	make dist-bzip2 && \
	rm -rf BUILD && \
	mkdir BUILD && \
	mv $(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.bz2 BUILD/$(PACKAGE_NAME)_$(PACKAGE_VERSION).orig.tar.bz2 && \
	cd BUILD && \
	tar -xvf $(PACKAGE_NAME)_$(PACKAGE_VERSION).orig.tar.bz2 && \
	cp -Rpf ../debian $(PACKAGE_NAME)-$(PACKAGE_VERSION) && \
	cp -pf ../autogen.sh $(PACKAGE_NAME)-$(PACKAGE_VERSION) && \
	cd $(abs_top_srcdir)/BUILD/$(PACKAGE_NAME)-$(PACKAGE_VERSION) && \
	debuild -us -uc && \
	cd $(abs_srcdir)

