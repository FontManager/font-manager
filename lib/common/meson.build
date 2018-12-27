
result = run_command(python, '-c', list_sources)

common_sources = result.stdout().strip().split('\n') + [
    configure_file(
        input: 'utils.c.in',
        output: 'utils.c',
        configuration: config
    ),
    gnome.compile_resources('font-manager-gresource',
                            gresource_xml_file,
                            source_dir: join_paths(meson.source_root(), 'data'))
]

result = run_command(python, '-c', list_headers)

common_headers = []

foreach h: result.stdout().strip().split('\n')
    if (h.startswith('json-proxy'))
        continue
    endif
    common_headers += h
endforeach

libcommon = both_libraries('common',
                            common_sources,
                            dependencies: [
                                json, gio, glib, gobject, gtk, pango, sqlite,
                                xml, fontconfig, freetype, pangoft2
                            ],
                            link_with: libunicode,
                            include_directories: default_includes)

common_gir = gnome.generate_gir(libcommon,
                                sources: [ common_sources, common_headers],
                                namespace: 'FontManager',
                                nsversion: meson.project_version(),
                                dependencies: [
                                    json, gio, glib, gobject, gtk, pango, sqlite,
                                    xml, fontconfig, freetype, pangoft2, unicode_vapi
                                ],
                                extra_args: [
                                    '--warn-all',
                                    '--accept-unprefixed'
                                ],
                                includes: [
                                    'Json-1.0',
                                    'Gdk-3.0',
                                    'Gtk-3.0',
                                    'libxml2-2.0'
                                ],
                                include_directories: default_includes)

configure_file(
    input: 'FontManager.metadata',
    output: 'FontManager-@0@.metadata'.format(meson.project_version()),
    copy: true
)

common_vapi = gnome.generate_vapi('FontManager-@0@'.format(meson.project_version()),
                                    sources: [
                                        common_gir[0],
                                        'FontManager-custom.vala'
                                    ],
                                    vapi_dirs: [
                                        meson.current_build_dir(),
                                        join_paths(meson.build_root(), 'lib', 'unicode')
                                    ],
                                    metadata_dirs: meson.current_build_dir(),
                                    packages: [
                                        'glib-2.0',
                                        'gdk-3.0',
                                        'gtk+-3.0',
                                        'json-glib-1.0',
                                        'libxml-2.0',
                                        'sqlite3',
                                        'Unicode-@0@'.format(meson.project_version())
                                    ])
