resource_dir = ${abs_top_builddir}/resources

AM_VALAFLAGS = \
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
--target-glib 2.38 \
--gresources $(resource_dir)/FontManagerGResource.xml

font_manager_CPPFLAGS = \
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

font_manager_VALASOURCES = \
Main.vala \
Common/About.vala \
Common/ArchiveManager.vala \
Common/Collections.vala \
Common/Components.vala \
Common/Constants.vala \
Common/Database.vala \
Common/FontInfo.vala \
Common/Library.vala \
Common/Utils.vala \
Filters/Category.vala \
Filters/Collection.vala \
Filters/Filter.vala \
Filters/SearchResult.vala \
Filters/Unsorted.vala \
FontConfig/Accept.vala \
FontConfig/Config.vala \
FontConfig/Directories.vala \
FontConfig/Enums.vala \
FontConfig/Family.vala \
FontConfig/Families.vala \
FontConfig/Font.vala \
FontConfig/Properties.vala \
FontConfig/Reject.vala \
FontConfig/Selections.vala \
FontConfig/XmlWriter.vala \
Glue/Glue.vala \
Json/Cacheable.vala \
Json/JsonWriter.vala \
Models/CategoryModel.vala \
Models/CollectionModel.vala \
Models/FontModel.vala \
Models/UserFontModel.vala \
UX/MainWindow.vala \
UX/CharacterMap.vala \
UX/GtkUtils.vala \
UX/Controls/CollectionControls.vala \
UX/Controls/CompareControls.vala \
UX/Controls/FontListControls.vala \
UX/Controls/PreviewControls.vala \
UX/Controls/TitleBar.vala \
UX/Controls/ModeSelector.vala \
UX/Dialogs/Migration.vala \
UX/Dialogs/NotImplemented.vala \
UX/Dialogs/FileSelector.vala \
UX/Sidebar/SideBar.vala \
UX/Sidebar/MainSideBar.vala \
UX/Sidebar/CharacterMapSideBar.vala \
UX/Trees/CollectionTree.vala \
UX/Trees/CategoryTree.vala \
UX/Trees/FontList.vala \
UX/Trees/FontListTree.vala \
UX/Widgets/FontScale.vala \
UX/Widgets/AdjustablePreview.vala \
UX/Widgets/CellRendererPill.vala \
UX/Widgets/TextViews.vala \
UX/Widgets/MultiDNDTreeView.vala \
UX/Widgets/ThinPaned.vala \
UX/Views/Compare.vala \
UX/Views/FontPreview.vala \
UX/Views/CharacterTable.vala \
UX/Views/Browse.vala

FontManagerGResource.c :
	cd $(resource_dir) && \
	glib-compile-resources --generate-source $(resource_dir)/FontManagerGResource.xml --target=$(abs_srcdir)/FontManagerGResource.c && \
	cd $(abs_srcdir)

BUILT_SOURCES = FontManagerGResource.c

font_manager_SOURCES = \
	$(font_manager_VALASOURCES) \
	Glue/_Glue_.c \
	Glue/Private.h \
	$(BUILT_SOURCES)

bin_PROGRAMS = font-manager

EXTRA_DIST = $(font_manager_VALASOURCES)

dist-hook:
	cd $(distdir) && \
	rm -f $(font_manager_VALASOURCES:.vala=.c) $(BUILT_SOURCES) font_manager_vala.stamp

clean-local:
	rm -f $(font_manager_VALASOURCES:.vala=.c) $(BUILT_SOURCES) font_manager_vala.stamp



