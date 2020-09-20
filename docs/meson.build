
gtk_doc = dependency('gtk-doc', version: '>= 1.25')

glib_prefix = dependency('glib-2.0').get_pkgconfig_variable('prefix')
glib_docpath = join_paths(glib_prefix, 'share', 'gtk-doc', 'html')
docpath = join_paths(get_option('datadir'), 'gtk-doc', 'html')

font_manager_reference = configure_file(
    input: 'font-manager.xml.in',
    output: 'font-manager.xml',
    configuration: config
)

gnome.gtkdoc('font-manager',
    main_xml: join_paths(meson.build_root(), 'docs', 'font-manager.xml'),
    namespace: 'font_manager',
    src_dir: [
        join_paths(meson.source_root(), 'lib', 'common'),
        join_paths(meson.build_root(), 'lib', 'common'),
        join_paths(meson.source_root(), 'lib', 'unicode')
    ],
    scan_args: [
        '--rebuild-types',
        '--rebuild-sections',
    ],
    fixxref_args: [
        '--html-dir=@0@'.format(docpath),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'glib')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'gobject')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'gio')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'json-glib')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'atk')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'gdk3')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'gtk3')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'pango')),
        '--extra-dir=@0@'.format(join_paths(glib_docpath, 'libxml2')),
    ],
    dependencies: libfontmanager_deps,
    install: true
)
