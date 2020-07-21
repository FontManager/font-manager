
libfontmanager_gresource_xml_file = files('gresources.xml')

libfontmanager_gresources = gnome.compile_resources('libfontmanager-gresources',
                                                    libfontmanager_gresource_xml_file)


result = run_command(python, '-c', list_sources)

common_sources = result.stdout().strip().split('\n')
common_sources += [
    configure_file(
        input: 'font-manager-utils.c.in',
        output: 'font-manager-utils.c',
        configuration: config
    )
]

result = run_command(python, '-c', list_headers)

common_headers = result.stdout().strip().split('\n')

HEADER = join_paths(meson.current_build_dir(), 'font-manager.h')

WRITE_HEADER = '''
from glob import glob

def filelist (ext):
    for f in sorted(glob('@0@/*.{}*'.format(ext), recursive=True)):
        yield f

with open('@1@', 'w') as H:
    H.write('#pragma once\n')
    for f in filelist('h'):
        f = f.replace('@2@/', '')
        H.write('#include "{}"\n'.format(f))
'''.format(meson.current_source_dir(), HEADER, meson.current_source_dir())

configure_file(
    command: [python, '-c', WRITE_HEADER],
    output: 'font-manager.h'
)

libcommon = both_libraries('common',
                            [ common_sources, libfontmanager_gresources ],
                            dependencies: project_deps,
                            link_with: libunicode)

common_gir = gnome.generate_gir(libcommon,
                                sources: [ common_sources, common_headers],
                                namespace: 'FontManager',
                                nsversion: meson.project_version(),
                                dependencies: [project_deps, unicode_vapi],
                                extra_args: [ '--warn-all' ],
                                includes: [
                                    'GLib-2.0',
                                    'Gio-2.0',
                                    'Gdk-3.0',
                                    'Gtk-3.0',
                                    'Json-1.0',
                                    'libxml2-2.0'
                                ])

configure_file(
    input: 'font-manager-common.metadata',
    output: 'FontManager-@0@.metadata'.format(meson.project_version()),
    copy: true
)

common_vapi = gnome.generate_vapi('font-manager-common',
                                    sources: [
                                        common_gir[0],
                                        unicode_gir[0],
                                        'font-manager-common.vala'
                                    ],
                                    vapi_dirs: [
                                        meson.current_build_dir(),
                                        join_paths(meson.build_root(), 'lib', 'unicode'),
                                        join_paths(meson.source_root(), 'lib', 'unicode')
                                    ],
                                    metadata_dirs: meson.current_build_dir(),
                                    packages: [
                                        'glib-2.0',
                                        'gio-2.0',
                                        'gdk-3.0',
                                        'gtk+-3.0',
                                        'json-glib-1.0',
                                        'libxml-2.0',
                                        'sqlite3',
                                        'Unicode'
                                    ])
