
libfontmanager_gresource_xml_file = files('gresources.xml')

libfontmanager_gresources = gnome.compile_resources('libfontmanager-gresources', libfontmanager_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources)
libvala_sources = result.stdout().strip().split('\n')

libvala = static_library('FontManager',
                            [libvala_sources, libfontmanager_gresources, config_vapi_file],
                            dependencies: [
                                common_vapi, unicode_vapi, m_dep, json, gio,
                                glib, gobject, gtk, pango, sqlite, xml
                            ],
                            link_with: [libcommon, libunicode],
                            include_directories: default_includes)

libvala_includes = include_directories('.')

libvala_headers = [
    configure_file(command: ['touch', 'FontManager.h'], output: 'FontManager.h'),
    configure_file(command: ['touch', 'FontManager.vapi'], output: 'FontManager.vapi')
]
