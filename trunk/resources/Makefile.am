EXTRA_DIST = \
	FontManagerGResource.xml \
	org.gnome.FontManager.gschema.xml \
	FontManager.css

install-data-local:
	$(MKDIR_P) $(DESTDIR)$(datadir)/glib-2.0/schemas/
	$(INSTALL) org.gnome.FontManager.gschema.xml $(DESTDIR)$(datadir)/glib-2.0/schemas/
	glib-compile-schemas $(DESTDIR)$(datadir)/glib-2.0/schemas/

uninstall-local:
	-rm $(DESTDIR)$(datadir)/glib-2.0/schemas/org.gnome.FontManager.gschema.xml
	-rm $(DESTDIR)$(datadir)/glib-2.0/schemas/gschemas.compiled
	glib-compile-schemas $(DESTDIR)$(datadir)/glib-2.0/schemas/


