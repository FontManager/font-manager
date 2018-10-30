include $(top_srcdir)/Flags.mk

libfmunicode_@PACKAGE_VERSION@_la_CFLAGS = $(AM_CFLAGS)

libfmunicode_@PACKAGE_VERSION@_la_LIBADD = $(AM_LDADD)

libfmunicode_@PACKAGE_VERSION@_la_SOURCES = \
	unicode-codepoint-list.c \
	unicode-codepoint-list.h \
	unicode-character-map.c \
	unicode-character-map.h \
	unicode-info.c \
	unicode-info.h

noinst_LTLIBRARIES = libfmunicode-@PACKAGE_VERSION@.la

EXTRA_DIST = \
	unicode-blocks.h \
	unicode-categories.h \
	unicode-names.h \
	unicode-nameslist.h \
	unicode-scripts.h \
	unicode-unihan.h \
	unicode-versions.h

CLEANFILES =

MAINTAINERCLEANFILES = \
	Makefile.in

# Vala bindings

-include $(INTROSPECTION_MAKEFILE)

if HAVE_INTROSPECTION

INTROSPECTION_GIRS = Unicode.gir
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(srcdir) --warn-all
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

Unicode.gir: $(noinst_LTLIBRARIES)
Unicode_gir_INCLUDES = Pango-1.0 Gdk-$(GTK_API_VERSION) Gtk-$(GTK_API_VERSION)
Unicode_gir_SCANNERFLAGS = --c-include "unicode-info.h"
Unicode_gir_LIBS = $(noinst_LTLIBRARIES)
Unicode_gir_FILES = $(libfmunicode_@PACKAGE_VERSION@_la_SOURCES)
Unicode_gir_NAMESPACE = Unicode

girdir = $(DESTDIR)$(datadir)/gir-1.0
typelibdir = $(DESTDIR)$(libdir)/girepository-1.0
gir_DATA = $(INTROSPECTION_GIRS)
typelib_DATA = $(INTROSPECTION_GIRS:.gir=.typelib)

if ENABLE_VAPIGEN

-include $(VAPIGEN_MAKEFILE)

Unicode.vapi: Unicode.gir

Unicode_vapi_FILES = Unicode.gir
Unicode_vapi_DEPS = glib-2.0 pango gdk-$(GTK_API_VERSION) gtk+-$(GTK_API_VERSION)
Unicode_vapi_METADATADIRS = $(srcdir)
Unicode_vapi_VAPIDIRS = $(datadir)/vala/vapi

VAPIGEN_VAPIS = Unicode.vapi

vapidir = $(DESTDIR)$(datadir)/vala/vapi
vapi_DATA = $(VAPIGEN_VAPIS)


# HAVE_INTROSPECTION
endif

CLEANFILES += $(gir_DATA) $(typelib_DATA)

# ENABLE_VAPIGEN
endif

EXTRA_DIST += Unicode.vapi Unicode.metadata
