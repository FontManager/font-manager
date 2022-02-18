
project('font-manager', ['c', 'vala'], license: 'GPL3', version: '0.9.0')

if meson.version().version_compare('< 0.53')
    error('Meson version is @0@ but project requires >= 0.53'.format(meson.version()))
endif

cc = meson.get_compiler('c')
# There has to be a better way to require a specific vala version, right?
valac = meson.get_compiler('vala')
if not valac.version().version_compare('>= 0.42')
    error('Vala compiler version is @0@ but project requires >= 0.42'.format(valac.version()))
endif
m_dep = cc.find_library('m', required: false)
python = import('python').find_installation('python3')
gnome = import('gnome')
json = dependency('json-glib-1.0', version: '>= 0.15')
gmodule = dependency('gmodule-2.0', version: '>= 2.70')
gtk = dependency('gtk4', version: '>= 4.0')

file_list_template = '''
from glob import glob
for f in sorted(glob('**/*.@0@', recursive=True)):
    print(f)
'''

list_sources = file_list_template.format('c')
list_headers = file_list_template.format('h')

base_deps = declare_dependency(
    dependencies: [m_dep, json, gmodule, gtk],
    include_directories: include_directories('.', 'lib/gtk')
)

add_global_arguments(
    '-DG_LOG_DOMAIN="[@0@]"'.format(meson.project_name()),
    '-DGETTEXT_PACKAGE="font-manager"',
    language: 'c'
)

subdir('lib')
subdir('test')

