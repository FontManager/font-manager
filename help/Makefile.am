man1_MANS = \
	$(PACKAGE_NAME).1

EXTRA_DIST = \
	$(PACKAGE_NAME).1.in

@YELP_HELP_RULES@

HELP_ID = $(PACKAGE_NAME)

HELP_FILES = \
	index.page

HELP_MEDIA = \
	media/logo.png

HELP_LINGUAS = \
	ar \
	pl

MAINTAINERCLEANFILES = \
	$(PACKAGE_NAME).pot \
	./Makefile.in

dist-hook:
	cd $(distdir) && find . -name *.stamp* -exec rm -f {} \;

