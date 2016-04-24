
gsettings_SCHEMAS = \
	org.gnome.FontManager.gschema.xml \
	org.gnome.FontViewer.gschema.xml

desktopdir = $(datadir)/applications
dist_desktop_in_files = \
	org.gnome.FontManager.desktop.in \
	org.gnome.FontViewer.desktop.in
dist_desktop_DATA = $(dist_desktop_in_files:.desktop.in=.desktop)

appdatadir = $(datarootdir)/appdata
appdata_in_files = org.gnome.FontManager.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)

@GSETTINGS_RULES@
@INTLTOOL_DESKTOP_RULE@
@INTLTOOL_XML_RULE@

org.gnome.FontManager.service:
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontManager'; \
	echo 'Exec=${bindir}/$(PACKAGE_NAME) --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

org.gnome.FontViewer.service:
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontViewer'; \
	echo 'Exec=${pkglibexecdir}/font-viewer --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

dbusservicedir = $(datadir)/dbus-1/services
dbusservice_DATA = \
	org.gnome.FontManager.service \
	org.gnome.FontViewer.service

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
	$(gsettings_SCHEMAS) \
	$(dist_desktop_in_files) \
	$(appdata_in_files)

MAINTAINERCLEANFILES = \
	Makefile.in

# Allow running without installation
compile-gsettings-schemas:
	$(GLIB_COMPILE_SCHEMAS) ./

all: compile-gsettings-schemas org.gnome.FontManager.service org.gnome.FontViewer.service
	$(SED) -i 's|\@PKGLIBEXECDIR\@|${pkglibexecdir}|g' org.gnome.FontViewer.desktop

.PHONY: compile-gsettings-schemas
