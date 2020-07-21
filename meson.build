project('font-manager', ['c', 'vala'], license: 'GPL3', version: '0.7.8')

if meson.version().version_compare('< 0.50')
    error('Meson version is @0@ but project requires >= 0.50'.format(meson.version()))
endif

meson_has_summary_function = meson.version().version_compare('>= 0.53')

cc = meson.get_compiler('c')
# There has to be a better way to require a specific vala version, right?
valac = meson.get_compiler('vala')
if not valac.version().version_compare('>= 0.42')
    error('Vala compiler version is @0@ but project requires >= 0.42'.format(valac.version()))
endif
m_dep = cc.find_library('m', required: false)
fontconfig = dependency('fontconfig', version: '>= 2.1')
freetype = dependency('freetype2', version: '>= 2.5')
json = dependency('json-glib-1.0', version: '>= 0.15')
gio = dependency('gio-2.0', version: '>= 2.44')
glib = dependency('glib-2.0', version: '>= 2.62')
gmodule = dependency('gmodule-2.0', version: '>= 2.44')
gobject = dependency('gobject-2.0', version: '>= 2.44')
gtk = dependency('gtk+-3.0', version: '>= 3.22')
pango = dependency('pango', version: '>= 1.4')
pangoft2 = dependency('pangoft2', version: '>= 1.4')
sqlite = dependency('sqlite3', version: '>= 3.8')
xml = dependency('libxml-2.0', version: '>= 2.9')

base_deps = declare_dependency(
    dependencies: [m_dep, json, gio, glib, gmodule, gobject, gtk, pango, sqlite, xml],
    include_directories: include_directories('.', 'lib/common', 'lib/orthographies', 'lib/unicode')
)

project_deps = declare_dependency(
    dependencies: [ base_deps, fontconfig, freetype, pangoft2 ]
)

i18n = import('i18n')
gnome= import('gnome')
python = import('python').find_installation('python3')

reproducible = get_option('reproducible') ? '-DREPRODUCIBLE' : '-DNOT_REPRODUCIBLE'

add_global_arguments(
    '-DG_LOG_DOMAIN="[@0@]"'.format(meson.project_name()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DGDK_DISABLE_DEPRECATED',
    '-DGTK_DISABLE_DEPRECATED',
    reproducible,
    language: 'c'
)

config_vapi_file = files('config.vapi')
prefix = get_option('prefix')
datadir = get_option('datadir')
pkglib_dir = join_paths(prefix, get_option('libdir'), meson.project_name())
pkglibexec_dir = join_paths(prefix, get_option('libexecdir'), meson.project_name())

config = configuration_data()
config.set('PACKAGE_NAME', meson.project_name())
config.set('PACKAGE_VERSION', meson.project_version())
config.set('PACKAGE_URL', 'http://fontmanager.github.io/')
config.set('PACKAGE_BUGREPORT', 'https://github.com/FontManager/master/issues')
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('PKGLIBEXECDIR', pkglibexec_dir)
config.set('prefix', prefix)
config.set('abs_top_srcdir', meson.current_build_dir())
configure_file(input: 'config.h.meson', output: 'config.h', configuration: config)

file_list_template = '''
from glob import glob
for f in sorted(glob('**/*.@0@', recursive=True)):
    print(f)
'''

list_sources = file_list_template.format('c')
list_headers = file_list_template.format('h')
list_vala_sources = file_list_template.format('vala')

if get_option('enable-nls')
    subdir('po')
endif

subdir('help')
subdir('lib')
subdir('src')
subdir('data')

if get_option('nautilus') or get_option('nemo')
    subdir('extensions')
endif

if get_option('gtk-doc')
    subdir('docs')
endif

meson.add_install_script('meson_post_install.py')
meson.add_dist_script('meson_dist.py')

if meson_has_summary_function

    summary(
        {
            'Font Manager': get_option('manager'),
            'Font Viewer': get_option('viewer'),
            'API Documentation': get_option('gtk-doc'),
            'Help Documents': get_option('yelp-doc'),
            'Nautilus extension': get_option('nautilus'),
            'Nemo extension': get_option('nemo'),
            'Translations': get_option('enable-nls'),
            'Reproducible build': get_option('reproducible')
        },
        section: '''Project options
        ''',
        bool_yn: true
    )

    summary(
        {
            'prefix': prefix,
            'bindir': join_paths(prefix, get_option('bindir')),
            'libdir': join_paths(prefix, get_option('libdir'), meson.project_name()),
            'libexecdir': join_paths(prefix, get_option('libexecdir'), meson.project_name()),
            'datadir': join_paths(prefix, datadir)
        },
        section: '''Directories
        '''
    )

endif

