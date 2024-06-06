
file_list_template = '''
from glob import glob
for f in sorted(glob('*.@0@', recursive=False)):
    print(f)
'''

list_sources = file_list_template.format('c')
list_headers = file_list_template.format('h')

subdir('data')
subdir('fontconfig')
subdir('common')
subdir('gtk')
subdir('json')

src_includes = [
    common_includes,
    fontconfig_includes,
    gtk_includes,
    json_includes,
    unicode_includes,
]

includes += [ include_directories('.'),  src_includes + data_includes ]

sources = [
    common_sources,
    fontconfig_sources,
    gtk_sources,
    json_sources,
    unicode_sources
]

headers = [
    common_headers,
    fontconfig_headers,
    gtk_headers,
    json_headers,
    unicode_headers
]

header = join_paths(meson.current_build_dir(), 'font-manager.h')

write_header = '''
from glob import glob
from os.path import basename

def filelist (ext):
    for f in sorted(glob('@0@/*/*.{}*'.format(ext), recursive=True)):
        yield f

with open('@1@', 'w') as H:
    H.write('#pragma once\n')
    for f in filelist('h'):
        H.write('#include "{}"\n'.format(basename(f)))
'''.format(meson.current_source_dir(), header, meson.current_source_dir())

library_header_file = configure_file(
    command: [python, '-c', write_header],
    output: 'font-manager.h'
)

gresources_xml_file = files('gresources.xml')

gresources = gnome.compile_resources('libfontmanager-gresources', gresources_xml_file)

libfontmanager = shared_library('fontmanager',
                                sources: [ sources, headers, gresources ],
                                include_directories: includes,
                                version: meson.project_version(),
                                dependencies: base_deps,
                                install: true,
                                install_dir: pkglib_dir)

gir = gnome.generate_gir(libfontmanager,
                         sources: [ sources, headers ],
                         namespace: 'FontManager',
                         nsversion: meson.project_version(),
                         dependencies: base_deps,
                         extra_args: [ '--warn-all' ],
                         includes: [ 'Gtk-4.0', 'Json-1.0', 'libxml2-2.0' ]
)

configure_file(
    input: 'font-manager.metadata',
    output: 'FontManager-@0@.metadata'.format(meson.project_version()),
    copy: true
)

vapi = gnome.generate_vapi('font-manager',
                            sources: [ gir[0], 'font-manager.vala' ],
                            vapi_dirs: meson.current_build_dir(),
                            metadata_dirs: meson.current_source_dir(),
                            packages: [ 'gtk4', 'json-glib-1.0', 'libxml-2.0', 'sqlite3' ]
)

if get_option('gtk-doc')
    subdir('docs')
endif

