
include $(top_srcdir)/Flags.mk


noinst_LTLIBRARIES = libunicode.la

libunicode_la_SOURCES = \
	unicode-block-model.c \
	unicode-block-model.h \
	unicode-block-codepoint-list.c \
	unicode-block-codepoint-list.h \
	unicode-chapters-model.c \
	unicode-chapters-model.h \
	unicode-character-map.c \
	unicode-character-map.h \
	unicode-codepoint-list.c \
	unicode-codepoint-list.h \
	unicode-script-model.c \
	unicode-script-model.h \
	unicode-script-codepoint-list.c \
	unicode-script-codepoint-list.h \
	unicode-info.c \
	unicode-info.h

libunicode_la_CPPFLAGS = \
	$(AM_CPPFLAGS)

libunicode_la_CFLAGS = \
	$(GTK_CFLAGS)	\
	$(AM_CFLAGS)

libunicode_la_LDFLAGS = \
	$(AM_LDADD)

# Dist & cleanup

EXTRA_DIST = \
	unicode-blocks.h \
	unicode-categories.h \
	unicode-i18n.h \
	unicode-names.h \
	unicode-nameslist.h \
	unicode-scripts.h \
	unicode-unihan.h \
	unicode-versions.h

CLEANFILES =

MAINTAINERCLEANFILES = \
	Makefile.in \
	Unicode.*

# introspection

-include $(INTROSPECTION_MAKEFILE)

INTROSPECTION_GIRS = Unicode.gir
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(srcdir) --warn-all
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

if HAVE_INTROSPECTION

Unicode.gir: libunicode.la
Unicode_gir_INCLUDES = Pango-1.0 Gdk-$(GTK_API_VERSION) Gtk-$(GTK_API_VERSION)
Unicode_gir_SCANNERFLAGS = --c-include "unicode.h"
Unicode_gir_LIBS = libunicode.la
Unicode_gir_FILES = $(libunicode_la_SOURCES)
Unicode_gir_NAMESPACE = Unicode

girdir = $(datadir)/gir-1.0
nodist_gir_DATA = $(INTROSPECTION_GIRS)

typelibdir = $(libdir)/girepository-1.0
nodist_typelib_DATA = $(INTROSPECTION_GIRS:.gir=.typelib)

CLEANFILES += $(nodist_gir_DATA) $(nodist_typelib_DATA)

if ENABLE_VAPIGEN

-include $(VAPIGEN_MAKEFILE)

Unicode.vapi: Unicode.gir

VAPIGEN_VAPIS = Unicode.vapi

Unicode_vapi_DEPS = \
	glib-2.0 \
	pango \
	gdk-$(GTK_API_VERSION) \
	gtk+-$(GTK_API_VERSION)

Unicode_vapi_METADATADIRS = $(srcdir)
Unicode_vapi_VAPIDIRS = $(datadir)/vala/vapi
Unicode_vapi_FILES = Unicode.gir

vapidir = $(VAPIGEN_VAPIDIR)
nodist_vapi_DATA = $(VAPIGEN_VAPIS)

CLEANFILES += $(nodist_vapi_DATA)

# HAVE_INTROSPECTION
endif
# ENABLE_VAPIGEN
endif

