@GSETTINGS_RULES@
gsettings_SCHEMAS = \
	org.gnome.FontManager.gschema.xml \
	org.gnome.FontViewer.gschema.xml

@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
dist_desktop_in_files = \
	org.gnome.FontManager.desktop.in \
	org.gnome.FontViewer.desktop.in
dist_desktop_DATA = $(dist_desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_XML_RULE@
appdatadir = $(datarootdir)/appdata
appdata_in_files = org.gnome.FontManager.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)

dbusservicedir = $(datadir)/dbus-1/services
dbusservice_DATA = \
	org.gnome.FontManager.service \
	org.gnome.FontViewer.service

org.gnome.FontManager.service: Makefile
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontManager'; \
	echo 'Exec=${bindir}/$(PACKAGE_NAME) --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

org.gnome.FontViewer.service: Makefile
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontViewer'; \
	echo 'Exec=${pkglibexecdir}/font-viewer --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

compile-gsettings-schemas:
	$(GLIB_COMPILE_SCHEMAS) ./

all: compile-gsettings-schemas
	$(SED) -i 's|\@PKGLIBEXECDIR\@|${pkglibexecdir}|g' org.gnome.FontViewer.desktop

CLEANFILES = \
	$(appdata_DATA) \
	$(dist_desktop_DATA) \
	$(dbusservice_DATA) \
	gschemas.compiled

DISTCLEANFILES = \
	$(appdata_DATA) \
	$(dist_desktop_DATA) \
	$(dbusservice_DATA)

EXTRA_DIST = \
	icons \
	FontManagerGResource.xml \
	FontManager.css \
	ApplicationMenu.ui \
	$(dist_desktop_in_files) \
	$(gsettings_SCHEMAS) \
	$(appdata_in_files)

MAINTAINERCLEANFILES = \
	./Makefile.in
