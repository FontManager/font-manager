
DEFAULT_CFLAGS = \
	-DG_LOG_DOMAIN=\"[font-manager]\" \
	-DLOCALEDIR=\"$(localedir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	$(CAIRO_CFLAGS) \
	$(FONTCONFIG_CFLAGS) \
	$(FREETYPE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GMODULE_CFLAGS) \
	$(GOBJECT_CFLAGS) \
	$(GTK_CFLAGS) \
	$(JSONGLIB_CFLAGS) \
	$(PANGO_CFLAGS) \
	$(PANGOCAIRO_CFLAGS) \
	$(PANGOFT2_CFLAGS) \
	$(SQLITE3_CFLAGS) \
	$(XML_CFLAGS)

DEFAULT_INCLUDES = \
	-I$(top_builddir) \
	-I$(top_srcdir)/lib/common \
	-I$(top_srcdir)/lib/orthographies \
	-I$(top_srcdir)/lib/unicode

# Our code should compile without warnings
AM_CFLAGS = \
	-Wall -Wextra -Werror=format-security \
	$(DEFAULT_CFLAGS) \
	$(DEFAULT_INCLUDES)

# Ignore warnings for Vala generated code
AM_VALA_CFLAGS = \
	-w \
	$(DEFAULT_CFLAGS) \
	$(DEFAULT_INCLUDES)

AM_VALAFLAGS = \
	--target-glib 2.44 \
	--pkg gmodule-2.0 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gtk+-3.0 \
	--pkg json-glib-1.0 \
	--pkg libxml-2.0 \
	--pkg pango \
	--pkg sqlite3

AM_LDADD = \
	-lm \
	-lpthread \
	$(CAIRO_LIBS) \
	$(FONTCONFIG_LIBS) \
	$(FREETYPE_LIBS) \
	$(GIO_LIBS) \
	$(GLIB_LIBS) \
	$(GMODULE_LIBS) \
	$(GOBJECT_LIBS) \
	$(GTK_LIBS) \
	$(JSONGLIB_LIBS) \
	$(PANGO_LIBS) \
	$(PANGOCAIRO_LIBS) \
	$(PANGOFT2_LIBS) \
	$(SQLITE3_LIBS) \
	$(XML_LIBS)

