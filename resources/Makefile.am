EXTRA_DIST = \
	FontManagerGResource.xml \
	FontManager.css \
	ApplicationMenu.ui \
	font-manager.desktop.in \
	org.gnome.FontManager.gschema.xml

gsettings_SCHEMAS = org.gnome.FontManager.gschema.xml
@GSETTINGS_RULES@

desktopdir = $(datadir)/applications
dist_desktop_in_files = font-manager.desktop.in
dist_desktop_DATA = $(dist_desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@
