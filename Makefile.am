
ACLOCAL_AMFLAGS = -I m4

SUBDIRS = \
	data \
	extensions \
	help \
	lib \
	src \
	po

EXTRA_DIST = \
	CHANGELOG \
	config.rpath \
	config.vapi \
	po/HEADER \
	po/Makevars.in \
	po/POTFILES.readme \
	po/POTFILES.skip \
	help/insert-header.sin \
	help/HEADER \
	Flags.mk

DISTCLEANFILES = \
	po/Makefile \
	po/Makefile.in \
	po/Makevars \
	po/$(PACKAGE_NAME).pot \
	po/POTFILES \
	po/*stamp*

MAINTAINERCLEANFILES = \
	ABOUT-NLS \
	aclocal.m4 \
	compile \
	config.h.in* \
	config.guess \
	config.rpath \
	config.sub \
	configure \
	depcomp \
	install-sh \
	ltmain.sh \
	missing \
	py-compile \
	Makefile.in \
	po/Makefile* \
	po/Makevars \
	po/POTFILES \
	po/*stamp* \
	po/.pot \
	po/$(PACKAGE_NAME).pot \
	po/*.template \
	po/*.sed \
	po/*.sin \
	po/*.header \
	po/*-quot

maintainer-clean-local:
	-rm -rf m4 autom4te.cache $(PACKAGE_NAME)-$(PACKAGE_VERSION)* BUILD TEST build
	-find . -name .libs -exec rm -rf {} \;
	-find . -name .deps -exec rm -rf {} \;
