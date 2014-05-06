EXTRA_DIST = \
	FontManagerGResource.xml \
	org.gnome.FontManager.gschema.xml \
	FontManager.css \
	font-manager.desktop

install-data-local:
	$(MKDIR_P) $(DESTDIR)$(datadir)/glib-2.0/schemas/
	$(INSTALL) org.gnome.FontManager.gschema.xml $(DESTDIR)$(datadir)/glib-2.0/schemas/
	glib-compile-schemas $(DESTDIR)$(datadir)/glib-2.0/schemas/
	desktop-file-install --dir=$(DESTDIR)$(datadir)/applications font-manager.desktop

uninstall-local:
	-rm -f $(DESTDIR)$(datadir)/glib-2.0/schemas/org.gnome.FontManager.gschema.xml
	-rm -f $(DESTDIR)$(datadir)/glib-2.0/schemas/gschemas.compiled
	-rm -f $(DESTDIR)$(datadir)/applications/font-manager.desktop
	glib-compile-schemas $(DESTDIR)$(datadir)/glib-2.0/schemas/
	

