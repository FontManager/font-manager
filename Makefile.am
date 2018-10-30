
ACLOCAL_AMFLAGS = -I m4

SUBDIRS = \
	data \
	extensions \
	help \
	lib \
	src \
	po \
	tests

CONFIG_STATUS_DEPENDENCIES = lib/common/utils.c.in

EXTRA_DIST = \
	config.vapi \
	po/insert-header.sin \
	po/Makefile.in.in \
	po/HEADER \
	po/POTFILES.in \
	po/POTFILES.readme \
	po/POTFILES.skip \
	help/insert-header.sin \
	help/HEADER \
	Flags.mk

DISTCLEANFILES = \
	po/Makefile \
	po/Makefile.in \
	po/POTFILES \
	po/*stamp*

MAINTAINERCLEANFILES = \
	aclocal.m4 \
	compile \
	config.h.* \
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

maintainer-clean-local:
	-rm -rf m4 autom4te.cache $(PACKAGE_NAME)-$(PACKAGE_VERSION)* BUILD
	-find . -name .libs -exec rm -rf {} \;
	-find . -name .deps -exec rm -rf {} \;

