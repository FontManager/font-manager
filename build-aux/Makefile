# Project must be configured or some of these targets will fail

abs_top_srcdir = $(shell realpath ../)
abs_srcdir = $(shell realpath .)
SED = $(shell which sed)
PACKAGE_NAME = font-manager

POTFILES.readme:
	echo "Do not edit POTFILES.* directly. See build-aux directory" > $(abs_top_srcdir)/po/$@

POTFILES.in:
	find $(abs_top_srcdir) -name "*.vala*" -print | $(SED) -e 's|$(abs_top_srcdir)/||g' -e 's/\.in//g' | sort | uniq > $(abs_top_srcdir)/po/$@ ;
	echo "[type: gettext/glade]data/ApplicationMenu.ui" >> $(abs_top_srcdir)/po/$@ ;
	echo "data/org.gnome.FontManager.appdata.xml.in" >> $(abs_top_srcdir)/po/$@ ;
	echo "data/org.gnome.FontManager.desktop.in" >> $(abs_top_srcdir)/po/$@ ;
	echo "" >> $(abs_top_srcdir)/po/$@ ;
	$(SED) -i 's|\.\./||g' $(abs_top_srcdir)/po/$@ ;

POTFILES.skip:
	find $(abs_top_srcdir) -name "*.vala*" -print | $(SED) -e 's|$(abs_top_srcdir)/||g' -e 's/\.in//g' | sort | uniq | $(SED) 's/.vala/.c/g' > $(abs_top_srcdir)/po/$@ ;
	$(SED) -i 's|\.\./||g' $(abs_top_srcdir)/po/$@ ;
	echo "lib/Glue/Enums.c" >> $(abs_top_srcdir)/po/$@ ;

$(PACKAGE_NAME).pot: POTFILES.readme POTFILES.in POTFILES.skip
	cd $(abs_top_srcdir)/po/ && \
	rm -f $@  && \
	$(MAKE) update-po && \
	$(SED) -f insert-header.sin -i $@  &&\
	cd $(abs_top_srcdir)/help && \
	rm -f $@  && \
	$(MAKE) pot && \
	$(SED) -f insert-header.sin -i $@  && \
	$(MAKE) repo && \
	cd $(abs_srcdir)

write_sources = \
	for i in `find . -type f -name '*.vala*' -print | $(SED) 's/\.in//g' | sort | uniq`; \
	do \
		echo "$$i \\" >> $1  ; \
	done && \
	$(SED) -i -e 's/^\.\//	/g' -e '$$ s/\\//' $1

ValaSources.mk:
	cd $(abs_top_srcdir)/lib && \
	echo "# Do not edit directly. See build-aux directory" > $@  && \
	echo "" >> $@ && \
	echo "libfontmanager_la_VALASOURCES = \\" >> $@  && \
	$(call write_sources,$@) && \
	cd $(abs_top_srcdir)/src/font-manager && \
	echo "# Do not edit directly. See build-aux directory" > $@  && \
	echo "" >> $@ && \
	echo "font_manager_VALASOURCES = \\" >> $@  && \
	$(call write_sources,$@) && \
	cd $(abs_srcdir)

License.h:
	license/genheader.py $(abs_top_srcdir)/lib/Glue

Vendor.h:
	vendor/genheader.py $(abs_top_srcdir)/lib/Glue

update-headers: License.h Vendor.h
update-po: $(PACKAGE_NAME).pot
update-sources: ValaSources.mk
update: update-headers update-po update-sources

# Fedora RPM packaging

rpm-prep:
	cd $(abs_top_srcdir) && \
	make dist-bzip2 && \
	rpmdev-setuptree && \
	cp *.bz2 ~/rpmbuild/SOURCES/ && \
	cp fedora/font-manager.spec ~/rpmbuild/SPECS/ && \
	cd $(abs_srcdir)

rpm: rpm-prep
	pkexec dnf builddep ~/rpmbuild/SPECS/font-manager.spec
	rpmbuild -bb ~/rpmbuild/SPECS/font-manager.spec

srpm: rpm-prep
	rpmbuild -bs ~/rpmbuild/SPECS/font-manager.spec

copr-build: srpm
	copr-cli build --nowait jerrycasiano/FontManager ~/rpmbuild/SRPMS/font-manager*rpm
