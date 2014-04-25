EXTRA_DIST = \
	FontManagerGResource.xml \
	org.gnome.FontManager.gschema.xml \
	FontManager.css

install-data-local:
	$(MKDIR_P) $(datadir)/glib-2.0/schemas/
	$(INSTALL) org.gnome.FontManager.gschema.xml $(datadir)/glib-2.0/schemas/
	glib-compile-schemas $(datadir)/glib-2.0/schemas/

uninstall-local:
	-rm $(datadir)/glib-2.0/schemas/org.gnome.FontManager.gschema.xml
	-rm $(datadir)/glib-2.0/schemas/gschemas.compiled
	glib-compile-schemas $(datadir)/glib-2.0/schemas/
