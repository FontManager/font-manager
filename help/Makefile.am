man1_MANS = \
	$(PACKAGE_NAME).1

EXTRA_DIST = \
	$(PACKAGE_NAME).1.in

@YELP_HELP_RULES@

HELP_ID = $(PACKAGE_NAME)

HELP_FILES = \
	font-manager-activating.page
	font-manager-addremove.page
	font-manager-browsing.page
	font-manager-category.page
	font-manager-charmap.page
	font-manager-CLI.page
	font-manager-collection.page
	font-manager-compare.page
	font-manager-fontlist.page
	font-manager-preferences.page
	font-manager-preview.page
	font-manager-search.page
	index.page

HELP_MEDIA = \
	media/logo.png

HELP_LINGUAS = \
	ar \
	pl \
	de

MAINTAINERCLEANFILES = \
	$(PACKAGE_NAME).pot \
	./Makefile.in

dist-hook:
	cd $(distdir) && find . -name *.stamp* -exec rm -f {} \;

