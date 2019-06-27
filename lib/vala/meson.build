
libfontmanager_gresource_xml_file = files('gresources.xml')

libfontmanager_gresources = gnome.compile_resources('libfontmanager-gresources', libfontmanager_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources)
libvala_sources = result.stdout().strip().split('\n')

vala_gir_file = 'FontManager-@0@.gir'.format(meson.project_version())
vala_header_file = 'FontManager-@0@.h'.format(meson.project_version())
vala_vapi_file = 'FontManager-@0@.vapi'.format(meson.project_version())

libvala_includes = include_directories('.')

libvala_headers = []

foreach f: [vala_header_file, vala_vapi_file]
    libvala_headers += configure_file(command: ['touch', f], output: f)
endforeach

libvala = static_library('FontManager',
                            [libvala_sources, libfontmanager_gresources, config_vapi_file],
                            dependencies: [
                                common_vapi, unicode_vapi, m_dep, json, gio,
                                glib, gobject, gtk, pango, sqlite, xml
                            ],
                            # vala_gir: vala_gir_file,
                            vala_header: vala_header_file,
                            vala_vapi: vala_vapi_file,
                            link_with: [libcommon, libunicode],
                            include_directories: default_includes)


