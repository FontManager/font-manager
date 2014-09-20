EXTRA_DIST = \
	FontManagerGResource.xml \
	FontManager.css \
	ApplicationMenu.ui \
	font-manager.desktop.in \
	org.gnome.FontManager.gschema.xml

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
EXTRA_DIST = $(appdata_in_files)
CLEANFILES = $(appdata_DATA)

