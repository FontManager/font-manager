
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
gnome = import('gnome')
json = dependency('json-glib-1.0', version: '>= 0.15')
gmodule = dependency('gmodule-2.0', version: '>= 2.70')
gtk = dependency('gtk4', version: '>= 4.0')

base_deps = declare_dependency(
    dependencies: [json, gmodule, gtk],
)

add_global_arguments(
    '-DG_LOG_DOMAIN="[@0@]"'.format(meson.project_name()),
    language: 'c'
)

subdir('test')

