include $(top_srcdir)/Flags.mk

_SOURCES_ = \
	font-manager-fontconfig.c \
	font-manager-alias.c \
	font-manager-aliases.c \
	font-manager-codepoint-list.c \
	font-manager-database.c \
	font-manager-family.c \
	font-manager-filter.c \
	font-manager-font.c \
	font-manager-font-info.c \
	font-manager-font-model.c \
	font-manager-freetype.c \
	font-manager-json-proxy.c \
	font-manager-json-proxy.h \
	font-manager-orthography.c \
	font-manager-properties.c \
	font-manager-selections.c \
	font-manager-source.c \
	font-manager-xml-writer.c \
	json.c \
	string-hashset.c \
	utils.c

_HEADERS_ = $(_SOURCES_:%.c=%.h)

libfmcommon_@PACKAGE_VERSION@_la_SOURCES = \
	$(_SOURCES_) \
	font-manager-gresource.c \
	json-proxy-object-properties.h

libfmcommon_@PACKAGE_VERSION@_la_CFLAGS = $(AM_CFLAGS)

libfmcommon_@PACKAGE_VERSION@_la_LDFLAGS = $(AM_LDADD)

noinst_LTLIBRARIES = libfmcommon-@PACKAGE_VERSION@.la

CLEANFILES =
MAINTAINERCLEANFILES = Makefile.in utils.c
EXTRA_DIST = $(_HEADERS_) utils.c.in license.h vendor.h

# Vala bindings

if HAVE_INTROSPECTION

-include $(INTROSPECTION_MAKEFILE)

INTROSPECTION_GIRS = FontManager.gir
INTROSPECTION_SCANNER_ARGS = --warn-all --accept-unprefixed -I../unicode/ -I../orthographies
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

FontManager.gir: $(noinst_LTLIBRARIES)
FontManager_gir_NAMESPACE = FontManager
FontManager_gir_INCLUDES = Json-1.0 libxml2-2.0 Gdk-$(GTK_API_VERSION) Gtk-$(GTK_API_VERSION)
FontManager_gir_LIBS = $(noinst_LTLIBRARIES) ../unicode/libfmunicode-@PACKAGE_VERSION@.la
FontManager_gir_FILES = $(_SOURCES_) $(_HEADERS_)
FontManager_gir_SCANNERFLAGS = --nsversion @PACKAGE_VERSION@

girdir = $(DESTDIR)$(datadir)/gir-1.0
typelibdir = $(DESTDIR)$(libdir)/girepository-1.0
gir_DATA = $(INTROSPECTION_GIRS)
typelib_DATA = $(INTROSPECTION_GIRS:.gir=.typelib)

if ENABLE_VAPIGEN

-include $(VAPIGEN_MAKEFILE)

FontManager.vapi: FontManager.gir
FontManager_vapi_METADATADIRS = $(srcdir)
FontManager_vapi_VAPIDIRS = $(srcdir) ../unicode
FontManager_vapi_GIRDIRS = $(srcdir)
FontManager_vapi_FILES = FontManager.gir FontManager-custom.vala

VAPIGEN_VAPIS = FontManager.vapi

FontManager_vapi_DEPS = \
	gdk-$(GTK_API_VERSION) \
	gtk+-$(GTK_API_VERSION) \
	json-glib-1.0 \
	libxml-2.0 \
	sqlite3 \
	Unicode

vapidir = $(DESTDIR)$(datadir)/vala/vapi
vapi_DATA = $(VAPIGEN_VAPIS)

# ENABLE_VAPIGEN
endif

CLEANFILES += $(gir_DATA) $(typelib_DATA)

# HAVE_INTROSPECTION
endif


EXTRA_DIST += FontManager.vapi FontManager.metadata FontManager-custom.vala
