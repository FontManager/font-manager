
SUBDIRS = \
	data \
	lib \
	src \
	tests \
	extensions \
	help \
	po

ACLOCAL_AMFLAGS = -I m4

CONFIG_STATUS_DEPENDENCIES = \
	lib/UX/Utils/Utils.vala.in \
	lib/FontConfig/Sources.vala.in \
	lib/Common/About.vala.in \
	lib/Common/Settings.vala.in \
	lib/Common/Constants.vala.in \
	lib/Common/Database.vala.in \
	lib/Common/Collections.vala.in \
	src/font-manager/Migration.vala.in \
	src/font-manager/Application.vala.in \
	src/font-manager/Main.vala.in \
	src/font-viewer/Application.vala.in

EXTRA_DIST = \
	po/insert-header.sin \
	po/Makefile.in.in \
	po/HEADER \
	po/POTFILES.in \
	po/POTFILES.readme \
	po/POTFILES.skip \
	help/insert-header.sin \
	help/HEADER \
	vapi/Unicode.vapi \
	Flags.mk

DISTCLEANFILES = \
	po/Makefile \
	po/Makefile.in \
	po/POTFILES \
	po/*stamp*

MAINTAINERCLEANFILES = \
	aclocal.m4 \
	compile \
	config.guess \
	config.sub \
	configure \
	depcomp \
	install-sh \
	ltmain.sh \
	missing \
	py-compile \
	Makefile.in \
	po/Makefile* \
	po/POTFILES \
	po/*stamp*

update_pot_header = \
	$(SED) -f insert-header.sin -i $1 && \
	$(SED) -i 's/PACKAGE/${PACKAGE_NAME}/g' $1 && \
	$(SED) -i 's/VERSION/${PACKAGE_VERSION}/g' $1

$(PACKAGE_NAME).pot:
	cd $(abs_top_srcdir)/po/ && \
	rm -f $@  && \
	$(MAKE) update-po && \
	$(call update_pot_header,$@) && \
	cd $(abs_top_srcdir)/help && \
	rm -f $@  && \
	$(MAKE) pot && \
	$(call update_pot_header,$@) && \
	$(MAKE) repo && \
	cd $(abs_srcdir)

maintainer-clean-local:
	-rm -rf m4 autom4te.cache $(PACKAGE_NAME)-$(PACKAGE_VERSION)* BUILD
	find . -name .libs -exec rm -rf {} \;
	find . -name .deps -exec rm -rf {} \;

all: $(PACKAGE_NAME).pot
.PHONY: $(PACKAGE_NAME).pot vapi/Unicode.vapi
