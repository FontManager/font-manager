
result = run_command(python, '-c', list_vala_sources)
libvala_sources = result.stdout().strip().split('\n')

libvala = static_library('FontManagerVala',
                            [libvala_sources, config_vapi_file],
                            dependencies: [
                                common_vapi, unicode_vapi, m_dep, json, gio,
                                glib, gobject, gtk, pango, sqlite, xml
                            ],
                            link_with: [libcommon, libunicode],
                            include_directories: default_includes)

libvala_includes = include_directories('.')

libvala_headers = [
    configure_file(command: ['touch', 'FontManagerVala.h'], output: 'FontManagerVala.h'),
    configure_file(command: ['touch', 'FontManagerVala.vapi'], output: 'FontManagerVala.vapi')
]
