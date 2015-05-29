@GSETTINGS_RULES@
gsettings_SCHEMAS = org.gnome.FontManager.gschema.xml

@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
dist_desktop_in_files = org.gnome.FontManager.desktop.in
dist_desktop_DATA = $(dist_desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_XML_RULE@
appdatadir = $(datarootdir)/appdata
appdata_in_files = font-manager.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)

dbusservicedir = $(datadir)/dbus-1/services
dbusservice_DATA = org.gnome.FontManager.service

org.gnome.FontManager.service: Makefile
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontManager'; \
	echo 'Exec=${bindir}/font-manager --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

CLEANFILES = \
	$(appdata_DATA) \
	$(dist_desktop_DATA) \
	$(dbusservice_DATA)

dist-hook:
	cd $(distdir) && rm -f $(appdata_DATA) $(dist_desktop_DATA) $(dbusservice_DATA)

EXTRA_DIST = \
	icons \
	FontManagerGResource.xml \
	FontManager.css \
	ApplicationMenu.ui \
	$(dist_desktop_in_files) \
	$(gsettings_SCHEMAS) \
	$(appdata_in_files)

