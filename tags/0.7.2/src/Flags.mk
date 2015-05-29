AM_CPPFLAGS = -DLOCALEDIR=\""$(localedir)"\"

AM_VALAFLAGS = \
--target-glib 2.38 \
--pkg gmodule-2.0 \
--pkg glib-2.0 \
--pkg gio-2.0 \
--pkg gtk+-3.0 \
--pkg gee-0.8 \
--pkg json-glib-1.0 \
--pkg Gucharmap-2.90 \
--pkg libxml-2.0 \
--pkg pango \
--pkg sqlite3 \
$(GTK_314_OR_LATER) \
$(GTK_316_OR_LATER) \
$(VALA_0271_OR_LATER) \
--gresources $(resource_dir)/FontManagerGResource.xml

font_manager_CPPFLAGS = \
-w \
$(XML_CFLAGS) \
$(FREETYPE_CFLAGS) \
$(FONTCONFIG_CFLAGS) \
$(GOBJECT_CFLAGS) \
$(GLIB_CFLAGS) \
$(GMODULE_CFLAGS) \
$(GIO_CFLAGS) \
$(CAIRO_CFLAGS) \
$(GTK_CFLAGS) \
$(PANGO_CFLAGS) \
$(PANGOCAIRO_CFLAGS) \
$(PANGOFT2_CFLAGS) \
$(GEE_CFLAGS) \
$(GUCHARMAP_CFLAGS) \
$(JSONGLIB_CFLAGS) \
$(SQLITE3_CFLAGS)

font_manager_LDADD = \
-lm \
-lpthread \
$(XML_LIBS) \
$(FREETYPE_LIBS) \
$(FONTCONFIG_LIBS) \
$(GOBJECT_LIBS) \
$(GLIB_LIBS) \
$(GMODULE_LIBS) \
$(GIO_LIBS) \
$(CAIRO_LIBS) \
$(GTK_LIBS) \
$(PANGO_LIBS) \
$(PANGOCAIRO_LIBS) \
$(PANGOFT2_LIBS) \
$(GEE_LIBS) \
$(GUCHARMAP_LIBS) \
$(JSONGLIB_LIBS) \
$(SQLITE3_LIBS)
