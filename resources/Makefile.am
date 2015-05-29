@GSETTINGS_RULES@
gsettings_SCHEMAS = org.gnome.FontManager.gschema.xml

@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
dist_desktop_in_files = font-manager.desktop.in
dist_desktop_DATA = $(dist_desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_XML_RULE@
appdatadir = $(datarootdir)/appdata
appdata_in_files = font-manager.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)

CLEANFILES = $(appdata_DATA) \
	$(dist_desktop_DATA)

EXTRA_DIST = \
	FontManagerGResource.xml \
	FontManager.css \
	ApplicationMenu.ui \
	$(dist_desktop_in_files) \
	$(gsettings_SCHEMAS) \
	$(appdata_in_files)

