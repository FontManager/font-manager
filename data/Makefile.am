
org.gnome.FontManager.desktop: org.gnome.FontManager.desktop.in
	$(AM_V_GEN)$(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

org.gnome.FontViewer.desktop: org.gnome.FontViewer.desktop.in
	$(AM_V_GEN)$(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

org.gnome.FontManager.appdata.xml: org.gnome.FontManager.appdata.xml.in
	$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

org.gnome.FontViewer.appdata.xml: org.gnome.FontViewer.appdata.xml.in
	$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

org.gnome.FontManager.service:
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontManager'; \
	echo 'Exec=${bindir}/$(PACKAGE_NAME) --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

org.gnome.FontViewer.service:
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
	echo 'Name=org.gnome.FontViewer'; \
	echo 'Exec=${pkglibexecdir}/font-viewer --gapplication-service') > $@.tmp && \
	mv $@.tmp $@

gsettings_SCHEMAS = \
	org.gnome.FontManager.gschema.xml \
	org.gnome.FontViewer.gschema.xml

@GSETTINGS_RULES@

desktopdir = $(datadir)/applications
dist_desktop_in_files = \
	org.gnome.FontManager.desktop.in.in \
	org.gnome.FontViewer.desktop.in.in
dist_desktop_DATA = $(dist_desktop_in_files:.desktop.in.in=.desktop)

appdatadir = $(datadir)/metainfo
appdata_in_files = \
	org.gnome.FontManager.appdata.xml.in.in \
	org.gnome.FontViewer.appdata.xml.in.in
appdata_DATA = $(appdata_in_files:.xml.in.in=.xml)

dbusservicedir = $(datadir)/dbus-1/services
dbusservice_DATA = \
	org.gnome.FontManager.service \
	org.gnome.FontViewer.service

CONFIG_STATUS_DEPENDENCIES = \
	$(dist_desktop_in_files)  \
	$(appdata_in_files)

CLEANFILES = \
	$(appdata_DATA) \
	$(dist_desktop_DATA) \
	$(dbusservice_DATA) \
	gschemas.compiled

DISTCLEANFILES = \
	$(appdata_DATA) \
	$(dist_desktop_DATA) \
	$(dbusservice_DATA)

EXTRA_DIST = \
	icons \
	ui \
	FontManagerGResource.xml \
	FontManager.css \
	$(gsettings_SCHEMAS) \
	$(dist_desktop_in_files) \
	$(appdata_in_files)

MAINTAINERCLEANFILES = \
	Makefile.in

# Allow running without installation
compile-gsettings-schemas:
	$(GLIB_COMPILE_SCHEMAS) ./

all: compile-gsettings-schemas org.gnome.FontManager.service org.gnome.FontViewer.service org.gnome.FontManager.appdata.xml org.gnome.FontViewer.appdata.xml
	$(SED) -i 's|\@PKGLIBEXECDIR\@|${pkglibexecdir}|g' org.gnome.FontViewer.desktop

.PHONY: compile-gsettings-schemas
